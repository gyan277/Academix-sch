-- Make student fields optional in database
-- Run this in Supabase SQL Editor

-- Check current constraints on students table
SELECT 
  column_name,
  is_nullable,
  data_type,
  column_default
FROM information_schema.columns
WHERE table_name = 'students' 
  AND column_name IN ('date_of_birth', 'parent_name', 'parent_phone');

-- Make date_of_birth, parent_name, and parent_phone nullable
ALTER TABLE students 
ALTER COLUMN date_of_birth DROP NOT NULL;

ALTER TABLE students 
ALTER COLUMN parent_name DROP NOT NULL;

ALTER TABLE students 
ALTER COLUMN parent_phone DROP NOT NULL;

-- Verify the changes
SELECT 
  column_name,
  is_nullable,
  data_type
FROM information_schema.columns
WHERE table_name = 'students' 
  AND column_name IN ('date_of_birth', 'parent_name', 'parent_phone');

-- ✅ After running this, these fields will be optional in the database