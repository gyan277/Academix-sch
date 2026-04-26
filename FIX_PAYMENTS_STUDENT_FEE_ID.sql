-- ============================================
-- FIX: Remove student_fee_id constraint from payments table
-- ============================================
-- The payments table has an old student_fee_id column that's blocking payments
-- We need to make it nullable or remove it

-- Option 1: Make student_fee_id nullable (RECOMMENDED)
ALTER TABLE payments 
ALTER COLUMN student_fee_id DROP NOT NULL;

-- Option 2: If student_fee_id is not needed at all, drop it
-- (Uncomment if you want to remove it completely)
-- ALTER TABLE payments DROP COLUMN IF EXISTS student_fee_id;

-- Verify the change
SELECT 
    column_name,
    data_type,
    is_nullable
FROM information_schema.columns
WHERE table_name = 'payments'
ORDER BY ordinal_position;
