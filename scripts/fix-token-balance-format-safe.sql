-- =====================================================
-- SCRIPT SEGURO PARA VERIFICAR Y CORREGIR FORMATO DE BALANCES
-- =====================================================
-- Evita overflow de enteros usando BIGINT y validaciones
-- =====================================================

DO $$
DECLARE
    user_record RECORD;
    total_users INT := 0;
    converted_users INT := 0;
    atomic_factor BIGINT := 1000000000; -- 1 LEAP = 10^9 unidades atómicas
    new_balance BIGINT;
    max_safe_balance BIGINT := 9223372036; -- Máximo balance seguro en LEAP (antes de overflow)
BEGIN
    -- Contar usuarios
    SELECT COUNT(*) INTO total_users FROM users;
    
    RAISE NOTICE 'Verificando balances de % usuarios...', total_users;
    RAISE NOTICE 'Balance máximo seguro: % LEAP', max_safe_balance;
    
    -- Iterar sobre cada usuario
    FOR user_record IN SELECT id, email, token_balance FROM users WHERE token_balance IS NOT NULL
    LOOP
        -- Si el balance es menor que 10 millones, probablemente está en LEAP
        -- y necesitamos convertirlo a unidades atómicas
        IF user_record.token_balance < 10000000 THEN
            -- Verificar que la conversión no cause overflow
            IF user_record.token_balance <= max_safe_balance THEN
                new_balance := user_record.token_balance * atomic_factor;
                
                RAISE NOTICE 'Convirtiendo balance para %: % LEAP -> % unidades atómicas', 
                    user_record.email, 
                    user_record.token_balance, 
                    new_balance;
                    
                -- Actualizar el balance usando BIGINT explícito
                UPDATE users 
                SET token_balance = new_balance,
                    updated_at = NOW()
                WHERE id = user_record.id;
                
                converted_users := converted_users + 1;
            ELSE
                RAISE WARNING 'Balance demasiado grande para convertir sin overflow: % LEAP para %', 
                    user_record.token_balance, user_record.email;
            END IF;
        ELSE
            RAISE NOTICE 'Balance ya en formato atómico para %: % unidades', 
                user_record.email, user_record.token_balance;
        END IF;
    END LOOP;
    
    RAISE NOTICE '==============================================';
    RAISE NOTICE 'VERIFICACIÓN DE BALANCES COMPLETADA';
    RAISE NOTICE '% de % usuarios tenían balances en formato LEAP', converted_users, total_users;
    RAISE NOTICE 'Todos los balances válidos ahora están en formato atómico';
    RAISE NOTICE '==============================================';
END $$;
