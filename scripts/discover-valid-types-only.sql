-- =====================================================
-- DISCOVER VALID TYPES - FIXED VERSION
-- =====================================================
-- Tests what values are allowed in token_transactions.type
-- =====================================================

-- Show the constraint definition first
DO $$
BEGIN
    RAISE NOTICE '==============================================';
    RAISE NOTICE 'TOKEN_TRANSACTIONS TYPE CONSTRAINT:';
    RAISE NOTICE '==============================================';
END $$;

SELECT 
    conname as constraint_name,
    pg_get_constraintdef(oid) as constraint_definition
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
        RAISE NOTICE 'NO USERS FOUND FOR TESTING';
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
        RAISE NOTICE 'VALID: %', test_type;
        
        -- Clean up - delete the test record
        DELETE FROM token_transactions 
        WHERE user_id = test_user_id 
        AND amount = 1 
        AND description = 'Test transaction'
        AND type = test_type;
        
    EXCEPTION WHEN OTHERS THEN
        result := FALSE;
        RAISE NOTICE 'INVALID: % (Error: %)', test_type, SQLERRM;
    END;
    
    RETURN result;
END;
$$ LANGUAGE plpgsql;

-- Test common values with notices
DO $$
DECLARE
    test_values TEXT[] := ARRAY[
        'transfer', 'payment', 'bonus', 'reward', 'purchase', 
        'send', 'receive', 'credit', 'debit', 'transaction',
        'deposit', 'withdrawal', 'earn', 'spend', 'refund'
    ];
    test_value TEXT;
    valid_count INTEGER := 0;
    valid_types TEXT[] := ARRAY[]::TEXT[];
BEGIN
    RAISE NOTICE '==============================================';
    RAISE NOTICE 'TESTING TYPE VALUES:';
    RAISE NOTICE '==============================================';
    
    FOREACH test_value IN ARRAY test_values
    LOOP
        IF test_token_transaction_type(test_value) THEN
            valid_count := valid_count + 1;
            valid_types := array_append(valid_types, test_value);
        END IF;
    END LOOP;
    
    RAISE NOTICE '==============================================';
    RAISE NOTICE 'SUMMARY:';
    RAISE NOTICE 'Valid types found: %', valid_count;
    RAISE NOTICE 'Valid types: %', array_to_string(valid_types, ', ');
    RAISE NOTICE '==============================================';
END $$;

-- Clean up
DROP FUNCTION test_token_transaction_type(TEXT);

-- Show existing values in the table
DO $$
BEGIN
    RAISE NOTICE '==============================================';
    RAISE NOTICE 'EXISTING VALUES IN token_transactions:';
    RAISE NOTICE '==============================================';
END $$;

SELECT 
    COALESCE(type, 'NULL') as existing_type, 
    COUNT(*) as count
FROM token_transactions 
GROUP BY type
ORDER BY count DESC;

-- Final summary
DO $$
BEGIN
    RAISE NOTICE '==============================================';
    RAISE NOTICE 'SCRIPT COMPLETED - CHECK RESULTS ABOVE';
    RAISE NOTICE '==============================================';
END $$;
