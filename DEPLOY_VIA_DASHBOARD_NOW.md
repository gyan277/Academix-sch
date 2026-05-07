# 🚀 Deploy Teacher Account Function - Dashboard Method (5 Minutes)

## This is the EASIEST way - No CLI needed!

### Step 1: Open Supabase Dashboard

Click this link:
**https://supabase.com/dashboard/project/iaaxucktpqwreqnnvrpz/functions**

(You'll need to login to Supabase if you're not already)

### Step 2: Create New Function

1. Click the green **"Create a new function"** button
2. In the "Function name" field, type: `create-teacher-account`
3. Click **"Create function"**

### Step 3: Copy the Code

Open this file in VS Code (or any editor):
```
supabase/functions/create-teacher-account/index.ts
```

**Select ALL the code** (Ctrl+A) and **Copy** (Ctrl+C)

### Step 4: Paste the Code

1. In the Supabase dashboard, you'll see a code editor
2. **Delete** any existing code in the editor
3. **Paste** your copied code (Ctrl+V)
4. Click the **"Deploy"** button (usually at the top right)

### Step 5: Wait for Deployment

You'll see a progress indicator. Wait until it says:
✅ **"Function deployed successfully"**

This usually takes 10-30 seconds.

### Step 6: Test It!

1. Go to: **https://academix-man.netlify.app**
2. Login as admin
3. Go to **Registrar** → **Staff** tab
4. Click **"Add Staff Member"**
5. Fill in the form:
   - Name: Test Teacher
   - Email: test@example.com
   - Phone: 0241234567
   - Position: Teacher
   - Assigned Class: (pick any class)
   - ✅ **Check "Create Login Account"**
   - Password: TestPass123
6. Click **"Add Staff Member"**

### Expected Result:

✅ Success message: "Teacher Test Teacher added successfully with login account"

### If It Works:

🎉 **Congratulations!** You can now create teacher accounts automatically!

Try logging out and logging in with:
- Email: test@example.com
- Password: TestPass123

The teacher should be able to login and see their dashboard!

### If It Doesn't Work:

Check these:
1. Make sure Netlify finished deploying the frontend (wait 2-3 minutes after pushing to GitHub)
2. Check browser console (F12) for any errors
3. Make sure you copied ALL the code from the index.ts file
4. Try refreshing the page and trying again

---

## Visual Guide:

**Supabase Dashboard → Functions → Create New Function**

```
Function Name: create-teacher-account
↓
Paste code from: supabase/functions/create-teacher-account/index.ts
↓
Click Deploy
↓
Wait for success message
↓
Test on production site!
```

---

## That's It!

This method is much simpler than installing the CLI. The function will work exactly the same way!

**Ready?** Click the link above and follow the steps! 🚀
