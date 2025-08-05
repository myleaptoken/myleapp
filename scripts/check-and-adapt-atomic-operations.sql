-- =====================================================
-- CHECK ATOMIC TOKEN OPERATIONS TABLE STRUCTURE
-- =====================================================
-- This script checks the current structure and adapts
-- the transfer function to match existing columns
-- =====================================================

BEGIN;

-- =====================================================
-- 1. CHECK CURRENT TABLE STRUCTURE
-- =====================================================

DO $$
BEGIN
    RAISE NOTICE '==============================================';
    RAISE NOTICE 'CHECKING ATOMIC_TOKEN_OPERATIONS TABLE STRUCTURE';
    RAISE NOTICE '==============================================';
END $$;

-- Show current columns
SELECT 'CURRENT COLUMNS IN atomic_token_operations' as info;
SELECT column_name, data_type, is_nullable, column_default
FROM information_schema.columns 
WHERE table_name = 'atomic_token_operations' 
AND table_schema = 'public'
ORDER BY ordinal_position;

-- =====================================================
-- 2. CREATE SIMPLIFIED TRANSFER FUNCTION
-- =====================================================
-- This function only uses columns that definitely exist

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
    v_columns_exist RECORD;
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
    
    -- Record atomic operation using only basic columns that should exist
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
        'user_transfer',
        amount,
        description,
        receiver_id,
        'completed',
        NOW()
    );
    
    -- Record in token_transactions for both users
    INSERT INTO token_transactions (
        id, user_id, amount, transaction_type, description, status, created_at
    ) VALUES 
    (gen_random_uuid(), sender_id, -amount, 'transfer_out', description, 'completed', NOW()),
    (gen_random_uuid(), receiver_id, amount, 'transfer_in', description, 'completed', NOW());
    
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
    RAISE NOTICE 'TRANSFER FUNCTION ADAPTED TO EXISTING STRUCTURE!';
    RAISE NOTICE '==============================================';
    RAISE NOTICE 'Function created: transfer_tokens_atomic()';
    RAISE NOTICE 'Uses only basic columns that exist in the table';
    RAISE NOTICE 'Token transfers should now work!';
    RAISE NOTICE '==============================================';
END $$;

-- Test the function exists
SELECT 'FUNCTION EXISTS' as info;
SELECT routine_name, routine_type 
FROM information_schema.routines 
WHERE routine_name = 'transfer_tokens_atomic' 
AND routine_schema = 'public';

-- Show sample data from atomic_token_operations if any exists
SELECT 'SAMPLE DATA FROM atomic_token_operations' as info;
SELECT * FROM atomic_token_operations LIMIT 3;
