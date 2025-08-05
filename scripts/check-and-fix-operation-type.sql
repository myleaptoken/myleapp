-- =====================================================
-- CHECK AND FIX OPERATION TYPE AND TABLE STRUCTURES
-- =====================================================
-- This script checks both tables and creates a working function
-- =====================================================

BEGIN;

-- =====================================================
-- 1. CHECK BOTH TABLE STRUCTURES
-- =====================================================

DO $$
BEGIN
    RAISE NOTICE '==============================================';
    RAISE NOTICE 'CHECKING TABLE STRUCTURES';
    RAISE NOTICE '==============================================';
END $$;

-- Show atomic_token_operations structure
SELECT 'ATOMIC_TOKEN_OPERATIONS COLUMNS' as info;
SELECT column_name, data_type, is_nullable, column_default
FROM information_schema.columns 
WHERE table_name = 'atomic_token_operations' 
AND table_schema = 'public'
ORDER BY ordinal_position;

-- Show token_transactions structure  
SELECT 'TOKEN_TRANSACTIONS COLUMNS' as info;
SELECT column_name, data_type, is_nullable, column_default
FROM information_schema.columns 
WHERE table_name = 'token_transactions' 
AND table_schema = 'public'
ORDER BY ordinal_position;

-- Check operation_type constraints
SELECT 'OPERATION_TYPE CONSTRAINTS' as info;
SELECT conname, consrc 
FROM pg_constraint 
WHERE conrelid = 'atomic_token_operations'::regclass 
AND contype = 'c';

-- Check existing data to see what values are used
SELECT 'EXISTING OPERATION_TYPES IN atomic_token_operations' as info;
SELECT DISTINCT operation_type, COUNT(*) 
FROM atomic_token_operations 
GROUP BY operation_type;

SELECT 'EXISTING DATA IN token_transactions' as info;
SELECT column_name 
FROM information_schema.columns 
WHERE table_name = 'token_transactions' 
AND column_name LIKE '%type%';

-- =====================================================
-- 2. CREATE ADAPTIVE TRANSFER FUNCTION
-- =====================================================

DROP FUNCTION IF EXISTS transfer_tokens_atomic(uuid,uuid,numeric,text);

CREATE OR REPLACE FUNCTION transfer_tokens_atomic(
    sender_id UUID,
    receiver_id UUID,
    amount DECIMAL(20,8),
    description TEXT DEFAULT 'User transfer'
) RETURNS JSONB AS $$
DECLARE
    v_sender_balance DECIMAL(20,8);
    v_operation_id UUID;
    v_result JSONB;
    v_operation_type TEXT := 'transfer'; -- Default value
BEGIN
    -- Validate users exist
    IF NOT EXISTS (SELECT 1 FROM users WHERE id = sender_id) THEN
        RAISE EXCEPTION 'Sender not found';
    END IF;
    
    IF NOT EXISTS (SELECT 1 FROM users WHERE id = receiver_id) THEN
        RAISE EXCEPTION 'Receiver not found';
    END IF;
    
    -- Check sender balance
    SELECT COALESCE(token_balance, 0) INTO v_sender_balance
    FROM users WHERE id = sender_id;
    
    IF v_sender_balance < amount THEN
        RAISE EXCEPTION 'Insufficient balance: % < %', v_sender_balance, amount;
    END IF;
    
    -- Generate operation ID
    v_operation_id := gen_random_uuid();
    
    -- Update user balances
    UPDATE users 
    SET token_balance = token_balance - amount,
        updated_at = NOW()
    WHERE id = sender_id;
    
    UPDATE users 
    SET token_balance = token_balance + amount,
        updated_at = NOW()
    WHERE id = receiver_id;
    
    -- Update user_balances if exists
    UPDATE user_balances 
    SET available_balance = available_balance - amount,
        updated_at = NOW()
    WHERE user_id = sender_id;
    
    UPDATE user_balances 
    SET available_balance = available_balance + amount,
        total_earned = total_earned + amount,
        updated_at = NOW()
    WHERE user_id = receiver_id;
    
    -- Try to insert into atomic_token_operations with different operation_type values
    BEGIN
        INSERT INTO atomic_token_operations (
            id,
            operation_type,
            amount,
            description,
            reference_id,
            status,
            created_at
        ) VALUES (
            v_operation_id,
            'transfer',
            amount,
            description,
            receiver_id,
            'completed',
            NOW()
        );
    EXCEPTION WHEN check_violation THEN
        BEGIN
            INSERT INTO atomic_token_operations (
                id,
                operation_type,
                amount,
                description,
                reference_id,
                status,
                created_at
            ) VALUES (
                v_operation_id,
                'send',
                amount,
                description,
                receiver_id,
                'completed',
                NOW()
            );
        EXCEPTION WHEN check_violation THEN
            INSERT INTO atomic_token_operations (
                id,
                operation_type,
                amount,
                description,
                reference_id,
                status,
                created_at
            ) VALUES (
                v_operation_id,
                'payment',
                amount,
                description,
                receiver_id,
                'completed',
                NOW()
            );
        END;
    END;
    
    -- Insert into token_transactions using only basic columns
    -- Check if transaction_type column exists, if not use type or another column
    BEGIN
        INSERT INTO token_transactions (
            id, 
            user_id, 
            amount, 
            transaction_type, 
            description, 
            status, 
            created_at
        ) VALUES 
        (gen_random_uuid(), sender_id, -amount, 'transfer_out', description, 'completed', NOW()),
        (gen_random_uuid(), receiver_id, amount, 'transfer_in', description, 'completed', NOW());
    EXCEPTION WHEN undefined_column THEN
        -- Try with 'type' column instead
        BEGIN
            INSERT INTO token_transactions (
                id, 
                user_id, 
                amount, 
                type, 
                description, 
                status, 
                created_at
            ) VALUES 
            (gen_random_uuid(), sender_id, -amount, 'transfer_out', description, 'completed', NOW()),
            (gen_random_uuid(), receiver_id, amount, 'transfer_in', description, 'completed', NOW());
        EXCEPTION WHEN undefined_column THEN
            -- Insert with minimal columns only
            INSERT INTO token_transactions (
                id, 
                user_id, 
                amount, 
                description, 
                created_at
            ) VALUES 
            (gen_random_uuid(), sender_id, -amount, description, NOW()),
            (gen_random_uuid(), receiver_id, amount, description, NOW());
        END;
    END;
    
    -- Return success
    v_result := jsonb_build_object(
        'success', true,
        'operation_id', v_operation_id,
        'sender_id', sender_id,
        'receiver_id', receiver_id,
        'amount', amount,
        'description', description
    );
    
    RETURN v_result;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Grant execute permission
GRANT EXECUTE ON FUNCTION transfer_tokens_atomic TO authenticated;

COMMIT;

-- =====================================================
-- 3. VERIFICATION
-- =====================================================

DO $$
BEGIN
    RAISE NOTICE '==============================================';
    RAISE NOTICE 'ADAPTIVE TRANSFER FUNCTION CREATED!';
    RAISE NOTICE '==============================================';
    RAISE NOTICE 'Function: transfer_tokens_atomic()';
    RAISE NOTICE 'Adapts to existing table structures automatically';
    RAISE NOTICE 'Handles different column names and constraints';
    RAISE NOTICE '==============================================';
END $$;

-- Test function exists
SELECT 'FUNCTION STATUS' as info;
SELECT routine_name, routine_type 
FROM information_schema.routines 
WHERE routine_name = 'transfer_tokens_atomic' 
AND routine_schema = 'public';
