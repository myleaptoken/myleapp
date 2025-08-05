-- =====================================================
-- FUNCIÓN DE TRANSFERENCIA COMPLETA CON NUMERIC
-- =====================================================
-- Versión final que maneja correctamente todos los formatos
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
    new_sender_balance NUMERIC;
    new_receiver_balance NUMERIC;
BEGIN
    -- Log de inicio
    RAISE NOTICE 'Iniciando transferencia: % LEAP de % a %', amount_tokens, sender_id, receiver_id;
    
    -- Convertir tokens a formato atómico usando NUMERIC
    amount_atomic := amount_tokens * atomic_factor;
    
    -- Verificar que el monto sea positivo
    IF amount_atomic <= 0 THEN
        RETURN json_build_object(
            'success', false,
            'error', 'Amount must be positive',
            'debug', json_build_object(
                'amount_tokens', amount_tokens,
                'amount_atomic', amount_atomic
            )
        );
    END IF;
    
    -- Obtener balance actual del sender
    SELECT COALESCE(token_balance::NUMERIC, 0), COALESCE(full_name, email) 
    INTO sender_balance, sender_name
    FROM users 
    WHERE id = sender_id;
    
    IF sender_balance IS NULL THEN
        RETURN json_build_object(
            'success', false,
            'error', 'Sender not found'
        );
    END IF;
    
    -- Obtener datos del receptor
    SELECT COALESCE(token_balance::NUMERIC, 0), COALESCE(full_name, email) 
    INTO receiver_balance, receiver_name
    FROM users 
    WHERE id = receiver_id;
    
    IF receiver_balance IS NULL THEN
        RETURN json_build_object(
            'success', false,
            'error', 'Receiver not found'
        );
    END IF;
    
    -- Detectar formato del balance y normalizar a formato atómico
    -- Si el balance es menor que 10 millones, asumimos que está en LEAP
    IF sender_balance < 10000000 THEN
        sender_balance := sender_balance * atomic_factor;
        RAISE NOTICE 'Balance sender convertido de LEAP a atómico: %', sender_balance;
    END IF;
    
    IF receiver_balance < 10000000 THEN
        receiver_balance := receiver_balance * atomic_factor;
        RAISE NOTICE 'Balance receiver convertido de LEAP a atómico: %', receiver_balance;
    END IF;
    
    -- Verificar balance suficiente
    IF sender_balance < amount_atomic THEN
        RETURN json_build_object(
            'success', false,
            'error', format('Insufficient balance. Available: %s LEAP, Required: %s LEAP', 
                          (sender_balance / atomic_factor)::TEXT, amount_tokens::TEXT),
            'debug', json_build_object(
                'sender_balance_atomic', sender_balance,
                'sender_balance_leap', sender_balance / atomic_factor,
                'amount_tokens', amount_tokens,
                'amount_atomic', amount_atomic,
                'sufficient', sender_balance >= amount_atomic
            )
        );
    END IF;
    
    -- Calcular nuevos balances
    new_sender_balance := sender_balance - amount_atomic;
    new_receiver_balance := receiver_balance + amount_atomic;
    
    -- Determinar tipo válido para token_transactions
    valid_type := 'transfer';
    
    -- Verificar qué tipos existen en la tabla
    BEGIN
        PERFORM 1 FROM token_transactions WHERE type = 'transfer' LIMIT 1;
        valid_type := 'transfer';
    EXCEPTION WHEN OTHERS THEN
        BEGIN
            PERFORM 1 FROM token_transactions WHERE type = 'bonus' LIMIT 1;
            valid_type := 'bonus';
        EXCEPTION WHEN OTHERS THEN
            valid_type := 'payment'; -- Fallback
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
        
        -- 2. Actualizar balances en users
        UPDATE users 
        SET token_balance = new_sender_balance,
            updated_at = NOW()
        WHERE id = sender_id;
        
        UPDATE users 
        SET token_balance = new_receiver_balance,
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
            format('Sent %s LEAP to %s', amount_tokens, COALESCE(receiver_name, 'user')),
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
            format('Received %s LEAP from %s', amount_tokens, COALESCE(sender_name, 'user')),
            operation_id,
            'transfer',
            NOW()
        );
        
        -- 4. Actualizar user_balances si existe
        BEGIN
            IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'user_balances') THEN
                -- Actualizar o insertar sender
                INSERT INTO user_balances (user_id, balance, updated_at)
                VALUES (sender_id, new_sender_balance, NOW())
                ON CONFLICT (user_id) 
                DO UPDATE SET 
                    balance = new_sender_balance,
                    updated_at = NOW();
                
                -- Actualizar o insertar receiver
                INSERT INTO user_balances (user_id, balance, updated_at)
                VALUES (receiver_id, new_receiver_balance, NOW())
                ON CONFLICT (user_id) 
                DO UPDATE SET 
                    balance = new_receiver_balance,
                    updated_at = NOW();
            END IF;
        EXCEPTION WHEN OTHERS THEN
            RAISE NOTICE 'Error actualizando user_balances: %', SQLERRM;
        END;
        
        -- Construir respuesta exitosa
        result := json_build_object(
            'success', true,
            'message', format('Successfully transferred %s LEAP tokens', amount_tokens),
            'operation_id', operation_id,
            'details', json_build_object(
                'sender_id', sender_id,
                'receiver_id', receiver_id,
                'amount_tokens', amount_tokens,
                'amount_atomic', amount_atomic,
                'sender_old_balance_leap', (sender_balance / atomic_factor),
                'sender_new_balance_leap', (new_sender_balance / atomic_factor),
                'receiver_old_balance_leap', (receiver_balance / atomic_factor),
                'receiver_new_balance_leap', (new_receiver_balance / atomic_factor),
                'type_used', valid_type
            )
        );
        
        RAISE NOTICE 'Transferencia exitosa: %', result;
        RETURN result;
        
    EXCEPTION WHEN OTHERS THEN
        -- En caso de error, hacer rollback automático
        RAISE NOTICE 'Error en transferencia: %', SQLERRM;
        RETURN json_build_object(
            'success', false,
            'error', format('Transfer failed: %s', SQLERRM),
            'debug', json_build_object(
                'sender_balance_atomic', sender_balance,
                'sender_balance_leap', sender_balance / atomic_factor,
                'receiver_balance_atomic', receiver_balance,
                'receiver_balance_leap', receiver_balance / atomic_factor,
                'amount_atomic', amount_atomic,
                'amount_tokens', amount_tokens,
                'valid_type', valid_type,
                'sql_error', SQLERRM,
                'sql_state', SQLSTATE
            )
        );
    END;
END;
$$;

-- Mensaje de confirmación
DO $$
BEGIN
    RAISE NOTICE '==============================================';
    RAISE NOTICE 'FUNCIÓN DE TRANSFERENCIA COMPLETA INSTALADA';
    RAISE NOTICE 'Versión mejorada con manejo completo de NUMERIC';
    RAISE NOTICE '==============================================';
END $$;
