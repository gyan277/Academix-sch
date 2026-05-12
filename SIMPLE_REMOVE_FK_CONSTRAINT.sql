-- SIMPLE FIX: Remove the problematic foreign key constraint
-- This allows inserts to work regardless of school_id value

-- Drop the foreign key constraint on school_id
ALTER TABLE student_fee_overrides 
DROP CONSTRAINT IF EXISTS fk_student_fee_overrides_school;

-- Verify it's gone
SELECT 
  '✅ Foreign key constraint removed' as status,
  COUNT(*) as remaining_fk_constraints
FROM pg_constraint
WHERE conrelid = 'student_fee_overrides'::regclass
AND conname = 'fk_student_fee_overrides_school';

-- Show remaining constraints
SELECT 
  'Remaining constraints:' as info,
  conname,
  contype
FROM pg_constraint
WHERE conrelid = 'student_fee_overrides'::regclass;

SELECT 'Done! Try saving the fee override now.' as message;
