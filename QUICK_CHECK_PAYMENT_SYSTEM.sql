-- ============================================
-- QUICK CHECK - Is Payment Cart System Ready?
-- ============================================
-- Run this simple query to check if your database is ready
-- Takes 2 seconds to run!

SELECT 
    -- Check 1: payment_type column
    CASE 
        WHEN EXISTS (
            SELECT 1 FROM information_schema.columns 
            WHERE table_name = 'payments' AND column_name = 'payment_type'
        ) THEN '✓ READY'
        ELSE '✗ MISSING - Run RUN_FINANCE_MIGRATION.sql'
    END as payment_type_status,
    
    -- Check 2: bus_fee column
    CASE 
        WHEN EXISTS (
            SELECT 1 FROM information_schema.columns 
            WHERE table_name = 'class_fees' AND column_name = 'bus_fee'
        ) THEN '✓ READY'
        ELSE '✗ MISSING - Run RUN_FINANCE_MIGRATION.sql'
    END as bus_fee_status,
    
    -- Check 3: canteen_fee column
    CASE 
        WHEN EXISTS (
            SELECT 1 FROM information_schema.columns 
            WHERE table_name = 'class_fees' AND column_name = 'canteen_fee'
        ) THEN '✓ READY'
        ELSE '✗ MISSING - Run RUN_FINANCE_MIGRATION.sql'
    END as canteen_fee_status,
    
    -- Check 4: student_fee_overrides table
    CASE 
        WHEN EXISTS (
            SELECT 1 FROM information_schema.tables 
            WHERE table_name = 'student_fee_overrides'
        ) THEN '✓ READY'
        ELSE '✗ MISSING - Run RUN_FINANCE_MIGRATION.sql'
    END as overrides_table_status;

-- ============================================
-- WHAT THE RESULTS MEAN:
-- ============================================
-- 
-- ✓ READY = Your database has this feature
-- ✗ MISSING = You need to run the migration
--
-- IF ALL SHOW ✓ READY:
--   Your database is perfect! The payment cart system will work.
--
-- IF ANY SHOW ✗ MISSING:
--   Run this file: RUN_FINANCE_MIGRATION.sql
--   (You should already have this file from earlier)
--
-- ============================================
