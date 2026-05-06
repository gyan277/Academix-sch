# Deploy API Fix - Quick Checklist

## ✅ What Was Fixed

The teacher login creation API has been completely restructured to work with Netlify serverless functions.

**Problem:** Express-based API was returning HTML instead of JSON on Netlify
**Solution:** Created individual serverless functions for each endpoint

## 📋 Pre-Deployment Checklist

- [x] Created `netlify/functions/create-staff-user.ts`
- [x] Created `netlify/functions/update-teacher-class.ts`
- [x] Updated `netlify.toml` with proper redirects
- [x] Backed up old `api.ts` file
- [ ] Commit and push changes to GitHub
- [ ] Verify environment variables in Netlify

## 🚀 Deployment Steps

### Step 1: Commit and Push

```bash
git add .
git commit -m "Fix: Restructure API for Netlify serverless functions"
git push origin main
```

### Step 2: Verify Environment Variables

Go to Netlify Dashboard → Your Site → Site settings → Environment variables

Ensure these are set:
- ✅ `VITE_SUPABASE_URL` = Your Supabase project URL
- ✅ `SUPABASE_SERVICE_ROLE_KEY` = Your service role key
- ✅ `VITE_SUPABASE_ANON_KEY` = Your anonymous key

### Step 3: Wait for Deployment

- Netlify will automatically deploy when you push to GitHub
- Watch the deploy log in Netlify dashboard
- Wait for "Published" status

### Step 4: Test the Fix

1. Go to: https://academix-man.netlify.app
2. Login as admin
3. Go to Registrar page
4. Try to create a new teacher with login account
5. Fill in all fields and check "Create Login Account"
6. Click "Add Staff Member"

**Expected Result:** ✅ Success message with teacher account created

**If it fails:** Check browser console for errors and see troubleshooting below

## 🧪 Testing Checklist

Test these scenarios:

- [ ] Create teacher WITH login account
- [ ] Create teacher WITHOUT login account
- [ ] Create non-teacher staff WITH login account
- [ ] Update teacher class assignment
- [ ] Verify teacher can login with created credentials

## 🔍 Troubleshooting

### Still Getting HTML Response?

1. **Clear Netlify cache:**
   - Netlify Dashboard → Deploys → Trigger deploy → "Clear cache and deploy site"

2. **Check function logs:**
   - Netlify Dashboard → Functions → Select function → View logs

3. **Verify redirects:**
   - Test direct function URL: `https://academix-man.netlify.app/.netlify/functions/create-staff-user`
   - Should return: `{"error":"Method not allowed"}` (because it's GET, not POST)

### Environment Variables Not Working?

1. Check variable names are EXACT (case-sensitive)
2. No extra spaces in values
3. Redeploy after changing variables

### CORS Errors?

- All functions include CORS headers
- If still seeing errors, check browser console for specific message

### Function Timeout?

- Netlify free tier: 10 second timeout
- Check if Supabase queries are slow
- Consider upgrading Netlify plan if needed

## 📊 Success Indicators

You'll know it's working when:

✅ No "Unexpected token '<'" errors
✅ API returns JSON responses
✅ Teacher accounts are created successfully
✅ Teachers can login with created credentials
✅ Class assignments work properly
✅ Multi-tenancy is preserved (correct school_id)

## 🎯 What Changed

### Before (Not Working on Netlify)
```
Frontend → /api/create-staff-user 
         → netlify/functions/api.ts (Express wrapper)
         → serverless-http
         → Returns HTML on error ❌
```

### After (Working on Netlify)
```
Frontend → /api/create-staff-user
         → netlify/functions/create-staff-user.ts (Direct function)
         → Returns JSON ✅
```

## 📁 Files Changed

**New Files:**
- `netlify/functions/create-staff-user.ts` - Staff user creation
- `netlify/functions/update-teacher-class.ts` - Class assignment updates
- `NETLIFY_SERVERLESS_API_RESTRUCTURE.md` - Full documentation
- `DEPLOY_API_FIX_CHECKLIST.md` - This file

**Modified Files:**
- `netlify.toml` - Updated redirects

**Backup Files:**
- `netlify/functions/api.ts.backup` - Old Express wrapper (kept for reference)

## 🎉 After Successful Deployment

1. Test creating multiple teachers
2. Verify they can all login
3. Check class assignments work
4. Confirm multi-tenancy (each school sees only their data)
5. Celebrate! 🎊

## 📞 Support

If issues persist after deployment:
1. Check Netlify function logs
2. Check browser console errors
3. Verify Supabase service role key has proper permissions
4. Check database RLS policies aren't blocking admin operations

---

**Ready to deploy?** Run the commands in Step 1 above! 🚀
