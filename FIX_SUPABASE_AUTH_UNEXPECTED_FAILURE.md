# Fix Supabase Auth "unexpected_failure" Error

## Error
"An error occurred during authentication. Please try again. (unexpected_failure)"

## Common Causes

### 1. Supabase Email Confirmations Enabled
Supabase requires email confirmation but SMTP is not configured.

**Fix:**
1. Go to Supabase Dashboard
2. Click on your project
3. Go to Authentication > Settings
4. Scroll to "Email Auth"
5. **Disable "Enable email confirmations"**
6. Click Save

### 2. Rate Limiting
Too many signup attempts in a short time.

**Fix:**
Wait 10-15 minutes and try again.

### 3. Invalid Email Domain
Some email domains are blocked by Supabase.

**Fix:**
Try a different email domain (Gmail, Outlook, etc.)

### 4. Supabase Project Issues
Project might be paused or have issues.

**Fix:**
1. Check Supabase Dashboard for project status
2. Restart the project if needed
3. Check for any service disruptions

### 5. Auth Trigger Errors
The `handle_new_user()` trigger might be failing.

**Fix:**
```sql
-- Check trigger logs
SELECT * FROM pg_stat_statements 
WHERE query LIKE '%handle_new_user%' 
ORDER BY calls DESC;

-- Temporarily disable trigger to test
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;

-- Try creating teacher again

-- Re-enable trigger
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW
  EXECUTE FUNCTION handle_new_user();
```

## Recommended Fix Steps

### Step 1: Disable Email Confirmations (Most Common Fix)
1. Go to https://supabase.com/dashboard
2. Select your project
3. Go to Authentication > Settings
4. Find "Enable email confirmations"
5. **Turn it OFF**
6. Save changes
7. Try creating teacher again

### Step 2: Check Supabase Logs
1. Go to Supabase Dashboard
2. Click "Logs" in sidebar
3. Select "Auth Logs"
4. Look for recent errors
5. Share any error messages

### Step 3: Test with Simple Signup
Try creating a user directly in Supabase:
1. Go to Authentication > Users
2. Click "Add user"
3. Enter email and password
4. If this fails, it's a Supabase configuration issue

### Step 4: Check Auth Settings
In Supabase Dashboard > Authentication > Settings:
- ✅ Enable signup: Should be ON
- ❌ Enable email confirmations: Should be OFF (unless SMTP configured)
- ✅ Enable phone confirmations: Should be OFF
- ✅ Minimum password length: 6 or 8

### Step 5: Verify SMTP (If Email Confirmations Needed)
If you need email confirmations:
1. Go to Authentication > Settings
2. Scroll to "SMTP Settings"
3. Configure your email provider
4. Test email sending

## Alternative: Create Teacher Manually

If Supabase signup is completely broken, create teacher manually:

```sql
-- Step 1: Create auth user
INSERT INTO auth.users (
  instance_id,
  id,
  aud,
  role,
  email,
  encrypted_password,
  email_confirmed_at,
  raw_user_meta_data,
  created_at,
  updated_at
)
VALUES (
  '00000000-0000-0000-0000-000000000000',
  gen_random_uuid(),
  'authenticated',
  'authenticated',
  'teacher@school.com',
  crypt('password123', gen_salt('bf')),
  NOW(),
  jsonb_build_object(
    'full_name', 'Teacher Name',
    'role', 'teacher',
    'phone', '+233501234567'
  ),
  NOW(),
  NOW()
)
RETURNING id;

-- Step 2: The handle_new_user() trigger should create the public.users record automatically
-- If not, create it manually:
INSERT INTO public.users (id, email, full_name, role, phone, school_id, status)
VALUES (
  'paste-id-from-above',
  'teacher@school.com',
  'Teacher Name',
  'teacher',
  '+233501234567',
  (SELECT id FROM schools LIMIT 1),
  'active'
);
```

## Debugging

### Check if auth.users table is accessible
```sql
SELECT COUNT(*) FROM auth.users;
```

### Check if trigger exists
```sql
SELECT * FROM information_schema.triggers 
WHERE trigger_name = 'on_auth_user_created';
```

### Check if function exists
```sql
SELECT * FROM pg_proc 
WHERE proname = 'handle_new_user';
```

### Test trigger manually
```sql
-- This should work without errors
SELECT handle_new_user();
```

## Prevention

To prevent this issue:

1. **Disable email confirmations** unless you have SMTP configured
2. **Use rate limiting carefully** - don't create too many users quickly
3. **Monitor Supabase logs** for auth errors
4. **Test auth in Supabase Dashboard** before using in app
5. **Keep Supabase project active** (not paused)

## Summary

**Most likely fix:** Disable email confirmations in Supabase Dashboard

Steps:
1. Supabase Dashboard > Authentication > Settings
2. Disable "Enable email confirmations"
3. Save
4. Try again

If that doesn't work, check Supabase logs and share the error messages!
