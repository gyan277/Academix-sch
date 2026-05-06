# Supabase Edge Function Setup - Teacher Account Creation

## ✅ Better Solution: Use Supabase Edge Functions

Instead of fighting with Netlify serverless functions, we're using **Supabase Edge Functions** which:
- ✅ Run directly in Supabase (no Netlify issues)
- ✅ Have direct access to Supabase Auth
- ✅ Work identically in local and production
- ✅ Are easier to deploy and manage
- ✅ No CORS or routing issues

## 📁 What Was Created

**`supabase/functions/create-teacher-account/index.ts`**
- Supabase Edge Function for creating teacher accounts
- Handles all the logic: Auth creation, users table, teacher_classes
- Returns proper JSON responses
- Built-in CORS handling

**Updated `client/pages/Registrar.tsx`**
- Now calls Supabase Edge Function instead of Netlify API
- Uses: `https://iaaxucktpqwreqnnvrpz.supabase.co/functions/v1/create-teacher-account`

## 🚀 Deployment Steps

### Step 1: Install Supabase CLI (if not already installed)

**Windows (PowerShell):**
```powershell
scoop install supabase
```

**Or download from:**
https://github.com/supabase/cli/releases

**Verify installation:**
```bash
supabase --version
```

### Step 2: Login to Supabase

```bash
supabase login
```

This will open a browser window to authenticate.

### Step 3: Link Your Project

```bash
supabase link --project-ref iaaxucktpqwreqnnvrpz
```

When prompted for the database password, use your Supabase database password.

### Step 4: Deploy the Edge Function

```bash
supabase functions deploy create-teacher-account
```

This will:
- Upload the function to Supabase
- Make it available at: `https://iaaxucktpqwreqnnvrpz.supabase.co/functions/v1/create-teacher-account`
- Set up proper environment variables automatically

### Step 5: Set Environment Variables (if needed)

The function needs access to:
- `SUPABASE_URL` - Automatically available
- `SUPABASE_SERVICE_ROLE_KEY` - Automatically available

These are automatically set by Supabase, so you don't need to do anything!

### Step 6: Test the Function

After deployment, test it:

```bash
curl -X POST \
  https://iaaxucktpqwreqnnvrpz.supabase.co/functions/v1/create-teacher-account \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer YOUR_ANON_KEY" \
  -d '{
    "email": "test@example.com",
    "password": "TestPass123",
    "full_name": "Test Teacher",
    "position": "Teacher",
    "school_id": "YOUR_SCHOOL_ID",
    "staff_id": "YOUR_STAFF_ID",
    "assigned_class": "Primary 3"
  }'
```

### Step 7: Deploy Frontend Changes

```bash
git add .
git commit -m "Switch to Supabase Edge Functions for teacher account creation"
git push origin main
```

Netlify will auto-deploy the frontend changes.

## 🧪 Testing

### Test in Production

1. Go to: https://academix-man.netlify.app
2. Login as admin
3. Go to Registrar → Staff
4. Click "Add Staff Member"
5. Fill in the form:
   - Name: Test Teacher
   - Email: test.teacher@example.com
   - Phone: 0241234567
   - Position: Teacher
   - Assigned Class: Primary 3
   - ✅ Create Login Account
   - Password: TestPass123
6. Click "Add Staff Member"

**Expected Result:**
✅ Success message: "Teacher Test Teacher added successfully with login account"

### Test Teacher Login

1. Logout from admin
2. Login with:
   - Email: test.teacher@example.com
   - Password: TestPass123
3. Should see teacher dashboard with assigned class

## 🔍 Monitoring

### View Function Logs

In Supabase Dashboard:
1. Go to: Edge Functions
2. Click on "create-teacher-account"
3. View logs and invocations

### Check Function Status

```bash
supabase functions list
```

## 🛠️ Local Development

### Run Function Locally

```bash
supabase functions serve create-teacher-account
```

This starts the function at: `http://localhost:54321/functions/v1/create-teacher-account`

### Test Locally

Update the frontend temporarily to use local URL:
```typescript
const supabaseUrl = 'http://localhost:54321';
```

Then test as normal.

## 📊 Advantages Over Netlify Functions

| Feature | Netlify Functions | Supabase Edge Functions |
|---------|------------------|------------------------|
| Deployment | Complex, needs build config | Simple, one command |
| Environment Variables | Manual setup in dashboard | Automatic |
| CORS | Manual configuration | Built-in |
| Auth Access | Needs service role key setup | Direct access |
| Debugging | Limited logs | Full logs in dashboard |
| Local Testing | Difficult | Easy with CLI |
| Cost | Included in Netlify plan | Included in Supabase plan |

## 🔧 Troubleshooting

### Function Not Found (404)

**Solution:**
```bash
supabase functions deploy create-teacher-account --no-verify-jwt
```

### Permission Denied

**Solution:**
```bash
supabase login
supabase link --project-ref iaaxucktpqwreqnnvrpz
```

### CORS Errors

The function includes proper CORS headers. If you still see errors:
1. Check the function logs in Supabase dashboard
2. Verify the Authorization header is being sent
3. Make sure you're using the correct Supabase URL

### Function Timeout

Supabase Edge Functions have a 150-second timeout (much longer than Netlify's 10 seconds).

## 📝 Function URL

**Production:**
```
https://iaaxucktpqwreqnnvrpz.supabase.co/functions/v1/create-teacher-account
```

**Local:**
```
http://localhost:54321/functions/v1/create-teacher-account
```

## 🎯 What Happens When Admin Creates Teacher

1. **Admin fills form** in Registrar page
2. **Frontend calls** Supabase Edge Function
3. **Function validates** school_id and staff_id
4. **Function creates** user in Supabase Auth
5. **Function inserts** record in users table
6. **Function creates** teacher_classes assignment (if applicable)
7. **Function returns** success with user details
8. **Frontend shows** success message
9. **Teacher can login** immediately with credentials

## ✅ Success Indicators

After deployment, you should see:
- ✅ Function appears in Supabase Dashboard → Edge Functions
- ✅ Function status: "Active"
- ✅ Teacher creation works in production
- ✅ No HTML/JSON errors
- ✅ Teachers can login immediately
- ✅ Class assignments work correctly

## 🔄 Updating the Function

If you need to make changes:

1. Edit `supabase/functions/create-teacher-account/index.ts`
2. Deploy again:
   ```bash
   supabase functions deploy create-teacher-account
   ```
3. Changes are live immediately (no frontend rebuild needed)

## 📚 Additional Resources

- [Supabase Edge Functions Docs](https://supabase.com/docs/guides/functions)
- [Supabase CLI Reference](https://supabase.com/docs/reference/cli/introduction)
- [Edge Functions Examples](https://github.com/supabase/supabase/tree/master/examples/edge-functions)

---

## 🎉 Summary

This approach is **much simpler** than Netlify serverless functions:
- ✅ One command to deploy
- ✅ No build configuration needed
- ✅ Works identically everywhere
- ✅ Better logging and monitoring
- ✅ Direct Supabase integration

**Next Step:** Run `supabase functions deploy create-teacher-account` and test!
