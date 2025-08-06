-- =====================================================
-- DESCUBRIR TIPOS VÁLIDOS PARA TOKEN_TRANSACTIONS
-- =====================================================
-- Encuentra qué valores son permitidos en el constraint
-- =====================================================

-- Mostrar el constraint actual
DO $$
BEGIN
    RAISE NOTICE '==============================================';
    RAISE NOTICE 'CONSTRAINT DE TOKEN_TRANSACTIONS.TYPE:';
    RAISE NOTICE '==============================================';
END $$;

SELECT 
    conname as constraint_name,
    pg_get_constraintdef(oid) as constraint_definition
FROM pg_constraint 
WHERE conrelid = 'token_transactions'::regclass 
AND contype = 'c'
AND conname LIKE '%type%';

-- Mostrar valores existentes en la tabla
DO $$
BEGIN
    RAISE NOTICE '==============================================';
    RAISE NOTICE 'VALORES EXISTENTES EN TOKEN_TRANSACTIONS:';
    RAISE NOTICE '==============================================';
END $$;

SELECT 
    COALESCE(type, 'NULL') as existing_type, 
    COUNT(*) as count
FROM token_transactions 
GROUP BY type
ORDER BY count DESC;

-- Función para probar tipos válidos
CREATE OR REPLACE FUNCTION test_token_type(test_type TEXT)
RETURNS BOOLEAN AS $$
DECLARE
    test_user_id UUID;
    result BOOLEAN := FALSE;
    test_id UUID;
BEGIN
    -- Obtener un usuario de prueba
    SELECT id INTO test_user_id FROM users LIMIT 1;
    
    IF test_user_id IS NULL THEN
        RAISE NOTICE 'NO HAY USUARIOS PARA PROBAR';
        RETURN FALSE;
    END IF;
    
    test_id := gen_random_uuid();
    
    BEGIN
        -- Intentar insertar con este tipo
        INSERT INTO token_transactions (
            id, user_id, amount, type, description, created_at
        ) VALUES (
            test_id, 
            test_user_id, 
            1000000000, -- 1 LEAP en formato atómico
            test_type, 
            'Test transaction', 
            NOW()
        );
        
        -- Si llegamos aquí, funcionó
        result := TRUE;
        RAISE NOTICE 'VÁLIDO: %', test_type;
        
        -- Limpiar - eliminar el registro de prueba
        DELETE FROM token_transactions WHERE id = test_id;
        
    EXCEPTION WHEN OTHERS THEN
        result := FALSE;
        RAISE NOTICE 'INVÁLIDO: % (Error: %)', test_type, SQLERRM;
    END;
    
    RETURN result;
END;
$$ LANGUAGE plpgsql;

-- Probar tipos comunes
DO $$
DECLARE
    test_values TEXT[] := ARRAY[
        'transfer', 'payment', 'bonus', 'reward', 'purchase', 
        'send', 'receive', 'credit', 'debit', 'transaction',
        'deposit', 'withdrawal', 'earn', 'spend', 'refund',
        'mint', 'burn', 'stake', 'unstake', 'fee'
    ];
    test_value TEXT;
    valid_count INTEGER := 0;
    valid_types TEXT[] := ARRAY[]::TEXT[];
BEGIN
    RAISE NOTICE '==============================================';
    RAISE NOTICE 'PROBANDO TIPOS VÁLIDOS:';
    RAISE NOTICE '==============================================';
    
    FOREACH test_value IN ARRAY test_values
    LOOP
        IF test_token_type(test_value) THEN
            valid_count := valid_count + 1;
            valid_types := array_append(valid_types, test_value);
        END IF;
    END LOOP;
    
    RAISE NOTICE '==============================================';
    RAISE NOTICE 'RESUMEN:';
    RAISE NOTICE 'Tipos válidos encontrados: %', valid_count;
    IF valid_count > 0 THEN
        RAISE NOTICE 'Tipos válidos: %', array_to_string(valid_types, ', ');
    ELSE
        RAISE NOTICE 'NO SE ENCONTRARON TIPOS VÁLIDOS';
    END IF;
    RAISE NOTICE '==============================================';
END $$;

-- Limpiar función temporal
DROP FUNCTION test_token_type(TEXT);

-- Mostrar estructura completa de la tabla
DO $$
BEGIN
    RAISE NOTICE '==============================================';
    RAISE NOTICE 'ESTRUCTURA DE TOKEN_TRANSACTIONS:';
    RAISE NOTICE '==============================================';
END $$;

SELECT 
    column_name,
    data_type,
    is_nullable,
    column_default
FROM information_schema.columns 
WHERE table_name = 'token_transactions'
AND table_schema = 'public'
ORDER BY ordinal_position;
