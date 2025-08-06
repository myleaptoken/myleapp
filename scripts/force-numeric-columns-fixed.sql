-- =====================================================
-- FORZAR CONVERSIÓN A NUMERIC - VERSIÓN CORREGIDA
-- =====================================================
-- Convierte todas las columnas de tokens a NUMERIC para evitar overflow
-- =====================================================

DO $$
DECLARE
    target_table TEXT;
    target_column TEXT;
    current_type TEXT;
    tables_to_fix TEXT[] := ARRAY['users', 'user_balances', 'atomic_token_operations', 'token_transactions'];
    columns_to_fix TEXT[] := ARRAY['token_balance', 'balance', 'amount'];
    table_exists BOOLEAN;
    column_exists BOOLEAN;
    conversion_count INTEGER := 0;
BEGIN
    RAISE NOTICE '==============================================';
    RAISE NOTICE 'INICIANDO CONVERSIÓN A NUMERIC';
    RAISE NOTICE '==============================================';
    
    -- Iterar sobre cada tabla
    FOREACH target_table IN ARRAY tables_to_fix
    LOOP
        -- Verificar si la tabla existe
        SELECT EXISTS (
            SELECT 1 FROM information_schema.tables 
            WHERE table_name = target_table 
            AND table_schema = 'public'
        ) INTO table_exists;
        
        IF table_exists THEN
            RAISE NOTICE 'Procesando tabla: %', target_table;
            
            -- Iterar sobre cada columna
            FOREACH target_column IN ARRAY columns_to_fix
            LOOP
                -- Verificar si la columna existe en esta tabla
                SELECT EXISTS (
                    SELECT 1 FROM information_schema.columns 
                    WHERE table_name = target_table 
                    AND column_name = target_column
                    AND table_schema = 'public'
                ) INTO column_exists;
                
                IF column_exists THEN
                    -- Obtener el tipo actual de la columna
                    SELECT data_type INTO current_type
                    FROM information_schema.columns 
                    WHERE table_name = target_table 
                    AND column_name = target_column
                    AND table_schema = 'public';
                    
                    RAISE NOTICE '  Columna %.% - Tipo actual: %', target_table, target_column, current_type;
                    
                    -- Si no es NUMERIC, convertir
                    IF current_type != 'numeric' THEN
                        BEGIN
                            EXECUTE format('ALTER TABLE %I ALTER COLUMN %I TYPE NUMERIC(20,0) USING %I::NUMERIC(20,0)', 
                                         target_table, target_column, target_column);
                            RAISE NOTICE '  ✓ Convertido %.% a NUMERIC(20,0)', target_table, target_column;
                            conversion_count := conversion_count + 1;
                        EXCEPTION WHEN OTHERS THEN
                            RAISE NOTICE '  ✗ Error convirtiendo %.%: %', target_table, target_column, SQLERRM;
                        END;
                    ELSE
                        RAISE NOTICE '  ✓ %.% ya es NUMERIC', target_table, target_column;
                    END IF;
                ELSE
                    RAISE NOTICE '  - Columna %.% no existe', target_table, target_column;
                END IF;
            END LOOP;
        ELSE
            RAISE NOTICE 'Tabla % no existe', target_table;
        END IF;
    END LOOP;
    
    RAISE NOTICE '==============================================';
    RAISE NOTICE 'CONVERSIÓN COMPLETADA';
    RAISE NOTICE 'Columnas convertidas: %', conversion_count;
    RAISE NOTICE '==============================================';
END $$;

-- Verificar los tipos finales
SELECT 
    table_name,
    column_name,
    data_type,
    numeric_precision,
    numeric_scale
FROM information_schema.columns 
WHERE table_name IN ('users', 'user_balances', 'atomic_token_operations', 'token_transactions')
AND column_name IN ('token_balance', 'balance', 'amount')
AND table_schema = 'public'
ORDER BY table_name, column_name;
