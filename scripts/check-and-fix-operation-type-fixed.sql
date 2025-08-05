-- =====================================================
-- COMPLETE OPERATION TYPE CHECKER AND FIXER
-- =====================================================
-- This script will check both tables and create a working transfer function
-- =====================================================

-- First, let's check what we have
DO $$
DECLARE
    has_atomic_table boolean := false;
    has_token_table boolean := false;
    atomic_columns text[];
    token_columns text[];
    constraint_def text;
BEGIN
    -- Check if atomic_token_operations exists
    SELECT EXISTS (
        SELECT FROM information_schema.tables 
        WHERE table_name = 'atomic_token_operations' 
        AND table_schema = 'public'
    ) INTO has_atomic_table;
    
    -- Check if token_transactions exists
    SELECT EXISTS (
        SELECT FROM information_schema.tables 
        WHERE table_name = 'token_transactions' 
        AND table_schema = 'public'
    ) INTO has_token_table;
    
    RAISE NOTICE 'atomic_token_operations exists: %', has_atomic_table;
    RAISE NOTICE 'token_transactions exists: %', has_token_table;
    
    -- Get atomic_token_operations columns
    IF has_atomic_table THEN
        SELECT array_agg(column_name) INTO atomic_columns
        FROM information_schema.columns 
        WHERE table_name = 'atomic_token_operations' 
        AND table_schema = 'public';
        
        RAISE NOTICE 'atomic_token_operations columns: %', atomic_columns;
    END IF;
    
    -- Get token_transactions columns
    IF has_token_table THEN
        SELECT array_agg(column_name) INTO token_columns
        FROM information_schema.columns 
        WHERE table_name = 'token_transactions' 
        AND table_schema = 'public';
        
        RAISE NOTICE 'token_transactions columns: %', token_columns;
    END IF;
END $$;

-- Now create the transfer function that adapts to what we have
CREATE OR REPLACE FUNCTION transfer_tokens_atomic(
    sender_id UUID,
    receiver_id UUID,
    amount DECIMAL(10,2),
    description TEXT DEFAULT NULL
) RETURNS JSON AS $$
DECLARE
    sender_balance DECIMAL(10,2);
    result JSON;
    operation_id UUID;
    has_token_table boolean;
    has_transaction_type boolean;
    has_type_column boolean;
BEGIN
    -- Check current sender balance
    SELECT COALESCE(SUM(
        CASE 
            WHEN operation_type IN ('deposit', 'reward', 'bonus', 'credit', 'receive') THEN amount
            WHEN operation_type IN ('withdrawal', 'transfer', 'purchase', 'debit', 'send') THEN -amount
            ELSE 0
        END
    ), 0) INTO sender_balance
    FROM atomic_token_operations 
    WHERE user_id = sender_id;
    
    -- Check if sender has enough balance
    IF sender_balance < amount THEN
        RETURN json_build_object(
            'success', false,
            'error', 'Insufficient balance',
            'current_balance', sender_balance,
            'requested_amount', amount
        );
    END IF;
    
    -- Check if token_transactions table exists
    SELECT EXISTS (
        SELECT FROM information_schema.tables 
        WHERE table_name = 'token_transactions' 
        AND table_schema = 'public'
    ) INTO has_token_table;
    
    -- Check if token_transactions has transaction_type column
    IF has_token_table THEN
        SELECT EXISTS (
            SELECT FROM information_schema.columns 
            WHERE table_name = 'token_transactions' 
            AND column_name = 'transaction_type'
            AND table_schema = 'public'
        ) INTO has_transaction_type;
        
        SELECT EXISTS (
            SELECT FROM information_schema.columns 
            WHERE table_name = 'token_transactions' 
            AND column_name = 'type'
            AND table_schema = 'public'
        ) INTO has_type_column;
    END IF;
    
    -- Start transaction
    BEGIN
        -- Generate operation ID
        operation_id := gen_random_uuid();
        
        -- Record sender's debit in atomic_token_operations
        INSERT INTO atomic_token_operations (
            id, user_id, operation_type, amount, description, created_at
        ) VALUES (
            gen_random_uuid(), sender_id, 'transfer', amount, 
            COALESCE(description, 'Transfer to user'), NOW()
        );
        
        -- Record receiver's credit in atomic_token_operations
        INSERT INTO atomic_token_operations (
            id, user_id, operation_type, amount, description, created_at
        ) VALUES (
            gen_random_uuid(), receiver_id, 'receive', amount, 
            COALESCE(description, 'Transfer from user'), NOW()
        );
        
        -- Record in token_transactions if table exists
        IF has_token_table THEN
            IF has_transaction_type THEN
                -- Use transaction_type column
                EXECUTE format('
                    INSERT INTO token_transactions (
                        id, sender_id, receiver_id, amount, transaction_type, description, created_at
                    ) VALUES ($1, $2, $3, $4, $5, $6, $7)
                ') USING operation_id, sender_id, receiver_id, amount, 'transfer', description, NOW();
            ELSIF has_type_column THEN
                -- Use type column
                EXECUTE format('
                    INSERT INTO token_transactions (
                        id, sender_id, receiver_id, amount, type, description, created_at
                    ) VALUES ($1, $2, $3, $4, $5, $6, $7)
                ') USING operation_id, sender_id, receiver_id, amount, 'transfer', description, NOW();
            ELSE
                -- No type column, just basic fields
                EXECUTE format('
                    INSERT INTO token_transactions (
                        id, sender_id, receiver_id, amount, description, created_at
                    ) VALUES ($1, $2, $3, $4, $5, $6)
                ') USING operation_id, sender_id, receiver_id, amount, description, NOW();
            END IF;
        END IF;
        
        -- Calculate new sender balance
        SELECT COALESCE(SUM(
            CASE 
                WHEN operation_type IN ('deposit', 'reward', 'bonus', 'credit', 'receive') THEN amount
                WHEN operation_type IN ('withdrawal', 'transfer', 'purchase', 'debit', 'send') THEN -amount
                ELSE 0
            END
        ), 0) INTO sender_balance
        FROM atomic_token_operations 
        WHERE user_id = sender_id;
        
        result := json_build_object(
            'success', true,
            'operation_id', operation_id,
            'sender_id', sender_id,
            'receiver_id', receiver_id,
            'amount', amount,
            'new_sender_balance', sender_balance,
            'description', description,
            'recorded_in_token_transactions', has_token_table,
            'has_transaction_type', has_transaction_type,
            'has_type_column', has_type_column
        );
        
        RETURN result;
        
    EXCEPTION WHEN OTHERS THEN
        -- Rollback and return error
        RETURN json_build_object(
            'success', false,
            'error', SQLERRM,
            'error_code', SQLSTATE
        );
    END;
END;
$$ LANGUAGE plpgsql;

-- Test the function exists
SELECT 'FUNCTION CREATED SUCCESSFULLY' as status, 
       'transfer_tokens_atomic' as function_name;
