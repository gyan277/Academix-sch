# 🚀 Complete Setup Instructions

## What's Been Done

✅ **Supabase Integration Started**
- Login page now uses Supabase authentication
- Auth hook updated to sign out from Supabase
- Database schema ready (12 tables)
- TypeScript types defined
- Environment variables configured

## What You Need to Do

### Step 1: Create Supabase Account (5 minutes)

1. Go to **https://supabase.com**
2. Click "Start your project" and sign up
3. Click "New Project"
4. Fill in:
   - **Name:** School Management System
   - **Database Password:** (create a strong password - SAVE THIS!)
   - **Region:** Choose closest to your location
5. Click "Create new project"
6. **Wait 2-3 minutes** for project to initialize ⏳

---

### Step 2: Get Your Credentials (1 minute)

1. In your Supabase dashboard, click **Settings** (gear icon in sidebar)
2. Click **API** in the settings menu
3. You'll see two important values:

   **Copy these:**
   - **Project URL** (looks like: `https://xxxxx.supabase.co`)
   - **anon public key** (long string starting with `eyJ...`)

---

### Step 3: Update .env File (30 seconds)

1. Open the `.env` file in your project root
2. Replace the placeholder values with your actual credentials:

```env
VITE_SUPABASE_URL=https://your-actual-project-id.supabase.co
VITE_SUPABASE_ANON_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.your-actual-key-here
```

**Example:**
```env
VITE_SUPABASE_URL=https://abcdefghijk.supabase.co
VITE_SUPABASE_ANON_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImFiY2RlZmdoaWprIiwicm9sZSI6ImFub24iLCJpYXQiOjE2ODk1MjM0NTYsImV4cCI6MjAwNTA5OTQ1Nn0.abc123xyz
```

---

### Step 4: Create Database Tables (2 minutes)

1. In Supabase dashboard, click **SQL Editor** (in sidebar)
2. Click **New query**
3. Open the file `SUPABASE_SETUP.md` in your project
4. Copy **ALL the SQL** from "Step 4: Create Database Tables" section
5. Paste it into the SQL Editor
6. Click **Run** (or press Ctrl+Enter)
7. Wait for "Success ✓" message

**What this does:**
- Creates 12 tables (students, staff, grades, attendance, etc.)
- Sets up relationships between tables
- Adds indexes for performance
- Creates triggers for auto-updating timestamps

---

### Step 5: Set Up Security Policies (1 minute)

1. Still in **SQL Editor**, click **New query**
2. Open `SUPABASE_SETUP.md` again
3. Copy **ALL the SQL** from "Step 5: Set Up Row Level Security (RLS)" section
4. Paste and click **Run**
5. Wait for "Success ✓"

**What this does:**
- Enables Row Level Security on all tables
- Sets up role-based access control
- Ensures teachers can only see their data
- Gives admins full access

---

### Step 6: Insert Sample Data (1 minute)

1. In **SQL Editor**, click **New query**
2. Copy SQL from "Step 6: Insert Sample Data" in `SUPABASE_SETUP.md`
3. Paste and **Run**

**What this does:**
- Creates default school settings
- Adds subjects (English, Math, Science, etc.)
- Creates current academic term

---

### Step 7: Create Your Admin User (2 minutes)

#### Part A: Create Auth User
1. In Supabase, go to **Authentication** → **Users** (in sidebar)
2. Click **Add user** → **Create new user**
3. Fill in:
   - **Email:** admin@school.edu (or your preferred email)
   - **Password:** (create a strong password - SAVE THIS!)
   - **Auto Confirm User:** ✓ Check this box
4. Click **Create user**
5. **IMPORTANT:** Copy the **User ID** (looks like: `12345678-1234-5678-1234-567812345678`)

#### Part B: Add User Profile
1. Go back to **SQL Editor**
2. Run this query (replace `YOUR_USER_ID` with the ID you copied):

```sql
INSERT INTO public.users (id, email, full_name, role, phone)
VALUES (
  'YOUR_USER_ID_HERE',
  'admin@school.edu',
  'Administrator',
  'admin',
  '+233501234567'
);
```

**Example:**
```sql
INSERT INTO public.users (id, email, full_name, role, phone)
VALUES (
  '12345678-1234-5678-1234-567812345678',
  'admin@school.edu',
  'Administrator',
  'admin',
  '+233501234567'
);
```

---

### Step 8: Create Storage Bucket for Files (1 minute)

1. In Supabase, go to **Storage** (in sidebar)
2. Click **New bucket**
3. Fill in:
   - **Name:** school-assets
   - **Public bucket:** ✓ Check this
4. Click **Create bucket**

**What this is for:**
- School logos
- Headmaster signatures
- Student photos
- Staff photos

---

### Step 9: Restart Your Development Server (30 seconds)

1. Stop your current server (press `Ctrl+C` in terminal)
2. Run:
```bash
pnpm dev
```

---

### Step 10: Test Login (1 minute)

1. Open your browser to `http://localhost:8081` (or whatever port is shown)
2. You should see the login page
3. Enter:
   - **Email:** admin@school.edu (or the email you used)
   - **Password:** (the password you created)
4. Click **Sign In**
5. You should be redirected to the Dashboard! 🎉

---

## ✅ Verification Checklist

After completing all steps, verify:

- [ ] `.env` file has your actual Supabase URL and key
- [ ] All SQL queries ran successfully (no errors)
- [ ] Admin user created in Authentication tab
- [ ] Admin user profile exists in `public.users` table
- [ ] Storage bucket `school-assets` created
- [ ] Development server restarted
- [ ] Can login with admin credentials
- [ ] Redirected to dashboard after login

---

## 🐛 Troubleshooting

### Error: "Missing Supabase environment variables"
**Solution:** 
- Check `.env` file has both `VITE_SUPABASE_URL` and `VITE_SUPABASE_ANON_KEY`
- Make sure there are no extra spaces
- Restart dev server after editing `.env`

### Error: "Invalid email or password"
**Solution:**
- Check you're using the correct email and password
- Verify user exists in **Authentication** → **Users**
- Make sure you checked "Auto Confirm User" when creating

### Error: "User profile not found"
**Solution:**
- Go to **SQL Editor** and run:
```sql
SELECT * FROM public.users;
```
- If empty, you need to run the INSERT query from Step 7 Part B
- Make sure the user ID matches the one from Authentication tab

### Error: "relation does not exist"
**Solution:**
- You need to run the database setup SQL from Step 4
- Go to **SQL Editor** and run all the CREATE TABLE statements

### Can't see any data in tables
**Solution:**
- Go to **Table Editor** in Supabase
- Click on any table (e.g., `students`, `users`)
- Check if tables exist
- If not, re-run Step 4 SQL

### Login works but redirects to blank page
**Solution:**
- Check browser console for errors (F12)
- Make sure all tables were created successfully
- Verify RLS policies were set up (Step 5)

---

## 📊 What's Working Now

✅ **Authentication**
- Login with Supabase
- Secure session management
- Role-based access control
- Proper logout

⏳ **Still Using Mock Data**
- Dashboard statistics
- Student/Staff lists
- Attendance records
- Grades and reports

---

## 🔜 Next Steps

Once login is working, I'll integrate:

1. **Dashboard** - Real statistics from database
2. **Registrar** - Add/edit/delete students and staff
3. **Attendance** - Mark and track attendance
4. **Academic** - Enter grades and generate reports
5. **Settings** - School configuration and file uploads

---

## 📞 Need Help?

If you get stuck:
1. Check the error message in browser console (F12)
2. Look at Supabase logs: **Logs** → **API** in dashboard
3. Verify each step was completed
4. Check `SUPABASE_SETUP.md` for detailed SQL

---

## 🎉 Success!

Once you can login successfully, you're ready for the next phase of integration!

**Current Status:**
- ✅ Supabase project created
- ✅ Database tables created
- ✅ Security policies set up
- ✅ Admin user created
- ✅ Login working with Supabase
- 🔄 Ready to integrate other pages

Let me know when login is working and we'll continue! 🚀
