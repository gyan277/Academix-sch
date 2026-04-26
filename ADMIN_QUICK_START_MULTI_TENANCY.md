# Admin Quick Start: Multi-Tenancy Setup

## 🎯 Overview

Your EduManage system now supports multiple schools! Each school's data is completely isolated - schools cannot see each other's students, staff, or grades.

## 📋 ONE-TIME SETUP (Run Once)

### Step 1: Run the Migration

1. Go to your Supabase Dashboard
2. Click on "SQL Editor" in the left sidebar
3. Click "New Query"
4. Copy and paste the entire contents of `database-migrations/add-school-multi-tenancy.sql`
5. Click "Run" (or press Ctrl+Enter)
6. Wait for "Success. No rows returned" message

This adds `school_id` columns to all tables and updates security policies.

## 🏫 REGISTERING A NEW SCHOOL

Follow these steps for each school you want to add to the system:

### Step 1: Create School Settings

1. Go to Supabase Dashboard → SQL Editor
2. Run this query (replace with actual school info):

```sql
INSERT INTO public.school_settings (
  school_name,
  school_address,
  school_phone,
  school_email,
  current_academic_year
) VALUES (
  'MOMA School',                    -- School name
  '123 School Street, Accra',       -- School address
  '+233 50 123 4567',               -- School phone
  'info@moma.edu.gh',               -- School email
  '2024/2025'                       -- Current academic year
)
RETURNING id;
```

3. **IMPORTANT**: Copy the returned `id` (this is the school_id)
   - Example: `a1b2c3d4-e5f6-7890-abcd-ef1234567890`

### Step 2: Create Admin User

**Option A: If you already have an admin user**, update their metadata using SQL:

```sql
-- Update auth.users metadata (replace email and school_id)
UPDATE auth.users
SET raw_user_meta_data = jsonb_set(
  COALESCE(raw_user_meta_data, '{}'::jsonb),
  '{school_id}',
  '"YOUR_SCHOOL_ID_HERE"'::jsonb
)
WHERE email = 'admin@moma.edu.gh';

-- Update public.users table
UPDATE public.users
SET school_id = 'YOUR_SCHOOL_ID_HERE'::UUID
WHERE email = 'admin@moma.edu.gh';
```

**Option B: If creating a new admin user**:

1. Go to Supabase Dashboard → Authentication → Users
2. Click "Add User" → "Create new user"
3. Fill in:
   - **Email**: `admin@moma.edu.gh` (or school's admin email)
   - **Password**: Choose a strong password
   - **Auto Confirm User**: ✅ Check this box
4. Click "User Metadata" section and add:

```json
{
  "full_name": "Admin Name",
  "role": "admin",
  "phone": "+233 50 123 4567",
  "school_id": "YOUR_SCHOOL_ID_HERE"
}
```

5. Click "Create user"

**Note**: If the User Metadata is not editable in the UI, use Option A (SQL method) instead.

### Step 3: Copy Default Data

1. Go to Supabase Dashboard → SQL Editor
2. Run these queries (replace `YOUR_SCHOOL_ID_HERE` with the school_id from Step 1):

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

### Step 4: Test Login

1. Go to your EduManage application
2. Login with the admin email and password you created
3. You should see the dashboard
4. Try adding a student in the Registrar page
5. Verify the student appears in the database with the correct school_id

## ✅ VERIFICATION

After registering a school, verify everything is working:

### Check User Profile
```sql
SELECT 
  u.id,
  u.email,
  u.full_name,
  u.role,
  u.school_id,
  s.school_name
FROM public.users u
LEFT JOIN public.school_settings s ON u.school_id = s.id
WHERE u.email = 'admin@moma.edu.gh';
```

You should see the user with their school_id and school_name.

### Check Data Isolation
```sql
-- Check students by school
SELECT 
  s.school_name,
  COUNT(st.id) as student_count
FROM public.school_settings s
LEFT JOIN public.students st ON s.id = st.school_id
GROUP BY s.school_name;
```

Each school should only see their own students.

## 🔄 ADDING ANOTHER SCHOOL

To add a second school (e.g., "ABC Academy"):

1. Repeat Step 1 with new school info:
```sql
INSERT INTO public.school_settings (
  school_name,
  school_address,
  school_phone,
  school_email,
  current_academic_year
) VALUES (
  'ABC Academy',
  '456 Academy Road, Kumasi',
  '+233 50 987 6543',
  'info@abc.edu.gh',
  '2024/2025'
)
RETURNING id;
```

2. Copy the new school_id

3. Create admin user with the new school_id in metadata

4. Copy default subjects and grading scale with the new school_id

5. Test login - ABC Academy admin should NOT see MOMA School's data!

## 🔒 SECURITY NOTES

- **Data Isolation**: Each school can ONLY see their own data
- **Automatic Filtering**: The database automatically filters data by school_id
- **No Cross-School Access**: Even if you know another school's student ID, you cannot access their data
- **Admin Separation**: Each school has their own admin(s)

## 🆘 TROUBLESHOOTING

### Problem: User can't login
- Check that "Auto Confirm User" was checked when creating the user
- Verify email confirmation is disabled in Supabase settings

### Problem: User sees no data after login
- Check that school_id is in the user's metadata
- Verify school_id matches a record in school_settings table
- Check that default subjects and grading scale were copied

### Problem: Error when adding students
- Verify the migration was run successfully
- Check that school_id column exists in students table
- Verify user's profile has school_id

### Problem: User sees data from other schools
- This should NEVER happen! Contact support immediately
- Check RLS policies are enabled on all tables
- Verify migration was run correctly

## 📞 SUPPORT

If you encounter any issues:
1. Check the browser console for error messages
2. Check Supabase logs in Dashboard → Logs
3. Verify all migration steps were completed
4. Check that user metadata includes school_id

## 🎉 SUCCESS!

Once you've registered your first school and can login, add students, and see them in the database, your multi-tenancy system is working correctly!

You can now:
- Register multiple schools
- Each school operates independently
- All data is automatically isolated
- No risk of data leakage between schools
