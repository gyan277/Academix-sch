# Fix Netlify API Deployment - Teacher Login Creation

## Problem
The `/api/create-staff-user` endpoint returns HTML instead of JSON, causing teacher login creation to fail.

## Root Cause
Environment variables (specifically `SUPABASE_SERVICE_ROLE_KEY`) are not set in Netlify's production environment.

## Solution: Add Environment Variables to Netlify

### Step 1: Go to Netlify Dashboard
1. Open [https://app.netlify.com](https://app.netlify.com)
2. Sign in to your account
3. Select your site: **academix-man**

### Step 2: Add Environment Variables
1. Click **Site settings** (or **Site configuration**)
2. Go to **Environment variables** in the left sidebar
3. Click **Add a variable** or **Add environment variables**

### Step 3: Add These Variables

Add each of these one by one:

#### Variable 1: VITE_SUPABASE_URL
- **Key:** `VITE_SUPABASE_URL`
- **Value:** `https://iaaxucktpqwreqnnvrpz.supabase.co`
- **Scopes:** All scopes (Production, Deploy Previews, Branch deploys)

#### Variable 2: VITE_SUPABASE_ANON_KEY
- **Key:** `VITE_SUPABASE_ANON_KEY`
- **Value:** `eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImlhYXh1Y2t0cHF3cmVxbm52cnB6Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzY4NTE1MzgsImV4cCI6MjA5MjQyNzUzOH0.et3rbkldyMaOH62x0fEYRVeh_FHmx9xpoavRN0jKMiM`
- **Scopes:** All scopes

#### Variable 3: SUPABASE_SERVICE_ROLE_KEY ⚠️ CRITICAL
- **Key:** `SUPABASE_SERVICE_ROLE_KEY`
- **Value:** `eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImlhYXh1Y2t0cHF3cmVxbm52cnB6Iiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc3Njg1MTUzOCwiZXhwIjoyMDkyNDI3NTM4fQ.d1B8uXCOn0sy3gBgwFlW5yqOVS6Kce7cgDMxOJ6GQY8`
- **Scopes:** All scopes
- **⚠️ This is the most important one!**

### Step 4: Redeploy Your Site
After adding the environment variables:

1. Go to **Deploys** tab
2. Click **Trigger deploy** dropdown
3. Select **Deploy site**
4. Wait for deployment to complete (usually 1-2 minutes)

### Step 5: Test the API
After redeployment, test if the API works:

1. Open browser console (F12)
2. Run this command:
```javascript
fetch('https://academix-man.netlify.app/api/ping')
  .then(r => r.json())
  .then(d => console.log('API Response:', d))
  .catch(e => console.error('API Error:', e));
```

**Expected result:** `{message: "ping pong"}`

If you see this, the API is working!

### Step 6: Test Teacher Creation
1. Go to Registrar → Staff tab
2. Click **Add Staff**
3. Fill in teacher details
4. ✅ Check **Create Login Account**
5. Enter email and password
6. Click **Add Staff**

**Expected result:** "Teacher [Name] added successfully with login account"

## Alternative: Check Current Environment Variables

To see what variables are currently set:

1. Go to **Site settings**
2. Click **Environment variables**
3. Check if `SUPABASE_SERVICE_ROLE_KEY` exists
4. If it exists, verify the value matches your `.env` file

## Troubleshooting

### Issue 1: Still Getting HTML Response
**Solution:** Clear Netlify cache and redeploy
1. Go to **Deploys**
2. Click **Trigger deploy** → **Clear cache and deploy site**

### Issue 2: "Unauthorized" Error
**Solution:** Check if service role key is correct
1. Go to Supabase Dashboard
2. Settings → API
3. Copy the **service_role** key (not anon key!)
4. Update in Netlify environment variables

### Issue 3: Variables Not Taking Effect
**Solution:** Ensure you redeployed after adding variables
- Environment variables only apply to NEW deployments
- You must trigger a new deploy after adding them

## Quick Verification Checklist

After setup, verify:
- [ ] All 3 environment variables added to Netlify
- [ ] Site redeployed after adding variables
- [ ] `/api/ping` returns JSON (not HTML)
- [ ] Can create teacher with login account
- [ ] Teacher can login successfully
- [ ] Teacher sees their assigned class

## Security Note

⚠️ **IMPORTANT:** The `SUPABASE_SERVICE_ROLE_KEY` is a sensitive key that bypasses Row Level Security. 

**Keep it secure:**
- ✅ Only add to Netlify environment variables
- ✅ Never commit to Git
- ✅ Never share publicly
- ❌ Don't expose in client-side code

The key is already in your `.env` file (which is gitignored), so it's safe. Just make sure it's also in Netlify.

## Expected Behavior After Fix

Once fixed, when you create a teacher with login:

1. **Staff record created** → Appears in staff list with ID (e.g., NHY0002)
2. **Auth account created** → User can login with email/password
3. **Users table updated** → User linked to school
4. **Class assigned** → Teacher sees only their class
5. **Success message** → "Teacher [Name] added successfully with login account"

No more warnings or errors!

## Need Help?

If you're still having issues after following these steps:

1. Check Netlify deploy logs for errors
2. Check browser console for API errors
3. Verify all environment variables are set correctly
4. Try clearing cache and redeploying

The API should work automatically once environment variables are properly configured in Netlify!