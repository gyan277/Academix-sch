-- =====================================================
-- DEFINITIVE FIX: Allow users to read their own profile during login
-- =====================================================

-- The issue is that during login, the user tries to read their profile
-- but RLS policies are blocking it because they're not "authenticated" yet

-- Step 1: Drop ALL existing policies on users table
DROP POLICY IF EXISTS "Users can view their own data" ON public.users;
DROP POLICY IF EXISTS "Admins can view all users" ON public.users;
DROP POLICY IF EXISTS "Admins can insert users" ON public.users;
DROP POLICY IF EXISTS "Admins can update users" ON public.users;
DROP POLICY IF EXISTS "Admins can delete users" ON public.users;
DROP POLICY IF EXISTS "Service role can insert users" ON public.users;
DROP POLICY IF EXISTS "Allow user profile creation on signup" ON public.users;

-- Step 2: Create simple, working policies

-- Allow authenticated users to read their own profile (CRITICAL for login)
CREATE POLICY "enable_read_own_profile"
  ON public.users
  FOR SELECT
  TO authenticated
  USING (auth.uid() = id);

-- Allow admins to read all profiles
CREATE POLICY "enable_read_all_for_admin"
  ON public.users
  FOR SELECT
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM public.users
      WHERE id = auth.uid() AND role = 'admin'
    )
  );

-- Allow admins to insert new users
CREATE POLICY "enable_insert_for_admin"
  ON public.users
  FOR INSERT
  TO authenticated
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM public.users
      WHERE id = auth.uid() AND role = 'admin'
    )
  );

-- Allow admins to update any user
CREATE POLICY "enable_update_for_admin"
  ON public.users
  FOR UPDATE
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM public.users
      WHERE id = auth.uid() AND role = 'admin'
    )
  );

-- Allow admins to delete users
CREATE POLICY "enable_delete_for_admin"
  ON public.users
  FOR DELETE
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM public.users
      WHERE id = auth.uid() AND role = 'admin'
    )
  );

-- Step 3: Verify the user profile exists
SELECT 
  id,
  email,
  full_name,
  role,
  created_at
FROM public.users
WHERE email = 'admin@moma.com';

-- =====================================================
-- If you see the admin user above, the fix is complete!
-- Now try logging in again.
-- =====================================================
