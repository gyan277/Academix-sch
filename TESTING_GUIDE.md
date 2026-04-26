# Testing Guide - School Management System

## ✅ What Was Changed

All hardcoded localStorage authentication has been removed. The app now uses **real Supabase authentication**:

- ✅ Authentication state managed by Supabase Auth
- ✅ User profiles loaded from `public.users` table
- ✅ Teacher class assignments loaded from `public.teacher_classes` table
- ✅ Real-time auth state changes
- ✅ Proper loading states
- ✅ Role-based route protection

## 🚀 How to Test

### Step 1: Make Sure Database is Set Up

1. Go to Supabase SQL Editor
2. Run the entire `supabase-setup.sql` script
3. Verify tables were created

### Step 2: Create Test Users

Run these SQL commands in Supabase SQL Editor:

```sql
-- First, create users in Supabase Auth (do this via Supabase Dashboard > Authentication > Users)
-- Then update their roles:

-- Make user an admin
UPDATE public.users 
SET role = 'admin', full_name = 'Admin User'
WHERE email = 'admin@school.com';

-- Make user a teacher
UPDATE public.users 
SET role = 'teacher', full_name = 'Teacher User'
WHERE email = 'teacher@school.com';

-- Make user a registrar
UPDATE public.users 
SET role = 'registrar', full_name = 'Registrar User'
WHERE email = 'registrar@school.com';
```

### Step 3: Start the Application

```bash
pnpm dev
```

### Step 4: Test Login

1. Go to http://localhost:8080
2. You'll be redirected to `/login`
3. Try logging in with your test credentials

### Step 5: Test Role-Based Access

**Admin User** should have access to:
- ✅ Dashboard
- ✅ Registrar
- ✅ Academic
- ✅ Attendance
- ✅ Communication
- ✅ Reports
- ✅ Settings

**Teacher User** should have access to:
- ✅ Attendance
- ✅ Academic
- ❌ Everything else (redirects to /attendance)

**Registrar User** should have access to:
- ✅ Registrar
- ❌ Everything else (redirects to /registrar)

## 🧪 Test Scenarios

### Test 1: Login Flow
1. Open app → Should redirect to `/login`
2. Enter valid credentials → Should login and redirect based on role
3. Check that user name appears in the UI

### Test 2: Protected Routes
1. Try accessing `/dashboard` without login → Should redirect to `/login`
2. Login as teacher → Try accessing `/dashboard` → Should redirect to `/attendance`
3. Login as admin → Should access all routes

### Test 3: Logout
1. Login as any user
2. Click logout button
3. Should redirect to `/login`
4. Try accessing protected route → Should redirect to `/login`

### Test 4: Session Persistence
1. Login as any user
2. Refresh the page
3. Should remain logged in (Supabase session persists)

## 🐛 Troubleshooting

### Issue: "User profile not found"
**Solution**: Make sure the user exists in both `auth.users` AND `public.users` tables. The trigger should create the profile automatically, but you can manually insert:

```sql
INSERT INTO public.users (id, email, full_name, role)
VALUES (
  'user-uuid-from-auth-users',
  'user@example.com',
  'Full Name',
  'admin'
);
```

### Issue: Infinite loading
**Solution**: Check browser console for errors. Make sure Supabase URL and keys are correct in `.env`

### Issue: Can't access certain pages
**Solution**: Check the user's role in the database:
```sql
SELECT email, role FROM public.users WHERE email = 'your-email@example.com';
```

## 📝 Notes

- No more localStorage for authentication
- Session is managed by Supabase (stored in browser's IndexedDB)
- User profile is fetched on every page load
- Auth state changes are detected automatically
- Loading states prevent flash of wrong content

Ready to test! 🎉
