-- =====================================================
-- INVESTIGATE TOKEN_TRANSACTIONS CONSTRAINT
-- =====================================================
-- Shows the exact constraint definition and tests values
-- =====================================================

-- 1. Show table structure
SELECT 
    column_name,
    data_type,
    is_nullable,
    column_default,
    character_maximum_length
FROM information_schema.columns 
WHERE table_name = 'token_transactions' 
AND table_schema = 'public'
ORDER BY ordinal_position;

-- 2. Show all constraints on token_transactions
SELECT 
    tc.constraint_name,
    tc.constraint_type,
    pg_get_constraintdef(pgc.oid) as constraint_definition
FROM information_schema.table_constraints tc
JOIN pg_constraint pgc ON tc.constraint_name = pgc.conname
WHERE tc.table_name = 'token_transactions'
AND tc.table_schema = 'public';

-- 3. Show check constraints specifically
SELECT 
    conname as constraint_name,
    pg_get_constraintdef(oid) as constraint_definition
FROM pg_constraint 
WHERE conrelid = 'public.token_transactions'::regclass
AND contype = 'c';

-- 4. Show existing values in type column
SELECT 
    type,
    COUNT(*) as count
FROM token_transactions
GROUP BY type
ORDER BY count DESC;

-- 5. Try to understand the constraint by testing values
DO $$
DECLARE
    test_values TEXT[] := ARRAY['transfer', 'transaction', 'payment', 'send', 'receive', 'bonus', 'reward', 'purchase', 'refund', 'withdrawal', 'deposit'];
    test_value TEXT;
    test_id UUID;
    test_user_id UUID;
BEGIN
    -- Get a test user
    SELECT id INTO test_user_id FROM users LIMIT 1;
    
    IF test_user_id IS NULL THEN
        RAISE NOTICE 'No users found for testing';
        RETURN;
    END IF;
    
    RAISE NOTICE '==============================================';
    RAISE NOTICE 'TESTING TYPE VALUES:';
    RAISE NOTICE '==============================================';
    
    FOREACH test_value IN ARRAY test_values
    LOOP
        BEGIN
            test_id := gen_random_uuid();
            
            INSERT INTO token_transactions (
                id, user_id, amount, type, description, created_at
            ) VALUES (
                test_id, test_user_id, 100, test_value, 'Test constraint', NOW()
            );
            
            RAISE NOTICE 'SUCCESS: % works', test_value;
            
            -- Clean up
            DELETE FROM token_transactions WHERE id = test_id;
            
        EXCEPTION WHEN OTHERS THEN
            RAISE NOTICE 'FAILED: % - %', test_value, SQLERRM;
        END;
    END LOOP;
    
    RAISE NOTICE '==============================================';
    RAISE NOTICE 'CONSTRAINT TESTING COMPLETE';
    RAISE NOTICE '==============================================';
END $$;
