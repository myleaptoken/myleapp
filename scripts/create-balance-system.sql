-- 💰 SISTEMA DE BALANCES INDEPENDIENTE
-- Crear tabla de balances con estructura correcta

-- 1. Crear tabla de balances
CREATE TABLE IF NOT EXISTS public.user_balances (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id UUID REFERENCES users(id) ON DELETE CASCADE,
  balance_type TEXT DEFAULT 'tokens' CHECK (balance_type IN ('tokens', 'points', 'credits')),
  available_balance DECIMAL(15,2) DEFAULT 0.00,
  pending_balance DECIMAL(15,2) DEFAULT 0.00,
  total_earned DECIMAL(15,2) DEFAULT 0.00,
  total_spent DECIMAL(15,2) DEFAULT 0.00,
  last_transaction_at TIMESTAMP WITH TIME ZONE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  UNIQUE(user_id, balance_type)
);

-- 2. Crear tabla de transacciones de balance
CREATE TABLE IF NOT EXISTS public.balance_transactions (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  user_balance_id UUID REFERENCES user_balances(id) ON DELETE CASCADE,
  user_id UUID REFERENCES users(id) ON DELETE CASCADE,
  transaction_type TEXT CHECK (transaction_type IN ('credit', 'debit', 'hold', 'release')),
  amount DECIMAL(15,2) NOT NULL,
  description TEXT NOT NULL,
  reference_type TEXT, -- 'event', 'course', 'purchase', 'bonus', etc.
  reference_id UUID, -- ID del evento, curso, etc.
  status TEXT DEFAULT 'completed' CHECK (status IN ('pending', 'completed', 'failed', 'cancelled')),
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 3. Migrar datos existentes de users.token_balance a user_balances
DO $$
DECLARE
  user_record RECORD;
  balance_id UUID;
BEGIN
  RAISE NOTICE '🔄 Migrando balances existentes...';
  
  FOR user_record IN 
    SELECT id, token_balance, email 
    FROM users 
    WHERE token_balance > 0
  LOOP
    -- Crear registro de balance para cada usuario
    INSERT INTO user_balances (
      user_id, 
      balance_type, 
      available_balance, 
      total_earned,
      last_transaction_at
    ) VALUES (
      user_record.id,
      'tokens',
      user_record.token_balance,
      user_record.token_balance,
      NOW()
    ) 
    ON CONFLICT (user_id, balance_type) 
    DO UPDATE SET 
      available_balance = user_record.token_balance,
      total_earned = user_record.token_balance,
      updated_at = NOW()
    RETURNING id INTO balance_id;
    
    -- Crear transacción inicial
    INSERT INTO balance_transactions (
      user_balance_id,
      user_id,
      transaction_type,
      amount,
      description,
      reference_type,
      status
    ) VALUES (
      balance_id,
      user_record.id,
      'credit',
      user_record.token_balance,
      'Balance inicial migrado desde users.token_balance',
      'migration',
      'completed'
    ) ON CONFLICT DO NOTHING;
    
    RAISE NOTICE '✅ Migrado balance para usuario %: % tokens', user_record.email, user_record.token_balance;
  END LOOP;
  
  RAISE NOTICE '🎉 Migración de balances completada!';
END $$;

-- 4. Crear función para obtener balance actual
CREATE OR REPLACE FUNCTION get_user_balance(p_user_id UUID, p_balance_type TEXT DEFAULT 'tokens')
RETURNS DECIMAL(15,2) AS $$
DECLARE
  current_balance DECIMAL(15,2);
BEGIN
  SELECT available_balance INTO current_balance
  FROM user_balances
  WHERE user_id = p_user_id AND balance_type = p_balance_type;
  
  RETURN COALESCE(current_balance, 0.00);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 5. Crear función para actualizar balance en users (trigger)
CREATE OR REPLACE FUNCTION sync_user_token_balance()
RETURNS TRIGGER AS $$
BEGIN
  -- Actualizar token_balance en users cuando cambie user_balances
  UPDATE users 
  SET token_balance = NEW.available_balance::INTEGER,
      updated_at = NOW()
  WHERE id = NEW.user_id;
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 6. Crear trigger para sincronizar balances
DROP TRIGGER IF EXISTS sync_token_balance_trigger ON user_balances;
CREATE TRIGGER sync_token_balance_trigger
  AFTER INSERT OR UPDATE OF available_balance ON user_balances
  FOR EACH ROW
  EXECUTE FUNCTION sync_user_token_balance();

-- 7. Crear función para procesar transacciones
CREATE OR REPLACE FUNCTION process_balance_transaction(
  p_user_id UUID,
  p_transaction_type TEXT,
  p_amount DECIMAL(15,2),
  p_description TEXT,
  p_reference_type TEXT DEFAULT NULL,
  p_reference_id UUID DEFAULT NULL
) RETURNS UUID AS $$
DECLARE
  balance_record RECORD;
  transaction_id UUID;
  new_balance DECIMAL(15,2);
BEGIN
  -- Obtener o crear balance del usuario
  SELECT * INTO balance_record
  FROM user_balances
  WHERE user_id = p_user_id AND balance_type = 'tokens';
  
  IF NOT FOUND THEN
    INSERT INTO user_balances (user_id, balance_type, available_balance)
    VALUES (p_user_id, 'tokens', 0.00)
    RETURNING * INTO balance_record;
  END IF;
  
  -- Calcular nuevo balance
  IF p_transaction_type = 'credit' THEN
    new_balance := balance_record.available_balance + p_amount;
  ELSIF p_transaction_type = 'debit' THEN
    new_balance := balance_record.available_balance - p_amount;
    -- Verificar fondos suficientes
    IF new_balance < 0 THEN
      RAISE EXCEPTION 'Fondos insuficientes. Balance actual: %, Monto requerido: %', 
        balance_record.available_balance, p_amount;
    END IF;
  ELSE
    RAISE EXCEPTION 'Tipo de transacción no válido: %', p_transaction_type;
  END IF;
  
  -- Crear transacción
  INSERT INTO balance_transactions (
    user_balance_id,
    user_id,
    transaction_type,
    amount,
    description,
    reference_type,
    reference_id,
    status
  ) VALUES (
    balance_record.id,
    p_user_id,
    p_transaction_type,
    p_amount,
    p_description,
    p_reference_type,
    p_reference_id,
    'completed'
  ) RETURNING id INTO transaction_id;
  
  -- Actualizar balance
  UPDATE user_balances SET
    available_balance = new_balance,
    total_earned = CASE 
      WHEN p_transaction_type = 'credit' THEN total_earned + p_amount
      ELSE total_earned
    END,
    total_spent = CASE 
      WHEN p_transaction_type = 'debit' THEN total_spent + p_amount
      ELSE total_spent
    END,
    last_transaction_at = NOW(),
    updated_at = NOW()
  WHERE id = balance_record.id;
  
  RETURN transaction_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 8. Crear triggers para updated_at
CREATE TRIGGER update_user_balances_updated_at 
  BEFORE UPDATE ON user_balances 
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_balance_transactions_updated_at 
  BEFORE UPDATE ON balance_transactions 
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- 9. Crear políticas RLS
ALTER TABLE user_balances ENABLE ROW LEVEL SECURITY;
ALTER TABLE balance_transactions ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view own balances" ON user_balances FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "Users can view own transactions" ON balance_transactions FOR SELECT USING (auth.uid() = user_id);

-- 10. Verificar migración
DO $$
DECLARE
  total_users INTEGER;
  total_balances INTEGER;
  total_transactions INTEGER;
BEGIN
  SELECT COUNT(*) INTO total_users FROM users WHERE token_balance > 0;
  SELECT COUNT(*) INTO total_balances FROM user_balances;
  SELECT COUNT(*) INTO total_transactions FROM balance_transactions;
  
  RAISE NOTICE '📊 RESUMEN DE MIGRACIÓN:';
  RAISE NOTICE '👥 Usuarios con balance: %', total_users;
  RAISE NOTICE '💰 Registros de balance creados: %', total_balances;
  RAISE NOTICE '📝 Transacciones creadas: %', total_transactions;
  RAISE NOTICE '✅ Sistema de balances configurado correctamente!';
END $$;

-- 11. Ejemplo de uso de las funciones
-- SELECT get_user_balance('user-uuid-here', 'tokens');
-- SELECT process_balance_transaction('user-uuid-here', 'credit', 500.00, 'Bonus por completar evento', 'bonus', null);
-- SELECT process_balance_transaction('user-uuid-here', 'debit', 250.00, 'Pago por evento', 'event', 'event-uuid-here');
