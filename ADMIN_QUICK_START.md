# Admin Quick Start Guide

A quick reference for setting up your school management system.

## 🚀 Initial Setup (One-time)

### Step 1: Set Up Database (5 minutes)

1. Create Supabase account at [supabase.com](https://supabase.com)
2. Create new project (choose name, password, region)
3. Go to **SQL Editor** → **New Query**
4. Copy entire `COMPLETE_DATABASE_SETUP.sql` file
5. Paste and click **Run**
6. Wait for "Success" message

### Step 2: Configure Authentication (2 minutes)

1. Go to **Authentication** → **Settings**
2. Set these:
   - ✅ Enable sign ups: **ON**
   - ✅ Enable email confirmations: **OFF**
3. Click **Save**

### Step 3: Create Admin Account (3 minutes)

1. Go to **Authentication** → **Users** → **Add User**
2. Enter your email and password
3. Check **"Auto Confirm User"**
4. Click **Create user**
5. Go to **SQL Editor** and run:
   ```sql
   UPDATE public.users 
   SET role = 'admin', full_name = 'Your Name' 
   WHERE email = 'your-email@school.com';
   ```

### Step 4: Configure Application (2 minutes)

1. Open `.env` file in project
2. Update with your Supabase credentials:
   ```env
   VITE_SUPABASE_URL=https://xxxxx.supabase.co
   VITE_SUPABASE_ANON_KEY=your-key-here
   ```
3. Save file

### Step 5: Deploy (5 minutes)

Choose one option:

**Option A: Vercel (Easiest)**
```bash
npm install -g vercel
pnpm build
vercel --prod
```

**Option B: Netlify**
```bash
npm install -g netlify-cli
pnpm build
netlify deploy --prod --dir=dist/spa
```

**Option C: Your Server**
```bash
pnpm build
# Copy dist/ folder to server
node dist/server/node-build.mjs
```

---

## 📋 Daily Operations

### Adding a New Teacher

1. Login as admin
2. Go to **Settings** page
3. Scroll to **"Teacher Management"**
4. Click **"Add New Teacher"**
5. Fill in:
   - Email (e.g., teacher@school.com)
   - Full Name
   - Phone
   - Click **"Generate"** for password
   - Select classes (optional)
6. Click **"Create Teacher"**
7. **Copy credentials** and share with teacher securely

### Adding Students

1. Go to **Registrar** page
2. Click **"Add New Student"**
3. Fill in all required fields:
   - Student ID
   - Full Name
   - Date of Birth
   - Gender
   - Class
   - Parent Name
   - Parent Phone
4. Click **"Add Student"**

### Adding Staff

1. Go to **Registrar** page
2. Switch to **"Staff"** tab
3. Click **"Add New Staff"**
4. Fill in details
5. Click **"Add Staff"**

### Updating School Settings

1. Go to **Settings** page
2. Update:
   - School Name
   - Address
   - Phone
   - Email
   - Academic Year
3. Click **"Save Settings"**

---

## 👥 User Roles & Access

### Admin (You)
- ✅ Full access to everything
- ✅ Create teacher accounts
- ✅ View all reports
- ✅ Manage settings
- ✅ Add students and staff

### Teachers
- ✅ Mark student attendance
- ✅ Enter exam scores
- ✅ Generate report cards
- ❌ Cannot create other users
- ❌ Cannot access settings

### Registrar
- ✅ Add/edit students
- ✅ Add/edit staff
- ✅ View student records
- ❌ Cannot mark attendance
- ❌ Cannot enter scores

---

## 🔧 Common Tasks

### Reset a Teacher's Password

**Option 1: Through Application**
1. Go to **Settings** → **Teacher Management**
2. Find the teacher
3. Click the **Key icon** (Reset Password)
4. Teacher will receive reset email

**Option 2: Through Supabase**
1. Go to Supabase → **Authentication** → **Users**
2. Find the user
3. Click **"..."** → **"Send Password Reset Email"**

### Deactivate a Teacher Account

1. Go to **Settings** → **Teacher Management**
2. Find the teacher
3. Click the **Power icon** (Toggle Status)
4. Status changes to "inactive"
5. Teacher can no longer login

### View All Teachers

1. Go to **Settings** page
2. Scroll to **"Teacher Management"**
3. All teachers are listed with:
   - Name
   - Email
   - Phone
   - Assigned classes
   - Status (active/inactive)

### Export Student Data

1. Go to **Registrar** page
2. Click **"Export to Excel"** button
3. Excel file downloads with all student data

### Generate Report Cards

1. Go to **Academic** page
2. Select class and subject
3. Enter scores for all students
4. Click **"Generate Reports"**
5. Switch to **"Reports"** tab
6. Click **"Download All Reports (PDF)"**

---

## 🆘 Troubleshooting

### Teacher Can't Login

**Problem**: "Invalid email or password"

**Solution**:
1. Go to Supabase → **SQL Editor**
2. Run this (replace email):
   ```sql
   UPDATE auth.users 
   SET email_confirmed_at = NOW()
   WHERE email = 'teacher@school.com';
   ```

### User Profile Not Found

**Problem**: Login works but shows "User profile not found"

**Solution**:
1. Check if user exists in `public.users` table
2. If not, run this SQL:
   ```sql
   INSERT INTO public.users (id, email, full_name, role, status)
   SELECT id, email, 'Full Name', 'teacher', 'active'
   FROM auth.users
   WHERE email = 'teacher@school.com';
   ```

### Dashboard Shows Zero

**This is normal!** Dashboard shows real data only. As you add:
- Students → Enrollment count increases
- Attendance → Attendance rate shows
- Staff → Staff count updates

### Can't See Students in Attendance

**Problem**: Attendance page is empty

**Reason**: No students added yet

**Solution**: Go to **Registrar** → Add students first

---

## 📞 Support Checklist

Before asking for help, check:

1. ✅ Supabase project is active
2. ✅ `.env` file has correct credentials
3. ✅ Email confirmations are disabled in Supabase
4. ✅ Sign ups are enabled in Supabase
5. ✅ User exists in both `auth.users` and `public.users`
6. ✅ Browser console (F12) for error messages

---

## 🎯 Quick Reference

| Task | Page | Action |
|------|------|--------|
| Add Teacher | Settings | Teacher Management → Add New Teacher |
| Add Student | Registrar | Students tab → Add New Student |
| Add Staff | Registrar | Staff tab → Add New Staff |
| Mark Attendance | Attendance | Select class → Mark students |
| Enter Scores | Academic | Select class/subject → Enter scores |
| Generate Reports | Academic | Enter scores → Generate Reports |
| Update School Info | Settings | School Settings → Save |
| View Teachers | Settings | Teacher Management section |
| Export Data | Registrar | Export to Excel button |

---

## 📱 Mobile Access

Teachers can access the system on their phones:
- ✅ Responsive design works on all devices
- ✅ Teachers can mark attendance on mobile
- ✅ Teachers can enter scores on mobile
- ✅ All features work on tablets and phones

---

**Need Help?** Check `DEPLOYMENT_GUIDE.md` for detailed instructions.
