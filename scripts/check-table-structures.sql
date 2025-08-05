-- Verificar estructura de tablas principales
SELECT 'TABLA: users' as info;
SELECT column_name, data_type, is_nullable, column_default
FROM information_schema.columns 
WHERE table_name = 'users' AND table_schema = 'public'
ORDER BY ordinal_position;

SELECT 'TABLA: user_balances' as info;
SELECT column_name, data_type, is_nullable, column_default
FROM information_schema.columns 
WHERE table_name = 'user_balances' AND table_schema = 'public'
ORDER BY ordinal_position;

SELECT 'TABLA: token_transactions' as info;
SELECT column_name, data_type, is_nullable, column_default
FROM information_schema.columns 
WHERE table_name = 'token_transactions' AND table_schema = 'public'
ORDER BY ordinal_position;

SELECT 'TABLA: treasury_accounts' as info;
SELECT column_name, data_type, is_nullable, column_default
FROM information_schema.columns 
WHERE table_name = 'treasury_accounts' AND table_schema = 'public'
ORDER BY ordinal_position;

SELECT 'TABLA: atomic_token_operations' as info;
SELECT column_name, data_type, is_nullable, column_default
FROM information_schema.columns 
WHERE table_name = 'atomic_token_operations' AND table_schema = 'public'
ORDER BY ordinal_position;
