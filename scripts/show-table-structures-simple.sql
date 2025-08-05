-- =====================================================
-- SIMPLE TABLE STRUCTURE CHECKER
-- =====================================================
-- Shows exactly what columns exist in both tables
-- =====================================================

-- Check atomic_token_operations table
SELECT 'ATOMIC_TOKEN_OPERATIONS TABLE STRUCTURE:' as section;

SELECT 
    column_name,
    data_type,
    is_nullable,
    column_default
FROM information_schema.columns 
WHERE table_name = 'atomic_token_operations' 
AND table_schema = 'public'
ORDER BY ordinal_position;

-- Check token_transactions table
SELECT 'TOKEN_TRANSACTIONS TABLE STRUCTURE:' as section;

SELECT 
    column_name,
    data_type,
    is_nullable,
    column_default
FROM information_schema.columns 
WHERE table_name = 'token_transactions' 
AND table_schema = 'public'
ORDER BY ordinal_position;

-- Check constraints on atomic_token_operations
SELECT 'CONSTRAINTS ON atomic_token_operations:' as section;

SELECT 
    conname as constraint_name,
    pg_get_constraintdef(oid) as constraint_definition
FROM pg_constraint 
WHERE conrelid = 'atomic_token_operations'::regclass;

-- Check what operation_type values currently exist
SELECT 'EXISTING operation_type VALUES:' as section;

SELECT DISTINCT operation_type, COUNT(*) as count
FROM atomic_token_operations 
GROUP BY operation_type
ORDER BY count DESC;

-- Check if token_transactions exists
SELECT 'TOKEN_TRANSACTIONS EXISTS:' as section;

SELECT EXISTS (
    SELECT FROM information_schema.tables 
    WHERE table_schema = 'public' 
    AND table_name = 'token_transactions'
) as table_exists;
