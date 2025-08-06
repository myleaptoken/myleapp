-- =====================================================
-- CONVERSIÓN SEGURA A NUMERIC PARA TODAS LAS COLUMNAS
-- =====================================================
-- Convierte todas las columnas relacionadas con tokens a NUMERIC
-- =====================================================

DO $$
DECLARE
    target_table TEXT;
    target_column TEXT;
    current_type TEXT;
    conversion_count INTEGER := 0;
BEGIN
    RAISE NOTICE '==============================================';
    RAISE NOTICE 'INICIANDO CONVERSIÓN A NUMERIC';
    RAISE NOTICE '==============================================';
    
    -- Lista de tablas y columnas a convertir
    FOR target_table, target_column IN VALUES 
        ('users', 'token_balance'),
        ('user_balances', 'balance'),
        ('atomic_token_operations', 'amount'),
        ('token_transactions', 'amount')
    LOOP
        -- Verificar si la tabla existe
        IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = target_table AND table_schema = 'public') THEN
            -- Verificar si la columna existe
            SELECT data_type INTO current_type
            FROM information_schema.columns 
            WHERE table_name = target_table 
            AND column_name = target_column 
            AND table_schema = 'public';
            
            IF current_type IS NOT NULL THEN
                RAISE NOTICE 'Procesando %.% (tipo actual: %)', target_table, target_column, current_type;
                
                -- Solo convertir si no es ya NUMERIC
                IF current_type != 'numeric' THEN
                    BEGIN
                        EXECUTE format('ALTER TABLE %I ALTER COLUMN %I TYPE NUMERIC(20,0)', target_table, target_column);
                        conversion_count := conversion_count + 1;
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
        ELSE
            RAISE NOTICE '⚠ Tabla % no existe', target_table;
        END IF;
    END LOOP;
    
    RAISE NOTICE '==============================================';
    RAISE NOTICE 'CONVERSIÓN COMPLETADA';
    RAISE NOTICE 'Columnas convertidas: %', conversion_count;
    RAISE NOTICE '==============================================';
END $$;

-- Verificar el resultado
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
