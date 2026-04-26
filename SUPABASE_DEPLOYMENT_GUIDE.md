# Supabase Deployment Guide

## Step 1: Run the SQL Script

1. Go to your Supabase Dashboard: https://supabase.com/dashboard
2. Select your project
3. Click on **SQL Editor** in the left sidebar
4. Click **New Query**
5. Copy the entire contents of `supabase-setup.sql`
6. Paste it into the SQL editor
7. Click **Run** (or press Ctrl/Cmd + Enter)

✅ This will create all tables, relationships, security policies, and sample data.

## Step 2: Create Your First Admin User

### Option A: Using Supabase Dashboard (Recommended)

1. Go to **Authentication** → **Users** in your Supabase dashboard
2. Click **Add user** → **Create new user**
3. Fill in:
   - **Email**: your-admin@example.com
   - **Password**: Choose a strong password
   - **Auto Confirm User**: ✅ Check this box
4. Click **Create user**

### Option B: Using Your Application

1. Start your application: `pnpm dev`
2. Go to the login page
3. Sign up with your admin credentials
4. The user will be created automatically

## Step 3: Set User Role to Admin

After creating the user, you need to set their role to 'admin':

1. Go to **SQL Editor** in Supabase
2. Run this query (replace the email with your admin email):

```sql
UPDATE public.users 
SET role = 'admin', full_name = 'Admin User'
WHERE email = 'your-admin@example.com';
```

## Step 4: Verify Everything Works

1. Start your application: `pnpm dev`
2. Log in with your admin credentials
3. You should have access to all features:
   - Dashboard
   - Student Registration (Registrar)
   - Attendance Management
   - Academic Records
   - Reports
   - Settings

## What Was Created

### Tables
- ✅ **users** - System users (admin, teacher, registrar)
- ✅ **students** - Student records
- ✅ **staff** - Staff members
- ✅ **subjects** - Academic subjects (8 default subjects included)
- ✅ **grades** - Student grades and scores
- ✅ **attendance** - Daily attendance records
- ✅ **teacher_classes** - Teacher-class assignments
- ✅ **school_settings** - School configuration

### Security Features
- ✅ Row Level Security (RLS) enabled on all tables
- ✅ Role-based access control policies
- ✅ Automatic user creation on signup
- ✅ Secure data access based on user roles

### Automatic Features
- ✅ Auto-calculate total scores (class_score + exam_score)
- ✅ Auto-calculate grades (A, B, C, D, E, F)
- ✅ Auto-update timestamps on record changes
- ✅ Prevent duplicate attendance entries
- ✅ Prevent duplicate grade entries

### Sample Data Included
- ✅ 8 default subjects (Math, English, Science, etc.)
- ✅ Default school settings

## Troubleshooting

### Issue: "permission denied for table users"
**Solution**: Make sure you ran the entire SQL script, including the GRANT statements at the end.

### Issue: "relation 'public.users' does not exist"
**Solution**: The SQL script didn't run completely. Try running it again.

### Issue: Can't log in after creating user
**Solution**: 
1. Check that the user exists in Authentication → Users
2. Verify the user has a role in the public.users table
3. Make sure you confirmed the user's email (or enabled auto-confirm)

### Issue: Teacher can't access certain features
**Solution**: Teachers only have access to Attendance and Academic pages. This is by design for security.

## Next Steps

1. ✅ Create additional users (teachers, registrars)
2. ✅ Add students via the Registrar page
3. ✅ Assign teachers to classes
4. ✅ Start marking attendance
5. ✅ Enter student grades
6. ✅ Generate reports

## Security Notes

- 🔒 All tables have Row Level Security enabled
- 🔒 Users can only access data based on their role
- 🔒 Teachers can only modify their own grades
- 🔒 Only admins can delete records
- 🔒 Registrars can only manage student records

Your school management system is now fully configured and ready to use! 🎉
