-- Script completo para diagnosticar la estructura de la base de datos
-- Ejecutar sección por sección para ver todos los resultados

-- SECCIÓN 1: Tablas existentes
SELECT 
    'TABLAS EXISTENTES' as seccion,
    table_name as tabla,
    'Existe' as estado
FROM information_schema.tables 
WHERE table_schema = 'public' 
AND table_name IN ('users', 'token_transactions', 'treasury_accounts', 'atomic_token_operations', 'user_balances')
ORDER BY table_name;

-- SECCIÓN 2: Estructura tabla users
SELECT 
    'ESTRUCTURA USERS' as seccion,
    column_name as columna,
    data_type as tipo,
    is_nullable as nullable,
    column_default as valor_default
FROM information_schema.columns 
WHERE table_name = 'users' AND table_schema = 'public'
ORDER BY ordinal_position;

-- SECCIÓN 3: Estructura tabla token_transactions
SELECT 
    'ESTRUCTURA TOKEN_TRANSACTIONS' as seccion,
    column_name as columna,
    data_type as tipo,
    is_nullable as nullable,
    column_default as valor_default
FROM information_schema.columns 
WHERE table_name = 'token_transactions' AND table_schema = 'public'
ORDER BY ordinal_position;

-- SECCIÓN 4: Estructura tabla treasury_accounts
SELECT 
    'ESTRUCTURA TREASURY_ACCOUNTS' as seccion,
    column_name as columna,
    data_type as tipo,
    is_nullable as nullable,
    column_default as valor_default
FROM information_schema.columns 
WHERE table_name = 'treasury_accounts' AND table_schema = 'public'
ORDER BY ordinal_position;

-- SECCIÓN 5: Estructura tabla atomic_token_operations
SELECT 
    'ESTRUCTURA ATOMIC_TOKEN_OPERATIONS' as seccion,
    column_name as columna,
    data_type as tipo,
    is_nullable as nullable,
    column_default as valor_default
FROM information_schema.columns 
WHERE table_name = 'atomic_token_operations' AND table_schema = 'public'
ORDER BY ordinal_position;

-- SECCIÓN 6: Funciones disponibles
SELECT 
    'FUNCIONES DISPONIBLES' as seccion,
    routine_name as funcion,
    routine_type as tipo
FROM information_schema.routines 
WHERE routine_schema = 'public' 
AND routine_name LIKE '%token%' OR routine_name LIKE '%balance%' OR routine_name LIKE '%atomic%'
ORDER BY routine_name;

-- SECCIÓN 7: Conteos de registros
SELECT 'CONTEOS' as seccion, 'users' as tabla, COUNT(*) as total FROM users
UNION ALL
SELECT 'CONTEOS' as seccion, 'token_transactions' as tabla, COUNT(*) as total FROM token_transactions
UNION ALL
SELECT 'CONTEOS' as seccion, 'treasury_accounts' as tabla, COUNT(*) as total FROM treasury_accounts
UNION ALL
SELECT 'CONTEOS' as seccion, 'atomic_token_operations' as tabla, COUNT(*) as total FROM atomic_token_operations;

-- SECCIÓN 8: Verificar columnas críticas
SELECT 
    'VERIFICACION COLUMNAS' as seccion,
    'users.token_balance' as columna,
    CASE WHEN EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'users' AND column_name = 'token_balance') 
         THEN 'EXISTE' ELSE 'NO EXISTE' END as estado
UNION ALL
SELECT 
    'VERIFICACION COLUMNAS' as seccion,
    'token_transactions.sender_id' as columna,
    CASE WHEN EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'token_transactions' AND column_name = 'sender_id') 
         THEN 'EXISTE' ELSE 'NO EXISTE' END as estado
UNION ALL
SELECT 
    'VERIFICACION COLUMNAS' as seccion,
    'token_transactions.receiver_id' as columna,
    CASE WHEN EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'token_transactions' AND column_name = 'receiver_id') 
         THEN 'EXISTE' ELSE 'NO EXISTE' END as estado;

-- SECCIÓN 9: Datos de usuarios (ya viste esto)
SELECT 
    'USUARIOS ACTUALES' as seccion,
    id,
    email,
    full_name,
    COALESCE(token_balance, 0) as balance_actual,
    created_at
FROM users 
ORDER BY created_at DESC;
