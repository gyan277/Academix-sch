# P3 Students Not Showing - Troubleshooting Guide

## Problem
Sir Isaac (careerghana01@gmail.com) is assigned to P3 but cannot see any students in the Academic page.

## Root Cause
The `loadStudents()` function was relying only on RLS policies without explicitly filtering by `school_id`. This caused issues when school_ids didn't match between teacher and students.

## Fix Applied

### 1. Frontend Changes (Academic.tsx)
- Added explicit `school_id` filter to the students query
- Added check to wait for `profileSchoolId` to load before querying
- Added console logging for debugging
- Updated useEffect dependency to include `profileSchoolId`

### 2. Database Fix (FINAL_P3_FIX_AND_VERIFY.sql)
Run this SQL script to:
- Check current state of Sir Isaac and P3 students
- Fix any school_id mismatches
- Verify the fix worked
- Test the exact query the frontend will use

## Steps to Resolve

### Step 1: Run Database Fix
```sql
-- Run FINAL_P3_FIX_AND_VERIFY.sql in Supabase SQL Editor
-- This will fix school_id mismatches and verify everything
```

### Step 2: Clear Browser Cache
1. Have Sir Isaac logout completely
2. Clear browser cache (Ctrl+Shift+Delete)
3. Close all browser tabs
4. Reopen browser and login again

### Step 3: Check Browser Console
1. Login as Sir Isaac
2. Go to Academic page
3. Open browser console (F12)
4. Look for these log messages:
   - `🔍 Loading students for class: P3 school_id: [uuid]`
   - `✅ Loaded students: X students`
   - `📋 First student: {...}`

### Step 4: Verify in Console
If you see:
- `⚠️ Profile school_id not loaded yet, waiting...` → Wait a moment, it should load
- `✅ Loaded students: 0 students` → School IDs don't match, run database fix
- `✅ Loaded students: 5 students` → SUCCESS!

## Expected Behavior After Fix

1. Sir Isaac logs in
2. Goes to Academic page
3. P3 is auto-selected (his assigned class)
4. Console shows: `✅ Loaded students: 5 students`
5. Score entry table shows all 5 P3 students:
   - Bernice Agyemang
   - Russel Agyemang
   - (and 3 others)

## If Still Not Working

### Check 1: Verify School IDs Match
```sql
-- Teacher's school_id
SELECT school_id FROM users WHERE email = 'careerghana01@gmail.com';

-- Students' school_ids
SELECT school_id, COUNT(*) FROM students WHERE class = 'P3' GROUP BY school_id;

-- They MUST match!
```

### Check 2: Verify RLS Policies
```sql
-- Check if RLS is blocking the query
SELECT * FROM students 
WHERE class = 'P3' 
  AND status = 'active'
  AND school_id = '[paste-teacher-school-id-here]';
```

### Check 3: Check Teacher Assignment
```sql
SELECT * FROM teacher_classes 
WHERE teacher_id = (SELECT id FROM users WHERE email = 'careerghana01@gmail.com')
  AND academic_year = '2024/2025';
```

## Prevention

To prevent this issue in the future:
1. Always use explicit `school_id` filters in queries
2. Don't rely solely on RLS policies for multi-tenancy
3. Add console logging for debugging
4. Verify school_id matches when creating students/teachers

## Technical Details

### Before Fix
```typescript
const { data, error } = await supabase
  .from("students")
  .select("id, student_id, full_name")
  .eq("class", selectedClass)
  .eq("status", "active")
  .order("full_name");
// ❌ No school_id filter - relies on RLS only
```

### After Fix
```typescript
const { data, error } = await supabase
  .from("students")
  .select("id, student_id, full_name, school_id")
  .eq("class", selectedClass)
  .eq("status", "active")
  .eq("school_id", profileSchoolId) // ✅ Explicit filter
  .order("full_name");
```

## Contact
If issue persists after following all steps, check:
1. Supabase logs for RLS policy errors
2. Network tab for failed queries
3. Console for JavaScript errors
