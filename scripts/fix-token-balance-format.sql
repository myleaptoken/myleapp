-- =====================================================
-- SCRIPT PARA VERIFICAR Y CORREGIR FORMATO DE BALANCES
-- =====================================================
-- Asegura que todos los balances estén en formato atómico
-- =====================================================

DO $$
DECLARE
    user_record RECORD;
    total_users INT := 0;
    converted_users INT := 0;
    atomic_factor BIGINT := 1000000000; -- 1 LEAP = 10^9 unidades atómicas
BEGIN
    -- Contar usuarios
    SELECT COUNT(*) INTO total_users FROM users;
    
    RAISE NOTICE 'Verificando balances de % usuarios...', total_users;
    
    -- Iterar sobre cada usuario
    FOR user_record IN SELECT id, email, token_balance FROM users
    LOOP
        -- Si el balance es menor que 10 millones, probablemente está en LEAP
        -- y necesitamos convertirlo a unidades atómicas
        IF user_record.token_balance IS NOT NULL AND user_record.token_balance < 10000000 THEN
            RAISE NOTICE 'Convirtiendo balance para %: % LEAP -> % unidades atómicas', 
                user_record.email, 
                user_record.token_balance, 
                user_record.token_balance * atomic_factor;
                
            -- Actualizar el balance
            UPDATE users 
            SET token_balance = token_balance * atomic_factor,
                updated_at = NOW()
            WHERE id = user_record.id;
            
            converted_users := converted_users + 1;
        END IF;
    END LOOP;
    
    RAISE NOTICE '==============================================';
    RAISE NOTICE 'VERIFICACIÓN DE BALANCES COMPLETADA';
    RAISE NOTICE '% de % usuarios tenían balances en formato LEAP', converted_users, total_users;
    RAISE NOTICE 'Todos los balances ahora están en formato atómico';
    RAISE NOTICE '==============================================';
END $$;
