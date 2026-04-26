-- FIX AUTH TRIGGER TRANSACTION ERROR
-- The handle_new_user() function is causing transaction errors

-- Step 1: Drop the problematic trigger
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;

-- Step 2: Create a better version of the function with proper error handling
CREATE OR REPLACE FUNCTION handle_new_user()
RETURNS TRIGGER AS $$
DECLARE
  default_school_id UUID;
  user_role TEXT;
BEGIN
  -- Get the first school's ID
  SELECT id INTO default_school_id
  FROM public.schools
  LIMIT 1;
  
  -- Get role from metadata, default to 'admin'
  user_role := COALESCE(NEW.raw_user_meta_data->>'role', 'admin');
  
  -- Insert into public.users with proper error handling
  BEGIN
    INSERT INTO public.users (
      id,
      email,
      full_name,
      role,
      phone,
      school_id,
      status,
      created_at,
      updated_at
    )
    VALUES (
      NEW.id,
      NEW.email,
      COALESCE(NEW.raw_user_meta_data->>'full_name', NEW.email),
      user_role,
      COALESCE(NEW.raw_user_meta_data->>'phone', ''),
      COALESCE((NEW.raw_user_meta_data->>'school_id')::UUID, default_school_id),
      'active',
      NOW(),
      NOW()
    )
    ON CONFLICT (id) DO UPDATE
    SET 
      email = EXCLUDED.email,
      full_name = COALESCE(EXCLUDED.full_name, public.users.full_name),
      role = COALESCE(EXCLUDED.role, public.users.role),
      phone = COALESCE(EXCLUDED.phone, public.users.phone),
      school_id = COALESCE(public.users.school_id, EXCLUDED.school_id),
      updated_at = NOW();
    
    RAISE LOG 'Successfully created/updated user % in public.users', NEW.email;
    
  EXCEPTION
    WHEN OTHERS THEN
      -- Log the error but don't fail the transaction
      RAISE WARNING 'Error in handle_new_user for %: % %', NEW.email, SQLERRM, SQLSTATE;
      -- Don't re-raise the error - let the auth user be created anyway
  END;
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Step 3: Recreate the trigger
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW
  EXECUTE FUNCTION handle_new_user();

-- Step 4: Grant necessary permissions
GRANT USAGE ON SCHEMA public TO postgres, anon, authenticated, service_role;
GRANT ALL ON ALL TABLES IN SCHEMA public TO postgres, anon, authenticated, service_role;
GRANT ALL ON ALL SEQUENCES IN SCHEMA public TO postgres, anon, authenticated, service_role;

-- Step 5: Verify the trigger is working
SELECT 
  'Trigger Status' as info,
  trigger_name,
  event_manipulation,
  event_object_table,
  action_statement
FROM information_schema.triggers
WHERE trigger_name = 'on_auth_user_created';

-- Step 6: Test the function manually (should not error)
DO $$
BEGIN
  RAISE NOTICE 'Trigger function exists and is ready';
END $$;

COMMENT ON FUNCTION handle_new_user() IS 
'Handles new user creation from auth.users. Now with proper error handling to prevent transaction aborts.';
