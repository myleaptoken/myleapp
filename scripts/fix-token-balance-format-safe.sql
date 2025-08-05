-- =====================================================
-- CORRECCIÓN SEGURA DE FORMATO DE BALANCES
-- =====================================================
-- Convierte balances de LEAP a formato atómico de forma segura
-- Evita overflow de enteros usando NUMERIC
-- =====================================================

DO $$
DECLARE
    user_record RECORD;
    current_balance NUMERIC;
    new_balance NUMERIC;
    atomic_factor CONSTANT NUMERIC := 1000000000; -- 1 billion
    max_safe_leap CONSTANT NUMERIC := 9223372036; -- Max safe LEAP tokens
    users_updated INTEGER := 0;
    users_skipped INTEGER := 0;
    users_errors INTEGER := 0;
BEGIN
    RAISE NOTICE '==============================================';
    RAISE NOTICE 'INICIANDO CORRECCIÓN SEGURA DE BALANCES';
    RAISE NOTICE 'Factor atómico: %', atomic_factor;
    RAISE NOTICE 'Máximo LEAP seguro: %', max_safe_leap;
    RAISE NOTICE '==============================================';
    
    -- Primero, verificar si necesitamos cambiar el tipo de columna
    BEGIN
        -- Intentar cambiar token_balance a NUMERIC si es necesario
        ALTER TABLE users ALTER COLUMN token_balance TYPE NUMERIC(20,0);
        RAISE NOTICE 'Columna token_balance convertida a NUMERIC(20,0)';
    EXCEPTION WHEN OTHERS THEN
        RAISE NOTICE 'Columna token_balance ya es compatible con NUMERIC';
    END;
    
    -- Procesar cada usuario
    FOR user_record IN 
        SELECT id, token_balance, email, full_name
        FROM users 
        WHERE token_balance IS NOT NULL 
        ORDER BY token_balance DESC
    LOOP
        current_balance := user_record.token_balance;
        
        -- Determinar si el balance está en formato LEAP o atómico
        IF current_balance < 10000000 THEN
            -- Balance está en LEAP, necesita conversión
            IF current_balance > max_safe_leap THEN
                RAISE WARNING 'Usuario % tiene balance demasiado alto: % LEAP (máximo seguro: %)', 
                    user_record.email, current_balance, max_safe_leap;
                users_errors := users_errors + 1;
                CONTINUE;
            END IF;
            
            new_balance := current_balance * atomic_factor;
            
            BEGIN
                UPDATE users 
                SET token_balance = new_balance,
                    updated_at = NOW()
                WHERE id = user_record.id;
                
                users_updated := users_updated + 1;
                RAISE NOTICE 'Usuario %: % LEAP → % atómico', 
                    user_record.email, current_balance, new_balance;
                    
            EXCEPTION WHEN OTHERS THEN
                RAISE WARNING 'Error actualizando usuario %: %', user_record.email, SQLERRM;
                users_errors := users_errors + 1;
            END;
            
        ELSE
            -- Balance ya está en formato atómico
            users_skipped := users_skipped + 1;
            RAISE NOTICE 'Usuario % ya tiene balance atómico: %', 
                user_record.email, current_balance;
        END IF;
    END LOOP;
    
    -- También actualizar user_balances si existe
    BEGIN
        IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'user_balances') THEN
            -- Cambiar tipo de columna si es necesario
            ALTER TABLE user_balances ALTER COLUMN balance TYPE NUMERIC(20,0);
            
            -- Actualizar balances en user_balances
            FOR user_record IN 
                SELECT user_id, balance
                FROM user_balances 
                WHERE balance IS NOT NULL AND balance < 10000000
            LOOP
                new_balance := user_record.balance * atomic_factor;
                
                UPDATE user_balances 
                SET balance = new_balance,
                    updated_at = NOW()
                WHERE user_id = user_record.user_id;
                    
                RAISE NOTICE 'user_balances actualizado para usuario %', user_record.user_id;
            END LOOP;
        END IF;
    EXCEPTION WHEN OTHERS THEN
        RAISE NOTICE 'Tabla user_balances no existe o no se pudo actualizar: %', SQLERRM;
    END;
    
    -- También actualizar atomic_token_operations si es necesario
    BEGIN
        IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'atomic_token_operations') THEN
            ALTER TABLE atomic_token_operations ALTER COLUMN amount TYPE NUMERIC(20,0);
            RAISE NOTICE 'Columna amount en atomic_token_operations convertida a NUMERIC(20,0)';
        END IF;
    EXCEPTION WHEN OTHERS THEN
        RAISE NOTICE 'No se pudo actualizar atomic_token_operations: %', SQLERRM;
    END;
    
    -- También actualizar token_transactions si es necesario
    BEGIN
        IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'token_transactions') THEN
            ALTER TABLE token_transactions ALTER COLUMN amount TYPE NUMERIC(20,0);
            RAISE NOTICE 'Columna amount en token_transactions convertida a NUMERIC(20,0)';
        END IF;
    EXCEPTION WHEN OTHERS THEN
        RAISE NOTICE 'No se pudo actualizar token_transactions: %', SQLERRM;
    END;
    
    -- Resumen final
    RAISE NOTICE '==============================================';
    RAISE NOTICE 'CORRECCIÓN DE BALANCES COMPLETADA';
    RAISE NOTICE 'Usuarios actualizados: %', users_updated;
    RAISE NOTICE 'Usuarios omitidos (ya atómicos): %', users_skipped;
    RAISE NOTICE 'Usuarios con errores: %', users_errors;
    RAISE NOTICE '==============================================';
    
    -- Mostrar algunos balances actualizados
    RAISE NOTICE 'BALANCES ACTUALES (primeros 5 usuarios):';
    FOR user_record IN 
        SELECT email, token_balance
        FROM users 
        WHERE token_balance IS NOT NULL 
        ORDER BY token_balance DESC 
        LIMIT 5
    LOOP
        RAISE NOTICE '% → % (% LEAP)', 
            user_record.email, 
            user_record.token_balance,
            (user_record.token_balance::NUMERIC / atomic_factor);
    END LOOP;
    
END $$;
