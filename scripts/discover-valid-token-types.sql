-- =====================================================
-- DESCUBRIR TIPOS VÁLIDOS EN TOKEN_TRANSACTIONS
-- =====================================================
-- Analiza la estructura y constraints de la tabla
-- =====================================================

DO $$
BEGIN
    RAISE NOTICE '==============================================';
    RAISE NOTICE 'ANALIZANDO TABLA TOKEN_TRANSACTIONS';
    RAISE NOTICE '==============================================';
END $$;

-- Mostrar estructura de la tabla
SELECT 
    column_name,
    data_type,
    is_nullable,
    column_default
FROM information_schema.columns 
WHERE table_name = 'token_transactions'
ORDER BY ordinal_position;

-- Mostrar constraints existentes
SELECT 
    conname as constraint_name,
    pg_get_constraintdef(oid) as constraint_definition
FROM pg_constraint 
WHERE conrelid = 'token_transactions'::regclass 
AND contype = 'c';

-- Mostrar tipos únicos existentes en la tabla
SELECT DISTINCT type, COUNT(*) as count
FROM token_transactions 
GROUP BY type
ORDER BY count DESC;

-- Mostrar información sobre columnas numéricas
SELECT 
    table_name,
    column_name,
    data_type,
    numeric_precision,
    numeric_scale
FROM information_schema.columns 
WHERE table_name IN ('token_transactions', 'users', 'atomic_token_operations')
AND data_type = 'numeric'
ORDER BY table_name, column_name;

DO $$
BEGIN
    RAISE NOTICE '==============================================';
    RAISE NOTICE 'ANÁLISIS COMPLETADO';
    RAISE NOTICE '==============================================';
END $$;
