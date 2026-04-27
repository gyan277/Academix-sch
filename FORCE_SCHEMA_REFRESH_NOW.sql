-- FORCE SCHEMA REFRESH - Run this to fix "table not found in schema cache" error
-- This script will force PostgREST to reload the schema immediately

-- Step 1: Verify tables exist
DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'teacher_fee_collections') THEN
    RAISE EXCEPTION 'teacher_fee_collections table does not exist! Run COMPLETE_FIX_WITH_SCHEMA_REFRESH.sql first!';
  END IF;
  
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'school_settings' AND column_name = 'enable_teacher_fee_collection') THEN
    RAISE EXCEPTION 'enable_teacher_fee_collection column does not exist! Run COMPLETE_FIX_WITH_SCHEMA_REFRESH.sql first!';
  END IF;
  
  RAISE NOTICE '✅ All tables and columns exist';
END $$;

-- Step 2: Force schema reload (multiple methods)
NOTIFY pgrst, 'reload schema';
NOTIFY pgrst, 'reload config';

-- Step 3: Wait a moment (PostgreSQL will process the notifications)
SELECT pg_sleep(1);

-- Step 4: Verify again
SELECT 
  '✅ Schema refresh sent!' as status,
  'Wait 5 seconds, then refresh your app (F5)' as next_step;

-- Step 5: Show what should be visible
SELECT 
  'Tables that should now be visible:' as info,
  table_name
FROM information_schema.tables 
WHERE table_schema = 'public' 
AND table_name IN ('teachers', 'teacher_fee_collections', 'school_settings')
ORDER BY table_name;
