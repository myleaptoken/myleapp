-- =====================================================
-- DISCOVER VALID TYPES - SIMPLE VERSION
-- =====================================================
-- Tests common values one by one
-- =====================================================

-- Show the constraint definition first
SELECT 'TOKEN_TRANSACTIONS TYPE CONSTRAINT:' as info;
SELECT 
    conname,
    pg_get_constraintdef(oid) as definition
FROM pg_constraint 
WHERE conrelid = 'token_transactions'::regclass 
AND contype = 'c'
AND conname LIKE '%type%';

-- Test individual values by creating a temporary function
CREATE OR REPLACE FUNCTION test_token_transaction_type(test_type TEXT)
RETURNS BOOLEAN AS $$
DECLARE
    test_user_id UUID;
    result BOOLEAN := FALSE;
BEGIN
    -- Get a test user
    SELECT id INTO test_user_id FROM users LIMIT 1;
    
    IF test_user_id IS NULL THEN
        RETURN FALSE;
    END IF;
    
    BEGIN
        -- Try to insert with this type
        INSERT INTO token_transactions (
            id, user_id, amount, type, description, created_at
        ) VALUES (
            gen_random_uuid(), 
            test_user_id, 
            1, 
            test_type, 
            'Test transaction', 
            NOW()
        );
        
        -- If we get here, it worked
        result := TRUE;
        
        -- Clean up - delete the test record
        DELETE FROM token_transactions 
        WHERE user_id = test_user_id 
        AND amount = 1 
        AND description = 'Test transaction'
        AND type = test_type;
        
    EXCEPTION WHEN OTHERS THEN
        result := FALSE;
    END;
    
    RETURN result;
END;
$$ LANGUAGE plpgsql;

-- Test common values
SELECT 'TESTING COMMON TYPE VALUES:' as info;

SELECT 
    'transfer' as test_value,
    test_token_transaction_type('transfer') as is_valid
UNION ALL
SELECT 
    'payment' as test_value,
    test_token_transaction_type('payment') as is_valid
UNION ALL
SELECT 
    'bonus' as test_value,
    test_token_transaction_type('bonus') as is_valid
UNION ALL
SELECT 
    'reward' as test_value,
    test_token_transaction_type('reward') as is_valid
UNION ALL
SELECT 
    'purchase' as test_value,
    test_token_transaction_type('purchase') as is_valid
UNION ALL
SELECT 
    'send' as test_value,
    test_token_transaction_type('send') as is_valid
UNION ALL
SELECT 
    'receive' as test_value,
    test_token_transaction_type('receive') as is_valid
UNION ALL
SELECT 
    'credit' as test_value,
    test_token_transaction_type('credit') as is_valid
UNION ALL
SELECT 
    'debit' as test_value,
    test_token_transaction_type('debit') as is_valid;

-- Clean up
DROP FUNCTION test_token_transaction_type(TEXT);
