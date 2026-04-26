# Finance System - Fresh Start Guide

## 🎯 Goal
Set up a clean finance system where:
- When you set a class fee, ALL students in that class are automatically billed
- When you record a payment, the balance is automatically calculated
- Status automatically shows: Paid, Partial, or Unpaid

## 📋 Step-by-Step Setup

### Step 1: Clean Setup (5 minutes)

1. **Open Supabase SQL Editor**
   - Go to your Supabase project
   - Click "SQL Editor" in the left sidebar

2. **Run the Clean Setup Script**
   - Copy ALL contents of `CLEAN_FINANCE_SETUP.sql`
   - Paste into SQL Editor
   - Click "Run"
   - Wait for "Setup Complete!" message

**What this does:**
- Removes old finance tables (if any)
- Creates fresh tables: `class_fees`, `student_fees`, `payments`
- Sets up automatic triggers for billing and calculations
- Enables security policies

### Step 2: Verify Setup (2 minutes)

Run this query to verify everything is ready:

```sql
-- Check tables exist
SELECT table_name 
FROM information_schema.tables 
WHERE table_schema = 'public' 
  AND table_name IN ('class_fees', 'student_fees', 'payments');

-- Check triggers exist
SELECT trigger_name, event_object_table
FROM information_schema.triggers
WHERE event_object_schema = 'public'
  AND trigger_name LIKE '%auto_bill%';
```

You should see:
- ✅ 3 tables (class_fees, payments, student_fees)
- ✅ 2 triggers (trigger_auto_bill_students, trigger_auto_bill_new_student)

### Step 3: Test with Your Data (5 minutes)

1. **Check your students:**
```sql
SELECT full_name, class, status, school_id
FROM public.students
WHERE status = 'active'
ORDER BY class;
```

2. **Get your IDs:**
```sql
-- Your school_id
SELECT id as school_id, school_name 
FROM public.school_settings 
LIMIT 1;

-- Your user_id
SELECT id as user_id, email 
FROM public.users 
WHERE role = 'admin' 
LIMIT 1;
```

3. **Set a class fee** (replace the IDs):
```sql
INSERT INTO public.class_fees (
  school_id,
  class,
  academic_year,
  term,
  fee_amount,
  description,
  created_by
) VALUES (
  'YOUR_SCHOOL_ID',     -- From step 2
  'P1',                 -- Your class name
  '2024/2025',         -- Current year
  'Term 1',            -- Optional
  500.00,              -- Fee amount
  'School fees',       -- Optional
  'YOUR_USER_ID'       -- From step 2
);
```

4. **Check if students were auto-billed:**
```sql
SELECT 
  s.full_name,
  s.class,
  sf.total_fee_amount,
  sf.balance,
  sf.payment_status
FROM public.student_fees sf
JOIN public.students s ON s.id = sf.student_id
WHERE sf.class = 'P1';  -- Your class
```

**Expected result:** All P1 students should appear with:
- total_fee_amount = 500.00
- balance = 500.00
- payment_status = 'unpaid'

### Step 4: Use the Frontend (2 minutes)

1. **Refresh your browser** (F5 or Ctrl+R)
2. **Go to Finance page**
3. **Click "Student Payments" tab**
4. **You should see your students!** 🎉

## ✅ Success Checklist

- [ ] Ran `CLEAN_FINANCE_SETUP.sql` successfully
- [ ] Verified 3 tables exist
- [ ] Verified 2 triggers exist
- [ ] Set a class fee
- [ ] Students automatically appeared in `student_fees` table
- [ ] Students show up in Finance page

## 🎯 How It Works

### When You Set a Class Fee:

```
You create class fee for "P1" = GH₵ 500
         ↓
Trigger fires automatically
         ↓
System finds all active students in P1
         ↓
Creates student_fees record for each student
         ↓
Each student now has:
  - Total Fee: GH₵ 500
  - Paid: GH₵ 0
  - Balance: GH₵ 500
  - Status: Unpaid
```

### When You Record a Payment:

```
You record: Student paid GH₵ 200
         ↓
Payment saved in payments table
         ↓
Trigger fires automatically
         ↓
System updates student_fees:
  - Total Fee: GH₵ 500
  - Paid: GH₵ 200
  - Balance: GH₵ 300
  - Status: Partial
```

### When Student Pays Full Amount:

```
You record: Student paid GH₵ 300 more
         ↓
System updates:
  - Total Fee: GH₵ 500
  - Paid: GH₵ 500
  - Balance: GH₵ 0
  - Status: Paid ✓
```

## 🔧 Troubleshooting

### Issue: Students not auto-billed

**Check 1:** Are students marked as "active"?
```sql
SELECT full_name, status FROM public.students WHERE class = 'P1';
```
If status is not 'active', update it:
```sql
UPDATE public.students SET status = 'active' WHERE class = 'P1';
```

**Check 2:** Do class names match exactly?
```sql
-- Student class names
SELECT DISTINCT class FROM public.students;

-- Class fee names
SELECT DISTINCT class FROM public.class_fees;
```
They must match EXACTLY (case-sensitive, no extra spaces)

**Check 3:** Do school_ids match?
```sql
SELECT 'Student' as type, school_id FROM public.students WHERE class = 'P1'
UNION ALL
SELECT 'Class Fee' as type, school_id FROM public.class_fees WHERE class = 'P1';
```
Both should have the same school_id

### Issue: Frontend shows "No student fees found"

**Solution:** Refresh the browser (F5 or Ctrl+R)

If still not showing, check browser console for errors (F12)

## 📞 Need Help?

If something isn't working:
1. Check the browser console (F12) for errors
2. Check Supabase logs for database errors
3. Run the diagnostic queries above
4. Make sure you refreshed the browser

## 🎉 You're Done!

Your finance system is now ready to use! Every time you:
- Set a class fee → Students are automatically billed
- Record a payment → Balance is automatically calculated
- Student pays full amount → Status automatically changes to "Paid"

Everything happens automatically! 🚀
