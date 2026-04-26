-- Reset All Payments
-- This will delete ALL payment records from the database
-- WARNING: This action cannot be undone!

-- Check current payment records before deletion
SELECT 'Current Payment Records' as info;
SELECT 
  COUNT(*) as total_payments,
  SUM(amount) as total_amount,
  payment_type,
  COUNT(DISTINCT student_id) as unique_students
FROM payments
GROUP BY payment_type;

-- Show total summary
SELECT 
  COUNT(*) as total_payment_records,
  SUM(amount) as total_amount_collected,
  COUNT(DISTINCT student_id) as students_with_payments
FROM payments;

-- UNCOMMENT THE LINE BELOW TO DELETE ALL PAYMENTS
-- DELETE FROM payments;

-- After deletion, verify
-- SELECT COUNT(*) as remaining_payments FROM payments;

-- Instructions:
-- 1. Review the current payment records above
-- 2. If you're sure you want to delete ALL payments, uncomment the DELETE line
-- 3. Run the script
-- 4. The verification query will confirm all payments are deleted
