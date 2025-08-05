-- =====================================================
-- FORZAR CONVERSIÓN A NUMERIC EN TODAS LAS TABLAS
-- =====================================================
-- Convierte todas las columnas de tokens a NUMERIC para evitar overflow
-- =====================================================

DO $$
DECLARE
    target_table TEXT;
    target_column TEXT;
    sql_command TEXT;
    current_type TEXT;
BEGIN
    RAISE NOTICE '==============================================';
    RAISE NOTICE 'FORZANDO CONVERSIÓN A NUMERIC EN TODAS LAS TABLAS';
    RAISE NOTICE '==============================================';
    
    -- Lista de tablas y columnas que necesitan ser NUMERIC
    FOR target_table, target_column IN VALUES 
        ('users', 'token_balance'),
        ('user_balances', 'balance'),
        ('atomic_token_operations', 'amount'),
        ('token_transactions', 'amount')
    LOOP
        -- Verificar si la tabla existe
        IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = target_table) THEN
            -- Verificar si la columna existe
            IF EXISTS (SELECT 1 FROM information_schema.columns 
                      WHERE table_name = target_table AND column_name = target_column) THEN
                
                -- Obtener el tipo actual
                SELECT data_type INTO current_type
                FROM information_schema.columns 
                WHERE table_name = target_table AND column_name = target_column;
                
                RAISE NOTICE 'Procesando: %.% (tipo actual: %)', target_table, target_column, current_type;
                
                -- Solo convertir si no es ya NUMERIC
                IF current_type != 'numeric' THEN
                    BEGIN
                        sql_command := format('ALTER TABLE %I ALTER COLUMN %I TYPE NUMERIC(20,0)', 
                                            target_table, target_column);
                        EXECUTE sql_command;
                        RAISE NOTICE '✓ Convertido: %.% → NUMERIC(20,0)', target_table, target_column;
                    EXCEPTION WHEN OTHERS THEN
                        RAISE WARNING '✗ Error convirtiendo %.%: %', target_table, target_column, SQLERRM;
                    END;
                ELSE
                    RAISE NOTICE '✓ Ya es NUMERIC: %.%', target_table, target_column;
                END IF;
            ELSE
                RAISE NOTICE '⚠ Columna %.% no existe', target_table, target_column;
            END IF;
        ELSE
            RAISE NOTICE '⚠ Tabla % no existe', target_table;
        END IF;
    END LOOP;
    
    RAISE NOTICE '==============================================';
    RAISE NOTICE 'CONVERSIÓN A NUMERIC COMPLETADA';
    RAISE NOTICE '==============================================';
    
    -- Verificar los tipos de datos actuales
    RAISE NOTICE 'TIPOS DE DATOS FINALES:';
    FOR target_table, target_column IN VALUES 
        ('users', 'token_balance'),
        ('user_balances', 'balance'),
        ('atomic_token_operations', 'amount'),
        ('token_transactions', 'amount')
    LOOP
        IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = target_table) AND
           EXISTS (SELECT 1 FROM information_schema.columns 
                  WHERE table_name = target_table AND column_name = target_column) THEN
            
            SELECT data_type INTO current_type
            FROM information_schema.columns 
            WHERE table_name = target_table AND column_name = target_column;
            
            RAISE NOTICE '%.% → %', target_table, target_column, current_type;
        END IF;
    END LOOP;
    
END $$;
