-- Script de diagnóstico para validar estructura de base de datos
-- Verificar qué tablas existen y sus columnas

-- =====================================================
-- DIAGNÓSTICO COMPLETO DE ESTRUCTURA DE BASE DE DATOS
-- =====================================================

DO $$
BEGIN
    RAISE NOTICE '🔍 INICIANDO DIAGNÓSTICO DE BASE DE DATOS...';
END $$;

-- =====================================================
-- 1. LISTAR TODAS LAS TABLAS RELACIONADAS
-- =====================================================
DO $$
DECLARE
    table_record RECORD;
BEGIN
    RAISE NOTICE '';
    RAISE NOTICE '📋 === TABLAS EXISTENTES ===';
    
    FOR table_record IN 
        SELECT schemaname, tablename 
        FROM pg_tables 
        WHERE schemaname = 'public' 
        AND (
            tablename LIKE '%user%' OR 
            tablename LIKE '%token%' OR 
            tablename LIKE '%balance%' OR 
            tablename LIKE '%transaction%' OR
            tablename LIKE '%treasury%' OR
            tablename LIKE '%atomic%'
        )
        ORDER BY tablename
    LOOP
        RAISE NOTICE '✅ Tabla: %', table_record.tablename;
    END LOOP;
END $$;

-- =====================================================
-- 2. ESTRUCTURA DE TABLA USERS
-- =====================================================
DO $$
DECLARE
    col_record RECORD;
BEGIN
    RAISE NOTICE '';
    RAISE NOTICE '👤 === ESTRUCTURA TABLA USERS ===';
    
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'users') THEN
        FOR col_record IN 
            SELECT 
                column_name, 
                data_type, 
                is_nullable,
                column_default
            FROM information_schema.columns 
            WHERE table_name = 'users' 
            ORDER BY ordinal_position
        LOOP
            RAISE NOTICE '  📝 %: % (nullable: %, default: %)', 
                col_record.column_name, 
                col_record.data_type, 
                col_record.is_nullable,
                COALESCE(col_record.column_default, 'none');
        END LOOP;
        
        -- Contar registros
        EXECUTE 'SELECT COUNT(*) FROM users' INTO col_record;
        RAISE NOTICE '  📊 Total usuarios: %', col_record.count;
    ELSE
        RAISE NOTICE '❌ Tabla users NO EXISTE';
    END IF;
END $$;

-- =====================================================
-- 3. ESTRUCTURA DE TABLA TOKEN_TRANSACTIONS
-- =====================================================
DO $$
DECLARE
    col_record RECORD;
BEGIN
    RAISE NOTICE '';
    RAISE NOTICE '💸 === ESTRUCTURA TABLA TOKEN_TRANSACTIONS ===';
    
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'token_transactions') THEN
        FOR col_record IN 
            SELECT 
                column_name, 
                data_type, 
                is_nullable,
                column_default
            FROM information_schema.columns 
            WHERE table_name = 'token_transactions' 
            ORDER BY ordinal_position
        LOOP
            RAISE NOTICE '  📝 %: % (nullable: %, default: %)', 
                col_record.column_name, 
                col_record.data_type, 
                col_record.is_nullable,
                COALESCE(col_record.column_default, 'none');
        END LOOP;
        
        -- Contar registros
        EXECUTE 'SELECT COUNT(*) FROM token_transactions' INTO col_record;
        RAISE NOTICE '  📊 Total transacciones: %', col_record.count;
    ELSE
        RAISE NOTICE '❌ Tabla token_transactions NO EXISTE';
    END IF;
END $$;

-- =====================================================
-- 4. ESTRUCTURA DE TABLA USER_BALANCES
-- =====================================================
DO $$
DECLARE
    col_record RECORD;
BEGIN
    RAISE NOTICE '';
    RAISE NOTICE '💰 === ESTRUCTURA TABLA USER_BALANCES ===';
    
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'user_balances') THEN
        FOR col_record IN 
            SELECT 
                column_name, 
                data_type, 
                is_nullable,
                column_default
            FROM information_schema.columns 
            WHERE table_name = 'user_balances' 
            ORDER BY ordinal_position
        LOOP
            RAISE NOTICE '  📝 %: % (nullable: %, default: %)', 
                col_record.column_name, 
                col_record.data_type, 
                col_record.is_nullable,
                COALESCE(col_record.column_default, 'none');
        END LOOP;
        
        -- Contar registros
        EXECUTE 'SELECT COUNT(*) FROM user_balances' INTO col_record;
        RAISE NOTICE '  📊 Total balances: %', col_record.count;
    ELSE
        RAISE NOTICE '❌ Tabla user_balances NO EXISTE';
    END IF;
END $$;

-- =====================================================
-- 5. ESTRUCTURA DE TABLA TREASURY_ACCOUNTS
-- =====================================================
DO $$
DECLARE
    col_record RECORD;
BEGIN
    RAISE NOTICE '';
    RAISE NOTICE '🏦 === ESTRUCTURA TABLA TREASURY_ACCOUNTS ===';
    
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'treasury_accounts') THEN
        FOR col_record IN 
            SELECT 
                column_name, 
                data_type, 
                is_nullable,
                column_default
            FROM information_schema.columns 
            WHERE table_name = 'treasury_accounts' 
            ORDER BY ordinal_position
        LOOP
            RAISE NOTICE '  📝 %: % (nullable: %, default: %)', 
                col_record.column_name, 
                col_record.data_type, 
                col_record.is_nullable,
                COALESCE(col_record.column_default, 'none');
        END LOOP;
        
        -- Contar registros
        EXECUTE 'SELECT COUNT(*) FROM treasury_accounts' INTO col_record;
        RAISE NOTICE '  📊 Total cuentas treasury: %', col_record.count;
    ELSE
        RAISE NOTICE '❌ Tabla treasury_accounts NO EXISTE';
    END IF;
END $$;

-- =====================================================
-- 6. ESTRUCTURA DE TABLA ATOMIC_TOKEN_OPERATIONS
-- =====================================================
DO $$
DECLARE
    col_record RECORD;
BEGIN
    RAISE NOTICE '';
    RAISE NOTICE '⚛️ === ESTRUCTURA TABLA ATOMIC_TOKEN_OPERATIONS ===';
    
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'atomic_token_operations') THEN
        FOR col_record IN 
            SELECT 
                column_name, 
                data_type, 
                is_nullable,
                column_default
            FROM information_schema.columns 
            WHERE table_name = 'atomic_token_operations' 
            ORDER BY ordinal_position
        LOOP
            RAISE NOTICE '  📝 %: % (nullable: %, default: %)', 
                col_record.column_name, 
                col_record.data_type, 
                col_record.is_nullable,
                COALESCE(col_record.column_default, 'none');
        END LOOP;
        
        -- Contar registros
        EXECUTE 'SELECT COUNT(*) FROM atomic_token_operations' INTO col_record;
        RAISE NOTICE '  📊 Total operaciones atómicas: %', col_record.count;
    ELSE
        RAISE NOTICE '❌ Tabla atomic_token_operations NO EXISTE';
    END IF;
END $$;

-- =====================================================
-- 7. FUNCIONES RELACIONADAS CON TOKENS
-- =====================================================
DO $$
DECLARE
    func_record RECORD;
BEGIN
    RAISE NOTICE '';
    RAISE NOTICE '🔧 === FUNCIONES DISPONIBLES ===';
    
    FOR func_record IN 
        SELECT 
            routine_name,
            routine_type
        FROM information_schema.routines 
        WHERE routine_schema = 'public' 
        AND (
            routine_name LIKE '%token%' OR 
            routine_name LIKE '%balance%' OR 
            routine_name LIKE '%transfer%' OR
            routine_name LIKE '%welcome%' OR
            routine_name LIKE '%treasury%'
        )
        ORDER BY routine_name
    LOOP
        RAISE NOTICE '  🔧 %: %', func_record.routine_name, func_record.routine_type;
    END LOOP;
END $$;

-- =====================================================
-- 8. DATOS DE MUESTRA
-- =====================================================
DO $$
BEGIN
    RAISE NOTICE '';
    RAISE NOTICE '📊 === DATOS DE MUESTRA ===';
    
    -- Usuarios con balances
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'users') THEN
        RAISE NOTICE '👥 Primeros 5 usuarios:';
        FOR rec IN 
            SELECT 
                email, 
                COALESCE(full_name, 'Sin nombre') as name,
                COALESCE(token_balance, 0) as balance
            FROM users 
            ORDER BY created_at 
            LIMIT 5
        LOOP
            RAISE NOTICE '  👤 %: % (% tokens)', rec.email, rec.name, rec.balance;
        END LOOP;
    END IF;
    
    -- Transacciones recientes
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'token_transactions') THEN
        RAISE NOTICE '';
        RAISE NOTICE '💸 Últimas 3 transacciones:';
        FOR rec IN 
            SELECT 
                id,
                amount,
                transaction_type,
                created_at
            FROM token_transactions 
            ORDER BY created_at DESC 
            LIMIT 3
        LOOP
            RAISE NOTICE '  💸 ID %: % tokens (%)', rec.id, rec.amount, rec.transaction_type;
        END LOOP;
    END IF;
END $$;

-- =====================================================
-- 9. RESUMEN FINAL
-- =====================================================
DO $$
DECLARE
    users_count INTEGER := 0;
    transactions_count INTEGER := 0;
    balances_count INTEGER := 0;
    treasury_count INTEGER := 0;
BEGIN
    RAISE NOTICE '';
    RAISE NOTICE '📋 === RESUMEN FINAL ===';
    
    -- Contar registros en cada tabla
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'users') THEN
        SELECT COUNT(*) INTO users_count FROM users;
    END IF;
    
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'token_transactions') THEN
        SELECT COUNT(*) INTO transactions_count FROM token_transactions;
    END IF;
    
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'user_balances') THEN
        SELECT COUNT(*) INTO balances_count FROM user_balances;
    END IF;
    
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'treasury_accounts') THEN
        SELECT COUNT(*) INTO treasury_count FROM treasury_accounts;
    END IF;
    
    RAISE NOTICE '👥 Usuarios: %', users_count;
    RAISE NOTICE '💸 Transacciones: %', transactions_count;
    RAISE NOTICE '💰 Balances: %', balances_count;
    RAISE NOTICE '🏦 Treasury: %', treasury_count;
    
    RAISE NOTICE '';
    RAISE NOTICE '✅ DIAGNÓSTICO COMPLETADO';
END $$;
