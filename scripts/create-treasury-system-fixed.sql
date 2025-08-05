-- Crear sistema de Treasury para tokens LEAP (CORREGIDO)
-- Paso 1: Crear tablas del Treasury

-- Treasury Accounts (Cuentas del tesoro)
CREATE TABLE IF NOT EXISTS public.treasury_accounts (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  account_type TEXT NOT NULL CHECK (account_type IN ('issuer', 'platform', 'reserve', 'rewards')),
  name TEXT NOT NULL,
  description TEXT,
  balance BIGINT DEFAULT 0, -- Balance en unidades atómicas (1 LEAP = 1000000 units)
  is_active BOOLEAN DEFAULT true,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  UNIQUE(account_type)
);

-- Atomic Token Operations (Operaciones atómicas)
CREATE TABLE IF NOT EXISTS public.atomic_token_operations (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  operation_type TEXT NOT NULL CHECK (operation_type IN ('mint', 'burn', 'transfer', 'lock', 'unlock')),
  from_account_type TEXT, -- 'user', 'treasury'
  from_account_id UUID,
  to_account_type TEXT, -- 'user', 'treasury'  
  to_account_id UUID,
  amount BIGINT NOT NULL, -- Cantidad en unidades atómicas
  reference_type TEXT, -- 'course_purchase', 'event_registration', 'user_transfer', etc.
  reference_id UUID,
  description TEXT NOT NULL,
  status TEXT DEFAULT 'pending' CHECK (status IN ('pending', 'completed', 'failed', 'cancelled')),
  processed_at TIMESTAMP WITH TIME ZONE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Insertar cuentas del Treasury (solo si no existen)
INSERT INTO treasury_accounts (account_type, name, description, balance) 
SELECT 'issuer', 'LEAP Token Issuer', 'Cuenta emisora principal de tokens LEAP', 1000000000000
WHERE NOT EXISTS (SELECT 1 FROM treasury_accounts WHERE account_type = 'issuer');

INSERT INTO treasury_accounts (account_type, name, description, balance) 
SELECT 'platform', 'MyLeap Platform', 'Cuenta de la plataforma para operaciones', 0
WHERE NOT EXISTS (SELECT 1 FROM treasury_accounts WHERE account_type = 'platform');

INSERT INTO treasury_accounts (account_type, name, description, balance) 
SELECT 'reserve', 'Reserve Fund', 'Fondo de reserva para estabilidad', 0
WHERE NOT EXISTS (SELECT 1 FROM treasury_accounts WHERE account_type = 'reserve');

INSERT INTO treasury_accounts (account_type, name, description, balance) 
SELECT 'rewards', 'Rewards Pool', 'Pool de recompensas para usuarios', 0
WHERE NOT EXISTS (SELECT 1 FROM treasury_accounts WHERE account_type = 'rewards');

-- Función para convertir LEAP a unidades atómicas
CREATE OR REPLACE FUNCTION leap_to_atomic(leap_amount DECIMAL)
RETURNS BIGINT AS $$
BEGIN
  RETURN (leap_amount * 1000000)::BIGINT;
END;
$$ LANGUAGE plpgsql;

-- Función para convertir unidades atómicas a LEAP
CREATE OR REPLACE FUNCTION atomic_to_leap(atomic_amount BIGINT)
RETURNS DECIMAL AS $$
BEGIN
  RETURN atomic_amount::DECIMAL / 1000000;
END;
$$ LANGUAGE plpgsql;

-- Función para procesar operación atómica (CORREGIDA)
CREATE OR REPLACE FUNCTION process_atomic_operation(
  p_operation_type TEXT,
  p_from_account_type TEXT,
  p_from_account_id UUID,
  p_to_account_type TEXT,
  p_to_account_id UUID,
  p_amount_leap DECIMAL,
  p_reference_type TEXT DEFAULT NULL,
  p_reference_id UUID DEFAULT NULL,
  p_description TEXT DEFAULT ''
)
RETURNS UUID AS $$
DECLARE
  v_operation_id UUID;
  v_atomic_amount BIGINT;
  v_from_balance BIGINT;
  v_to_balance BIGINT;
BEGIN
  -- Convertir a unidades atómicas
  v_atomic_amount := leap_to_atomic(p_amount_leap);
  
  -- Crear registro de operación
  INSERT INTO atomic_token_operations (
    operation_type, from_account_type, from_account_id, 
    to_account_type, to_account_id, amount, 
    reference_type, reference_id, description
  ) VALUES (
    p_operation_type, p_from_account_type, p_from_account_id,
    p_to_account_type, p_to_account_id, v_atomic_amount,
    p_reference_type, p_reference_id, p_description
  ) RETURNING id INTO v_operation_id;

  -- Procesar según tipo de operación
  IF p_operation_type = 'transfer' THEN
    -- Verificar balance origen
    IF p_from_account_type = 'user' THEN
      SELECT leap_to_atomic(COALESCE(available_balance, 0)) INTO v_from_balance
      FROM user_balances 
      WHERE user_id = p_from_account_id AND balance_type = 'tokens';
      
      IF v_from_balance < v_atomic_amount THEN
        UPDATE atomic_token_operations 
        SET status = 'failed', processed_at = NOW()
        WHERE id = v_operation_id;
        RAISE EXCEPTION 'Insufficient balance';
      END IF;
    ELSIF p_from_account_type = 'treasury' THEN
      SELECT balance INTO v_from_balance
      FROM treasury_accounts 
      WHERE id = p_from_account_id;
      
      IF v_from_balance < v_atomic_amount THEN
        UPDATE atomic_token_operations 
        SET status = 'failed', processed_at = NOW()
        WHERE id = v_operation_id;
        RAISE EXCEPTION 'Insufficient treasury balance';
      END IF;
    END IF;

    -- Ejecutar transferencia
    -- Debitar origen
    IF p_from_account_type = 'user' THEN
      UPDATE user_balances 
      SET available_balance = available_balance - atomic_to_leap(v_atomic_amount),
          updated_at = NOW()
      WHERE user_id = p_from_account_id AND balance_type = 'tokens';
    ELSIF p_from_account_type = 'treasury' THEN
      UPDATE treasury_accounts 
      SET balance = balance - v_atomic_amount,
          updated_at = NOW()
      WHERE id = p_from_account_id;
    END IF;

    -- Acreditar destino
    IF p_to_account_type = 'user' THEN
      INSERT INTO user_balances (user_id, balance_type, available_balance, total_earned)
      VALUES (p_to_account_id, 'tokens', atomic_to_leap(v_atomic_amount), atomic_to_leap(v_atomic_amount))
      ON CONFLICT (user_id, balance_type) 
      DO UPDATE SET 
        available_balance = user_balances.available_balance + atomic_to_leap(v_atomic_amount),
        total_earned = user_balances.total_earned + atomic_to_leap(v_atomic_amount),
        updated_at = NOW();
    ELSIF p_to_account_type = 'treasury' THEN
      UPDATE treasury_accounts 
      SET balance = balance + v_atomic_amount,
          updated_at = NOW()
      WHERE id = p_to_account_id;
    END IF;

    -- Registrar transacción
    INSERT INTO token_transactions (
      sender_id, receiver_id, amount, transaction_type, 
      description, reference_id, reference_type
    ) VALUES (
      CASE WHEN p_from_account_type = 'user' THEN p_from_account_id ELSE NULL END,
      CASE WHEN p_to_account_type = 'user' THEN p_to_account_id ELSE NULL END,
      atomic_to_leap(v_atomic_amount),
      CASE 
        WHEN p_from_account_type = 'treasury' THEN 'system_credit'
        WHEN p_to_account_type = 'treasury' THEN 'system_debit'
        ELSE 'transfer'
      END,
      p_description,
      p_reference_id,
      p_reference_type
    );
  END IF;

  -- Marcar operación como completada
  UPDATE atomic_token_operations 
  SET status = 'completed', processed_at = NOW()
  WHERE id = v_operation_id;

  RETURN v_operation_id;
END;
$$ LANGUAGE plpgsql;

-- Función para transferir tokens entre usuarios (CORREGIDA)
CREATE OR REPLACE FUNCTION transfer_tokens_atomic(
  sender_id UUID,
  receiver_id UUID,
  amount DECIMAL,
  description TEXT DEFAULT ''
)
RETURNS UUID AS $$
BEGIN
  RETURN process_atomic_operation(
    'transfer',
    'user', sender_id,
    'user', receiver_id,
    amount,
    'user_transfer',
    NULL,
    description
  );
END;
$$ LANGUAGE plpgsql;

-- Función para comprar curso (CORREGIDA)
CREATE OR REPLACE FUNCTION purchase_course_atomic(
  user_id UUID,
  course_id UUID,
  course_price DECIMAL
)
RETURNS UUID AS $$
DECLARE
  v_platform_account UUID;
BEGIN
  -- Obtener cuenta de la plataforma
  SELECT id INTO v_platform_account 
  FROM treasury_accounts 
  WHERE account_type = 'platform';

  RETURN process_atomic_operation(
    'transfer',
    'user', user_id,
    'treasury', v_platform_account,
    course_price,
    'course_purchase',
    course_id,
    'Compra de curso'
  );
END;
$$ LANGUAGE plpgsql;

-- Función para registrar evento (CORREGIDA)
CREATE OR REPLACE FUNCTION register_event_atomic(
  user_id UUID,
  event_id UUID,
  event_price DECIMAL
)
RETURNS UUID AS $$
DECLARE
  v_platform_account UUID;
BEGIN
  -- Obtener cuenta de la plataforma
  SELECT id INTO v_platform_account 
  FROM treasury_accounts 
  WHERE account_type = 'platform';

  RETURN process_atomic_operation(
    'transfer',
    'user', user_id,
    'treasury', v_platform_account,
    event_price,
    'event_registration',
    event_id,
    'Registro a evento'
  );
END;
$$ LANGUAGE plpgsql;

-- Función para dar recompensas (CORREGIDA)
CREATE OR REPLACE FUNCTION reward_user_atomic(
  user_id UUID,
  amount DECIMAL,
  reason TEXT DEFAULT ''
)
RETURNS UUID AS $$
DECLARE
  v_rewards_account UUID;
BEGIN
  -- Obtener cuenta de recompensas
  SELECT id INTO v_rewards_account 
  FROM treasury_accounts 
  WHERE account_type = 'rewards';

  RETURN process_atomic_operation(
    'transfer',
    'treasury', v_rewards_account,
    'user', user_id,
    amount,
    'reward',
    NULL,
    reason
  );
END;
$$ LANGUAGE plpgsql;

-- Función para obtener balance de usuario (CORREGIDA)
CREATE OR REPLACE FUNCTION get_user_balance_atomic(p_user_id UUID)
RETURNS TABLE(
  available_balance DECIMAL,
  total_earned DECIMAL,
  total_spent DECIMAL,
  pending_balance DECIMAL
) AS $$
BEGIN
  RETURN QUERY
  SELECT 
    COALESCE(ub.available_balance, 0) as available_balance,
    COALESCE(ub.total_earned, 0) as total_earned,
    COALESCE(ub.total_spent, 0) as total_spent,
    COALESCE(ub.pending_balance, 0) as pending_balance
  FROM user_balances ub
  WHERE ub.user_id = p_user_id AND ub.balance_type = 'tokens'
  UNION ALL
  SELECT 0::DECIMAL, 0::DECIMAL, 0::DECIMAL, 0::DECIMAL
  WHERE NOT EXISTS (
    SELECT 1 FROM user_balances 
    WHERE user_id = p_user_id AND balance_type = 'tokens'
  )
  LIMIT 1;
END;
$$ LANGUAGE plpgsql;

-- Crear índices para performance
CREATE INDEX IF NOT EXISTS idx_atomic_operations_status ON atomic_token_operations(status);
CREATE INDEX IF NOT EXISTS idx_atomic_operations_type ON atomic_token_operations(operation_type);
CREATE INDEX IF NOT EXISTS idx_atomic_operations_from ON atomic_token_operations(from_account_type, from_account_id);
CREATE INDEX IF NOT EXISTS idx_atomic_operations_to ON atomic_token_operations(to_account_type, to_account_id);
CREATE INDEX IF NOT EXISTS idx_atomic_operations_created ON atomic_token_operations(created_at);

-- Función para updated_at (si no existe)
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Triggers para updated_at
DROP TRIGGER IF EXISTS update_treasury_accounts_updated_at ON treasury_accounts;
CREATE TRIGGER update_treasury_accounts_updated_at 
  BEFORE UPDATE ON treasury_accounts 
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- RLS Policies
ALTER TABLE treasury_accounts ENABLE ROW LEVEL SECURITY;
ALTER TABLE atomic_token_operations ENABLE ROW LEVEL SECURITY;

-- Solo admins pueden ver treasury (por ahora deshabilitado para testing)
-- CREATE POLICY "Only admins can view treasury" ON treasury_accounts FOR SELECT USING (false);
-- CREATE POLICY "Only admins can view operations" ON atomic_token_operations FOR SELECT USING (false);
