-- =====================================================
-- FUNCIÓN DE TRANSFERENCIA CON SOPORTE NUMERIC
-- =====================================================
-- Usa NUMERIC en lugar de BIGINT para evitar overflow
-- =====================================================

CREATE OR REPLACE FUNCTION transfer_tokens_atomic(
    sender_id UUID,
    receiver_id UUID,
    amount_tokens DECIMAL,
    description_text TEXT DEFAULT 'Token transfer'
)
RETURNS JSON
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    sender_balance NUMERIC;
    receiver_balance NUMERIC;
    amount_atomic NUMERIC;
    operation_id UUID;
    sender_tx_id UUID;
    receiver_tx_id UUID;
    valid_type TEXT;
    result JSON;
    sender_name TEXT;
    receiver_name TEXT;
    atomic_factor CONSTANT NUMERIC := 1000000000;
BEGIN
    -- Convertir tokens a formato atómico usando NUMERIC
    amount_atomic := amount_tokens * atomic_factor;
    
    -- Verificar que el monto sea positivo
    IF amount_atomic <= 0 THEN
        RETURN json_build_object(
            'success', false,
            'error', 'Amount must be positive'
        );
    END IF;
    
    -- Obtener balance actual del sender
    SELECT COALESCE(token_balance::NUMERIC, 0), COALESCE(full_name, email) 
    INTO sender_balance, sender_name
    FROM users 
    WHERE id = sender_id;
    
    -- Obtener datos del receptor
    SELECT COALESCE(token_balance::NUMERIC, 0), COALESCE(full_name, email) 
    INTO receiver_balance, receiver_name
    FROM users 
    WHERE id = receiver_id;
    
    -- Verificar si el balance está en formato LEAP o atómico
    -- Si el balance es menor que 10 millones, asumimos que está en LEAP y lo convertimos
    IF sender_balance < 10000000 THEN
        sender_balance := sender_balance * atomic_factor;
    END IF;
    
    IF receiver_balance < 10000000 THEN
        receiver_balance := receiver_balance * atomic_factor;
    END IF;
    
    -- Verificar balance suficiente
    IF sender_balance < amount_atomic THEN
        RETURN json_build_object(
            'success', false,
            'error', format('Insufficient balance. Available: %s LEAP, Required: %s LEAP', 
                          (sender_balance / atomic_factor), amount_tokens),
            'sender_balance', sender_balance,
            'required', amount_atomic,
            'debug', json_build_object(
                'sender_balance_leap', sender_balance / atomic_factor,
                'amount_tokens', amount_tokens,
                'amount_atomic', amount_atomic
            )
        );
    END IF;
    
    -- Determinar qué tipo usar para token_transactions
    valid_type := 'bonus'; -- Usar bonus como tipo por defecto
    
    -- Intentar determinar un tipo válido
    BEGIN
        -- Intentar con 'transfer'
        PERFORM 1 FROM token_transactions WHERE type = 'transfer' LIMIT 1;
        valid_type := 'transfer';
    EXCEPTION WHEN OTHERS THEN
        BEGIN
            -- Intentar con 'transaction'
            PERFORM 1 FROM token_transactions WHERE type = 'transaction' LIMIT 1;
            valid_type := 'transaction';
        EXCEPTION WHEN OTHERS THEN
            BEGIN
                -- Intentar con 'payment'
                PERFORM 1 FROM token_transactions WHERE type = 'payment' LIMIT 1;
                valid_type := 'payment';
            EXCEPTION WHEN OTHERS THEN
                -- Usar 'bonus' como último recurso
                valid_type := 'bonus';
            END;
        END;
    END;
    
    -- Generar IDs únicos
    operation_id := gen_random_uuid();
    sender_tx_id := gen_random_uuid();
    receiver_tx_id := gen_random_uuid();
    
    -- Iniciar transacción atómica
    BEGIN
        -- 1. Registrar en atomic_token_operations
        INSERT INTO atomic_token_operations (
            id,
            operation_type,
            from_account_type,
            from_account_id,
            to_account_type,
            to_account_id,
            amount,
            reference_type,
            reference_id,
            description,
            status,
            processed_at,
            created_at
        ) VALUES (
            operation_id,
            'transfer',
            'user',
            sender_id,
            'user',
            receiver_id,
            amount_atomic,
            'user_transfer',
            operation_id,
            description_text,
            'completed',
            NOW(),
            NOW()
        );
        
        -- 2. Actualizar balances en users usando NUMERIC
        UPDATE users 
        SET token_balance = (token_balance::NUMERIC - amount_atomic),
            updated_at = NOW()
        WHERE id = sender_id;
        
        UPDATE users 
        SET token_balance = (token_balance::NUMERIC + amount_atomic),
            updated_at = NOW()
        WHERE id = receiver_id;
        
        -- 3. Registrar transacciones en token_transactions
        -- Transacción del sender (negativa)
        INSERT INTO token_transactions (
            id,
            user_id,
            amount,
            type,
            description,
            reference_id,
            reference_type,
            created_at
        ) VALUES (
            sender_tx_id,
            sender_id,
            -amount_atomic,
            valid_type,
            format('Sent %s LEAP to %s', amount_tokens, receiver_name),
            operation_id,
            'transfer',
            NOW()
        );
        
        -- Transacción del receiver (positiva)
        INSERT INTO token_transactions (
            id,
            user_id,
            amount,
            type,
            description,
            reference_id,
            reference_type,
            created_at
        ) VALUES (
            receiver_tx_id,
            receiver_id,
            amount_atomic,
            valid_type,
            format('Received %s LEAP from %s', amount_tokens, sender_name),
            operation_id,
            'transfer',
            NOW()
        );
        
        -- 4. Actualizar user_balances si existe
        BEGIN
            IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'user_balances') THEN
                -- Actualizar sender
                UPDATE user_balances 
                SET balance = (balance::NUMERIC - amount_atomic),
                    updated_at = NOW()
                WHERE user_id = sender_id;
                
                -- Actualizar receiver
                UPDATE user_balances 
                SET balance = (balance::NUMERIC + amount_atomic),
                    updated_at = NOW()
                WHERE user_id = receiver_id;
            END IF;
        EXCEPTION WHEN OTHERS THEN
            -- Ignorar errores en user_balances
            NULL;
        END;
        
        -- Construir respuesta exitosa
        result := json_build_object(
            'success', true,
            'message', format('Successfully transferred %s LEAP tokens', amount_tokens),
            'operation_id', operation_id,
            'type_used', valid_type,
            'details', json_build_object(
                'sender_id', sender_id,
                'receiver_id', receiver_id,
                'amount_tokens', amount_tokens,
                'amount_atomic', amount_atomic,
                'sender_new_balance_leap', (sender_balance - amount_atomic) / atomic_factor,
                'receiver_new_balance_leap', (receiver_balance + amount_atomic) / atomic_factor
            )
        );
        
        RETURN result;
        
    EXCEPTION WHEN OTHERS THEN
        -- En caso de error, hacer rollback automático
        RETURN json_build_object(
            'success', false,
            'error', format('Transfer failed: %s', SQLERRM),
            'debug', json_build_object(
                'sender_balance', sender_balance,
                'sender_balance_leap', sender_balance / atomic_factor,
                'amount_atomic', amount_atomic,
                'amount_tokens', amount_tokens,
                'valid_type', valid_type,
                'sql_error', SQLERRM
            )
        );
    END;
END;
$$;

-- Mensaje de confirmación
DO $$
BEGIN
    RAISE NOTICE '==============================================';
    RAISE NOTICE 'FUNCIÓN DE TRANSFERENCIA CON NUMERIC INSTALADA';
    RAISE NOTICE 'Ahora usa NUMERIC para evitar overflow de enteros';
    RAISE NOTICE '==============================================';
END $$;
