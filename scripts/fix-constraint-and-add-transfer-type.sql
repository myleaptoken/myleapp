-- =====================================================
-- ARREGLAR CONSTRAINT Y AÑADIR TIPO 'transfer'
-- =====================================================
-- Modifica el constraint para permitir 'transfer' como tipo válido
-- =====================================================

-- Primero, mostrar el constraint actual
DO $$
BEGIN
    RAISE NOTICE '==============================================';
    RAISE NOTICE 'ANALIZANDO CONSTRAINT ACTUAL';
    RAISE NOTICE '==============================================';
END $$;

-- Mostrar constraint actual
SELECT 
    conname as constraint_name,
    pg_get_constraintdef(oid) as constraint_definition
FROM pg_constraint 
WHERE conrelid = 'token_transactions'::regclass 
AND contype = 'c'
AND conname LIKE '%type%';

-- Eliminar constraint existente si existe
DO $$
DECLARE
    constraint_name TEXT;
BEGIN
    -- Buscar el constraint de tipo
    SELECT conname INTO constraint_name
    FROM pg_constraint 
    WHERE conrelid = 'token_transactions'::regclass 
    AND contype = 'c'
    AND conname LIKE '%type%'
    LIMIT 1;
    
    IF constraint_name IS NOT NULL THEN
        RAISE NOTICE 'Eliminando constraint existente: %', constraint_name;
        EXECUTE format('ALTER TABLE token_transactions DROP CONSTRAINT %I', constraint_name);
        RAISE NOTICE '✓ Constraint eliminado';
    ELSE
        RAISE NOTICE 'No se encontró constraint de tipo existente';
    END IF;
END $$;

-- Crear nuevo constraint que incluya 'transfer' y otros tipos comunes
ALTER TABLE token_transactions 
ADD CONSTRAINT token_transactions_type_check 
CHECK (type IN ('bonus', 'reward', 'payment', 'transfer', 'credit', 'debit', 'deposit', 'withdrawal', 'purchase', 'refund'));

-- Verificar el nuevo constraint
DO $$
BEGIN
    RAISE NOTICE '==============================================';
    RAISE NOTICE 'NUEVO CONSTRAINT CREADO';
    RAISE NOTICE '==============================================';
END $$;

SELECT 
    conname as constraint_name,
    pg_get_constraintdef(oid) as constraint_definition
FROM pg_constraint 
WHERE conrelid = 'token_transactions'::regclass 
AND contype = 'c'
AND conname LIKE '%type%';

-- Probar que 'transfer' ahora funciona
DO $$
DECLARE
    test_user_id UUID;
    test_id UUID;
BEGIN
    -- Obtener un usuario de prueba
    SELECT id INTO test_user_id FROM users LIMIT 1;
    
    IF test_user_id IS NOT NULL THEN
        test_id := gen_random_uuid();
        
        BEGIN
            -- Intentar insertar con tipo 'transfer'
            INSERT INTO token_transactions (
                id, user_id, amount, type, description, created_at
            ) VALUES (
                test_id, 
                test_user_id, 
                1000000000, 
                'transfer', 
                'Test transfer transaction', 
                NOW()
            );
            
            RAISE NOTICE '✓ Tipo "transfer" funciona correctamente';
            
            -- Limpiar
            DELETE FROM token_transactions WHERE id = test_id;
            
        EXCEPTION WHEN OTHERS THEN
            RAISE NOTICE '✗ Error con tipo "transfer": %', SQLERRM;
        END;
    ELSE
        RAISE NOTICE '⚠ No hay usuarios para probar';
    END IF;
END $$;

DO $$
BEGIN
    RAISE NOTICE '==============================================';
    RAISE NOTICE 'CONSTRAINT ACTUALIZADO EXITOSAMENTE';
    RAISE NOTICE 'Tipos permitidos: bonus, reward, payment, transfer, credit, debit, deposit, withdrawal, purchase, refund';
    RAISE NOTICE '==============================================';
END $$;
