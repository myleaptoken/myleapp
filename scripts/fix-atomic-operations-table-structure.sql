-- =====================================================
-- FIX ATOMIC TOKEN OPERATIONS TABLE STRUCTURE
-- =====================================================
-- This script fixes the atomic_token_operations table structure
-- and updates the transfer function to match the actual columns
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
SELECT 'CURRENT COLUMNS' as info;
SELECT column_name, data_type, is_nullable, column_default
FROM information_schema.columns 
WHERE table_name = 'atomic_token_operations' 
ORDER BY ordinal_position;

-- =====================================================
-- 2. ADD MISSING COLUMNS IF THEY DON'T EXIST
-- =====================================================

-- Add from_account column if it doesn't exist
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'atomic_token_operations' 
        AND column_name = 'from_account'
    ) THEN
        ALTER TABLE atomic_token_operations 
        ADD COLUMN from_account TEXT;
        RAISE NOTICE 'Added from_account column';
    ELSE
        RAISE NOTICE 'from_account column already exists';
    END IF;
END $$;

-- Add to_account column if it doesn't exist
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'atomic_token_operations' 
        AND column_name = 'to_account'
    ) THEN
        ALTER TABLE atomic_token_operations 
        ADD COLUMN to_account TEXT;
        RAISE NOTICE 'Added to_account column';
    ELSE
        RAISE NOTICE 'to_account column already exists';
    END IF;
END $$;

-- Add metadata column if it doesn't exist
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'atomic_token_operations' 
        AND column_name = 'metadata'
    ) THEN
        ALTER TABLE atomic_token_operations 
        ADD COLUMN metadata JSONB;
        RAISE NOTICE 'Added metadata column';
    ELSE
        RAISE NOTICE 'metadata column already exists';
    END IF;
END $$;

-- =====================================================
-- 3. DROP AND RECREATE TRANSFER FUNCTION
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
    
    -- Record atomic operation (using only existing columns)
    INSERT INTO atomic_token_operations (
        id,
        operation_type,
        amount,
        description,
        user_id,
        reference_id,
        status,
        created_at,
        from_account,
        to_account,
        metadata
    ) VALUES (
        v_operation_id,
        'user_transfer',
        amount,
        description,
        sender_id,
        receiver_id,
        'completed',
        NOW(),
        'user',
        'user',
        jsonb_build_object(
            'sender_id', sender_id,
            'receiver_id', receiver_id,
            'transfer_type', 'peer_to_peer'
        )
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
-- VERIFICATION
-- =====================================================

DO $$
BEGIN
    RAISE NOTICE '==============================================';
    RAISE NOTICE 'ATOMIC TOKEN OPERATIONS TABLE FIXED!';
    RAISE NOTICE '==============================================';
    RAISE NOTICE 'Columns added/verified:';
    RAISE NOTICE '- from_account';
    RAISE NOTICE '- to_account';
    RAISE NOTICE '- metadata';
    RAISE NOTICE '';
    RAISE NOTICE 'Function updated:';
    RAISE NOTICE '- transfer_tokens_atomic() with correct columns';
    RAISE NOTICE '';
    RAISE NOTICE 'Token transfers should now work!';
    RAISE NOTICE '==============================================';
END $$;

-- Show final table structure
SELECT 'FINAL TABLE STRUCTURE' as info;
SELECT column_name, data_type, is_nullable, column_default
FROM information_schema.columns 
WHERE table_name = 'atomic_token_operations' 
ORDER BY ordinal_position;
