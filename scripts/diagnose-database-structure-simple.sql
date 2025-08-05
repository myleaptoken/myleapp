-- Script simple para diagnosticar la estructura de la base de datos

-- 1. Mostrar todas las tablas relacionadas con tokens/usuarios
SELECT 
    'TABLAS EXISTENTES:' as info,
    table_name as nombre_tabla
FROM information_schema.tables 
WHERE table_schema = 'public' 
AND table_name IN ('users', 'token_transactions', 'treasury_accounts', 'atomic_token_operations', 'user_balances')
ORDER BY table_name;

-- 2. Estructura de la tabla users
SELECT 
    'ESTRUCTURA TABLA USERS:' as info,
    column_name as columna,
    data_type as tipo,
    is_nullable as nullable,
    column_default as valor_default
FROM information_schema.columns 
WHERE table_name = 'users' AND table_schema = 'public'
ORDER BY ordinal_position;

-- 3. Contar usuarios
SELECT 
    'CONTEO USUARIOS:' as info,
    COUNT(*) as total_usuarios
FROM users;

-- 4. Estructura de la tabla token_transactions
SELECT 
    'ESTRUCTURA TABLA TOKEN_TRANSACTIONS:' as info,
    column_name as columna,
    data_type as tipo,
    is_nullable as nullable,
    column_default as valor_default
FROM information_schema.columns 
WHERE table_name = 'token_transactions' AND table_schema = 'public'
ORDER BY ordinal_position;

-- 5. Contar transacciones
SELECT 
    'CONTEO TRANSACCIONES:' as info,
    COUNT(*) as total_transacciones
FROM token_transactions;

-- 6. Estructura de la tabla treasury_accounts
SELECT 
    'ESTRUCTURA TABLA TREASURY_ACCOUNTS:' as info,
    column_name as columna,
    data_type as tipo,
    is_nullable as nullable,
    column_default as valor_default
FROM information_schema.columns 
WHERE table_name = 'treasury_accounts' AND table_schema = 'public'
ORDER BY ordinal_position;

-- 7. Contar treasury accounts
SELECT 
    'CONTEO TREASURY:' as info,
    COUNT(*) as total_treasury
FROM treasury_accounts;

-- 8. Estructura de la tabla atomic_token_operations
SELECT 
    'ESTRUCTURA TABLA ATOMIC_TOKEN_OPERATIONS:' as info,
    column_name as columna,
    data_type as tipo,
    is_nullable as nullable,
    column_default as valor_default
FROM information_schema.columns 
WHERE table_name = 'atomic_token_operations' AND table_schema = 'public'
ORDER BY ordinal_position;

-- 9. Contar operaciones atómicas
SELECT 
    'CONTEO OPERACIONES ATOMICAS:' as info,
    COUNT(*) as total_operaciones
FROM atomic_token_operations;

-- 10. Verificar funciones críticas
SELECT 
    'FUNCIONES DISPONIBLES:' as info,
    routine_name as nombre_funcion,
    routine_type as tipo_funcion
FROM information_schema.routines 
WHERE routine_schema = 'public' 
AND routine_name IN ('get_user_balance_atomic', 'process_atomic_operation', 'transfer_tokens_atomic', 'give_welcome_bonus')
ORDER BY routine_name;

-- 11. Verificar columnas críticas específicas
SELECT 
    'VERIFICACION COLUMNAS CRITICAS:' as info,
    CASE 
        WHEN EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'users' AND column_name = 'token_balance') 
        THEN 'users.token_balance: SI EXISTE'
        ELSE 'users.token_balance: NO EXISTE'
    END as users_token_balance,
    CASE 
        WHEN EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'token_transactions' AND column_name = 'sender_id') 
        THEN 'token_transactions.sender_id: SI EXISTE'
        ELSE 'token_transactions.sender_id: NO EXISTE'
    END as transactions_sender_id,
    CASE 
        WHEN EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'token_transactions' AND column_name = 'receiver_id') 
        THEN 'token_transactions.receiver_id: SI EXISTE'
        ELSE 'token_transactions.receiver_id: NO EXISTE'
    END as transactions_receiver_id;

-- 12. Mostrar algunos datos de usuarios (sin datos sensibles)
SELECT 
    'MUESTRA DE USUARIOS:' as info,
    id,
    email,
    full_name,
    COALESCE(token_balance, 0) as balance_actual,
    created_at
FROM users 
ORDER BY created_at DESC 
LIMIT 5;
