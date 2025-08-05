-- 🔍 Script de Diagnóstico Seguro de Base de Datos
-- Este script verifica la estructura actual sin asumir qué columnas existen

DO $$
DECLARE
    table_record RECORD;
    column_record RECORD;
    function_record RECORD;
    count_result INTEGER;
BEGIN
    RAISE NOTICE '🔍 ===== DIAGNÓSTICO DE BASE DE DATOS =====';
    RAISE NOTICE '';
    
    -- 1. Verificar qué tablas existen
    RAISE NOTICE '📋 TABLAS EXISTENTES:';
    FOR table_record IN 
        SELECT table_name 
        FROM information_schema.tables 
        WHERE table_schema = 'public' 
        AND table_type = 'BASE TABLE'
        AND table_name IN ('users', 'token_transactions', 'treasury_accounts', 'atomic_token_operations', 'user_balances')
        ORDER BY table_name
    LOOP
        RAISE NOTICE '  ✅ %', table_record.table_name;
    END LOOP;
    
    RAISE NOTICE '';
    
    -- 2. Estructura detallada de cada tabla
    RAISE NOTICE '🏗️ ESTRUCTURA DE TABLAS:';
    
    -- Tabla users
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'users' AND table_schema = 'public') THEN
        RAISE NOTICE '';
        RAISE NOTICE '👤 TABLA: users';
        FOR column_record IN 
            SELECT column_name, data_type, is_nullable, column_default
            FROM information_schema.columns 
            WHERE table_name = 'users' AND table_schema = 'public'
            ORDER BY ordinal_position
        LOOP
            RAISE NOTICE '  - % | % | nullable: % | default: %', 
                column_record.column_name, 
                column_record.data_type, 
                column_record.is_nullable,
                COALESCE(column_record.column_default, 'none');
        END LOOP;
        
        -- Contar registros
        EXECUTE 'SELECT COUNT(*) FROM users' INTO count_result;
        RAISE NOTICE '  📊 Total registros: %', count_result;
    ELSE
        RAISE NOTICE '❌ Tabla users NO EXISTE';
    END IF;
    
    -- Tabla token_transactions
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'token_transactions' AND table_schema = 'public') THEN
        RAISE NOTICE '';
        RAISE NOTICE '💰 TABLA: token_transactions';
        FOR column_record IN 
            SELECT column_name, data_type, is_nullable, column_default
            FROM information_schema.columns 
            WHERE table_name = 'token_transactions' AND table_schema = 'public'
            ORDER BY ordinal_position
        LOOP
            RAISE NOTICE '  - % | % | nullable: % | default: %', 
                column_record.column_name, 
                column_record.data_type, 
                column_record.is_nullable,
                COALESCE(column_record.column_default, 'none');
        END LOOP;
        
        -- Contar registros
        EXECUTE 'SELECT COUNT(*) FROM token_transactions' INTO count_result;
        RAISE NOTICE '  📊 Total registros: %', count_result;
    ELSE
        RAISE NOTICE '❌ Tabla token_transactions NO EXISTE';
    END IF;
    
    -- Tabla treasury_accounts
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'treasury_accounts' AND table_schema = 'public') THEN
        RAISE NOTICE '';
        RAISE NOTICE '🏦 TABLA: treasury_accounts';
        FOR column_record IN 
            SELECT column_name, data_type, is_nullable, column_default
            FROM information_schema.columns 
            WHERE table_name = 'treasury_accounts' AND table_schema = 'public'
            ORDER BY ordinal_position
        LOOP
            RAISE NOTICE '  - % | % | nullable: % | default: %', 
                column_record.column_name, 
                column_record.data_type, 
                column_record.is_nullable,
                COALESCE(column_record.column_default, 'none');
        END LOOP;
        
        -- Contar registros
        EXECUTE 'SELECT COUNT(*) FROM treasury_accounts' INTO count_result;
        RAISE NOTICE '  📊 Total registros: %', count_result;
    ELSE
        RAISE NOTICE '❌ Tabla treasury_accounts NO EXISTE';
    END IF;
    
    -- Tabla atomic_token_operations
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'atomic_token_operations' AND table_schema = 'public') THEN
        RAISE NOTICE '';
        RAISE NOTICE '⚛️ TABLA: atomic_token_operations';
        FOR column_record IN 
            SELECT column_name, data_type, is_nullable, column_default
            FROM information_schema.columns 
            WHERE table_name = 'atomic_token_operations' AND table_schema = 'public'
            ORDER BY ordinal_position
        LOOP
            RAISE NOTICE '  - % | % | nullable: % | default: %', 
                column_record.column_name, 
                column_record.data_type, 
                column_record.is_nullable,
                COALESCE(column_record.column_default, 'none');
        END LOOP;
        
        -- Contar registros
        EXECUTE 'SELECT COUNT(*) FROM atomic_token_operations' INTO count_result;
        RAISE NOTICE '  📊 Total registros: %', count_result;
    ELSE
        RAISE NOTICE '❌ Tabla atomic_token_operations NO EXISTE';
    END IF;
    
    RAISE NOTICE '';
    
    -- 3. Verificar funciones críticas
    RAISE NOTICE '🔧 FUNCIONES DISPONIBLES:';
    FOR function_record IN 
        SELECT routine_name, routine_type
        FROM information_schema.routines 
        WHERE routine_schema = 'public' 
        AND routine_name IN ('get_user_balance_atomic', 'process_atomic_operation', 'transfer_tokens_atomic', 'give_welcome_bonus')
        ORDER BY routine_name
    LOOP
        RAISE NOTICE '  ✅ % (%)', function_record.routine_name, function_record.routine_type;
    END LOOP;
    
    RAISE NOTICE '';
    
    -- 4. Verificar columnas críticas específicas
    RAISE NOTICE '🔍 VERIFICACIÓN DE COLUMNAS CRÍTICAS:';
    
    -- Verificar token_balance en users
    IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'users' AND column_name = 'token_balance' AND table_schema = 'public') THEN
        RAISE NOTICE '  ✅ users.token_balance existe';
    ELSE
        RAISE NOTICE '  ❌ users.token_balance NO EXISTE';
    END IF;
    
    -- Verificar sender_id en token_transactions
    IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'token_transactions' AND column_name = 'sender_id' AND table_schema = 'public') THEN
        RAISE NOTICE '  ✅ token_transactions.sender_id existe';
    ELSE
        RAISE NOTICE '  ❌ token_transactions.sender_id NO EXISTE';
    END IF;
    
    -- Verificar receiver_id en token_transactions
    IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'token_transactions' AND column_name = 'receiver_id' AND table_schema = 'public') THEN
        RAISE NOTICE '  ✅ token_transactions.receiver_id existe';
    ELSE
        RAISE NOTICE '  ❌ token_transactions.receiver_id NO EXISTE';
    END IF;
    
    -- Verificar user_id en token_transactions
    IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'token_transactions' AND column_name = 'user_id' AND table_schema = 'public') THEN
        RAISE NOTICE '  ✅ token_transactions.user_id existe';
    ELSE
        RAISE NOTICE '  ❌ token_transactions.user_id NO EXISTE';
    END IF;
    
    RAISE NOTICE '';
    RAISE NOTICE '🎯 ===== FIN DEL DIAGNÓSTICO =====';
    
END $$;
