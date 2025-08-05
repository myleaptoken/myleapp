-- Reset completo de balances a 1230 tokens con transacciones del treasury
BEGIN;

-- Paso 1: Limpiar datos existentes
DELETE FROM token_transactions;
DELETE FROM user_balances;
DELETE FROM atomic_token_operations;

-- Paso 2: Actualizar tabla users
UPDATE users SET token_balance = 1230;

-- Paso 3: Crear registros en user_balances (si la tabla existe)
DO $$
BEGIN
  -- Verificar si existe la tabla user_balances
  IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'user_balances') THEN
    -- Insertar balances para todos los usuarios
    INSERT INTO user_balances (user_id, balance_type, available_balance, total_earned, total_spent, pending_balance, created_at, updated_at)
    SELECT 
      id as user_id,
      'tokens' as balance_type,
      1230 as available_balance,
      1230 as total_earned,
      0 as total_spent,
      0 as pending_balance,
      NOW() as created_at,
      NOW() as updated_at
    FROM users
    ON CONFLICT (user_id, balance_type) 
    DO UPDATE SET 
      available_balance = 1230,
      total_earned = 1230,
      total_spent = 0,
      pending_balance = 0,
      updated_at = NOW();
    
    RAISE NOTICE 'user_balances actualizada';
  ELSE
    RAISE NOTICE 'Tabla user_balances no existe, saltando...';
  END IF;
END $$;

-- Paso 4: Crear transacciones desde treasury (si la tabla token_transactions tiene las columnas correctas)
DO $$
DECLARE
  user_record RECORD;
  treasury_id UUID;
BEGIN
  -- Verificar si existen las columnas necesarias en token_transactions
  IF EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_name = 'token_transactions' AND column_name = 'sender_id'
  ) AND EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_name = 'token_transactions' AND column_name = 'receiver_id'
  ) THEN
    
    -- Obtener o crear treasury account para MyLeap Platform
    SELECT id INTO treasury_id 
    FROM treasury_accounts 
    WHERE type = 'platform' OR description ILIKE '%platform%' OR description ILIKE '%myleap%'
    LIMIT 1;
    
    IF treasury_id IS NULL THEN
      -- Crear treasury account si no existe
      INSERT INTO treasury_accounts (amount, type, description, created_at)
      VALUES (10000000, 'platform', 'MyLeap Platform Treasury', NOW())
      RETURNING id INTO treasury_id;
      
      RAISE NOTICE 'Treasury account creada: %', treasury_id;
    END IF;
    
    -- Crear transacciones de bienvenida para cada usuario
    FOR user_record IN SELECT id, email FROM users LOOP
      INSERT INTO token_transactions (
        sender_id, 
        receiver_id, 
        amount, 
        transaction_type, 
        description, 
        status,
        created_at
      ) VALUES (
        NULL, -- Treasury no tiene sender_id de usuario
        user_record.id,
        1230,
        'welcome_bonus',
        'Bonus de bienvenida - 1230 LEAP tokens',
        'completed',
        NOW()
      );
    END LOOP;
    
    RAISE NOTICE 'Transacciones de bienvenida creadas';
    
  ELSE
    RAISE NOTICE 'Columnas sender_id/receiver_id no existen en token_transactions, saltando transacciones...';
  END IF;
END $$;

-- Paso 5: Crear operaciones atómicas (si la tabla existe)
DO $$
DECLARE
  user_record RECORD;
BEGIN
  IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'atomic_token_operations') THEN
    FOR user_record IN SELECT id, email FROM users LOOP
      INSERT INTO atomic_token_operations (
        operation_type,
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
        'user',
        user_record.id,
        1230000000, -- 1230 LEAP en unidades atómicas
        'welcome_bonus',
        'Bonus de bienvenida - 1230 LEAP tokens',
        'completed',
        NOW(),
        NOW()
      );
    END LOOP;
    
    RAISE NOTICE 'Operaciones atómicas creadas';
  ELSE
    RAISE NOTICE 'Tabla atomic_token_operations no existe, saltando...';
  END IF;
END $$;

-- Paso 6: Verificar resultados
SELECT 'VERIFICACIÓN FINAL:' as info;

SELECT 'USUARIOS CON NUEVOS BALANCES:' as seccion;
SELECT 
    email,
    full_name,
    token_balance,
    created_at
FROM users
ORDER BY email;

-- Verificar user_balances si existe
DO $$
BEGIN
  IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'user_balances') THEN
    RAISE NOTICE 'BALANCES EN user_balances:';
    PERFORM * FROM user_balances;
  END IF;
END $$;

-- Verificar transacciones si existen
DO $$
BEGIN
  IF EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_name = 'token_transactions' AND column_name = 'receiver_id'
  ) THEN
    RAISE NOTICE 'TRANSACCIONES CREADAS:';
    PERFORM COUNT(*) FROM token_transactions;
  END IF;
END $$;

COMMIT;

SELECT 'RESET COMPLETO FINALIZADO: Todos los usuarios tienen 1230 tokens con transacciones del treasury' as resultado;
