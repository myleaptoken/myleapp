-- =====================================================
-- FORZAR CONVERSIÓN A NUMERIC EN TODAS LAS TABLAS
-- =====================================================
-- Convierte todas las columnas de tokens a NUMERIC para evitar overflow
-- =====================================================

DO $$
DECLARE
    table_name TEXT;
    column_name TEXT;
    sql_command TEXT;
BEGIN
    RAISE NOTICE '==============================================';
    RAISE NOTICE 'FORZANDO CONVERSIÓN A NUMERIC EN TODAS LAS TABLAS';
    RAISE NOTICE '==============================================';
    
    -- Lista de tablas y columnas que necesitan ser NUMERIC
    FOR table_name, column_name IN VALUES 
        ('users', 'token_balance'),
        ('user_balances', 'balance'),
        ('atomic_token_operations', 'amount'),
        ('token_transactions', 'amount')
    LOOP
        -- Verificar si la tabla existe
        IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = table_name) THEN
            -- Verificar si la columna existe
            IF EXISTS (SELECT 1 FROM information_schema.columns 
                      WHERE table_name = table_name AND column_name = column_name) THEN
                
                BEGIN
                    sql_command := format('ALTER TABLE %I ALTER COLUMN %I TYPE NUMERIC(20,0)', 
                                        table_name, column_name);
                    EXECUTE sql_command;
                    RAISE NOTICE 'Convertido: %.% → NUMERIC(20,0)', table_name, column_name;
                EXCEPTION WHEN OTHERS THEN
                    RAISE WARNING 'Error convirtiendo %.%: %', table_name, column_name, SQLERRM;
                END;
            ELSE
                RAISE NOTICE 'Columna %.% no existe', table_name, column_name;
            END IF;
        ELSE
            RAISE NOTICE 'Tabla % no existe', table_name;
        END IF;
    END LOOP;
    
    RAISE NOTICE '==============================================';
    RAISE NOTICE 'CONVERSIÓN A NUMERIC COMPLETADA';
    RAISE NOTICE '==============================================';
    
    -- Verificar los tipos de datos actuales
    RAISE NOTICE 'TIPOS DE DATOS ACTUALES:';
    FOR table_name, column_name IN VALUES 
        ('users', 'token_balance'),
        ('user_balances', 'balance'),
        ('atomic_token_operations', 'amount'),
        ('token_transactions', 'amount')
    LOOP
        IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = table_name) AND
           EXISTS (SELECT 1 FROM information_schema.columns 
                  WHERE table_name = table_name AND column_name = column_name) THEN
            
            SELECT data_type INTO sql_command
            FROM information_schema.columns 
            WHERE table_name = table_name AND column_name = column_name;
            
            RAISE NOTICE '%.% → %', table_name, column_name, sql_command;
        END IF;
    END LOOP;
    
END $$;
