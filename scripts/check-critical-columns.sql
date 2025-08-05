-- Verificar columnas críticas que necesitamos
SELECT 'Verificando columnas críticas...' as info;

-- Verificar si existe sender_id en token_transactions
SELECT 
  CASE 
    WHEN EXISTS (
      SELECT 1 FROM information_schema.columns 
      WHERE table_name = 'token_transactions' 
      AND column_name = 'sender_id'
    ) THEN 'token_transactions.sender_id: EXISTE'
    ELSE 'token_transactions.sender_id: NO EXISTE'
  END as check_sender_id;

-- Verificar si existe receiver_id en token_transactions
SELECT 
  CASE 
    WHEN EXISTS (
      SELECT 1 FROM information_schema.columns 
      WHERE table_name = 'token_transactions' 
      AND column_name = 'receiver_id'
    ) THEN 'token_transactions.receiver_id: EXISTE'
    ELSE 'token_transactions.receiver_id: NO EXISTE'
  END as check_receiver_id;

-- Verificar si existe available_balance en user_balances
SELECT 
  CASE 
    WHEN EXISTS (
      SELECT 1 FROM information_schema.columns 
      WHERE table_name = 'user_balances' 
      AND column_name = 'available_balance'
    ) THEN 'user_balances.available_balance: EXISTE'
    ELSE 'user_balances.available_balance: NO EXISTE'
  END as check_available_balance;

-- Verificar si existe total_earned en user_balances
SELECT 
  CASE 
    WHEN EXISTS (
      SELECT 1 FROM information_schema.columns 
      WHERE table_name = 'user_balances' 
      AND column_name = 'total_earned'
    ) THEN 'user_balances.total_earned: EXISTE'
    ELSE 'user_balances.total_earned: NO EXISTE'
  END as check_total_earned;
