-- AUTO SCHOOL_ID ASSIGNMENT FOR NEW USERS
-- Automatically assigns school_id to new users when they are created

-- Function to auto-assign school_id to new users
CREATE OR REPLACE FUNCTION auto_assign_school_id()
RETURNS TRIGGER AS $$
DECLARE
  default_school_id UUID;
BEGIN
  -- Only proceed if school_id is NULL
  IF NEW.school_id IS NULL THEN
    -- Get the first school's ID (or you can customize this logic)
    SELECT id INTO default_school_id
    FROM schools
    LIMIT 1;
    
    -- If a school exists, assign it
    IF default_school_id IS NOT NULL THEN
      NEW.school_id := default_school_id;
      
      RAISE NOTICE 'Auto-assigned school_id % to user %', default_school_id, NEW.email;
    ELSE
      -- No schools exist - this is a problem
      RAISE WARNING 'No schools found in database. User % created without school_id', NEW.email;
    END IF;
  END IF;
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create trigger on users table
DROP TRIGGER IF EXISTS auto_assign_school_id_trigger ON users;
CREATE TRIGGER auto_assign_school_id_trigger
  BEFORE INSERT ON users
  FOR EACH ROW
  EXECUTE FUNCTION auto_assign_school_id();

-- Also create a function to handle auth.users trigger
-- This ensures school_id is set when user is created via Supabase Auth
CREATE OR REPLACE FUNCTION handle_new_user()
RETURNS TRIGGER AS $$
DECLARE
  default_school_id UUID;
BEGIN
  -- Get the first school's ID
  SELECT id INTO default_school_id
  FROM schools
  LIMIT 1;
  
  -- Insert into public.users with school_id
  INSERT INTO public.users (id, email, full_name, role, school_id, status)
  VALUES (
    NEW.id,
    NEW.email,
    COALESCE(NEW.raw_user_meta_data->>'full_name', NEW.email),
    COALESCE(NEW.raw_user_meta_data->>'role', 'admin'),
    default_school_id,
    'active'
  )
  ON CONFLICT (id) DO UPDATE
  SET 
    email = EXCLUDED.email,
    full_name = COALESCE(EXCLUDED.full_name, public.users.full_name),
    role = COALESCE(EXCLUDED.role, public.users.role),
    school_id = COALESCE(public.users.school_id, EXCLUDED.school_id);
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Recreate the auth trigger to use the updated function
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW
  EXECUTE FUNCTION handle_new_user();

-- Test: Check if trigger is working
SELECT 
  'Trigger Status' as info,
  trigger_name,
  event_manipulation,
  event_object_table,
  action_statement
FROM information_schema.triggers
WHERE trigger_name IN ('auto_assign_school_id_trigger', 'on_auth_user_created');

COMMENT ON FUNCTION auto_assign_school_id() IS 
'Automatically assigns the default school_id to new users if they do not have one. Prevents NULL school_id issues.';

COMMENT ON FUNCTION handle_new_user() IS 
'Handles new user creation from auth.users and ensures they get a school_id assigned automatically.';
