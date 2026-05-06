# 🧪 Test API Fix - Step-by-Step Guide

## ⏰ First: Wait for Deployment

1. Go to: https://app.netlify.com/sites/academix-man/deploys
2. You should see a new deployment in progress
3. Wait for status to change to **"Published"** (usually 2-3 minutes)
4. Look for the commit message: "Fix: Restructure API for Netlify serverless functions"

## ✅ Step 1: Verify Environment Variables

Before testing, make sure environment variables are set:

1. Go to Netlify Dashboard
2. Click on your site (academix-man)
3. Go to: **Site settings** → **Environment variables**
4. Verify these exist:
   - `VITE_SUPABASE_URL`
   - `SUPABASE_SERVICE_ROLE_KEY`
   - `VITE_SUPABASE_ANON_KEY`

If any are missing, add them and redeploy.

## 🧪 Step 2: Test Teacher Creation

### Test Case 1: Create Teacher WITH Login Account

1. **Open production site:**
   ```
   https://academix-man.netlify.app
   ```

2. **Login as Admin:**
   - Use your admin credentials
   - Should see the dashboard

3. **Navigate to Registrar:**
   - Click "Registrar" in the sidebar
   - Click on "Staff" tab

4. **Click "Add Staff Member"**

5. **Fill in the form:**
   ```
   Name: John Mensah
   Email: john.mensah@test.com
   Phone: 0241234567
   Position: Teacher
   Specialization: Mathematics
   Assigned Class: Primary 3 (or any class)
   ✅ Create Login Account (CHECK THIS BOX)
   Password: TestPass123
   ```

6. **Click "Add Staff Member"**

7. **Expected Result:**
   ```
   ✅ Success message appears
   ✅ Message says: "Teacher John Mensah added successfully with login account"
   ✅ New staff member appears in the list
   ✅ Shows assigned class
   ```

8. **What to check in browser console (F12):**
   ```
   ✅ No errors
   ✅ API response is JSON (not HTML)
   ✅ Response includes: { success: true, user_id: "...", ... }
   ```

### Test Case 2: Verify Teacher Can Login

1. **Logout from admin account**

2. **Try to login with new teacher credentials:**
   ```
   Email: john.mensah@test.com
   Password: TestPass123
   ```

3. **Expected Result:**
   ```
   ✅ Login successful
   ✅ Redirected to teacher dashboard
   ✅ Can see assigned class
   ✅ Can access teacher features
   ```

### Test Case 3: Create Staff WITHOUT Login Account

1. **Login as admin again**

2. **Go to Registrar → Staff**

3. **Add another staff member:**
   ```
   Name: Mary Asante
   Email: (leave empty)
   Phone: 0241234568
   Position: Secretary
   Specialization: Administration
   ❌ Create Login Account (UNCHECK THIS BOX)
   ```

4. **Click "Add Staff Member"**

5. **Expected Result:**
   ```
   ✅ Success message: "Secretary Mary Asante added successfully"
   ✅ No login account created
   ✅ Staff member appears in list
   ```

### Test Case 4: Update Teacher Class Assignment

1. **Find the teacher you created (John Mensah)**

2. **Click edit icon**

3. **Change assigned class:**
   ```
   Change from: Primary 3
   Change to: Primary 4
   ```

4. **Click "Save Changes"**

5. **Expected Result:**
   ```
   ✅ Success message appears
   ✅ Class assignment updated
   ✅ Teacher can see new class when they login
   ```

## 🔍 What to Look For

### ✅ Success Indicators

**In Browser Console (F12 → Console):**
```
✅ No "Unexpected token '<'" errors
✅ No "SyntaxError: JSON.parse" errors
✅ API responses are JSON objects
✅ Status codes are 200 (success)
```

**In Network Tab (F12 → Network):**
```
✅ POST /api/create-staff-user → Status: 200
✅ Response type: application/json
✅ Response body: { success: true, ... }
```

**In UI:**
```
✅ Success toast notifications appear
✅ New staff members show in list immediately
✅ No error messages
✅ Forms reset after successful submission
```

### ❌ Failure Indicators

**If you see these, something is wrong:**

```
❌ "Unexpected token '<', "<!DOCTYPE "... is not valid JSON"
❌ HTML response instead of JSON
❌ 404 Not Found errors
❌ CORS errors
❌ "Failed to create login account" errors
```

## 🚨 If Tests Fail

### Problem: Still Getting HTML Response

**Solution 1: Clear Netlify Cache**
1. Go to Netlify Dashboard
2. Deploys → Trigger deploy
3. Select "Clear cache and deploy site"
4. Wait for new deployment
5. Test again

**Solution 2: Check Function Logs**
1. Netlify Dashboard → Functions
2. Click on "create-staff-user"
3. View logs
4. Look for errors

### Problem: Environment Variables Not Working

**Solution:**
1. Netlify Dashboard → Site settings → Environment variables
2. Verify all three variables are set
3. Check for typos or extra spaces
4. Click "Save" if you made changes
5. Trigger a new deployment
6. Test again

### Problem: CORS Errors

**Solution:**
1. Check browser console for exact error
2. Verify the API endpoint is being called correctly
3. Check Netlify function logs
4. Ensure redirects in netlify.toml are correct

### Problem: Function Timeout

**Solution:**
1. Check if Supabase is responding slowly
2. Verify service role key is correct
3. Check Supabase logs for errors
4. Consider upgrading Netlify plan if needed

## 📊 Test Results Checklist

Use this to track your testing:

- [ ] Deployment completed successfully
- [ ] Environment variables verified
- [ ] Created teacher WITH login account
- [ ] Teacher appears in staff list
- [ ] Teacher can login with credentials
- [ ] Teacher sees correct assigned class
- [ ] Created staff WITHOUT login account
- [ ] Updated teacher class assignment
- [ ] No errors in browser console
- [ ] API returns JSON (not HTML)
- [ ] Multi-tenancy working (correct school_id)

## 🎉 Success!

If all tests pass, you're done! The API is now working correctly on Netlify production.

**What changed:**
- ✅ Teacher login creation works automatically
- ✅ No more manual account creation needed
- ✅ Class assignments work properly
- ✅ Multi-tenancy is preserved
- ✅ Production matches local development behavior

## 📸 Screenshots to Take

For documentation, take screenshots of:
1. Successful teacher creation (success message)
2. New teacher in staff list
3. Teacher login screen
4. Teacher dashboard after login
5. Browser console showing JSON response
6. Network tab showing 200 status

## 🔄 Continuous Testing

After initial success, test these scenarios:

1. **Multiple Schools:**
   - Create teachers for different schools
   - Verify each school only sees their own staff

2. **Different Positions:**
   - Create Head Teacher with login
   - Create Librarian with login
   - Verify role-based access

3. **Edge Cases:**
   - Try duplicate email (should fail gracefully)
   - Try invalid school_id (should fail gracefully)
   - Try missing required fields (should show validation error)

## 📞 Need Help?

If tests fail after trying all solutions:

1. Check Netlify function logs
2. Check Supabase logs
3. Verify database RLS policies
4. Check service role key permissions
5. Review the full documentation in `NETLIFY_SERVERLESS_API_RESTRUCTURE.md`

---

**Ready to test?** Start with Step 1 above! 🚀

**Production URL:** https://academix-man.netlify.app
