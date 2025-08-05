-- =====================================================
-- COMPLETE TABLE DIAGNOSIS
-- =====================================================
-- Shows all table structures and constraints
-- =====================================================

DO $$
BEGIN
    RAISE NOTICE '==============================================';
    RAISE NOTICE 'STARTING COMPLETE TABLE DIAGNOSIS';
    RAISE NOTICE '==============================================';
END $$;

-- Check if tables exist
SELECT 
    'TABLE EXISTS CHECK' as info,
    table_name,
    CASE WHEN table_name IS NOT NULL THEN 'EXISTS' ELSE 'MISSING' END as status
FROM information_schema.tables 
WHERE table_schema = 'public' 
AND table_name IN ('users', 'user_balances', 'token_transactions', 'atomic_token_operations', 'treasury_accounts')
ORDER BY table_name;

-- Show users table structure
SELECT 'USERS TABLE STRUCTURE' as info;
SELECT column_name, data_type, is_nullable, column_default
FROM information_schema.columns 
WHERE table_schema = 'public' 
AND table_name = 'users'
ORDER BY ordinal_position;

-- Show user_balances table structure
SELECT 'USER_BALANCES TABLE STRUCTURE' as info;
SELECT column_name, data_type, is_nullable, column_default
FROM information_schema.columns 
WHERE table_schema = 'public' 
AND table_name = 'user_balances'
ORDER BY ordinal_position;

-- Show token_transactions table structure
SELECT 'TOKEN_TRANSACTIONS TABLE STRUCTURE' as info;
SELECT column_name, data_type, is_nullable, column_default
FROM information_schema.columns 
WHERE table_schema = 'public' 
AND table_name = 'token_transactions'
ORDER BY ordinal_position;

-- Show atomic_token_operations table structure
SELECT 'ATOMIC_TOKEN_OPERATIONS TABLE STRUCTURE' as info;
SELECT column_name, data_type, is_nullable, column_default
FROM information_schema.columns 
WHERE table_schema = 'public' 
AND table_name = 'atomic_token_operations'
ORDER BY ordinal_position;

-- Show constraints on operation_type
SELECT 'OPERATION_TYPE CONSTRAINTS' as info;
SELECT 
    tc.constraint_name,
    pg_get_constraintdef(pgc.oid) as constraint_definition
FROM information_schema.table_constraints tc
JOIN pg_constraint pgc ON tc.constraint_name = pgc.conname
WHERE tc.table_schema = 'public' 
AND tc.table_name = 'atomic_token_operations'
AND tc.constraint_type = 'CHECK'
AND pg_get_constraintdef(pgc.oid) LIKE '%operation_type%';

-- Show sample data from atomic_token_operations
SELECT 'ATOMIC_TOKEN_OPERATIONS SAMPLE DATA' as info;
SELECT operation_type, from_account_type, to_account_type, amount, status, created_at
FROM atomic_token_operations 
ORDER BY created_at DESC 
LIMIT 5;

-- Show sample data from token_transactions
SELECT 'TOKEN_TRANSACTIONS SAMPLE DATA' as info;
SELECT user_id, amount, type, description, created_at
FROM token_transactions 
ORDER BY created_at DESC 
LIMIT 5;

-- Show current user balances comparison
SELECT 'BALANCE COMPARISON' as info;
SELECT 
    u.id,
    u.email,
    u.token_balance as users_balance,
    COALESCE(ub.available_balance, 0) as user_balances_available,
    COALESCE(ub.total_earned, 0) as user_balances_earned,
    COALESCE(ub.total_spent, 0) as user_balances_spent
FROM users u
LEFT JOIN user_balances ub ON u.id = ub.user_id
WHERE u.token_balance > 0 OR ub.available_balance > 0
ORDER BY u.token_balance DESC
LIMIT 10;

DO $$
BEGIN
    RAISE NOTICE '==============================================';
    RAISE NOTICE 'DIAGNOSIS COMPLETE';
    RAISE NOTICE '==============================================';
END $$;
