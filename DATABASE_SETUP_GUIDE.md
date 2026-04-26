# Complete Database Setup Guide for MOMA School Management System

## Overview

This guide will help you set up a fresh database for your MOMA school management system with all the features including the new admin teacher management functionality.

## Step 1: Backup Your Current Database (Optional)

If you have existing data you want to keep:

1. Go to Supabase Dashboard → Database → Backups
2. Click "Create backup"
3. Wait for backup to complete

## Step 2: Run the Complete Database Setup Script

1. **Open Supabase SQL Editor**
   - Go to https://supabase.com/dashboard
   - Select your project
   - Click **SQL Editor** in the left sidebar

2. **Create a New Query**
   - Click **New Query** button

3. **Copy the SQL Script**
   - Open `COMPLETE_DATABASE_SETUP.sql`
   - Copy the entire contents (Ctrl+A, Ctrl+C)

4. **Paste and Run**
   - Paste into the SQL editor
   - Click **Run** (or press Ctrl/Cmd + Enter)
   - Wait for execution to complete (should take 5-10 seconds)

5. **Verify Success**
   - Scroll to the bottom of the results
   - You should see:
     - List of all tables created
     - List of all triggers created
     - List of all RLS policies created
     - 8 subjects in the subjects table
     - 1 school settings record

## Step 3: Create Your First Admin User

### Option A: Via Supabase Dashboard (Recommended)

1. **Go to Authentication**
   - Click **Authentication** in the left sidebar
   - Click **Users** tab

2. **Add New User**
   - Click **Add user** button
   - Select **Create new user**

3. **Fill in Details**
   - **Email**: `admin@moma.com` (or your preferred email)
   - **Password**: Choose a strong password (at least 8 characters)
   - **Auto Confirm User**: ✅ Check this box
   - Click **Create user**

4. **Update User Role to Admin**
   - Go back to **SQL Editor**
   - Run this query (replace email if you used a different one):
   
   ```sql
   UPDATE public.users 
   SET role = 'admin', full_name = 'Admin User'
   WHERE email = 'admin@moma.com';
   ```

5. **Verify Admin User**
   - Run this query to confirm:
   
   ```sql
   SELECT id, email, full_name, role, status 
   FROM public.users 
   WHERE email = 'admin@moma.com';
   ```
   
   - You should see your admin user with role = 'admin'

### Option B: Via SQL (Advanced)

If you prefer to do everything via SQL:

```sql
-- Note: You'll need to use Supabase Dashboard to create the auth user first,
-- then run this to update the profile:

UPDATE public.users 
SET role = 'admin', full_name = 'Admin User', status = 'active'
WHERE email = 'admin@moma.com';
```

## Step 4: Test Your Setup

1. **Start Your Application**
   ```bash
   pnpm dev
   ```

2. **Open in Browser**
   - Go to http://localhost:8082/

3. **Login**
   - Email: `admin@moma.com`
   - Password: (the password you set)

4. **Verify Access**
   - You should be redirected to the Dashboard
   - Check that you can access all pages:
     - ✅ Dashboard
     - ✅ Registrar
     - ✅ Academic
     - ✅ Attendance
     - ✅ Reports
     - ✅ Settings

5. **Check Teacher Management**
   - Go to Settings page
   - You should see a "Teachers" tab
   - Click on it to access teacher management

## What Was Created

### Tables (8 total)
1. **users** - System users (admin, teacher, registrar) with status field
2. **students** - Student records
3. **staff** - Staff members
4. **subjects** - Academic subjects (8 pre-loaded)
5. **grades** - Student grades and scores
6. **attendance** - Daily attendance records
7. **teacher_classes** - Teacher-class assignments
8. **school_settings** - School configuration

### Features
- ✅ Automatic timestamp updates
- ✅ Auto-calculate grades (A-F)
- ✅ Auto-create user profiles on signup
- ✅ Row Level Security (RLS) enabled
- ✅ Referential integrity (foreign keys)
- ✅ Unique constraints (no duplicates)
- ✅ Status field for users (active/inactive)
- ✅ Teacher class assignments

### Sample Data
- ✅ 8 subjects (Math, English, Science, etc.)
- ✅ Default school settings (MOMA School)

## Troubleshooting

### Issue: "relation already exists"

**Solution**: The script is designed to work with existing tables. If you want a completely fresh start, uncomment the DROP TABLE lines at the top of the script (lines 13-21).

### Issue: "permission denied"

**Solution**: Make sure you're running the script as the database owner. In Supabase, you should have full permissions by default.

### Issue: "trigger already exists"

**Solution**: The script uses `DROP TRIGGER IF EXISTS` before creating triggers, so this shouldn't happen. If it does, the script will continue anyway.

### Issue: Can't login after creating admin user

**Solution**: 
1. Check that the user exists in Authentication → Users
2. Verify the user profile exists:
   ```sql
   SELECT * FROM public.users WHERE email = 'admin@moma.com';
   ```
3. Make sure the role is set to 'admin':
   ```sql
   UPDATE public.users SET role = 'admin' WHERE email = 'admin@moma.com';
   ```

### Issue: "User profile not found"

**Solution**: The trigger should create the profile automatically. If it doesn't:
```sql
INSERT INTO public.users (id, email, full_name, role, status)
SELECT 
  id,
  email,
  'Admin User',
  'admin',
  'active'
FROM auth.users 
WHERE email = 'admin@moma.com'
ON CONFLICT (id) DO UPDATE 
SET role = 'admin', full_name = 'Admin User', status = 'active';
```

## Next Steps

Once your database is set up and you can login:

1. **Create Teacher Accounts**
   - Go to Settings → Teachers tab
   - Click "Add New Teacher"
   - Fill in teacher details
   - Assign classes (optional)
   - Copy the credentials to share with the teacher

2. **Add Students**
   - Go to Registrar page
   - Add student records

3. **Assign Classes to Teachers**
   - Go to Settings → Teachers tab
   - Edit a teacher
   - Select classes they should teach

4. **Start Using the System**
   - Mark attendance
   - Enter grades
   - Generate reports

## Security Notes

- 🔒 All tables have Row Level Security (RLS) enabled
- 🔒 Authorization is handled in the application layer
- 🔒 Passwords are hashed by Supabase Auth
- 🔒 Only authenticated users can access data
- 🔒 Admin features are protected by role checks

## Database Schema Diagram

```
auth.users (Supabase Auth)
    ↓ (1:1)
public.users (User Profiles)
    ↓ (1:N)
public.teacher_classes (Class Assignments)

public.students
    ↓ (1:N)
public.grades ← public.subjects
    ↑
public.users (teachers)

public.students
    ↓ (1:N)
public.attendance
    ↑
public.users (marked_by)
```

## Support

If you encounter any issues:
1. Check the browser console for errors (F12)
2. Check the Supabase logs in the Dashboard
3. Verify your .env file has correct Supabase URL and keys
4. Make sure your dev server is running (pnpm dev)

Your database is now ready! 🎉
