-- Fix: total_score column should be a generated column, not manually inserted
-- The error occurs because we're trying to insert into a GENERATED ALWAYS column

-- Step 1: Check current column definition
SELECT column_name, column_default, is_generated, generation_expression
FROM information_schema.columns
WHERE table_name = 'academic_scores' 
  AND column_name = 'total_score';

-- Step 2: Drop the generated column constraint and make it a regular computed column
ALTER TABLE academic_scores 
DROP COLUMN IF EXISTS total_score;

-- Step 3: Add it back as a regular column with a default
ALTER TABLE academic_scores 
ADD COLUMN total_score DECIMAL(5,2) GENERATED ALWAYS AS (
  COALESCE(class_score, 0) + COALESCE(exam_score, 0)
) STORED;

-- Alternative: If the above doesn't work, make it a regular column
-- ALTER TABLE academic_scores 
-- ADD COLUMN total_score DECIMAL(5,2);

-- Step 4: Verify the fix
SELECT column_name, is_generated, generation_expression
FROM information_schema.columns
WHERE table_name = 'academic_scores' 
  AND column_name = 'total_score';
