# 🚀 Deploy Teacher Account Creation - Final Steps

## What's Ready:
✅ Supabase Edge Function created
✅ Frontend updated to use Edge Function
✅ Code pushed to GitHub (Netlify will auto-deploy frontend)

## What You Need to Do:

### Step 1: Install Supabase CLI (if not installed)

**Check if already installed:**
```bash
supabase --version
```

**If not installed, install it:**

**Option A: Using Scoop (Windows):**
```powershell
scoop bucket add supabase https://github.com/supabase/scoop-bucket.git
scoop install supabase
```

**Option B: Direct Download:**
Go to: https://github.com/supabase/cli/releases
Download the Windows installer and run it.

### Step 2: Login to Supabase

```bash
supabase login
```

This will open your browser to authenticate.

### Step 3: Link Your Project

```bash
supabase link --project-ref iaaxucktpqwreqnnvrpz
```

When asked for database password, use your Supabase database password.

### Step 4: Deploy the Edge Function

```bash
supabase functions deploy create-teacher-account
```

**That's it!** The function will be live at:
```
https://iaaxucktpqwreqnnvrpz.supabase.co/functions/v1/create-teacher-account
```

### Step 5: Test It!

1. Wait for Netlify to finish deploying (2-3 minutes)
2. Go to: https://academix-man.netlify.app
3. Login as admin
4. Go to Registrar → Staff
5. Try creating a teacher with login account

**It should work perfectly now!**

## Why This Will Work:

1. **Supabase Edge Functions** run directly in Supabase (no Netlify issues)
2. **Direct Auth access** - no service role key issues
3. **Automatic environment variables** - Supabase handles them
4. **Better logging** - see everything in Supabase dashboard
5. **Works everywhere** - local and production identical

## Troubleshooting:

### If `supabase` command not found:
- Restart your terminal after installation
- Or add to PATH manually

### If link fails:
- Make sure you're logged in: `supabase login`
- Check project ref is correct: `iaaxucktpqwreqnnvrpz`

### If deploy fails:
- Check you're in the project root directory
- Make sure the function file exists at: `supabase/functions/create-teacher-account/index.ts`

## Quick Commands Summary:

```bash
# 1. Install (if needed)
scoop install supabase

# 2. Login
supabase login

# 3. Link project
supabase link --project-ref iaaxucktpqwreqnnvrpz

# 4. Deploy function
supabase functions deploy create-teacher-account

# 5. Test on production site
# https://academix-man.netlify.app
```

## After Deployment:

You'll be able to:
✅ Create teacher accounts with email/password
✅ Assign classes automatically
✅ Teachers can login immediately
✅ Everything works in production
✅ No more HTML/JSON errors

---

**Ready?** Run the commands above and you're done! 🎉
