-- =====================================================
-- CONVERTIR COLUMNAS A NUMERIC DE FORMA SEGURA
-- =====================================================
-- Convierte todas las columnas relacionadas con tokens a NUMERIC
-- para evitar problemas de overflow de enteros
-- =====================================================

DO $$
DECLARE
    target_table TEXT;
    target_column TEXT;
    current_type TEXT;
    conversion_sql TEXT;
    tables_to_fix TEXT[] := ARRAY['users', 'atomic_token_operations', 'token_transactions'];
    columns_to_fix TEXT[] := ARRAY['token_balance', 'amount'];
    table_column_pair RECORD;
BEGIN
    RAISE NOTICE '==============================================';
    RAISE NOTICE 'INICIANDO CONVERSIÓN A NUMERIC';
    RAISE NOTICE '==============================================';
    
    -- Iterar sobre cada combinación tabla-columna
    FOREACH target_table IN ARRAY tables_to_fix
    LOOP
        FOREACH target_column IN ARRAY columns_to_fix
        LOOP
            -- Verificar si la tabla y columna existen
            SELECT data_type INTO current_type
            FROM information_schema.columns 
            WHERE table_name = target_table 
            AND column_name = target_column;
            
            IF current_type IS NOT NULL THEN
                RAISE NOTICE 'Procesando %.% (tipo actual: %)', target_table, target_column, current_type;
                
                -- Solo convertir si no es ya NUMERIC
                IF current_type != 'numeric' THEN
                    BEGIN
                        -- Construir y ejecutar SQL de conversión
                        conversion_sql := format('ALTER TABLE %I ALTER COLUMN %I TYPE NUMERIC(20,0) USING %I::NUMERIC', 
                                                target_table, target_column, target_column);
                        
                        EXECUTE conversion_sql;
                        RAISE NOTICE '✓ Convertido %.% a NUMERIC(20,0)', target_table, target_column;
                        
                    EXCEPTION WHEN OTHERS THEN
                        RAISE NOTICE '✗ Error convirtiendo %.%: %', target_table, target_column, SQLERRM;
                    END;
                ELSE
                    RAISE NOTICE '✓ %.% ya es NUMERIC', target_table, target_column;
                END IF;
            ELSE
                RAISE NOTICE '⚠ Columna %.% no existe', target_table, target_column;
            END IF;
        END LOOP;
    END LOOP;
    
    -- Verificar conversiones
    RAISE NOTICE '==============================================';
    RAISE NOTICE 'VERIFICANDO CONVERSIONES';
    RAISE NOTICE '==============================================';
    
    FOR table_column_pair IN
        SELECT 
            table_name,
            column_name,
            data_type,
            numeric_precision,
            numeric_scale
        FROM information_schema.columns 
        WHERE table_name = ANY(tables_to_fix)
        AND column_name = ANY(columns_to_fix)
        AND data_type = 'numeric'
        ORDER BY table_name, column_name
    LOOP
        RAISE NOTICE '✓ %.%: % (precision: %, scale: %)', 
                     table_column_pair.table_name, 
                     table_column_pair.column_name,
                     table_column_pair.data_type,
                     table_column_pair.numeric_precision,
                     table_column_pair.numeric_scale;
    END LOOP;
    
    RAISE NOTICE '==============================================';
    RAISE NOTICE 'CONVERSIÓN A NUMERIC COMPLETADA';
    RAISE NOTICE '==============================================';
END $$;
