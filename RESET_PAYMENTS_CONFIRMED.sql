-- Reset All Payments - CONFIRMED VERSION
-- This will immediately delete ALL payment records
-- Run this script in Supabase SQL Editor

BEGIN;

-- Show what will be deleted
SELECT 'Payment records to be deleted:' as info;
SELECT 
  payment_type,
  COUNT(*) as count,
  SUM(amount) as total_amount
FROM payments
GROUP BY payment_type;

-- Delete all payment records
DELETE FROM payments;

-- Verify deletion
SELECT 'Verification - Remaining payments:' as info;
SELECT COUNT(*) as remaining_payments FROM payments;

COMMIT;

-- Success message
SELECT 'All payments have been reset successfully!' as result;
