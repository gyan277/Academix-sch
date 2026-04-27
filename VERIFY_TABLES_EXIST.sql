-- Quick verification: Do the tables exist?
-- Run this in Supabase SQL Editor

-- Check if tables exist
SELECT 
  'Tables in database:' as info,
  table_name,
  '✅ EXISTS' as status
FROM information_schema.tables 
WHERE table_schema = 'public' 
AND table_name IN ('teachers', 'teacher_fee_collections', 'school_settings')
ORDER BY table_name;

-- Check if column exists
SELECT 
  'Column check:' as info,
  column_name,
  data_type,
  '✅ EXISTS' as status
FROM information_schema.columns 
WHERE table_schema = 'public'
AND table_name = 'school_settings' 
AND column_name = 'enable_teacher_fee_collection';

-- If you see results above, the tables exist!
-- The error is just a schema cache issue in PostgREST.

-- Try one more schema refresh
NOTIFY pgrst, 'reload schema';

SELECT '✅ If you see tables above, they exist!' as result,
       '⚠️ The error is just PostgREST cache' as issue,
       '🔧 Solution: Wait 2-3 minutes OR restart PostgREST' as fix;
