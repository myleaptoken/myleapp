-- Script para resetear balances a 1230 tokens
BEGIN;

-- 1. Limpiar transacciones existentes
DELETE FROM token_transactions;
DELETE FROM atomic_token_operations;

-- 2. Resetear balances en users a 1230
UPDATE users SET token_balance = 1230;

-- 3. Limpiar y recrear treasury accounts
DELETE FROM treasury_accounts;

-- 4. Crear treasury account para cada usuario con 1230 tokens
INSERT INTO treasury_accounts (user_id, balance_type, available_balance, reserved_balance, total_earned, total_spent, last_updated)
SELECT 
    id as user_id,
    'tokens' as balance_type,
    1230 as available_balance,
    0 as reserved_balance,
    1230 as total_earned,
    0 as total_spent,
    NOW() as last_updated
FROM users;

-- 5. Registrar operación de welcome bonus para cada usuario
INSERT INTO atomic_token_operations (user_id, operation_type, amount, description, status, created_at)
SELECT 
    id as user_id,
    'credit' as operation_type,
    1230 as amount,
    'Welcome bonus - Reset to 1230 tokens' as description,
    'completed' as status,
    NOW() as created_at
FROM users;

-- 6. Verificar resultados
SELECT 'VERIFICACION FINAL:' as info;
SELECT 
    u.email,
    u.token_balance as balance_users_table,
    ta.available_balance as balance_treasury,
    COUNT(ato.id) as operations_count
FROM users u
LEFT JOIN treasury_accounts ta ON u.id = ta.user_id
LEFT JOIN atomic_token_operations ato ON u.id = ato.user_id
GROUP BY u.id, u.email, u.token_balance, ta.available_balance
ORDER BY u.email;

COMMIT;
