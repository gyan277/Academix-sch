# Install Supabase CLI - Manual Method

Since the automated installation isn't working, let's install it manually. It's very simple!

## Option 1: Direct Download (Easiest)

### Step 1: Download

Click this link to download:
**https://github.com/supabase/cli/releases**

1. Scroll down to "Assets"
2. Download the file that says: `supabase_windows_amd64.zip` or similar

### Step 2: Extract

1. Right-click the downloaded ZIP file
2. Click "Extract All..."
3. Extract to: `C:\supabase`

### Step 3: Add to PATH

1. Press `Windows + R`
2. Type: `sysdm.cpl` and press Enter
3. Click "Environment Variables"
4. Under "User variables", find "Path" and click "Edit"
5. Click "New"
6. Add: `C:\supabase`
7. Click "OK" on all windows

### Step 4: Test

1. **Close and reopen your terminal** (important!)
2. Run: `supabase --version`
3. Should show the version number

## Option 2: Use Supabase Dashboard (No CLI needed!)

If the CLI installation is too complicated, you can deploy the function directly through the Supabase Dashboard:

### Step 1: Go to Supabase Dashboard

https://supabase.com/dashboard/project/iaaxucktpqwreqnnvrpz/functions

### Step 2: Create New Function

1. Click "Create a new function"
2. Name: `create-teacher-account`
3. Click "Create function"

### Step 3: Copy the Code

Open this file in your project:
```
supabase/functions/create-teacher-account/index.ts
```

Copy ALL the code from that file.

### Step 4: Paste and Deploy

1. Paste the code into the Supabase editor
2. Click "Deploy"
3. Wait for deployment to complete

### Step 5: Test

1. Go to: https://academix-man.netlify.app
2. Login as admin
3. Try creating a teacher with login account
4. Should work perfectly!

## Which Option Should You Choose?

**Option 2 (Dashboard)** is easier if you just want to get it working quickly.

**Option 1 (CLI)** is better for future updates and development.

## After Installation

Once the function is deployed (either way), run these commands to test:

```bash
# Test the function is live
curl https://iaaxucktpqwreqnnvrpz.supabase.co/functions/v1/create-teacher-account
```

Should return an error (because we didn't send data), but it means the function exists!

## Need Help?

If both options don't work, let me know and I'll help you troubleshoot!

---

**Recommended:** Try Option 2 (Dashboard) first - it's the quickest way to get it working!
