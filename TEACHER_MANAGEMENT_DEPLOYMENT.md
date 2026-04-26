# Teacher Management Feature - Deployment Guide

## Overview

This guide provides instructions for deploying the Admin Teacher Management feature to your Supabase instance.

## Prerequisites

- Access to Supabase SQL Editor
- Admin user account in the system
- Existing database schema from `supabase-setup.sql`

## Deployment Steps

### Step 1: Run Database Migration

Execute the SQL migration to add the `status` column to the users table:

```sql
-- Add status column to users table for teacher account management
ALTER TABLE public.users 
ADD COLUMN IF NOT EXISTS status TEXT NOT NULL DEFAULT 'active' 
CHECK (status IN ('active', 'inactive'));

-- Create index for performance when filtering by status
CREATE INDEX IF NOT EXISTS idx_users_status ON public.users(status);

-- Update existing users to have active status
UPDATE public.users 
SET status = 'active' 
WHERE status IS NULL;
```

**Location**: `database-migrations/add-status-column.sql`

**How to run**:
1. Open your Supabase project dashboard
2. Navigate to SQL Editor
3. Copy and paste the migration SQL
4. Click "Run" to execute

### Step 2: Verify RLS Policies

Ensure the following RLS policies exist on the `users` table (these should already be in place from `supabase-setup.sql`):

- ✅ "Admins can view all users" - Allows admins to see all teacher accounts
- ✅ "Admins can insert users" - Allows admins to create teacher accounts
- ✅ "Admins can update users" - Allows admins to edit teacher information

### Step 3: Deploy Application Code

The following files have been created/modified:

**New Files**:
- `client/components/TeacherManagement.tsx` - Main teacher management component
- `client/lib/teacher-utils.ts` - Validation and utility functions
- `database-migrations/add-status-column.sql` - Database migration

**Modified Files**:
- `shared/types.ts` - Added teacher-related TypeScript interfaces
- `client/pages/Settings.tsx` - Integrated Teachers tab (admin-only)

**Deployment**:
1. Commit all changes to your repository
2. Push to your deployment branch
3. Your hosting platform (Netlify/Vercel) will automatically deploy

### Step 4: Verify Deployment

1. **Login as Admin**:
   - Navigate to `/settings`
   - Verify "Teachers" tab is visible

2. **Test Teacher Creation**:
   - Click "Add New Teacher"
   - Fill in required fields
   - Submit form
   - Verify credentials dialog appears
   - Verify teacher appears in list

3. **Test Teacher Editing**:
   - Click edit button on a teacher card
   - Modify information
   - Save changes
   - Verify updates appear in list

4. **Test Status Toggle**:
   - Click power button to deactivate a teacher
   - Verify status badge changes to "inactive"
   - Try logging in as that teacher (should fail)
   - Reactivate the teacher
   - Verify login works again

5. **Test Password Reset**:
   - Click key button on a teacher card
   - Verify credentials dialog shows new password
   - Copy password
   - Login as that teacher with new password

6. **Test Access Control**:
   - Logout
   - Login as a teacher or registrar user
   - Navigate to `/settings`
   - Verify "Teachers" tab is NOT visible

## Feature Capabilities

### For Administrators

1. **Create Teacher Accounts**:
   - Email, full name, phone, password
   - Optional class assignments
   - Automatic credential generation
   - One-time credential display

2. **Edit Teacher Information**:
   - Update name and phone
   - Modify class assignments
   - Email cannot be changed (security)

3. **Manage Account Status**:
   - Activate/deactivate accounts
   - Inactive accounts cannot login
   - Status visible in teacher list

4. **Reset Passwords**:
   - Generate secure temporary passwords
   - Display credentials to admin
   - Teacher can change password after login

5. **View Teacher List**:
   - All teachers sorted alphabetically
   - Status badges (active/inactive)
   - Assigned classes displayed
   - Quick action buttons

### Security Features

- ✅ Admin-only access (role-based)
- ✅ RLS policies enforce database security
- ✅ Passwords never stored in application state
- ✅ One-time credential display
- ✅ Input validation on all fields
- ✅ Secure password generation
- ✅ Error handling with user-friendly messages

## Troubleshooting

### Teachers Tab Not Visible

**Problem**: Admin user doesn't see Teachers tab in Settings

**Solution**:
1. Verify user has role "admin" in users table:
   ```sql
   SELECT id, email, role FROM public.users WHERE email = 'your-admin@email.com';
   ```
2. If role is not "admin", update it:
   ```sql
   UPDATE public.users SET role = 'admin' WHERE email = 'your-admin@email.com';
   ```

### Cannot Create Teachers

**Problem**: Error when trying to create teacher account

**Solution**:
1. Check Supabase Auth settings:
   - Ensure email confirmations are disabled for admin-created users
   - Verify admin API access is enabled
2. Check RLS policies:
   ```sql
   SELECT * FROM pg_policies WHERE tablename = 'users';
   ```
3. Verify admin user has correct permissions

### Status Column Missing

**Problem**: Error about missing "status" column

**Solution**:
1. Run the database migration from Step 1
2. Verify column exists:
   ```sql
   SELECT column_name, data_type FROM information_schema.columns 
   WHERE table_name = 'users' AND column_name = 'status';
   ```

### Teacher Cannot Login After Creation

**Problem**: Newly created teacher cannot login

**Possible Causes**:
1. Account status is "inactive" - Check and activate
2. Password was not copied correctly - Reset password
3. Email confirmation required - Disable in Supabase Auth settings

## Database Schema Changes

### users Table

**Added Column**:
```sql
status TEXT NOT NULL DEFAULT 'active' CHECK (status IN ('active', 'inactive'))
```

**Added Index**:
```sql
CREATE INDEX idx_users_status ON public.users(status);
```

### No Changes Required For:
- `teacher_classes` table (already exists)
- `auth.users` table (managed by Supabase)
- RLS policies (already configured)

## API Endpoints

This feature uses Supabase client-side SDK exclusively. No custom API endpoints required.

**Supabase Operations Used**:
- `supabase.auth.admin.createUser()` - Create teacher auth account
- `supabase.auth.admin.updateUserById()` - Reset password
- `supabase.from('users').select()` - Fetch teachers
- `supabase.from('users').update()` - Update teacher info
- `supabase.from('teacher_classes').insert()` - Assign classes
- `supabase.from('teacher_classes').delete()` - Remove class assignments

## Support

For issues or questions:
1. Check Supabase logs in dashboard
2. Check browser console for errors
3. Verify RLS policies are correct
4. Ensure admin user has correct role

## Next Steps

After successful deployment, consider:
1. Creating your first teacher accounts
2. Assigning classes to teachers
3. Testing teacher login and access
4. Training admin staff on the interface
5. Documenting your school's teacher onboarding process
