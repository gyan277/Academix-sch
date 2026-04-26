-- TEST WITHOUT TRIGGER
-- Temporarily disable the auth trigger to see if it's causing the issue

-- Step 1: Check if trigger exists
SELECT 
  'Current Triggers' as info,
  trigger_name,
  event_object_table,
  action_statement,
  action_timing
FROM information_schema.triggers
WHERE trigger_name LIKE '%auth%' OR trigger_name LIKE '%user%'
ORDER BY trigger_name;

-- Step 2: Disable the trigger temporarily
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;

-- Step 3: Check trigger is disabled
SELECT 
  'After Disable' as info,
  COUNT(*) as trigger_count
FROM information_schema.triggers
WHERE trigger_name = 'on_auth_user_created';
-- Should return 0

-- Step 4: Now try creating a teacher in the UI
-- If it works, the trigger was the problem

-- Step 5: Re-enable the trigger (run this after testing)
/*
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW
  EXECUTE FUNCTION handle_new_user();
*/

-- Step 6: Verify trigger is re-enabled
/*
SELECT 
  'After Re-enable' as info,
  trigger_name,
  event_object_table
FROM information_schema.triggers
WHERE trigger_name = 'on_auth_user_created';
*/
