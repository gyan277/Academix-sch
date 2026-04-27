-- Enable Teacher Fee Collection Feature
-- Run this in Supabase SQL Editor

-- Enable the feature for your school
UPDATE school_settings
SET enable_teacher_fee_collection = true
WHERE id IN (SELECT id FROM schools LIMIT 1);

-- Verify it's enabled
SELECT 
  '✅ Feature Status' as check_name,
  school_name,
  enable_teacher_fee_collection,
  CASE 
    WHEN enable_teacher_fee_collection = true THEN '✅ ENABLED - Teachers should see Fee Collection in sidebar'
    ELSE '❌ DISABLED - Feature is off'
  END as status
FROM school_settings;

SELECT 'Now logout and login as teacher. The Fee Collection link should appear in the sidebar!' as next_step;
