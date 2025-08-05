-- Arreglar la contabilidad del Treasury y establecer el sistema correcto
BEGIN;

-- Paso 1: Contar cuántos usuarios tenemos y cuántos tokens se distribuyeron
DO $$
DECLARE
    user_count BIGINT;
    total_distributed BIGINT;
    issuer_account_id UUID;
    rewards_account_id UUID;
BEGIN
    -- Contar usuarios
    SELECT COUNT(*)::BIGINT INTO user_count FROM users;
    
    -- Calcular total distribuido (1230 tokens por usuario en unidades atómicas)
    total_distributed := user_count * 1230000000::BIGINT; -- En unidades atómicas (1230 * 1,000,000)
    
    RAISE NOTICE 'Usuarios: %, Tokens distribuidos: % atomic units (% LEAP)', 
        user_count, total_distributed, (total_distributed::DECIMAL / 1000000);
    
    -- Obtener IDs de cuentas treasury
    SELECT id INTO issuer_account_id FROM treasury_accounts WHERE account_type = 'issuer';
    SELECT id INTO rewards_account_id FROM treasury_accounts WHERE account_type = 'rewards';
    
    IF issuer_account_id IS NULL THEN
        RAISE EXCEPTION 'Issuer account not found';
    END IF;
    
    IF rewards_account_id IS NULL THEN
        RAISE EXCEPTION 'Rewards account not found';
    END IF;
    
    -- Verificar que el issuer tenga suficiente balance
    DECLARE
        issuer_balance BIGINT;
    BEGIN
        SELECT balance INTO issuer_balance FROM treasury_accounts WHERE id = issuer_account_id;
        
        IF issuer_balance < total_distributed THEN
            RAISE NOTICE 'WARNING: Issuer balance (%) is less than required (%). Proceeding anyway.', 
                issuer_balance, total_distributed;
        END IF;
    END;
    
    -- Paso 2: Transferir tokens del issuer al rewards pool
    UPDATE treasury_accounts 
    SET balance = balance - total_distributed,
        updated_at = NOW()
    WHERE id = issuer_account_id;
    
    UPDATE treasury_accounts 
    SET balance = balance + total_distributed,
        updated_at = NOW()
    WHERE id = rewards_account_id;
    
    -- Paso 3: Registrar la operación de transferencia treasury -> rewards
    INSERT INTO atomic_token_operations (
        operation_type,
        from_account_type,
        from_account_id,
        to_account_type,
        to_account_id,
        amount,
        reference_type,
        description,
        status,
        processed_at,
        created_at
    ) VALUES (
        'transfer',
        'treasury',
        issuer_account_id,
        'treasury', 
        rewards_account_id,
        total_distributed,
        'treasury_allocation',
        'Transferencia de tokens del issuer al rewards pool para distribución inicial',
        'completed',
        NOW(),
        NOW()
    );
    
    -- Paso 4: Actualizar las operaciones existentes de usuarios para que vengan del rewards pool
    UPDATE atomic_token_operations 
    SET from_account_type = 'treasury',
        from_account_id = rewards_account_id,
        description = 'Bonus de bienvenida - 1230 LEAP tokens (desde rewards pool)'
    WHERE reference_type = 'welcome_bonus' 
    AND to_account_type = 'user';
    
    RAISE NOTICE 'Contabilidad del treasury corregida exitosamente';
END $$;

-- Paso 5: Crear vista para ver el estado actual del treasury
CREATE OR REPLACE VIEW treasury_summary AS
SELECT 
    account_type,
    name,
    description,
    atomic_to_leap(balance) as balance_leap,
    balance as balance_atomic,
    is_active,
    updated_at
FROM treasury_accounts
ORDER BY 
    CASE account_type 
        WHEN 'issuer' THEN 1
        WHEN 'rewards' THEN 2  
        WHEN 'platform' THEN 3
        WHEN 'reserve' THEN 4
        ELSE 5
    END;

-- Paso 6: Crear función para obtener circulación total de tokens
CREATE OR REPLACE FUNCTION get_token_circulation()
RETURNS TABLE(
    total_issued DECIMAL,
    total_in_treasury DECIMAL,
    total_in_circulation DECIMAL,
    total_user_balances DECIMAL,
    accounting_difference DECIMAL
) AS $$
DECLARE
    v_total_issued DECIMAL;
    v_total_treasury DECIMAL;
    v_total_users DECIMAL;
BEGIN
    -- Total emitido (lo que salió del issuer)
    SELECT 10000000 - atomic_to_leap(balance) INTO v_total_issued
    FROM treasury_accounts WHERE account_type = 'issuer';
    
    -- Total en treasury (rewards + platform + reserve)
    SELECT COALESCE(SUM(atomic_to_leap(balance)), 0) INTO v_total_treasury
    FROM treasury_accounts 
    WHERE account_type IN ('rewards', 'platform', 'reserve');
    
    -- Total en balances de usuarios
    SELECT COALESCE(SUM(available_balance), 0) INTO v_total_users
    FROM user_balances WHERE balance_type = 'tokens';
    
    RETURN QUERY SELECT 
        COALESCE(v_total_issued, 0),
        COALESCE(v_total_treasury, 0),
        COALESCE(v_total_issued, 0) - COALESCE(v_total_treasury, 0),
        COALESCE(v_total_users, 0),
        (COALESCE(v_total_issued, 0) - COALESCE(v_total_treasury, 0)) - COALESCE(v_total_users, 0);
END;
$$ LANGUAGE plpgsql;

-- Paso 7: Verificar la contabilidad
SELECT 'ESTADO DEL TREASURY DESPUÉS DE LA CORRECCIÓN:' as info;
SELECT * FROM treasury_summary;

SELECT 'CIRCULACIÓN DE TOKENS:' as info;
SELECT * FROM get_token_circulation();

SELECT 'OPERACIONES ATÓMICAS REGISTRADAS (últimas 10):' as info;
SELECT 
    operation_type,
    from_account_type,
    to_account_type,
    atomic_to_leap(amount) as amount_leap,
    reference_type,
    description,
    status,
    created_at
FROM atomic_token_operations
ORDER BY created_at DESC
LIMIT 10;

COMMIT;

SELECT 'CONTABILIDAD DEL TREASURY CORREGIDA EXITOSAMENTE' as resultado;
