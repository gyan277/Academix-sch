# Teacher Fee Collection - Quick Setup Guide

## Step 1: Run Database Migration

1. Open Supabase Dashboard
2. Go to SQL Editor
3. Open the file: `database-migrations/add-teacher-fee-collection.sql`
4. Copy all the SQL code
5. Paste into Supabase SQL Editor
6. Click "Run"
7. You should see: "Teacher fee collection system created successfully!"

## Step 2: Enable the Feature

1. Login to Academix as **Admin**
2. Go to **Settings** (in sidebar)
3. Stay on the **Profile** tab
4. Scroll down to find **"Teacher Fee Collection"** section
5. Check the checkbox to enable it
6. Click **"Save School Settings"** button
7. You should see success message

## Step 3: Assign Teachers to Classes (If Not Already Done)

Teachers need a class assigned to collect fees:

1. Still in Settings, click **"Teachers"** tab
2. Find a teacher in the list
3. Click **Edit** on their row
4. Set **"Class Assigned"** dropdown (e.g., "Primary 1")
5. Click **Save**
6. Repeat for all teachers who will collect fees

## Step 4: Test as Teacher

1. Logout from admin account
2. Login as a **Teacher** (who has a class assigned)
3. You should now see **"Fee Collection"** in the sidebar
4. Click on it
5. You'll see:
   - Summary cards (students, pending, confirmed amounts)
   - **"Collect Fees"** tab with list of students
   - **"My Collections"** tab with history

### Collect a Fee:
1. In "Collect Fees" tab, find a student
2. Click **"Collect Fee"** button
3. Dialog opens:
   - Select fee type (Bus or Canteen)
   - Amount is pre-filled
   - Add optional notes
4. Click **"Record Collection"**
5. Success! Collection is now **pending** admin confirmation

### View History:
1. Click **"My Collections"** tab
2. See all your collections with status:
   - 🟠 **Pending**: Waiting for admin
   - 🟢 **Confirmed**: Admin received money
   - 🔴 **Rejected**: Admin rejected with reason

## Step 5: Confirm as Admin

1. Logout from teacher account
2. Login as **Admin**
3. Go to **Finance** (in sidebar)
4. Click **"Teacher Collections"** tab (new tab!)
5. You'll see:
   - Summary cards
   - Three tabs: Pending, Confirmed, Rejected

### Confirm a Collection:
1. In **"Pending"** tab, see teacher's collection
2. Review details (teacher, student, amount)
3. Click **"Confirm"** button
4. Confirmation dialog shows details
5. Click **"Confirm Receipt"**
6. Success! Payment is now created and student balance updated

### Reject a Collection:
1. In **"Pending"** tab, find collection
2. Click **"Reject"** button
3. Enter reason (e.g., "Amount incorrect")
4. Click **"Reject Collection"**
5. Teacher will see rejection reason in their history

## Step 6: Verify Payment Created

1. Still as admin, go to Finance → **"Payments"** tab
2. Find the student whose fee was confirmed
3. You should see:
   - Payment recorded
   - Balance reduced
   - Status updated

## That's It! 🎉

The system is now fully operational. Teachers can collect fees, and you (admin) confirm them before they're recorded as payments.

## Quick Reference

### Teacher View:
- **Sidebar**: Fee Collection
- **Can Do**: Collect bus/canteen fees from assigned class
- **Cannot Do**: Confirm own collections, see other teachers' collections

### Admin View:
- **Location**: Finance → Teacher Collections tab
- **Can Do**: Confirm or reject all teacher collections
- **Effect**: Confirming creates payment and updates student balance

## Troubleshooting

**Teacher doesn't see "Fee Collection" in sidebar:**
- Check feature is enabled in Settings
- Check teacher has a class assigned
- Check teacher is logged in (not admin)

**No students showing in teacher's list:**
- Check students exist in that class
- Check students are "active" status
- Check class fees are configured

**Admin doesn't see Teacher Collections tab:**
- Check you're logged in as admin (not teacher)
- Refresh the page

**Collection not creating payment:**
- Check admin clicked "Confirm" (not just viewed it)
- Check for errors in browser console
- Check Supabase logs

## Need Help?

Check the complete documentation: `TEACHER_FEE_COLLECTION_COMPLETE.md`
