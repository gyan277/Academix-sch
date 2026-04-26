# Simple Setup Guide - Multi-Tenancy

## 🎯 Quick Setup (5 Minutes)

Follow these steps **in order** in your Supabase SQL Editor:

---

## Step 1: Run the Migration

Copy and paste this entire file into Supabase SQL Editor and run it:
```
database-migrations/add-school-multi-tenancy.sql
```

Wait for "Success" message.

---

## Step 2: Register Your School

```sql
-- Replace with your actual school information
INSERT INTO public.school_settings (
  school_name,
  school_address,
  school_phone,
  school_email,
  current_academic_year
) VALUES (
  'MOMA School',                    -- Change this
  '123 School Street, Accra',       -- Change this
  '+233 50 123 4567',               -- Change this
  'info@moma.edu.gh',               -- Change this
  '2024/2025'                       -- Current year
)
RETURNING id;
```

**IMPORTANT**: Copy the `id` that is returned. You'll need it in the next steps!

Example result:
```
id: a1b2c3d4-e5f6-7890-abcd-ef1234567890
```

---

## Step 3: Update Your Admin User

Replace `YOUR_SCHOOL_ID_HERE` with the ID from Step 2, and replace the email with your admin email:

```sql
-- Update auth.users metadata
UPDATE auth.users
SET raw_user_meta_data = jsonb_set(
  COALESCE(raw_user_meta_data, '{}'::jsonb),
  '{school_id}',
  '"YOUR_SCHOOL_ID_HERE"'::jsonb
)
WHERE email = 'admin@moma.edu.gh';  -- Change to your admin email

-- Update public.users table
UPDATE public.users
SET school_id = 'YOUR_SCHOOL_ID_HERE'::UUID
WHERE email = 'admin@moma.edu.gh';  -- Change to your admin email
```

---

## Step 4: Copy Default Data

Replace `YOUR_SCHOOL_ID_HERE` with the ID from Step 2:

```sql
-- Copy subjects for all classes
INSERT INTO public.class_subjects (class, subject_id, academic_year, school_id)
SELECT 
  cs.class,
  cs.subject_id,
  cs.academic_year,
  'YOUR_SCHOOL_ID_HERE'::UUID
FROM public.class_subjects cs
WHERE cs.school_id IS NULL
ON CONFLICT DO NOTHING;

-- Copy grading scale
INSERT INTO public.grading_scale (grade, min_score, max_score, sort_order, school_id)
SELECT 
  grade,
  min_score,
  max_score,
  sort_order,
  'YOUR_SCHOOL_ID_HERE'::UUID
FROM public.grading_scale
WHERE school_id IS NULL
ON CONFLICT DO NOTHING;
```

---

## Step 5: Verify Everything Works

```sql
-- Check your user has school_id
SELECT 
  u.email,
  u.full_name,
  u.role,
  u.school_id,
  s.school_name
FROM public.users u
LEFT JOIN public.school_settings s ON u.school_id = s.id
WHERE u.email = 'admin@moma.edu.gh';  -- Change to your admin email
```

You should see:
- ✅ Your email
- ✅ Your name
- ✅ Role: admin
- ✅ school_id: (the UUID)
- ✅ school_name: MOMA School

---

## Step 6: Test in the App

1. **Logout** from EduManage (if you're logged in)
2. **Login** again with your admin credentials
3. Go to **Registrar** page
4. Try to **add a student**
5. Check if the student appears in the list

If it works, you're done! 🎉

---

## 🔍 Troubleshooting

### Problem: school_id is NULL in the verification query

**Solution**: Run Step 3 again, make sure you:
- Replaced `YOUR_SCHOOL_ID_HERE` with the actual UUID
- Used the correct email address
- Included the quotes around the UUID in the jsonb_set

### Problem: Can't add students - "School information not found"

**Solution**: 
1. Logout and login again
2. Run the verification query (Step 5)
3. Make sure school_id is not NULL

### Problem: Error when running Step 4

**Solution**: This is okay if you see "duplicate key" errors - it means the data already exists. Just continue to Step 5.

---

## 📋 Complete Example

Here's a complete example with actual values:

```sql
-- Step 2: Register school
INSERT INTO public.school_settings (
  school_name, school_address, school_phone, 
  school_email, current_academic_year
) VALUES (
  'MOMA School', '123 Main St', '+233501234567', 
  'info@moma.edu.gh', '2024/2025'
)
RETURNING id;
-- Returns: a1b2c3d4-e5f6-7890-abcd-ef1234567890

-- Step 3: Update admin user
UPDATE auth.users
SET raw_user_meta_data = jsonb_set(
  COALESCE(raw_user_meta_data, '{}'::jsonb),
  '{school_id}',
  '"a1b2c3d4-e5f6-7890-abcd-ef1234567890"'::jsonb
)
WHERE email = 'admin@moma.edu.gh';

UPDATE public.users
SET school_id = 'a1b2c3d4-e5f6-7890-abcd-ef1234567890'::UUID
WHERE email = 'admin@moma.edu.gh';

-- Step 4: Copy defaults
INSERT INTO public.class_subjects (class, subject_id, academic_year, school_id)
SELECT class, subject_id, academic_year, 
  'a1b2c3d4-e5f6-7890-abcd-ef1234567890'::UUID
FROM public.class_subjects WHERE school_id IS NULL
ON CONFLICT DO NOTHING;

INSERT INTO public.grading_scale (grade, min_score, max_score, sort_order, school_id)
SELECT grade, min_score, max_score, sort_order,
  'a1b2c3d4-e5f6-7890-abcd-ef1234567890'::UUID
FROM public.grading_scale WHERE school_id IS NULL
ON CONFLICT DO NOTHING;

-- Step 5: Verify
SELECT u.email, u.role, u.school_id, s.school_name
FROM public.users u
LEFT JOIN public.school_settings s ON u.school_id = s.id
WHERE u.email = 'admin@moma.edu.gh';
```

---

## ✅ Success Checklist

- [ ] Migration ran successfully
- [ ] School created (got school_id)
- [ ] Admin user updated with school_id
- [ ] Defaults copied (subjects and grades)
- [ ] Verification query shows school_id and school_name
- [ ] Can login to EduManage
- [ ] Can add a student successfully
- [ ] Student appears in the list

---

## 🎉 Done!

Your multi-tenancy system is now active! You can:
- Add students and staff
- They will automatically be linked to your school
- Other schools (when you add them) won't see your data

**Need to add another school?** Just repeat Steps 2-4 with different school information and a different admin email.
