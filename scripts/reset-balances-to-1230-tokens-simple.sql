-- Script simple para resetear balances a 1230 tokens
BEGIN;

-- Solo actualizar la tabla users que sabemos que existe
UPDATE users SET token_balance = 1230;

-- Verificar el resultado
SELECT 'RESULTADO DEL RESET:' as info;
SELECT 
    email,
    full_name,
    token_balance,
    created_at
FROM users
ORDER BY email;

COMMIT;

SELECT 'RESET COMPLETADO: Todos los usuarios ahora tienen 1230 tokens' as resultado;
