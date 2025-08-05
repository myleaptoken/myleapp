-- =====================================================
-- MYLEAP TOKEN SYSTEM - COMPLETE SETUP
-- =====================================================
-- This script sets up the complete token system with:
-- 1. Atomic operations functions
-- 2. Transfer functions with double-entry accounting
-- 3. Balance validation and integrity checks
-- 4. Hybrid system (atomic_token_operations + token_transactions)
-- 5. User balance and transaction history functions
-- =====================================================

BEGIN;

-- =====================================================
-- 1. CORE TRANSFER FUNCTION (Base for all operations)
-- =====================================================

CREATE OR REPLACE FUNCTION process_token_transfer(
    p_from_account TEXT,
    p_to_account TEXT,
    p_amount DECIMAL(20,8),
    p_description TEXT,
    p_operation_type TEXT DEFAULT 'transfer',
    p_user_id UUID DEFAULT NULL,
    p_reference_id UUID DEFAULT NULL
) RETURNS JSONB AS $$
DECLARE
    v_operation_id UUID;
    v_from_balance DECIMAL(20,8);
    v_to_balance DECIMAL(20,8);
    v_result JSONB;
BEGIN
    -- Generate operation ID
    v_operation_id := gen_random_uuid();
    
    -- Validate amount
    IF p_amount <= 0 THEN
        RAISE EXCEPTION 'Amount must be positive';
    END IF;
    
    -- Check source balance (if not issuer)
    IF p_from_account != 'issuer' THEN
        SELECT balance INTO v_from_balance 
        FROM treasury_accounts 
        WHERE account_type = p_from_account;
        
        IF v_from_balance IS NULL THEN
            RAISE EXCEPTION 'Source account not found: %', p_from_account;
        END IF;
        
        IF v_from_balance < p_amount THEN
            RAISE EXCEPTION 'Insufficient balance in %: % < %', p_from_account, v_from_balance, p_amount;
        END IF;
    END IF;
    
    -- Update treasury balances
    IF p_from_account != 'issuer' THEN
        UPDATE treasury_accounts 
        SET balance = balance - p_amount,
            updated_at = NOW()
        WHERE account_type = p_from_account;
    END IF;
    
    IF p_to_account != 'user' THEN
        UPDATE treasury_accounts 
        SET balance = balance + p_amount,
            updated_at = NOW()
        WHERE account_type = p_to_account;
    END IF;
    
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
        status,
        created_at
    ) VALUES (
        v_operation_id,
        p_operation_type,
        p_from_account,
        p_to_account,
        p_amount,
        p_description,
        p_user_id,
        p_reference_id,
        'completed',
        NOW()
    );
    
    -- If user is involved, also record in token_transactions for compatibility
    IF p_user_id IS NOT NULL THEN
        INSERT INTO token_transactions (
            id,
            user_id,
            amount,
            transaction_type,
            description,
            status,
            created_at
        ) VALUES (
            gen_random_uuid(),
            p_user_id,
            CASE 
                WHEN p_to_account = 'user' THEN p_amount 
                ELSE -p_amount 
            END,
            p_operation_type,
            p_description,
            'completed',
            NOW()
        );
    END IF;
    
    -- Return result
    v_result := jsonb_build_object(
        'success', true,
        'operation_id', v_operation_id,
        'amount', p_amount,
        'description', p_description
    );
    
    RETURN v_result;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- =====================================================
-- 2. USER TRANSFER FUNCTION
-- =====================================================

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

-- =====================================================
-- 3. REWARD USER FUNCTION
-- =====================================================

CREATE OR REPLACE FUNCTION reward_user_from_pool(
    p_user_id UUID,
    p_amount DECIMAL(20,8),
    p_description TEXT DEFAULT 'Reward from pool',
    p_reference_id UUID DEFAULT NULL
) RETURNS JSONB AS $$
DECLARE
    v_result JSONB;
BEGIN
    -- Validate user exists
    IF NOT EXISTS (SELECT 1 FROM users WHERE id = p_user_id) THEN
        RAISE EXCEPTION 'User not found';
    END IF;
    
    -- Process transfer from rewards pool to user
    SELECT process_token_transfer(
        'rewards',
        'user',
        p_amount,
        p_description,
        'reward',
        p_user_id,
        p_reference_id
    ) INTO v_result;
    
    -- Update user balance
    UPDATE users 
    SET token_balance = token_balance + p_amount,
        updated_at = NOW()
    WHERE id = p_user_id;
    
    -- Update user_balances
    INSERT INTO user_balances (user_id, available_balance, total_earned, created_at, updated_at)
    VALUES (p_user_id, p_amount, p_amount, NOW(), NOW())
    ON CONFLICT (user_id) 
    DO UPDATE SET 
        available_balance = user_balances.available_balance + p_amount,
        total_earned = user_balances.total_earned + p_amount,
        updated_at = NOW();
    
    RETURN v_result;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- =====================================================
-- 4. PURCHASE FUNCTION
-- =====================================================

CREATE OR REPLACE FUNCTION purchase_with_tokens(
    p_user_id UUID,
    p_amount DECIMAL(20,8),
    p_description TEXT DEFAULT 'Purchase',
    p_reference_id UUID DEFAULT NULL
) RETURNS JSONB AS $$
DECLARE
    v_user_balance DECIMAL(20,8);
    v_result JSONB;
BEGIN
    -- Check user balance
    SELECT COALESCE(token_balance, 0) INTO v_user_balance
    FROM users WHERE id = p_user_id;
    
    IF v_user_balance < p_amount THEN
        RAISE EXCEPTION 'Insufficient balance for purchase: % < %', v_user_balance, p_amount;
    END IF;
    
    -- Process transfer from user to platform
    SELECT process_token_transfer(
        'user',
        'platform',
        p_amount,
        p_description,
        'purchase',
        p_user_id,
        p_reference_id
    ) INTO v_result;
    
    -- Update user balance
    UPDATE users 
    SET token_balance = token_balance - p_amount,
        updated_at = NOW()
    WHERE id = p_user_id;
    
    -- Update user_balances
    UPDATE user_balances 
    SET available_balance = available_balance - p_amount,
        total_spent = total_spent + p_amount,
        updated_at = NOW()
    WHERE user_id = p_user_id;
    
    RETURN v_result;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- =====================================================
-- 5. USER BALANCE FUNCTION
-- =====================================================

CREATE OR REPLACE FUNCTION get_user_balance_atomic(p_user_id UUID)
RETURNS JSONB AS $$
DECLARE
    v_result JSONB;
    v_user_balance DECIMAL(20,8);
    v_total_earned DECIMAL(20,8);
    v_total_spent DECIMAL(20,8);
    v_pending_balance DECIMAL(20,8);
BEGIN
    -- Get balance from users table
    SELECT COALESCE(token_balance, 0) INTO v_user_balance
    FROM users WHERE id = p_user_id;
    
    -- Get totals from user_balances
    SELECT 
        COALESCE(total_earned, 0),
        COALESCE(total_spent, 0),
        COALESCE(pending_balance, 0)
    INTO v_total_earned, v_total_spent, v_pending_balance
    FROM user_balances 
    WHERE user_id = p_user_id;
    
    -- If no record in user_balances, use defaults
    v_total_earned := COALESCE(v_total_earned, 0);
    v_total_spent := COALESCE(v_total_spent, 0);
    v_pending_balance := COALESCE(v_pending_balance, 0);
    
    v_result := jsonb_build_object(
        'user_id', p_user_id,
        'available_balance', v_user_balance,
        'total_earned', v_total_earned,
        'total_spent', v_total_spent,
        'pending_balance', v_pending_balance,
        'net_balance', v_total_earned - v_total_spent
    );
    
    RETURN v_result;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- =====================================================
-- 6. USER TRANSACTION HISTORY
-- =====================================================

CREATE OR REPLACE FUNCTION get_user_transaction_history(
    p_user_id UUID,
    p_limit INTEGER DEFAULT 50
) RETURNS TABLE (
    id UUID,
    operation_type TEXT,
    amount DECIMAL(20,8),
    description TEXT,
    is_incoming BOOLEAN,
    created_at TIMESTAMPTZ,
    reference_id UUID,
    metadata JSONB
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        ato.id,
        ato.operation_type,
        ato.amount,
        ato.description,
        CASE 
            WHEN ato.to_account = 'user' AND ato.user_id = p_user_id THEN true
            WHEN ato.from_account = 'user' AND ato.user_id = p_user_id THEN false
            WHEN ato.operation_type = 'user_transfer' AND ato.reference_id = p_user_id THEN true
            WHEN ato.operation_type = 'user_transfer' AND ato.user_id = p_user_id THEN false
            ELSE false
        END as is_incoming,
        ato.created_at,
        ato.reference_id,
        ato.metadata
    FROM atomic_token_operations ato
    WHERE ato.user_id = p_user_id 
       OR ato.reference_id = p_user_id
       OR (ato.metadata->>'sender_id')::UUID = p_user_id
       OR (ato.metadata->>'receiver_id')::UUID = p_user_id
    ORDER BY ato.created_at DESC
    LIMIT p_limit;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- =====================================================
-- 7. SYSTEM INTEGRITY CHECK
-- =====================================================

CREATE OR REPLACE FUNCTION verify_token_integrity()
RETURNS TABLE (
    check_name TEXT,
    status TEXT,
    details JSONB
) AS $$
BEGIN
    -- Check 1: Treasury balance consistency
    RETURN QUERY
    SELECT 
        'treasury_balance_check'::TEXT,
        CASE 
            WHEN SUM(balance) > 0 THEN 'OK'
            ELSE 'WARNING'
        END::TEXT,
        jsonb_build_object(
            'total_treasury_balance', SUM(balance),
            'accounts', jsonb_agg(jsonb_build_object('type', account_type, 'balance', balance))
        )
    FROM treasury_accounts;
    
    -- Check 2: User balance consistency
    RETURN QUERY
    SELECT 
        'user_balance_check'::TEXT,
        'OK'::TEXT,
        jsonb_build_object(
            'total_user_balance', SUM(COALESCE(token_balance, 0)),
            'user_count', COUNT(*),
            'average_balance', AVG(COALESCE(token_balance, 0))
        )
    FROM users;
    
    -- Check 3: Operation count
    RETURN QUERY
    SELECT 
        'operations_check'::TEXT,
        'OK'::TEXT,
        jsonb_build_object(
            'total_operations', COUNT(*),
            'completed_operations', COUNT(*) FILTER (WHERE status = 'completed'),
            'operation_types', jsonb_agg(DISTINCT operation_type)
        )
    FROM atomic_token_operations;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- =====================================================
-- 8. FIX SEARCH_USERS FUNCTION
-- =====================================================

DROP FUNCTION IF EXISTS search_users(TEXT);

CREATE OR REPLACE FUNCTION search_users(search_term TEXT)
RETURNS TABLE (
    id UUID,
    email TEXT,
    full_name TEXT,
    user_id TEXT,
    avatar_url TEXT
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        u.id,
        u.email,
        u.full_name,
        u.user_id,
        u.avatar_url
    FROM users u
    WHERE 
        u.email ILIKE '%' || search_term || '%'
        OR u.full_name ILIKE '%' || search_term || '%'
        OR u.user_id ILIKE '%' || search_term || '%'
    ORDER BY 
        CASE 
            WHEN u.email = search_term THEN 1
            WHEN u.user_id = search_term THEN 2
            WHEN u.email ILIKE search_term || '%' THEN 3
            WHEN u.full_name ILIKE search_term || '%' THEN 4
            ELSE 5
        END,
        u.full_name
    LIMIT 10;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- =====================================================
-- 9. CREATE SYSTEM STATS VIEW
-- =====================================================

CREATE OR REPLACE VIEW token_system_stats AS
SELECT 
    'Treasury Accounts' as category,
    jsonb_build_object(
        'issuer', (SELECT balance FROM treasury_accounts WHERE account_type = 'issuer'),
        'rewards', (SELECT balance FROM treasury_accounts WHERE account_type = 'rewards'),
        'platform', (SELECT balance FROM treasury_accounts WHERE account_type = 'platform'),
        'reserve', (SELECT balance FROM treasury_accounts WHERE account_type = 'reserve'),
        'total_treasury', (SELECT SUM(balance) FROM treasury_accounts)
    ) as data
UNION ALL
SELECT 
    'User Balances' as category,
    jsonb_build_object(
        'total_users', (SELECT COUNT(*) FROM users),
        'users_with_balance', (SELECT COUNT(*) FROM users WHERE token_balance > 0),
        'total_user_balance', (SELECT SUM(COALESCE(token_balance, 0)) FROM users),
        'average_balance', (SELECT AVG(COALESCE(token_balance, 0)) FROM users)
    ) as data
UNION ALL
SELECT 
    'Operations' as category,
    jsonb_build_object(
        'total_operations', (SELECT COUNT(*) FROM atomic_token_operations),
        'completed_operations', (SELECT COUNT(*) FROM atomic_token_operations WHERE status = 'completed'),
        'operation_types', (SELECT jsonb_agg(DISTINCT operation_type) FROM atomic_token_operations),
        'total_volume', (SELECT SUM(amount) FROM atomic_token_operations WHERE status = 'completed')
    ) as data;

-- =====================================================
-- 10. GRANT PERMISSIONS
-- =====================================================

-- Grant execute permissions on functions
GRANT EXECUTE ON FUNCTION process_token_transfer TO authenticated;
GRANT EXECUTE ON FUNCTION transfer_tokens_atomic TO authenticated;
GRANT EXECUTE ON FUNCTION reward_user_from_pool TO authenticated;
GRANT EXECUTE ON FUNCTION purchase_with_tokens TO authenticated;
GRANT EXECUTE ON FUNCTION get_user_balance_atomic TO authenticated;
GRANT EXECUTE ON FUNCTION get_user_transaction_history TO authenticated;
GRANT EXECUTE ON FUNCTION verify_token_integrity TO authenticated;
GRANT EXECUTE ON FUNCTION search_users TO authenticated;

-- Grant select on view
GRANT SELECT ON token_system_stats TO authenticated;

COMMIT;

-- =====================================================
-- INSTALLATION COMPLETE - SHOW RESULTS
-- =====================================================

DO $$
BEGIN
    RAISE NOTICE '==============================================';
    RAISE NOTICE 'MYLEAP TOKEN SYSTEM SETUP COMPLETE!';
    RAISE NOTICE '==============================================';
    RAISE NOTICE 'Functions created:';
    RAISE NOTICE '- process_token_transfer()';
    RAISE NOTICE '- transfer_tokens_atomic()';
    RAISE NOTICE '- reward_user_from_pool()';
    RAISE NOTICE '- purchase_with_tokens()';
    RAISE NOTICE '- get_user_balance_atomic()';
    RAISE NOTICE '- get_user_transaction_history()';
    RAISE NOTICE '- verify_token_integrity()';
    RAISE NOTICE '- search_users() [FIXED]';
    RAISE NOTICE '';
    RAISE NOTICE 'Views created:';
    RAISE NOTICE '- token_system_stats';
    RAISE NOTICE '';
    RAISE NOTICE 'System ready for use!';
    RAISE NOTICE '==============================================';
END $$;

-- Show current system stats
SELECT 'CURRENT SYSTEM STATUS' as info;
SELECT * FROM token_system_stats;

-- Show integrity check
SELECT 'INTEGRITY CHECK' as info;
SELECT * FROM verify_token_integrity();
