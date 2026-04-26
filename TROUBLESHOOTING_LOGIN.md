# Troubleshooting: Infinite Recursion Login Error

## Current Status
You're still seeing: `User profile error: infinite recursion detected in policy for relation "users"`

## Diagnostic Steps

### Step 1: Check Current RLS Status

Run `CHECK_ALL_RLS_POLICIES.sql` in Supabase SQL Editor to see:
- Which tables have RLS enabled
- What policies currently exist
- Which policies might be causing recursion

**What to look for:**
- Any policies on the `users` table
- Any policies with subqueries that reference `users` table

### Step 2: Nuclear Option - Disable RLS Completely

If you're still seeing the error, run `NUCLEAR_FIX_RLS.sql`:

```sql
-- This will:
-- 1. Completely disable RLS on users table
-- 2. Drop ALL policies
-- 3. Verify the fix worked
```

**This WILL fix the issue** because:
- No RLS = No policies = No recursion possible
- You can re-enable RLS later with proper policies

### Step 3: Clear Browser Cache

After running the SQL fix:

1. **Hard refresh** your browser:
   - Windows/Linux: `Ctrl + Shift + R`
   - Mac: `Cmd + Shift + R`

2. **Or clear Supabase session**:
   - Open browser DevTools (F12)
   - Go to Application tab
   - Clear all storage for your site
   - Refresh page

### Step 4: Check Supabase Logs

If still not working, check Supabase logs:

1. Go to Supabase Dashboard
2. Click on your project
3. Go to "Logs" section
4. Look for errors related to RLS or policies

## Common Issues

### Issue 1: Policies Not Actually Dropped

**Symptom**: You ran the SQL but policies still exist

**Solution**: Run this to force-drop all policies:

```sql
DO $$ 
DECLARE
    r RECORD;
BEGIN
    FOR r IN (SELECT policyname FROM pg_policies WHERE tablename = 'users' AND schemaname = 'public') LOOP
        EXECUTE 'DROP POLICY IF EXISTS ' || quote_ident(r.policyname) || ' ON public.users CASCADE';
    END LOOP;
END $$;
```

### Issue 2: RLS Still Enabled

**Symptom**: RLS is still enabled on users table

**Solution**: Force disable it:

```sql
ALTER TABLE public.users DISABLE ROW LEVEL SECURITY;
```

### Issue 3: Cached Query Results

**Symptom**: Browser is using cached data

**Solution**: 
1. Clear browser cache
2. Open in incognito/private window
3. Try logging in again

### Issue 4: Wrong Supabase Project

**Symptom**: Changes not taking effect

**Solution**: Verify you're editing the correct Supabase project:
1. Check `.env` file for `VITE_SUPABASE_URL`
2. Verify it matches the Supabase project you're editing
3. Make sure you're not in a different environment (staging vs production)

## Verification Checklist

After running the fix, verify:

- [ ] RLS is disabled on users table
  ```sql
  SELECT rowsecurity FROM pg_tables 
  WHERE schemaname = 'public' AND tablename = 'users';
  -- Should return: false
  ```

- [ ] No policies exist on users table
  ```sql
  SELECT COUNT(*) FROM pg_policies 
  WHERE schemaname = 'public' AND tablename = 'users';
  -- Should return: 0
  ```

- [ ] Can query users table directly
  ```sql
  SELECT * FROM public.users WHERE email = 'admin@moma.com';
  -- Should return your admin user
  ```

- [ ] Browser cache cleared
- [ ] Hard refresh performed
- [ ] Login page loads without error

## If Still Not Working

### Last Resort: Check Auth Configuration

1. **Verify user exists in Supabase Auth**:
   - Go to Supabase Dashboard → Authentication → Users
   - Find `admin@moma.com`
   - Check if user is confirmed and active

2. **Check if email confirmation is disabled**:
   - Go to Supabase Dashboard → Authentication → Settings
   - Under "Email Auth", ensure "Enable email confirmations" is OFF

3. **Verify the user profile exists**:
   ```sql
   SELECT * FROM auth.users WHERE email = 'admin@moma.com';
   SELECT * FROM public.users WHERE email = 'admin@moma.com';
   ```
   Both queries should return a user.

4. **Check if there's a mismatch**:
   ```sql
   -- Check if auth.users.id matches public.users.id
   SELECT 
     au.id as auth_id,
     au.email as auth_email,
     pu.id as profile_id,
     pu.email as profile_email
   FROM auth.users au
   LEFT JOIN public.users pu ON au.id = pu.id
   WHERE au.email = 'admin@moma.com';
   ```
   The IDs should match.

## Expected Result

After following these steps, you should:
1. ✅ Be able to login without infinite recursion error
2. ✅ See the dashboard
3. ✅ Access all features

## Next Steps After Login Works

Once login is working:

1. **Test multi-tenancy**: Verify schools are isolated
2. **Implement teacher management**: Continue with the spec
3. **Re-enable RLS properly**: Add back simple policies if needed

## Files Reference

- `NUCLEAR_FIX_RLS.sql` - Completely disables RLS (guaranteed fix)
- `CHECK_ALL_RLS_POLICIES.sql` - Diagnostic queries
- `DISABLE_RLS_USERS_FINAL.sql` - Previous fix attempt
- `RLS_RECURSION_FIX_GUIDE.md` - Detailed explanation

## Contact Points

If you're still stuck after all this:
1. Share the output of `CHECK_ALL_RLS_POLICIES.sql`
2. Share any error messages from browser console
3. Share Supabase logs if available

---

**TL;DR**: Run `NUCLEAR_FIX_RLS.sql`, clear browser cache, hard refresh, try login.
