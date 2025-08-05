-- Primero, verificar qué constraint existe en token_transactions.type
DO $$
DECLARE
    constraint_def text;
BEGIN
    -- Obtener la definición del constraint
    SELECT pg_get_constraintdef(oid) INTO constraint_def
    FROM pg_constraint 
    WHERE conname LIKE '%token_transactions%type%check%' 
    AND conrelid = 'token_transactions'::regclass;
    
    IF constraint_def IS NOT NULL THEN
        RAISE NOTICE 'Found constraint: %', constraint_def;
    ELSE
        RAISE NOTICE 'No type constraint found on token_transactions';
    END IF;
END $$;

-- Crear o reemplazar la función de transferencia
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
    sender_balance BIGINT;
    receiver_balance BIGINT;
    amount_atomic BIGINT;
    operation_id UUID;
    sender_tx_id UUID;
    receiver_tx_id UUID;
    valid_type TEXT;
    result JSON;
BEGIN
    -- Convertir tokens a formato atómico
    amount_atomic := (amount_tokens * 1000000000)::BIGINT;
    
    -- Verificar que el monto sea positivo
    IF amount_atomic <= 0 THEN
        RETURN json_build_object(
            'success', false,
            'error', 'Amount must be positive'
        );
    END IF;
    
    -- Obtener balance actual del sender
    SELECT COALESCE(token_balance, 0) INTO sender_balance
    FROM users 
    WHERE id = sender_id;
    
    -- Verificar balance suficiente
    IF sender_balance < amount_atomic THEN
        RETURN json_build_object(
            'success', false,
            'error', format('Insufficient balance. Available: %s LEAP, Required: %s LEAP', 
                          (sender_balance::DECIMAL / 1000000000), amount_tokens),
            'debug', json_build_object(
                'sender_balance_atomic', sender_balance,
                'sender_balance_leap', (sender_balance::DECIMAL / 1000000000),
                'amount_requested', amount_tokens,
                'amount_atomic', amount_atomic
            )
        );
    END IF;
    
    -- Obtener balance del receiver
    SELECT COALESCE(token_balance, 0) INTO receiver_balance
    FROM users 
    WHERE id = receiver_id;
    
    -- Determinar qué tipo usar para token_transactions
    -- Probar diferentes valores en orden de preferencia
    valid_type := 'transfer'; -- Valor por defecto
    
    BEGIN
        -- Probar insertar un registro temporal para ver qué tipo funciona
        INSERT INTO token_transactions (id, user_id, amount, type, description, reference_type)
        VALUES (gen_random_uuid(), sender_id, -amount_atomic, 'transfer', 'test', 'test');
        DELETE FROM token_transactions WHERE description = 'test' AND reference_type = 'test';
        valid_type := 'transfer';
    EXCEPTION WHEN check_violation THEN
        BEGIN
            INSERT INTO token_transactions (id, user_id, amount, type, description, reference_type)
            VALUES (gen_random_uuid(), sender_id, -amount_atomic, 'transaction', 'test', 'test');
            DELETE FROM token_transactions WHERE description = 'test' AND reference_type = 'test';
            valid_type := 'transaction';
        EXCEPTION WHEN check_violation THEN
            BEGIN
                INSERT INTO token_transactions (id, user_id, amount, type, description, reference_type)
                VALUES (gen_random_uuid(), sender_id, -amount_atomic, 'payment', 'test', 'test');
                DELETE FROM token_transactions WHERE description = 'test' AND reference_type = 'test';
                valid_type := 'payment';
            EXCEPTION WHEN check_violation THEN
                valid_type := 'bonus'; -- Fallback que sabemos que funciona
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
        
        -- 2. Actualizar balances en users
        UPDATE users 
        SET token_balance = token_balance - amount_atomic,
            updated_at = NOW()
        WHERE id = sender_id;
        
        UPDATE users 
        SET token_balance = token_balance + amount_atomic,
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
            format('Sent %s LEAP to %s', amount_tokens, 
                   (SELECT COALESCE(full_name, email) FROM users WHERE id = receiver_id)),
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
            format('Received %s LEAP from %s', amount_tokens,
                   (SELECT COALESCE(full_name, email) FROM users WHERE id = sender_id)),
            operation_id,
            'transfer',
            NOW()
        );
        
        -- 4. Actualizar user_balances si existe
        IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'user_balances') THEN
            -- Actualizar sender
            INSERT INTO user_balances (user_id, balance, updated_at)
            VALUES (sender_id, sender_balance - amount_atomic, NOW())
            ON CONFLICT (user_id) 
            DO UPDATE SET 
                balance = sender_balance - amount_atomic,
                updated_at = NOW();
            
            -- Actualizar receiver
            INSERT INTO user_balances (user_id, balance, updated_at)
            VALUES (receiver_id, receiver_balance + amount_atomic, NOW())
            ON CONFLICT (user_id) 
            DO UPDATE SET 
                balance = receiver_balance + amount_atomic,
                updated_at = NOW();
        END IF;
        
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
                'sender_new_balance', sender_balance - amount_atomic,
                'receiver_new_balance', receiver_balance + amount_atomic
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
                'amount_atomic', amount_atomic,
                'valid_type', valid_type,
                'sql_error', SQLERRM
            )
        );
    END;
END;
$$;

-- Mensaje de confirmación
SELECT 'Function transfer_tokens_atomic created successfully' as status;
