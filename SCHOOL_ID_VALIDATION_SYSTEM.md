# School ID Validation System

## Overview
Automatic validation system that ensures teachers and students in the same class always have matching school_ids. This prevents multi-tenancy violations and data leakage.

## How It Works

### 1. Database Level Protection (Triggers)

#### Teacher Assignment Validation
When a teacher is assigned to a class, the system automatically:
- Checks if the teacher has a valid school_id
- Checks all students in that class
- Blocks the assignment if school_ids don't match
- Shows clear error message explaining the mismatch

#### Student Assignment Validation
When a student is assigned to a class, the system automatically:
- Checks if the student has a valid school_id
- Checks if there's a teacher assigned to that class
- Blocks the assignment if school_ids don't match
- Shows clear error message explaining the mismatch

### 2. Frontend Level Protection

#### Teacher Management Interface
Before saving class assignments:
- Validates school_id match for each class
- Shows warning toast if mismatch detected
- Skips problematic class assignments
- Continues with valid assignments

### 3. Query Level Protection

All student/staff queries now explicitly filter by school_id:
- Academic.tsx - Score entry and reports
- Attendance.tsx - Attendance tracking
- Registrar.tsx - Student/staff management
- Reports.tsx - Analytics and reports

## Database Functions

### validate_teacher_class_assignment()
Trigger function that runs BEFORE INSERT/UPDATE on teacher_classes table.

**Checks:**
- Teacher has a school_id (not NULL)
- All students in the class have matching school_id
- Raises exception if validation fails

### validate_student_class_assignment()
Trigger function that runs BEFORE INSERT/UPDATE on students table.

**Checks:**
- Student has a school_id (not NULL)
- Teacher assigned to the class has matching school_id
- Raises exception if validation fails

### check_teacher_class_mismatches()
Helper function to identify existing mismatches.

**Returns:**
- Teacher email and school_id
- Class name
- Number of students
- Number of mismatched students
- List of student school_ids

**Usage:**
```sql
SELECT * FROM check_teacher_class_mismatches();
```

## Installation

### Step 1: Run Database Migration
```sql
-- Run this in Supabase SQL Editor
\i database-migrations/add-teacher-class-validation.sql
```

### Step 2: Fix Existing Mismatches
```sql
-- First, identify mismatches
SELECT * FROM check_teacher_class_mismatches();

-- Then fix them manually or run:
\i FIX_NULL_SCHOOL_IDS.sql
```

### Step 3: Deploy Frontend Changes
The frontend validation is already included in:
- `client/components/TeacherManagement.tsx`
- `client/pages/Academic.tsx`
- `client/pages/Attendance.tsx`
- `client/pages/Registrar.tsx`

## Error Messages

### Database Trigger Errors

**Teacher Assignment Error:**
```
Cannot assign teacher to class P3. 
Teacher school_id (abc-123) does not match 5 student(s) in this class. 
Please ensure all students have the same school_id as the teacher.
```

**Student Assignment Error:**
```
Cannot assign student to class P3. 
Student school_id (abc-123) does not match teacher school_id (xyz-789) for this class.
```

**Missing School ID Error:**
```
Teacher must have a school_id before being assigned to a class
```

### Frontend Validation Errors

**Toast Notification:**
```
School ID Mismatch
Cannot assign teacher to P3. Students in this class belong to a different school.
```

## Best Practices

### 1. Always Set School ID First
Before assigning teachers or students to classes:
```sql
-- Set teacher school_id
UPDATE users 
SET school_id = 'your-school-uuid'
WHERE email = 'teacher@example.com';

-- Set student school_id
UPDATE students 
SET school_id = 'your-school-uuid'
WHERE id = 'student-uuid';
```

### 2. Check for Mismatches Regularly
```sql
-- Run this weekly to catch any issues
SELECT * FROM check_teacher_class_mismatches();
```

### 3. Fix Mismatches Immediately
If mismatches are found:
```sql
-- Option 1: Update students to match teacher
UPDATE students
SET school_id = (SELECT school_id FROM users WHERE id = 'teacher-uuid')
WHERE class = 'P3';

-- Option 2: Reassign teacher to different class
DELETE FROM teacher_classes 
WHERE teacher_id = 'teacher-uuid' AND class = 'P3';
```

### 4. Use Explicit Filters in Queries
Always filter by school_id in queries:
```typescript
const { data } = await supabase
  .from('students')
  .select('*')
  .eq('class', selectedClass)
  .eq('school_id', profile.school_id) // ✅ Explicit filter
  .eq('status', 'active');
```

Don't rely only on RLS:
```typescript
// ❌ BAD - Relies only on RLS
const { data } = await supabase
  .from('students')
  .select('*')
  .eq('class', selectedClass)
  .eq('status', 'active');
```

## Troubleshooting

### Issue: Teacher can't see students in assigned class

**Diagnosis:**
```sql
-- Check school_ids
SELECT 
  'Teacher' as type,
  school_id,
  email
FROM users 
WHERE email = 'teacher@example.com'

UNION ALL

SELECT 
  'Students' as type,
  school_id,
  COUNT(*)::text || ' students'
FROM students 
WHERE class = 'P3'
GROUP BY school_id;
```

**Fix:**
```sql
-- Update students to match teacher
UPDATE students
SET school_id = (SELECT school_id FROM users WHERE email = 'teacher@example.com')
WHERE class = 'P3';
```

### Issue: Can't assign teacher to class

**Error:** "Cannot assign teacher to class P3..."

**Diagnosis:**
```sql
-- Check what's wrong
SELECT 
  u.email as teacher,
  u.school_id as teacher_school_id,
  s.full_name as student,
  s.school_id as student_school_id,
  CASE 
    WHEN u.school_id = s.school_id THEN 'MATCH'
    WHEN u.school_id IS NULL THEN 'TEACHER NULL'
    WHEN s.school_id IS NULL THEN 'STUDENT NULL'
    ELSE 'MISMATCH'
  END as status
FROM users u
CROSS JOIN students s
WHERE u.email = 'teacher@example.com'
  AND s.class = 'P3';
```

**Fix:**
```sql
-- Fix NULL school_ids first
UPDATE users 
SET school_id = (SELECT id FROM schools LIMIT 1)
WHERE email = 'teacher@example.com' AND school_id IS NULL;

UPDATE students
SET school_id = (SELECT school_id FROM users WHERE email = 'teacher@example.com')
WHERE class = 'P3';
```

### Issue: Students have NULL school_id

**Diagnosis:**
```sql
SELECT COUNT(*) as null_count
FROM students
WHERE school_id IS NULL;
```

**Fix:**
```sql
-- Set all students to the school's ID
UPDATE students
SET school_id = (SELECT id FROM schools LIMIT 1)
WHERE school_id IS NULL;
```

## Testing

### Test 1: Valid Assignment
```sql
-- Should succeed
INSERT INTO teacher_classes (teacher_id, class, academic_year)
VALUES (
  (SELECT id FROM users WHERE email = 'teacher@example.com'),
  'P3',
  '2024/2025'
);
```

### Test 2: Invalid Assignment (Different School)
```sql
-- Should fail with error
-- First create a mismatch
UPDATE students SET school_id = 'different-uuid' WHERE class = 'P3' LIMIT 1;

-- Then try to assign teacher
INSERT INTO teacher_classes (teacher_id, class, academic_year)
VALUES (
  (SELECT id FROM users WHERE email = 'teacher@example.com'),
  'P3',
  '2024/2025'
);
-- Expected: ERROR - school_id mismatch
```

### Test 3: NULL School ID
```sql
-- Should fail with error
UPDATE users SET school_id = NULL WHERE email = 'teacher@example.com';

INSERT INTO teacher_classes (teacher_id, class, academic_year)
VALUES (
  (SELECT id FROM users WHERE email = 'teacher@example.com'),
  'P3',
  '2024/2025'
);
-- Expected: ERROR - Teacher must have a school_id
```

## Maintenance

### Weekly Checks
```sql
-- Run every Monday
SELECT * FROM check_teacher_class_mismatches();
```

### Monthly Audit
```sql
-- Check for NULL school_ids
SELECT 'Teachers with NULL school_id' as issue, COUNT(*) as count
FROM users WHERE role = 'teacher' AND school_id IS NULL
UNION ALL
SELECT 'Students with NULL school_id' as issue, COUNT(*) as count
FROM students WHERE school_id IS NULL
UNION ALL
SELECT 'Staff with NULL school_id' as issue, COUNT(*) as count
FROM staff WHERE school_id IS NULL;
```

## Benefits

1. **Automatic Protection** - No manual checks needed
2. **Clear Error Messages** - Easy to understand what went wrong
3. **Multi-Layer Defense** - Database + Frontend validation
4. **Prevents Data Leakage** - Teachers can only see their school's students
5. **Easy Troubleshooting** - Helper functions identify issues quickly
6. **Future-Proof** - Works for all new assignments automatically

## Summary

This system ensures that teachers and students in the same class always belong to the same school. It prevents multi-tenancy violations at multiple levels:
- Database triggers block invalid assignments
- Frontend validation warns before saving
- Explicit query filters ensure correct data loading
- Helper functions identify and fix existing issues
