# School Management System - Deployment Guide

This guide will help you deploy the MOMA School Management System for production use.

## Prerequisites

- Node.js 18+ and pnpm installed
- A Supabase account (free tier works)
- A domain name (optional, but recommended)

## Step 1: Set Up Supabase Database

### 1.1 Create a Supabase Project

1. Go to [supabase.com](https://supabase.com) and sign up/login
2. Click **"New Project"**
3. Fill in:
   - **Project Name**: Your school name (e.g., "MOMA School")
   - **Database Password**: Choose a strong password (save this!)
   - **Region**: Choose closest to your location
4. Click **"Create new project"** and wait 2-3 minutes

### 1.2 Run Database Setup Script

1. In your Supabase project, go to **SQL Editor** (left sidebar)
2. Click **"New Query"**
3. Copy the entire contents of `COMPLETE_DATABASE_SETUP.sql`
4. Paste it into the SQL Editor
5. Click **"Run"** (or press Ctrl+Enter)
6. Wait for "Success. No rows returned" message

### 1.3 Configure Authentication Settings

1. Go to **Authentication** → **Settings** (or **Providers** → **Email**)
2. Configure these settings:
   - ✅ **Enable sign ups**: ON
   - ✅ **Enable email confirmations**: OFF (important!)
   - ✅ **Enable email provider**: ON
3. Click **"Save"**

### 1.4 Create Your First Admin User

1. Go to **Authentication** → **Users**
2. Click **"Add User"** → **"Create new user"**
3. Fill in:
   - **Email**: Your admin email (e.g., admin@yourschool.com)
   - **Password**: Choose a strong password
   - **Auto Confirm User**: ON (check this box)
4. Click **"Create user"**

5. Now make this user an admin by running this SQL:
   - Go to **SQL Editor**
   - Run this query (replace with your email):
   ```sql
   UPDATE public.users 
   SET role = 'admin', full_name = 'Admin Name' 
   WHERE email = 'admin@yourschool.com';
   ```

### 1.5 Get Your Supabase Credentials

1. Go to **Settings** → **API**
2. Copy these values (you'll need them next):
   - **Project URL** (looks like: `https://xxxxx.supabase.co`)
   - **anon public** key (the long string under "Project API keys")

## Step 2: Configure Your Application

### 2.1 Update Environment Variables

1. Open the `.env` file in your project root
2. Update with your Supabase credentials:

```env
VITE_SUPABASE_URL=https://your-project.supabase.co
VITE_SUPABASE_ANON_KEY=your-anon-key-here
```

3. Save the file

### 2.2 Update School Branding (Optional)

1. Open `COMPLETE_DATABASE_SETUP.sql`
2. Find line with `'Your School Name'`
3. Change it to your actual school name
4. Re-run the SQL in Supabase SQL Editor

## Step 3: Build for Production

### 3.1 Install Dependencies

```bash
pnpm install
```

### 3.2 Build the Application

```bash
pnpm build
```

This creates optimized production files in the `dist/` folder.

## Step 4: Deploy to Hosting

You have several deployment options:

### Option A: Deploy to Vercel (Recommended - Free)

1. Install Vercel CLI:
   ```bash
   npm install -g vercel
   ```

2. Login to Vercel:
   ```bash
   vercel login
   ```

3. Deploy:
   ```bash
   vercel
   ```

4. Follow the prompts:
   - Link to existing project? **N**
   - Project name? **your-school-name**
   - Directory? **./dist/spa**
   - Override settings? **N**

5. Add environment variables in Vercel Dashboard:
   - Go to your project → Settings → Environment Variables
   - Add `VITE_SUPABASE_URL` and `VITE_SUPABASE_ANON_KEY`
   - Redeploy: `vercel --prod`

### Option B: Deploy to Netlify (Free)

1. Install Netlify CLI:
   ```bash
   npm install -g netlify-cli
   ```

2. Login to Netlify:
   ```bash
   netlify login
   ```

3. Deploy:
   ```bash
   netlify deploy --prod --dir=dist/spa
   ```

4. Add environment variables:
   - Go to Site Settings → Environment Variables
   - Add `VITE_SUPABASE_URL` and `VITE_SUPABASE_ANON_KEY`
   - Trigger a new deploy

### Option C: Deploy to Your Own Server

1. Copy the `dist/` folder to your server
2. Install Node.js on the server
3. Run the production server:
   ```bash
   cd dist
   node server/node-build.mjs
   ```

4. Use a process manager like PM2:
   ```bash
   npm install -g pm2
   pm2 start server/node-build.mjs --name school-system
   pm2 save
   pm2 startup
   ```

5. Set up Nginx as reverse proxy (optional):
   ```nginx
   server {
       listen 80;
       server_name yourschool.com;
       
       location / {
           proxy_pass http://localhost:8080;
           proxy_http_version 1.1;
           proxy_set_header Upgrade $http_upgrade;
           proxy_set_header Connection 'upgrade';
           proxy_set_header Host $host;
           proxy_cache_bypass $http_upgrade;
       }
   }
   ```

## Step 5: First Login and Setup

### 5.1 Login as Admin

1. Open your deployed application URL
2. Click **"Login"**
3. Enter your admin email and password
4. You should be redirected to the Dashboard

### 5.2 Update School Settings

1. Go to **Settings** page (sidebar)
2. Update:
   - School Name
   - School Address
   - Contact Information
   - Academic Year
3. Click **"Save Settings"**

### 5.3 Create Teacher Accounts

1. Still in **Settings** page, scroll to **"Teacher Management"**
2. Click **"Add New Teacher"**
3. Fill in teacher details:
   - Email
   - Full Name
   - Phone
   - Password (or click "Generate")
   - Assign Classes (optional)
4. Click **"Create Teacher"**
5. **Important**: Copy the credentials and share them securely with the teacher

### 5.4 Add Students

1. Go to **Registrar** page
2. Click **"Add New Student"**
3. Fill in student details
4. Click **"Add Student"**
5. Repeat for all students

### 5.5 Add Staff Members

1. In **Registrar** page, switch to **"Staff"** tab
2. Click **"Add New Staff"**
3. Fill in staff details
4. Click **"Add Staff"**

## Step 6: Train Your Users

### For Teachers:

1. Share their login credentials (email + password)
2. Show them how to:
   - Mark student attendance
   - Enter exam scores
   - Generate report cards
3. Teachers can only access:
   - Attendance page (Students & Reports tabs)
   - Academic page

### For Registrar:

1. Share their login credentials
2. Show them how to:
   - Add new students
   - Update student information
   - Manage staff records
3. Registrars can only access:
   - Registrar page

### For Admin:

1. You have full access to all features
2. You can:
   - Create teacher accounts
   - View all reports
   - Manage settings
   - Access all pages

## Security Best Practices

1. **Change Default Passwords**: Make sure all users change their passwords after first login
2. **Use Strong Passwords**: Require at least 8 characters with mixed case and numbers
3. **Regular Backups**: Supabase automatically backs up your database, but you can also export data regularly
4. **Monitor Access**: Check Supabase Dashboard → Authentication → Users to see who's logging in
5. **Keep Software Updated**: Regularly update dependencies with `pnpm update`

## Troubleshooting

### Teachers Can't Login

1. Check if email confirmation is disabled in Supabase
2. Run this SQL to manually confirm their email:
   ```sql
   UPDATE auth.users 
   SET email_confirmed_at = NOW()
   WHERE email = 'teacher@email.com';
   ```

### "User profile not found" Error

1. Check if the user exists in `public.users` table
2. If not, the trigger might not have fired. Manually insert:
   ```sql
   INSERT INTO public.users (id, email, full_name, role, status)
   VALUES (
     'user-id-from-auth-users',
     'email@example.com',
     'Full Name',
     'teacher',
     'active'
   );
   ```

### Data Not Showing

1. Check browser console for errors (F12)
2. Verify Supabase credentials in `.env` are correct
3. Check RLS policies are enabled in Supabase

## Support

For issues or questions:
1. Check the browser console (F12) for error messages
2. Check Supabase logs in Dashboard → Logs
3. Review the `DATABASE_SETUP_GUIDE.md` for database issues

## Next Steps

- Set up automated backups
- Configure custom domain
- Add SMS integration for parent notifications
- Customize report card templates
- Add more subjects in Settings

---

**Congratulations!** Your school management system is now live and ready to use! 🎉
