-- Clear All Finance Data
-- This script removes all financial records from the database
-- Run this in Supabase SQL Editor to start fresh

-- WARNING: This will delete all financial data!
-- Make sure you want to do this before running.

BEGIN;

-- Clear new finance tables (from enhanced system)
DELETE FROM salary_payments;
DELETE FROM staff_salaries;
DELETE FROM custom_expenses;
DELETE FROM student_fee_overrides;

-- Clear existing finance tables
DELETE FROM payments;
DELETE FROM class_fees;

-- Reset any sequences if needed
-- (None needed as we use UUIDs)

COMMIT;

-- Verify all tables are empty
SELECT 'salary_payments' as table_name, COUNT(*) as count FROM salary_payments
UNION ALL
SELECT 'staff_salaries', COUNT(*) FROM staff_salaries
UNION ALL
SELECT 'custom_expenses', COUNT(*) FROM custom_expenses
UNION ALL
SELECT 'student_fee_overrides', COUNT(*) FROM student_fee_overrides
UNION ALL
SELECT 'payments', COUNT(*) FROM payments
UNION ALL
SELECT 'class_fees', COUNT(*) FROM class_fees;

-- Expected result: All counts should be 0
