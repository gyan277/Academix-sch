-- Fix: Delete ALL existing grading scales first
-- Then you can use the UI to add your custom grading scale

-- Delete ALL grading scales for your school
DELETE FROM grading_scale 
WHERE school_id = (
  SELECT id FROM schools WHERE school_name = 'Mount Olivet Methodist Academy' LIMIT 1
);


-- Verify they're deleted
SELECT COUNT(*) as remaining_grades
FROM grading_scale
WHERE school_id = (
  SELECT id FROM schools WHERE school_name = 'Mount Olivet Methodist Academy' LIMIT 1
);

-- Should return 0

-- ✅ After running this:
-- 1. Refresh the Settings → Grades page
-- 2. Click "Reset to Default" button
-- 3. Click "Save Grading Scale"
-- 4. Should work without error!
