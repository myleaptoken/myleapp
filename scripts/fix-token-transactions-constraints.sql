-- =====================================================
-- FIX TOKEN TRANSACTIONS CONSTRAINTS
-- =====================================================
-- Synchronizes atomic_token_operations with token_transactions
-- =====================================================

-- First, let's see what we have
DO $$
BEGIN
    RAISE NOTICE '==============================================';
    RAISE NOTICE 'CURRENT STATE ANALYSIS:';
    RAISE NOTICE '==============================================';
END $$;

-- Show current counts
SELECT 
    'atomic_token_operations' as table_name,
    COUNT(*) as total_records
FROM atomic_token_operations
UNION ALL
SELECT 
    'token_transactions' as table_name,
    COUNT(*) as total_records
FROM token_transactions;

-- Show what constraint exists on token_transactions.type
SELECT 
    'CONSTRAINT INFO' as info,
    conname as constraint_name,
    pg_get_constraintdef(oid) as definition
FROM pg_constraint 
WHERE conrelid = 'token_transactions'::regclass 
AND contype = 'c'
AND conname LIKE '%type%';

-- Try to sync missing records from atomic_token_operations to token_transactions
-- We'll use a safe approach - only sync if we can determine a valid type

DO $$
DECLARE
    atomic_record RECORD;
    valid_type TEXT := 'transfer'; -- Default
    synced_count INTEGER := 0;
BEGIN
    RAISE NOTICE '==============================================';
    RAISE NOTICE 'ATTEMPTING TO SYNC MISSING RECORDS:';
    RAISE NOTICE '==============================================';
    
    -- First, try to determine what type values work
    BEGIN
        INSERT INTO token_transactions (
            id, user_id, amount, type, description, created_at
        ) 
        SELECT 
            gen_random_uuid(),
            (SELECT id FROM users LIMIT 1),
            1,
            'transfer',
            'Test',
            NOW()
        WHERE EXISTS (SELECT 1 FROM users);
        
        DELETE FROM token_transactions WHERE description = 'Test' AND amount = 1;
        valid_type := 'transfer';
        RAISE NOTICE 'Using type: transfer';
        
    EXCEPTION WHEN OTHERS THEN
        BEGIN
            INSERT INTO token_transactions (
                id, user_id, amount, type, description, created_at
            ) 
            SELECT 
                gen_random_uuid(),
                (SELECT id FROM users LIMIT 1),
                1,
                'payment',
                'Test',
                NOW()
            WHERE EXISTS (SELECT 1 FROM users);
            
            DELETE FROM token_transactions WHERE description = 'Test' AND amount = 1;
            valid_type := 'payment';
            RAISE NOTICE 'Using type: payment';
            
        EXCEPTION WHEN OTHERS THEN
            valid_type := 'credit';
            RAISE NOTICE 'Using type: credit (fallback)';
        END;
    END;
    
    -- Now sync the missing records
    FOR atomic_record IN 
        SELECT * FROM atomic_token_operations 
        WHERE operation_type = 'transfer'
        AND from_account_type = 'user'
        AND to_account_type = 'user'
    LOOP
        -- Check if this operation already has corresponding token_transactions
        IF NOT EXISTS (
            SELECT 1 FROM token_transactions 
            WHERE reference_id = atomic_record.id
        ) THEN
            -- Create sender record (negative amount)
            INSERT INTO token_transactions (
                id,
                user_id,
                amount,
                type,
                description,
                reference_id,
                reference_type,
                created_at
            ) VALUES (
                gen_random_uuid(),
                atomic_record.from_account_id,
                -atomic_record.amount,
                valid_type,
                'Sent: ' || COALESCE(atomic_record.description, 'Token transfer'),
                atomic_record.id,
                'atomic_operation',
                atomic_record.created_at
            );
            
            -- Create receiver record (positive amount)
            INSERT INTO token_transactions (
                id,
                user_id,
                amount,
                type,
                description,
                reference_id,
                reference_type,
                created_at
            ) VALUES (
                gen_random_uuid(),
                atomic_record.to_account_id,
                atomic_record.amount,
                valid_type,
                'Received: ' || COALESCE(atomic_record.description, 'Token transfer'),
                atomic_record.id,
                'atomic_operation',
                atomic_record.created_at
            );
            
            synced_count := synced_count + 1;
        END IF;
    END LOOP;
    
    RAISE NOTICE 'Synced % atomic operations to token_transactions', synced_count;
    RAISE NOTICE '==============================================';
END $$;

-- Show final counts
SELECT 
    'FINAL COUNTS' as info,
    'atomic_token_operations' as table_name,
    COUNT(*) as total_records
FROM atomic_token_operations
UNION ALL
SELECT 
    'FINAL COUNTS' as info,
    'token_transactions' as table_name,
    COUNT(*) as total_records
FROM token_transactions;
