# Fix Admin Can't See Teacher Collections

## The Problem
Teacher collected money but admin can't see it in Finance → Teacher Collections tab.

## The Solution (Run These 2 Scripts)

### Step 1: Run the Quick Fix
Open Supabase SQL Editor and run:
```
QUICK_FIX_ADMIN_COLLECTIONS.sql
```

This will:
- ✅ Create/update the RPC function
- ✅ Check if collections exist
- ✅ Test the RPC function
- ✅ Check for year/term mismatch
- ✅ Tell you exactly what's wrong

### Step 2: Check the Results
The script will tell you one of these:

#### Result A: "Should work now"
- ✅ Everything is fixed
- 👉 Go to admin Finance page
- 👉 Click Teacher Collections tab
- 👉 Press Ctrl+R (or Cmd+R) to refresh
- ✅ You should see the collections

#### Result B: "No collections - Teacher needs to collect fees"
- ❌ No collections in database
- 👉 Teacher submission failed
- 👉 Have teacher login and collect fees again
- 👉 Check browser console (F12) for errors when teacher submits

#### Result C: "Year/term mismatch"
- ❌ Collections exist but for different academic year/term
- 👉 The script will show you the exact UPDATE command to run
- 👉 Copy and run that UPDATE command
- 👉 Or have teacher collect fees again for current year/term

## Optional: Emergency Diagnostic
If you want to see EVERYTHING in the database, run:
```
EMERGENCY_CHECK_COLLECTIONS.sql
```

This shows:
- All collections in database
- Current academic settings
- Year/term mismatches
- RPC function status
- Detailed diagnosis

## Optional: Insert Test Collection
If you want to test with fake data, run:
```
INSERT_TEST_COLLECTION.sql
```

This will:
- Create a test collection
- Use a real teacher and student
- Set amount to GHS 50.00
- Mark as pending
- You can then test confirming it in admin

## What to Check in Browser
1. Open browser DevTools (F12)
2. Go to Console tab
3. Refresh the Teacher Collections page
4. Look for red error messages
5. Share any errors you see

## Common Issues and Fixes

### Issue: "Could not find table 'teacher_fee_collections'"
**Fix**: The RPC function bypasses this - run QUICK_FIX_ADMIN_COLLECTIONS.sql

### Issue: "No pending collections" but teacher collected
**Fix**: Year/term mismatch - run QUICK_FIX_ADMIN_COLLECTIONS.sql to see the fix

### Issue: Teacher can't submit collections
**Fix**: Check browser console when teacher clicks "Record Collection"

### Issue: RPC function error
**Fix**: Run QUICK_FIX_ADMIN_COLLECTIONS.sql to recreate the function

## Files You Need
1. `QUICK_FIX_ADMIN_COLLECTIONS.sql` - Main fix (RUN THIS FIRST)
2. `EMERGENCY_CHECK_COLLECTIONS.sql` - Detailed diagnostic (optional)
3. `INSERT_TEST_COLLECTION.sql` - Create test data (optional)

## After It Works
Once admin can see and confirm collections:
1. Admin clicks "Confirm" button
2. System creates payment record automatically
3. Student balance is updated
4. Collection status changes to "confirmed"
5. Teacher can see status in their "My Collections" tab
