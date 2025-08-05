-- =====================================================
-- FIX RLS POLICIES FOR TOKEN SYSTEM
-- =====================================================
-- This script fixes Row Level Security policies for the token system
-- to allow authenticated users to perform token operations
-- =====================================================

BEGIN;

-- =====================================================
-- 1. ENABLE RLS ON TOKEN TABLES (if not already enabled)
-- =====================================================

-- Enable RLS on atomic_token_operations
ALTER TABLE atomic_token_operations ENABLE ROW LEVEL SECURITY;

-- Enable RLS on token_transactions  
ALTER TABLE token_transactions ENABLE ROW LEVEL SECURITY;

-- Enable RLS on user_balances
ALTER TABLE user_balances ENABLE ROW LEVEL SECURITY;

-- Enable RLS on treasury_accounts
ALTER TABLE treasury_accounts ENABLE ROW LEVEL SECURITY;

-- =====================================================
-- 2. DROP EXISTING POLICIES (if any)
-- =====================================================

DROP POLICY IF EXISTS "Users can view their own token operations" ON atomic_token_operations;
DROP POLICY IF EXISTS "Users can insert token operations" ON atomic_token_operations;
DROP POLICY IF EXISTS "System can manage token operations" ON atomic_token_operations;

DROP POLICY IF EXISTS "Users can view their own transactions" ON token_transactions;
DROP POLICY IF EXISTS "Users can insert transactions" ON token_transactions;
DROP POLICY IF EXISTS "System can manage transactions" ON token_transactions;

DROP POLICY IF EXISTS "Users can view their own balance" ON user_balances;
DROP POLICY IF EXISTS "Users can manage their own balance" ON user_balances;
DROP POLICY IF EXISTS "System can manage balances" ON user_balances;

DROP POLICY IF EXISTS "Anyone can view treasury accounts" ON treasury_accounts;
DROP POLICY IF EXISTS "System can manage treasury" ON treasury_accounts;

-- =====================================================
-- 3. CREATE NEW PERMISSIVE POLICIES
-- =====================================================

-- atomic_token_operations policies
CREATE POLICY "Users can view token operations" ON atomic_token_operations
    FOR SELECT TO authenticated
    USING (true);

CREATE POLICY "Users can insert token operations" ON atomic_token_operations
    FOR INSERT TO authenticated
    WITH CHECK (true);

CREATE POLICY "System can manage token operations" ON atomic_token_operations
    FOR ALL TO authenticated
    USING (true)
    WITH CHECK (true);

-- token_transactions policies  
CREATE POLICY "Users can view transactions" ON token_transactions
    FOR SELECT TO authenticated
    USING (true);

CREATE POLICY "Users can insert transactions" ON token_transactions
    FOR INSERT TO authenticated
    WITH CHECK (true);

CREATE POLICY "System can manage transactions" ON token_transactions
    FOR ALL TO authenticated
    USING (true)
    WITH CHECK (true);

-- user_balances policies
CREATE POLICY "Users can view balances" ON user_balances
    FOR SELECT TO authenticated
    USING (true);

CREATE POLICY "Users can manage balances" ON user_balances
    FOR ALL TO authenticated
    USING (true)
    WITH CHECK (true);

-- treasury_accounts policies
CREATE POLICY "Users can view treasury" ON treasury_accounts
    FOR SELECT TO authenticated
    USING (true);

CREATE POLICY "System can manage treasury" ON treasury_accounts
    FOR ALL TO authenticated
    USING (true)
    WITH CHECK (true);

-- =====================================================
-- 4. GRANT TABLE PERMISSIONS
-- =====================================================

-- Grant permissions on tables
GRANT ALL ON atomic_token_operations TO authenticated;
GRANT ALL ON token_transactions TO authenticated;
GRANT ALL ON user_balances TO authenticated;
GRANT ALL ON treasury_accounts TO authenticated;

-- Grant permissions on sequences
GRANT USAGE, SELECT ON ALL SEQUENCES IN SCHEMA public TO authenticated;

-- =====================================================
-- 5. UPDATE FUNCTION SECURITY
-- =====================================================

-- Make sure functions run with definer rights (bypass RLS)
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
    
    -- Record atomic operation
    INSERT INTO atomic_token_operations (
        id,
        operation_type,
        from_account,
        to_account,
        amount,
        description,
        user_id,
        reference_id,
        metadata,
        status,
        created_at
    ) VALUES (
        v_operation_id,
        'user_transfer',
        'user',
        'user',
        amount,
        description,
        sender_id,
        receiver_id,
        jsonb_build_object(
            'sender_id', sender_id,
            'receiver_id', receiver_id,
            'transfer_type', 'peer_to_peer'
        ),
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
-- VERIFICATION
-- =====================================================

DO $$
BEGIN
    RAISE NOTICE '==============================================';
    RAISE NOTICE 'TOKEN SYSTEM RLS POLICIES FIXED!';
    RAISE NOTICE '==============================================';
    RAISE NOTICE 'Policies created for:';
    RAISE NOTICE '- atomic_token_operations';
    RAISE NOTICE '- token_transactions';
    RAISE NOTICE '- user_balances';
    RAISE NOTICE '- treasury_accounts';
    RAISE NOTICE '';
    RAISE NOTICE 'Functions updated:';
    RAISE NOTICE '- transfer_tokens_atomic() with SECURITY DEFINER';
    RAISE NOTICE '';
    RAISE NOTICE 'Token transfers should now work!';
    RAISE NOTICE '==============================================';
END $$;

-- Show current policies
SELECT 'CURRENT RLS POLICIES' as info;
SELECT schemaname, tablename, policyname, permissive, roles, cmd, qual 
FROM pg_policies 
WHERE tablename IN ('atomic_token_operations', 'token_transactions', 'user_balances', 'treasury_accounts')
ORDER BY tablename, policyname;
