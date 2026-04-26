# Supabase Quick Start - 5 Minutes Setup

## 🎯 Goal
Connect your School Management System to Supabase database

## ⚡ Steps (5 minutes)

### 1️⃣ Create Supabase Project (2 min)
```
1. Go to: https://supabase.com
2. Click "Start your project"
3. Sign up with GitHub/Google
4. Click "New Project"
5. Fill in:
   - Name: School Management System
   - Password: (create strong password)
   - Region: (choose closest)
6. Click "Create new project"
7. Wait 2-3 minutes ⏳
```

### 2️⃣ Get Credentials (30 sec)
```
1. In dashboard: Settings → API
2. Copy these two values:
   ✓ Project URL
   ✓ anon public key
```

### 3️⃣ Update .env File (30 sec)
```bash
# Open .env file and paste your values:
VITE_SUPABASE_URL=https://xxxxx.supabase.co
VITE_SUPABASE_ANON_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...
```

### 4️⃣ Create Database (1 min)
```
1. In Supabase: SQL Editor
2. Open SUPABASE_SETUP.md
3. Copy ALL the SQL (Step 4 section)
4. Paste in SQL Editor
5. Click "Run" ▶️
6. Wait for "Success" ✅
```

### 5️⃣ Create Admin User (1 min)
```
1. Authentication → Users → "Add user"
2. Email: admin@school.edu
3. Password: (your choice - save it!)
4. Auto Confirm User: ✓ Yes
5. Click "Create user"
6. Copy the User ID (looks like: 12345678-1234-...)
7. Go back to SQL Editor
8. Run this (replace USER_ID):

INSERT INTO public.users (id, email, full_name, role)
VALUES ('YOUR_USER_ID_HERE', 'admin@school.edu', 'Administrator', 'admin');
```

### 6️⃣ Restart Server (10 sec)
```bash
# Stop current server (Ctrl+C)
pnpm dev
```

## ✅ Done!

Your app is now connected to Supabase!

Login with:
- **Email:** admin@school.edu
- **Password:** (what you set in step 5)

---

## 🆘 Quick Fixes

### "Missing environment variables"
→ Check `.env` file has both VITE_SUPABASE_URL and VITE_SUPABASE_ANON_KEY

### "relation does not exist"
→ Run the database SQL again in SQL Editor

### Can't login
→ Make sure you ran the INSERT INTO users command with correct user ID

### Still stuck?
→ Check `DATABASE_INTEGRATION_GUIDE.md` for detailed help

---

## 📊 What You Get

✅ **12 Database Tables** - Students, Staff, Grades, Attendance, etc.
✅ **Security** - Row Level Security enabled
✅ **Authentication** - User management built-in
✅ **File Storage** - For logos and photos
✅ **Real-time** - Live updates
✅ **Free Tier** - 500MB database, 1GB storage

---

## 🎓 Next: Connect Frontend

Once database is set up, we'll connect:
1. Login page → Supabase Auth
2. Student management → students table
3. Grades → grades table
4. Attendance → attendance table
5. Settings → school_settings table

**Ready to integrate? Let me know!** 🚀
