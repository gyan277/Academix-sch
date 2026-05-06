# Fix API Endpoint Issue - Teacher Login Creation

## Problem
When creating teachers with login accounts, you get this error:
```
Staff Added with Warning
Teacher [Name] added, but login account creation failed: 
Unexpected token '<' ... is not valid JSON
```

## Root Cause
The `/api/create-staff-user` endpoint is returning HTML instead of JSON, which means:
1. The server route isn't properly deployed on Netlify
2. The API endpoint is returning a 404 or error page
3. Environment variables might not be set in Netlify

## Quick Fix: Manual Account Creation

Since the staff record is created successfully, you just need to create the login account manually:

### Step 1: Check Staff Record
Run this in Supabase SQL Editor:
```sql
SELECT 
  id,
  staff_id,
  full_name,
  email,
  position,
  school_id
FROM public.staff 
WHERE full_name ILIKE '%daniel%gyan%'
ORDER BY full_name;
```

### Step 2: Create Login in Supabase Auth
1. Go to **Supabase Dashboard > Authentication > Users**
2. Click **Add User**
3. Fill in:
   - Email: (from staff record)
   - Password: Create a secure password
   - ✅ Check "Email Confirm"
4. Click **Create User**
5. **Copy the User ID**

### Step 3: Link to Staff Record
```sql
-- Replace 'PASTE_USER_ID_HERE' with actual UUID from Step 2
INSERT INTO public.users (
    id,
    email,
    role,
    full_name,
    school_id
) 
SELECT 
    'PASTE_USER_ID_HERE'::UUID,
    s.email,
    CASE 
        WHEN s.position ILIKE '%teacher%' THEN 'teacher'
        ELSE 'staff'
    END,
    s.full_name,
    s.school_id
FROM public.staff s
WHERE s.full_name = 'Daniel Gyan'  -- Replace with actual name
LIMIT 1;
```

### Step 4: Assign Class (If Teacher)
```sql
-- Only run this if the person is a teacher
INSERT INTO public.teacher_classes (
    teacher_id,
    class,
    academic_year,
    school_id
)
SELECT 
    'PASTE_USER_ID_HERE'::UUID,  -- Same User ID
    'Primary 3',  -- Replace with actual class
    '2025/2026',
    s.school_id
FROM public.staff s
WHERE s.full_name = 'Daniel Gyan'  -- Replace with actual name
LIMIT 1;
```

## Permanent Fix: Deploy Server Properly

### Option 1: Check Netlify Environment Variables
1. Go to **Netlify Dashboard**
2. Select your site
3. Go to **Site settings > Environment variables**
4. Verify these are set:
   - `VITE_SUPABASE_URL`
   - `VITE_SUPABASE_ANON_KEY`
   - `SUPABASE_SERVICE_ROLE_KEY`

### Option 2: Verify Server Deployment
Check if your Express server is running:
```bash
# Test the API endpoint
curl https://academix-man.netlify.app/api/ping
```

If this returns an error, your server isn't deployed properly.

### Option 3: Check Netlify Functions
Netlify might need the API routes configured as serverless functions. Check your `netlify.toml`:

```toml
[build]
  command = "pnpm build"
  publish = "dist"

[[redirects]]
  from = "/api/*"
  to = "/.netlify/functions/:splat"
  status = 200

[functions]
  directory = "netlify/functions"
```

## Workaround: Don't Create Login Accounts

For now, you can:
1. **Create staff without login** - Uncheck "Create Login Account"
2. **Add login later** - Use manual process above when needed
3. **Only create logins for teachers** - Staff like secretaries don't need system access

## Testing the Fix

After creating the login manually:
1. Try logging in with the teacher's email and password
2. Verify they can see their assigned class
3. Check they can mark attendance and enter grades

## Example: Fix Daniel Gyan's Account

```sql
-- 1. Check his staff record
SELECT * FROM public.staff WHERE full_name = 'Daniel Gyan';

-- 2. Create user in Supabase Auth Dashboard (copy User ID)

-- 3. Link to staff record (replace USER_ID)
INSERT INTO public.users (id, email, role, full_name, school_id)
SELECT 
    'YOUR_USER_ID_HERE'::UUID,
    email,
    'teacher',
    full_name,
    school_id
FROM public.staff 
WHERE full_name = 'Daniel Gyan';

-- 4. Assign to class (if needed)
INSERT INTO public.teacher_classes (teacher_id, class, academic_year, school_id)
SELECT 
    'YOUR_USER_ID_HERE'::UUID,
    'Primary 3',
    '2025/2026',
    school_id
FROM public.staff 
WHERE full_name = 'Daniel Gyan';
```

## Prevention

Until the API is fixed:
1. ✅ Create staff records normally
2. ❌ Don't check "Create Login Account"
3. ✅ Create logins manually when needed
4. ✅ Document which staff need login access

This way you can continue registering staff without errors!