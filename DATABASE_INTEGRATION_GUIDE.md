# Database Integration Guide - Supabase

## ✅ What's Been Set Up

### 1. **Supabase Client Installed**
- ✅ `@supabase/supabase-js` package added
- ✅ Client configuration created at `client/lib/supabase.ts`
- ✅ TypeScript types defined for all tables

### 2. **Environment Variables Ready**
- ✅ `.env` file updated with Supabase placeholders
- ✅ Variables prefixed with `VITE_` for Vite compatibility

### 3. **Complete Database Schema**
- ✅ 12 tables designed for full school management
- ✅ Row Level Security (RLS) policies
- ✅ Indexes for performance
- ✅ Triggers for auto-updating timestamps

---

## 🚀 Quick Start (5 Steps)

### Step 1: Create Supabase Account
1. Go to [https://supabase.com](https://supabase.com)
2. Sign up (free tier is perfect to start)
3. Create a new project
4. Wait 2-3 minutes for setup

### Step 2: Get Your Credentials
1. In Supabase dashboard: **Settings** → **API**
2. Copy:
   - **Project URL**
   - **anon/public key**

### Step 3: Update .env File
Open `.env` and replace:
```env
VITE_SUPABASE_URL=https://your-project.supabase.co
VITE_SUPABASE_ANON_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...
```

### Step 4: Run Database Setup
1. Open Supabase **SQL Editor**
2. Copy the entire SQL from `SUPABASE_SETUP.md`
3. Click "Run"
4. Wait for success message

### Step 5: Create Admin User
1. **Authentication** → **Users** → "Add user"
2. Email: `admin@school.edu`
3. Password: (your choice)
4. Auto Confirm: Yes
5. Copy the user ID
6. Run in SQL Editor:
```sql
INSERT INTO public.users (id, email, full_name, role)
VALUES ('paste-user-id-here', 'admin@school.edu', 'Administrator', 'admin');
```

### Step 6: Restart Server
```bash
pnpm dev
```

---

## 📊 Database Schema Overview

### Core Tables

#### 1. **users** (Authentication & Roles)
- Extends Supabase auth.users
- Stores role (admin/teacher/registrar)
- Links to all user actions

#### 2. **students** (Student Records)
- Full student information
- Parent/guardian details
- Class assignments
- Status tracking

#### 3. **staff** (Staff Records)
- Employee information
- Position and specialization
- Employment history

#### 4. **grades** (Academic Performance)
- Class scores (30%)
- Exam scores (70%)
- Auto-calculated totals
- Grade assignments

#### 5. **attendance** (Student Attendance)
- Daily attendance records
- Status: present/absent/late
- Teacher tracking

#### 6. **staff_attendance** (Staff Attendance)
- Clock in/out times
- Daily status

#### 7. **subjects** (Course Catalog)
- Subject names and codes
- Descriptions

#### 8. **teacher_classes** (Class Assignments)
- Links teachers to classes
- Multiple class support

#### 9. **sms_log** (Communication History)
- SMS records
- Delivery status
- Recipient tracking

#### 10. **terms** (Academic Calendar)
- Term dates
- Academic year tracking
- Current term flag

#### 11. **school_settings** (Configuration)
- School information
- Logo and signature URLs
- System settings

#### 12. **calendar_events** (Events)
- Holidays, exams, meetings
- Event types and dates

---

## 🔒 Security Features

### Row Level Security (RLS)
- ✅ All tables protected
- ✅ Role-based access control
- ✅ Teachers can only access their data
- ✅ Admins have full access

### Authentication
- ✅ Supabase Auth integration
- ✅ Secure password hashing
- ✅ JWT tokens
- ✅ Session management

---

## 🔌 API Integration Examples

### Example 1: Fetch Students
```typescript
import { supabase } from '@/lib/supabase';

const { data, error } = await supabase
  .from('students')
  .select('*')
  .eq('class', 'P1')
  .eq('status', 'active');
```

### Example 2: Add Student
```typescript
const { data, error } = await supabase
  .from('students')
  .insert({
    student_id: 'STU001',
    full_name: 'John Doe',
    date_of_birth: '2016-05-15',
    gender: 'Male',
    class: 'P1',
    parent_name: 'James Doe',
    parent_phone: '+233501234567',
    admission_date: new Date().toISOString().split('T')[0],
    status: 'active'
  });
```

### Example 3: Mark Attendance
```typescript
const { data, error } = await supabase
  .from('attendance')
  .insert({
    student_id: 'student-uuid',
    class: 'P1',
    date: new Date().toISOString().split('T')[0],
    status: 'present',
    marked_by: 'teacher-uuid'
  });
```

### Example 4: Enter Grades
```typescript
const { data, error } = await supabase
  .from('grades')
  .insert({
    student_id: 'student-uuid',
    subject_id: 'subject-uuid',
    class: 'P1',
    term: 'Term 1',
    academic_year: '2023/2024',
    class_score: 25,
    exam_score: 65,
    teacher_id: 'teacher-uuid'
  });
```

### Example 5: Authentication
```typescript
// Sign in
const { data, error } = await supabase.auth.signInWithPassword({
  email: 'admin@school.edu',
  password: 'your-password'
});

// Get current user
const { data: { user } } = await supabase.auth.getUser();

// Sign out
await supabase.auth.signOut();
```

---

## 📁 File Storage (for logos/photos)

### Setup Storage Bucket
```sql
-- Run in Supabase SQL Editor
INSERT INTO storage.buckets (id, name, public)
VALUES ('school-assets', 'school-assets', true);
```

### Upload File
```typescript
const { data, error } = await supabase.storage
  .from('school-assets')
  .upload('logos/school-logo.png', file);

// Get public URL
const { data: { publicUrl } } = supabase.storage
  .from('school-assets')
  .getPublicUrl('logos/school-logo.png');
```

---

## 🔄 Next Steps for Full Integration

### Phase 1: Authentication (Priority 1)
- [ ] Update Login.tsx to use Supabase auth
- [ ] Replace localStorage with Supabase session
- [ ] Add password reset functionality
- [ ] Implement proper logout

### Phase 2: Student Management (Priority 2)
- [ ] Connect Registrar page to students table
- [ ] Add real-time student CRUD operations
- [ ] Implement student search
- [ ] Add photo upload

### Phase 3: Academic Module (Priority 3)
- [ ] Connect grades table
- [ ] Implement score entry
- [ ] Generate reports from database
- [ ] Add grade history

### Phase 4: Attendance (Priority 4)
- [ ] Connect attendance table
- [ ] Real-time attendance marking
- [ ] Attendance reports
- [ ] Absence notifications

### Phase 5: Settings (Priority 5)
- [ ] Connect school_settings table
- [ ] File upload for logo/signature
- [ ] Term management
- [ ] Calendar events

---

## 🐛 Troubleshooting

### Error: "Missing Supabase environment variables"
**Solution:** Check `.env` file has correct values and restart server

### Error: "Row Level Security policy violation"
**Solution:** Make sure user is authenticated and has correct role

### Error: "relation does not exist"
**Solution:** Run the database setup SQL in Supabase SQL Editor

### Can't login
**Solution:** 
1. Check user exists in Authentication tab
2. Verify user record in public.users table
3. Check password is correct

### Data not showing
**Solution:**
1. Check RLS policies
2. Verify user role
3. Check browser console for errors

---

## 📚 Resources

- **Supabase Docs:** https://supabase.com/docs
- **Supabase JS Client:** https://supabase.com/docs/reference/javascript
- **RLS Guide:** https://supabase.com/docs/guides/auth/row-level-security
- **Storage Guide:** https://supabase.com/docs/guides/storage

---

## ✨ Benefits of This Setup

✅ **Scalable:** Handles thousands of students
✅ **Secure:** Row-level security built-in
✅ **Real-time:** Live updates across devices
✅ **Free Tier:** 500MB database, 1GB storage
✅ **Automatic Backups:** Daily backups included
✅ **API Auto-generated:** REST and GraphQL APIs
✅ **TypeScript Support:** Full type safety
✅ **Authentication:** Built-in user management

---

**You're all set! Follow the Quick Start guide above to get your database running.** 🎉
