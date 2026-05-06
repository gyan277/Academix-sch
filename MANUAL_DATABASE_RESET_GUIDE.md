# Manual Database Reset Guide for Production

This guide walks you through manually resetting your database in Supabase for a fresh production start.

## 🚨 WARNING
This will delete ALL data including users, schools, students, and staff. Only proceed if you want a complete fresh start for production.

## Step 1: Access Supabase Dashboard

1. Go to [supabase.com](https://supabase.com)
2. Sign in to your account
3. Select your project
4. Go to **SQL Editor** in the left sidebar

## Step 2: Delete All Data (Run Each Query Separately)

Copy and paste each query below into the SQL Editor and run them **one by one**:

### 2.1 Delete Academic and Attendance Data
```sql
DELETE FROM public.academic_scores;
DELETE FROM public.attendance;
```

### 2.2 Delete Financial Data
```sql
DELETE FROM public.payments;
DELETE FROM public.fee_collections;
DELETE FROM public.class_fees;
DELETE FROM public.staff_salaries;
```

### 2.3 Delete Teacher Assignments
```sql
DELETE FROM public.teacher_classes;
```

### 2.4 Delete Students and Staff
```sql
DELETE FROM public.students;
DELETE FROM public.staff;
```

### 2.5 Delete Users
```sql
DELETE FROM public.users;
```

### 2.6 Delete System Data
```sql
DELETE FROM public.activity_log;
DELETE FROM public.grading_scale;
```

### 2.7 Delete Schools (Last)
```sql
DELETE FROM public.school_settings;
```

## Step 3: Set Up Student ID Generation

### 3.1 Remove Old Functions and Triggers
```sql
DROP TRIGGER IF EXISTS generate_school_specific_student_id_trigger ON public.students;
DROP TRIGGER IF EXISTS auto_assign_student_id_trigger ON public.students;
DROP TRIGGER IF EXISTS auto_generate_proper_student_id_trigger ON public.students;
DROP FUNCTION IF EXISTS generate_school_specific_student_id();
DROP FUNCTION IF EXISTS auto_assign_student_id();
DROP FUNCTION IF EXISTS auto_generate_proper_student_id();
```

### 3.2 Create New Student ID Function
```sql
CREATE OR REPLACE FUNCTION auto_generate_student_id()
RETURNS TRIGGER AS $
DECLARE
    school_name_val TEXT;
    school_prefix TEXT;
    next_number INTEGER;
    new_student_id TEXT;
BEGIN
    IF NEW.student_number IS NULL OR NEW.student_number = '' THEN
        
        -- Get school name
        SELECT school_name INTO school_name_val
        FROM public.school_settings 
        WHERE id = NEW.school_id;
        
        -- Generate prefix from first 3 letters of school name
        school_prefix := UPPER(LEFT(
            REGEXP_REPLACE(
                REGEXP_REPLACE(COALESCE(school_name_val, 'SCH'), '[^A-Za-z]', '', 'g'),
                '\s+', '', 'g'
            ), 3
        ));
        
        -- Ensure we have exactly 3 characters
        IF LENGTH(school_prefix) < 3 THEN
            school_prefix := RPAD(school_prefix, 3, 'X');
        ELSIF LENGTH(school_prefix) > 3 THEN
            school_prefix := LEFT(school_prefix, 3);
        END IF;
        
        -- Get next number for this school
        SELECT COALESCE(MAX(
            CASE 
                WHEN student_number LIKE school_prefix || '%' 
                     AND LENGTH(student_number) = 7
                     AND SUBSTRING(student_number FROM 4) ~ '^[0-9]+$'
                THEN CAST(SUBSTRING(student_number FROM 4) AS INTEGER)
                ELSE 0 
            END
        ), 0) + 1
        INTO next_number
        FROM public.students 
        WHERE school_id = NEW.school_id 
          AND status = 'active'
          AND student_number IS NOT NULL;
        
        -- Create new ID
        new_student_id := school_prefix || LPAD(next_number::TEXT, 4, '0');
        
        -- Set both fields
        NEW.student_number := new_student_id;
        NEW.student_id := new_student_id;
        
    END IF;
    
    RETURN NEW;
END;
$ LANGUAGE plpgsql;
```

### 3.3 Create Student ID Trigger
```sql
CREATE TRIGGER auto_generate_student_id_trigger
    BEFORE INSERT ON public.students
    FOR EACH ROW
    EXECUTE FUNCTION auto_generate_student_id();
```

## Step 4: Set Up Staff ID Generation

### 4.1 Create Staff ID Function
```sql
CREATE OR REPLACE FUNCTION auto_generate_staff_id()
RETURNS TRIGGER AS $
DECLARE
    school_name_val TEXT;
    school_prefix TEXT;
    next_number INTEGER;
    new_staff_id TEXT;
BEGIN
    IF NEW.staff_id IS NULL OR NEW.staff_id = '' THEN
        
        -- Get school name
        SELECT school_name INTO school_name_val
        FROM public.school_settings 
        WHERE id = NEW.school_id;
        
        -- Generate prefix from first 3 letters of school name
        school_prefix := UPPER(LEFT(
            REGEXP_REPLACE(
                REGEXP_REPLACE(COALESCE(school_name_val, 'STF'), '[^A-Za-z]', '', 'g'),
                '\s+', '', 'g'
            ), 3
        ));
        
        -- Ensure we have exactly 3 characters
        IF LENGTH(school_prefix) < 3 THEN
            school_prefix := RPAD(school_prefix, 3, 'X');
        ELSIF LENGTH(school_prefix) > 3 THEN
            school_prefix := LEFT(school_prefix, 3);
        END IF;
        
        -- Get next number for this school
        SELECT COALESCE(MAX(
            CASE 
                WHEN staff_id LIKE school_prefix || '%' 
                     AND LENGTH(staff_id) = 7
                     AND SUBSTRING(staff_id FROM 4) ~ '^[0-9]+$'
                THEN CAST(SUBSTRING(staff_id FROM 4) AS INTEGER)
                ELSE 0 
            END
        ), 0) + 1
        INTO next_number
        FROM public.staff 
        WHERE school_id = NEW.school_id 
          AND status = 'active'
          AND staff_id IS NOT NULL;
        
        -- Create new ID
        new_staff_id := school_prefix || LPAD(next_number::TEXT, 4, '0');
        
        -- Set staff_id
        NEW.staff_id := new_staff_id;
        
    END IF;
    
    RETURN NEW;
END;
$ LANGUAGE plpgsql;
```

### 4.2 Create Staff ID Trigger
```sql
CREATE TRIGGER auto_generate_staff_id_trigger
    BEFORE INSERT ON public.staff
    FOR EACH ROW
    EXECUTE FUNCTION auto_generate_staff_id();
```

## Step 5: Verify Clean State

Run this query to verify everything is clean:

```sql
SELECT 
  'Schools' as table_name,
  COUNT(*) as record_count,
  CASE WHEN COUNT(*) = 0 THEN '✅ CLEAN' ELSE '❌ NOT CLEAN' END as status
FROM public.school_settings
UNION ALL
SELECT 
  'Students' as table_name,
  COUNT(*) as record_count,
  CASE WHEN COUNT(*) = 0 THEN '✅ CLEAN' ELSE '❌ NOT CLEAN' END as status
FROM public.students
UNION ALL
SELECT 
  'Staff' as table_name,
  COUNT(*) as record_count,
  CASE WHEN COUNT(*) = 0 THEN '✅ CLEAN' ELSE '❌ NOT CLEAN' END as status
FROM public.staff
UNION ALL
SELECT 
  'Users' as table_name,
  COUNT(*) as record_count,
  CASE WHEN COUNT(*) = 0 THEN '✅ CLEAN' ELSE '❌ NOT CLEAN' END as status
FROM public.users;
```

## Step 6: Verify Triggers Are Active

```sql
SELECT 
  'Student ID Generation' as system,
  CASE WHEN EXISTS (
    SELECT 1 FROM information_schema.triggers 
    WHERE trigger_name = 'auto_generate_student_id_trigger'
  ) THEN '✅ ACTIVE' ELSE '❌ MISSING' END as status
UNION ALL
SELECT 
  'Staff ID Generation' as system,
  CASE WHEN EXISTS (
    SELECT 1 FROM information_schema.triggers 
    WHERE trigger_name = 'auto_generate_staff_id_trigger'
  ) THEN '✅ ACTIVE' ELSE '❌ MISSING' END as status;
```

## ✅ Success!

If all queries ran successfully, your database is now:

- 🗑️ **Completely clean** - No data remains
- 🔧 **Properly configured** - ID generation systems ready
- 🏫 **Ready for schools** - New registrations will work perfectly
- 🆔 **Smart ID generation** - Each school gets unique prefixes

## What Happens Next?

When schools register:
- **Greenwood Academy** → Students: GRE0001, GRE0002... | Staff: GRE0001, GRE0002...
- **St. Mary's School** → Students: STM0001, STM0002... | Staff: STM0001, STM0002...
- **Any School Name** → First 3 letters become the prefix

## Need Help?

If any query fails:
1. Check the error message
2. Make sure you're running queries in order
3. Some tables might not exist (that's okay)
4. The important part is that the triggers are created successfully

Your database is now ready for production school registrations! 🎉