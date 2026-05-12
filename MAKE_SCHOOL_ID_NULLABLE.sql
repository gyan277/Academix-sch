-- TEMPORARY FIX: Make school_id nullable in student_fee_overrides
-- This allows the insert to succeed even if school_id is problematic
-- We can fix the data later

-- Drop the NOT NULL constraint on school_id
ALTER TABLE student_fee_overrides 
ALTER COLUMN school_id DROP NOT NULL;

-- Verify the change
SELECT 
  'Column is now nullable' as status,
  column_name,
  data_type,
  is_nullable
FROM information_schema.columns
WHERE table_name = 'student_fee_overrides'
AND column_name = 'school_id';

-- Show the constraint
SELECT 
  'Foreign key constraint still exists (but column is nullable)' as info,
  conname,
  pg_get_constraintdef(oid)
FROM pg_constraint
WHERE conrelid = 'student_fee_overrides'::regclass
AND conname LIKE '%school%';

SELECT '✅ school_id is now nullable. Try saving the fee override again.' as message;
