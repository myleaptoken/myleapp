-- Script para resetear balances a 1230 tokens basado en la estructura real
BEGIN;

-- 1. Limpiar transacciones existentes
DELETE FROM token_transactions;
DELETE FROM atomic_token_operations;
DELETE FROM treasury_accounts;

-- 2. Resetear balances en users a 1230
UPDATE users SET token_balance = 1230;

-- 3. Crear treasury accounts basado en la estructura real (amount, type, description)
INSERT INTO treasury_accounts (user_id, amount, type, description, created_at)
SELECT 
    id as user_id,
    1230 as amount,
    'welcome_bonus' as type,
    'Reset welcome bonus to 1230 LEAP tokens' as description,
    NOW() as created_at
FROM users;

-- 4. Registrar operación atómica para cada usuario
INSERT INTO atomic_token_operations (user_id, operation_type, amount, description, status, created_at)
SELECT 
    id as user_id,
    'credit' as operation_type,
    1230 as amount,
    'Welcome bonus - Reset to 1230 tokens' as description,
    'completed' as status,
    NOW() as created_at
FROM users;

-- 5. Verificar resultados
SELECT 'VERIFICACION FINAL - USUARIOS:' as info;
SELECT 
    email,
    token_balance,
    created_at
FROM users
ORDER BY email;

SELECT 'VERIFICACION FINAL - TREASURY:' as info;
SELECT 
    ta.user_id,
    u.email,
    ta.amount,
    ta.type,
    ta.description
FROM treasury_accounts ta
JOIN users u ON ta.user_id = u.id
ORDER BY u.email;

SELECT 'VERIFICACION FINAL - OPERACIONES ATOMICAS:' as info;
SELECT 
    ato.user_id,
    u.email,
    ato.operation_type,
    ato.amount,
    ato.status
FROM atomic_token_operations ato
JOIN users u ON ato.user_id = u.id
ORDER BY u.email;

COMMIT;

SELECT 'RESET COMPLETADO: Todos los usuarios ahora tienen 1230 tokens de bienvenida' as resultado;
