-- Fix Staff Salaries Foreign Key Constraint
-- Remove the constraint that requires staff_id to be in users table
-- This allows us to add salaries for staff from both users and staff tables

-- Drop the foreign key constraint
ALTER TABLE staff_salaries 
DROP CONSTRAINT IF EXISTS staff_salaries_staff_id_fkey;

-- Drop the same constraint from salary_payments
ALTER TABLE salary_payments
DROP CONSTRAINT IF EXISTS salary_payments_staff_id_fkey;

-- Verify constraints are removed
SELECT 
  conname as constraint_name,
  conrelid::regclass as table_name,
  confrelid::regclass as foreign_table
FROM pg_constraint
WHERE conname LIKE '%staff%salaries%staff_id%'
   OR conname LIKE '%salary_payments%staff_id%';

-- Success message
DO $$
BEGIN
  RAISE NOTICE '✅ Foreign key constraints removed successfully!';
  RAISE NOTICE 'You can now add salaries for staff from both users and staff tables.';
END $$;
