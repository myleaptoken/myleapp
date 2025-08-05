-- Script para resetear saldos de usuarios y ajustar bonus de bienvenida
-- Paso 1: Limpiar datos existentes

-- Limpiar transacciones existentes
DELETE FROM token_transactions;
DELETE FROM atomic_token_operations;

-- Limpiar balances de usuarios
DELETE FROM user_balances;

-- Resetear balance en tabla users (por compatibilidad)
UPDATE users SET token_balance = 0 WHERE token_balance IS NOT NULL;

-- Paso 2: Crear función para dar bonus de bienvenida (1230 tokens)
CREATE OR REPLACE FUNCTION give_welcome_bonus(p_user_id UUID)
RETURNS UUID AS $$
DECLARE
  v_rewards_account UUID;
  v_operation_id UUID;
BEGIN
  -- Obtener cuenta de recompensas
  SELECT id INTO v_rewards_account 
  FROM treasury_accounts 
  WHERE account_type = 'rewards';

  -- Si no existe la cuenta de rewards, crearla
  IF v_rewards_account IS NULL THEN
    INSERT INTO treasury_accounts (account_type, name, description, balance)
    VALUES ('rewards', 'Rewards Pool', 'Pool de recompensas para usuarios', leap_to_atomic(100000))
    RETURNING id INTO v_rewards_account;
  END IF;

  -- Verificar si el usuario ya tiene bonus de bienvenida
  IF EXISTS (
    SELECT 1 FROM token_transactions 
    WHERE receiver_id = p_user_id 
    AND transaction_type = 'system_credit' 
    AND description LIKE '%bienvenida%'
  ) THEN
    RAISE NOTICE 'Usuario % ya tiene bonus de bienvenida', p_user_id;
    RETURN NULL;
  END IF;

  -- Dar bonus de bienvenida usando el sistema atómico
  SELECT process_atomic_operation(
    'transfer',
    'treasury', v_rewards_account,
    'user', p_user_id,
    1230, -- Nuevo monto de bienvenida
    'welcome_bonus',
    NULL,
    'Bonus de bienvenida - 1230 LEAP tokens'
  ) INTO v_operation_id;

  -- También actualizar la tabla users para compatibilidad
  UPDATE users 
  SET token_balance = 1230, updated_at = NOW()
  WHERE id = p_user_id;

  RAISE NOTICE 'Bonus de bienvenida de 1230 tokens otorgado a usuario %', p_user_id;
  RETURN v_operation_id;
END;
$$ LANGUAGE plpgsql;

-- Paso 3: Dar bonus de bienvenida a todos los usuarios existentes
DO $$
DECLARE
  user_record RECORD;
  operation_result UUID;
BEGIN
  -- Asegurar que la cuenta de rewards tenga suficiente balance
  UPDATE treasury_accounts 
  SET balance = leap_to_atomic(1000000) -- 1M tokens para rewards
  WHERE account_type = 'rewards';

  -- Dar bonus a todos los usuarios
  FOR user_record IN 
    SELECT id, email, full_name 
    FROM users 
    WHERE id IS NOT NULL
  LOOP
    BEGIN
      SELECT give_welcome_bonus(user_record.id) INTO operation_result;
      
      IF operation_result IS NOT NULL THEN
        RAISE NOTICE 'Bonus otorgado a: % (%) - Operation: %', 
          COALESCE(user_record.full_name, user_record.email), 
          user_record.id, 
          operation_result;
      END IF;
      
    EXCEPTION WHEN OTHERS THEN
      RAISE NOTICE 'Error otorgando bonus a %: %', user_record.email, SQLERRM;
    END;
  END LOOP;
  
  RAISE NOTICE 'Proceso de bonus de bienvenida completado';
END;
$$;

-- Paso 4: Crear función para verificar balances
CREATE OR REPLACE FUNCTION verify_user_balances()
RETURNS TABLE(
  user_email TEXT,
  user_name TEXT,
  balance_users_table DECIMAL,
  balance_atomic_system DECIMAL,
  total_earned DECIMAL,
  transaction_count BIGINT
) AS $$
BEGIN
  RETURN QUERY
  SELECT 
    u.email,
    COALESCE(u.full_name, 'Sin nombre') as user_name,
    COALESCE(u.token_balance, 0) as balance_users_table,
    COALESCE(ub.available_balance, 0) as balance_atomic_system,
    COALESCE(ub.total_earned, 0) as total_earned,
    COALESCE(tt.transaction_count, 0) as transaction_count
  FROM users u
  LEFT JOIN user_balances ub ON u.id = ub.user_id AND ub.balance_type = 'tokens'
  LEFT JOIN (
    SELECT 
      COALESCE(sender_id, receiver_id) as user_id,
      COUNT(*) as transaction_count
    FROM token_transactions 
    GROUP BY COALESCE(sender_id, receiver_id)
  ) tt ON u.id = tt.user_id
  ORDER BY u.email;
END;
$$ LANGUAGE plpgsql;

-- Paso 5: Verificar resultados
SELECT 'Verificación de balances después del reset:' as status;
SELECT * FROM verify_user_balances();

-- Mostrar resumen del treasury
SELECT 
  account_type,
  name,
  atomic_to_leap(balance) as balance_leap,
  balance as balance_atomic,
  is_active
FROM treasury_accounts
ORDER BY account_type;

-- Mostrar últimas transacciones
SELECT 
  tt.created_at,
  u1.email as sender_email,
  u2.email as receiver_email,
  tt.amount,
  tt.transaction_type,
  tt.description
FROM token_transactions tt
LEFT JOIN users u1 ON tt.sender_id = u1.id
LEFT JOIN users u2 ON tt.receiver_id = u2.id
ORDER BY tt.created_at DESC
LIMIT 10;
