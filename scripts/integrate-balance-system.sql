-- 💰 INTEGRACIÓN COMPLETA DEL SISTEMA DE BALANCES
-- Integrar token_transactions existente + nuevo sistema + sincronización

-- 1. Crear tabla de balances (si no existe)
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

-- 2. Migrar datos de users.token_balance Y token_transactions a user_balances
DO $$
DECLARE
  user_record RECORD;
  balance_id UUID;
  total_earned_calc DECIMAL(15,2);
  total_spent_calc DECIMAL(15,2);
BEGIN
  RAISE NOTICE '🔄 Integrando sistema de balances...';
  
  FOR user_record IN 
    SELECT id, token_balance, email 
    FROM users 
  LOOP
    -- Calcular totales desde token_transactions existente
    SELECT 
      COALESCE(SUM(CASE WHEN amount > 0 THEN amount ELSE 0 END), 0),
      COALESCE(SUM(CASE WHEN amount < 0 THEN ABS(amount) ELSE 0 END), 0)
    INTO total_earned_calc, total_spent_calc
    FROM token_transactions 
    WHERE user_id = user_record.id;
    
    -- Si no hay transacciones pero sí balance, usar el balance como earned inicial
    IF total_earned_calc = 0 AND user_record.token_balance > 0 THEN
      total_earned_calc := user_record.token_balance;
    END IF;
    
    -- Crear/actualizar registro de balance
    INSERT INTO user_balances (
      user_id, 
      balance_type, 
      available_balance, 
      total_earned,
      total_spent,
      last_transaction_at
    ) VALUES (
      user_record.id,
      'tokens',
      user_record.token_balance,
      total_earned_calc,
      total_spent_calc,
      COALESCE((SELECT MAX(created_at) FROM token_transactions WHERE user_id = user_record.id), NOW())
    ) 
    ON CONFLICT (user_id, balance_type) 
    DO UPDATE SET 
      available_balance = user_record.token_balance,
      total_earned = total_earned_calc,
      total_spent = total_spent_calc,
      updated_at = NOW();
    
    RAISE NOTICE '✅ Integrado balance para %: % tokens (earned: %, spent: %)', 
      user_record.email, user_record.token_balance, total_earned_calc, total_spent_calc;
  END LOOP;
  
  RAISE NOTICE '🎉 Integración completada!';
END $$;

-- 3. Función para sincronizar user_balances con users.token_balance
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

-- 4. Trigger para sincronización automática
DROP TRIGGER IF EXISTS sync_token_balance_trigger ON user_balances;
CREATE TRIGGER sync_token_balance_trigger
  AFTER INSERT OR UPDATE OF available_balance ON user_balances
  FOR EACH ROW
  EXECUTE FUNCTION sync_user_token_balance();

-- 5. Función para transferir tokens entre usuarios
CREATE OR REPLACE FUNCTION transfer_tokens(
  p_from_user_id UUID,
  p_to_user_id UUID,
  p_amount DECIMAL(15,2),
  p_description TEXT DEFAULT 'Transferencia entre usuarios'
) RETURNS JSON AS $$
DECLARE
  from_balance DECIMAL(15,2);
  to_balance DECIMAL(15,2);
  from_user_email TEXT;
  to_user_email TEXT;
  transaction_id UUID;
BEGIN
  -- Validar que no sea el mismo usuario
  IF p_from_user_id = p_to_user_id THEN
    RETURN json_build_object('success', false, 'error', 'No puedes transferir tokens a ti mismo');
  END IF;
  
  -- Validar cantidad
  IF p_amount <= 0 THEN
    RETURN json_build_object('success', false, 'error', 'La cantidad debe ser mayor a 0');
  END IF;
  
  -- Obtener emails para logs
  SELECT email INTO from_user_email FROM users WHERE id = p_from_user_id;
  SELECT email INTO to_user_email FROM users WHERE id = p_to_user_id;
  
  IF NOT FOUND THEN
    RETURN json_build_object('success', false, 'error', 'Usuario destinatario no encontrado');
  END IF;
  
  -- Obtener balance del remitente
  SELECT available_balance INTO from_balance
  FROM user_balances
  WHERE user_id = p_from_user_id AND balance_type = 'tokens';
  
  IF from_balance IS NULL THEN
    from_balance := 0;
  END IF;
  
  -- Verificar fondos suficientes
  IF from_balance < p_amount THEN
    RETURN json_build_object(
      'success', false, 
      'error', 'Fondos insuficientes. Balance disponible: ' || from_balance::TEXT
    );
  END IF;
  
  -- Crear/obtener balance del destinatario
  INSERT INTO user_balances (user_id, balance_type, available_balance)
  VALUES (p_to_user_id, 'tokens', 0.00)
  ON CONFLICT (user_id, balance_type) DO NOTHING;
  
  SELECT available_balance INTO to_balance
  FROM user_balances
  WHERE user_id = p_to_user_id AND balance_type = 'tokens';
  
  -- Realizar transferencia
  BEGIN
    -- Debitar del remitente
    UPDATE user_balances SET
      available_balance = available_balance - p_amount,
      total_spent = total_spent + p_amount,
      last_transaction_at = NOW(),
      updated_at = NOW()
    WHERE user_id = p_from_user_id AND balance_type = 'tokens';
    
    -- Acreditar al destinatario
    UPDATE user_balances SET
      available_balance = available_balance + p_amount,
      total_earned = total_earned + p_amount,
      last_transaction_at = NOW(),
      updated_at = NOW()
    WHERE user_id = p_to_user_id AND balance_type = 'tokens';
    
    -- Registrar en token_transactions (tabla existente)
    -- Transacción de débito (remitente)
    INSERT INTO token_transactions (
      user_id, amount, type, description, created_at
    ) VALUES (
      p_from_user_id, 
      -p_amount, 
      'spent', 
      'Enviado a ' || to_user_email || ': ' || p_description,
      NOW()
    );
    
    -- Transacción de crédito (destinatario)
    INSERT INTO token_transactions (
      user_id, amount, type, description, created_at
    ) VALUES (
      p_to_user_id, 
      p_amount, 
      'earned', 
      'Recibido de ' || from_user_email || ': ' || p_description,
      NOW()
    ) RETURNING id INTO transaction_id;
    
    RETURN json_build_object(
      'success', true,
      'transaction_id', transaction_id,
      'from_user', from_user_email,
      'to_user', to_user_email,
      'amount', p_amount,
      'new_balance', from_balance - p_amount
    );
    
  EXCEPTION WHEN OTHERS THEN
    RETURN json_build_object('success', false, 'error', 'Error en la transferencia: ' || SQLERRM);
  END;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 6. Función para obtener balance actual
CREATE OR REPLACE FUNCTION get_user_balance(p_user_id UUID)
RETURNS DECIMAL(15,2) AS $$
DECLARE
  current_balance DECIMAL(15,2);
BEGIN
  SELECT available_balance INTO current_balance
  FROM user_balances
  WHERE user_id = p_user_id AND balance_type = 'tokens';
  
  RETURN COALESCE(current_balance, 0.00);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 7. Crear políticas RLS
ALTER TABLE user_balances ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Users can view own balances" ON user_balances;
CREATE POLICY "Users can view own balances" ON user_balances 
  FOR SELECT USING (auth.uid() = user_id);

-- 8. Verificar integración
DO $$
DECLARE
  total_users INTEGER;
  total_balances INTEGER;
  total_token_transactions INTEGER;
BEGIN
  SELECT COUNT(*) INTO total_users FROM users;
  SELECT COUNT(*) INTO total_balances FROM user_balances;
  SELECT COUNT(*) INTO total_token_transactions FROM token_transactions;
  
  RAISE NOTICE '📊 RESUMEN DE INTEGRACIÓN:';
  RAISE NOTICE '👥 Total usuarios: %', total_users;
  RAISE NOTICE '💰 Balances integrados: %', total_balances;
  RAISE NOTICE '📝 Token transactions existentes: %', total_token_transactions;
  RAISE NOTICE '✅ Sistema integrado correctamente!';
  RAISE NOTICE '';
  RAISE NOTICE '🔧 Funciones disponibles:';
  RAISE NOTICE '   - get_user_balance(user_id)';
  RAISE NOTICE '   - transfer_tokens(from_user, to_user, amount, description)';
END $$;
