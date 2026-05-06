-- =====================================================
-- CLEAR DATABASE AND KEEP ONLY TWO SCHOOLS
-- =====================================================
-- This script clears all data and keeps only:
-- 1. Mount Olivet Methodist Academy (MOMA) -> MOU prefix
-- 2. Nhyiaeso International School -> NHY prefix

-- =====================================================
-- STEP 1: SHOW CURRENT STATE
-- =====================================================

SELECT 'STEP 1: Current database state before cleanup' as status;

SELECT 
  'Schools' as table_name,
  COUNT(*) as record_count
FROM public.school_settings
UNION ALL
SELECT 
  'Students' as table_name,
  COUNT(*) as record_count
FROM public.students
UNION ALL
SELECT 
  'Staff' as table_name,
  COUNT(*) as record_count
FROM public.staff
UNION ALL
SELECT 
  'Users' as table_name,
  COUNT(*) as record_count
FROM public.users
UNION ALL
SELECT 
  'Teacher Classes' as table_name,
  COUNT(*) as record_count
FROM public.teacher_classes
UNION ALL
SELECT 
  'Academic Scores' as table_name,
  COUNT(*) as record_count
FROM public.academic_scores
UNION ALL
SELECT 
  'Payments' as table_name,
  COUNT(*) as record_count
FROM public.payments
UNION ALL
SELECT 
  'Fee Collections' as table_name,
  COUNT(*) as record_count
FROM public.fee_collections;

-- Show current schools
SELECT 
  id,
  school_name,
  'Will be ' || CASE 
    WHEN school_name ILIKE '%nhyiaeso%' THEN 'KEPT (NHY prefix)'
    WHEN school_name ILIKE '%mount%olivet%' OR school_name ILIKE '%moma%' THEN 'KEPT (MOU prefix)'
    ELSE 'DELETED'
  END as action
FROM public.school_settings
ORDER BY school_name;

-- =====================================================
-- STEP 2: IDENTIFY SCHOOLS TO KEEP
-- =====================================================

SELECT 'STEP 2: Identifying schools to keep' as status;

-- Get the IDs of schools we want to keep
DO $
DECLARE
    nhyiaeso_school_id UUID;
    mount_olivet_school_id UUID;
    schools_to_delete UUID[];
BEGIN
    -- Find Nhyiaeso International School
    SELECT id INTO nhyiaeso_school_id
    FROM public.school_settings 
    WHERE school_name ILIKE '%nhyiaeso%'
    LIMIT 1;
    
    -- Find Mount Olivet Methodist Academy
    SELECT id INTO mount_olivet_school_id
    FROM public.school_settings 
    WHERE school_name ILIKE '%mount%olivet%' OR school_name ILIKE '%moma%'
    LIMIT 1;
    
    -- Get all school IDs to delete
    SELECT ARRAY_AGG(id) INTO schools_to_delete
    FROM public.school_settings 
    WHERE id NOT IN (COALESCE(nhyiaeso_school_id, '00000000-0000-0000-0000-000000000000'::UUID), 
                     COALESCE(mount_olivet_school_id, '00000000-0000-0000-0000-000000000000'::UUID))
      AND id IS NOT NULL;
    
    RAISE NOTICE 'Nhyiaeso School ID: %', COALESCE(nhyiaeso_school_id::TEXT, 'NOT FOUND');
    RAISE NOTICE 'Mount Olivet School ID: %', COALESCE(mount_olivet_school_id::TEXT, 'NOT FOUND');
    RAISE NOTICE 'Schools to delete: %', COALESCE(array_length(schools_to_delete, 1), 0);
    
    -- Store in temporary table for use in next steps
    DROP TABLE IF EXISTS temp_cleanup_schools;
    CREATE TEMP TABLE temp_cleanup_schools (
        nhyiaeso_id UUID,
        mount_olivet_id UUID,
        delete_ids UUID[]
    );
    
    INSERT INTO temp_cleanup_schools VALUES (
        nhyiaeso_school_id,
        mount_olivet_school_id,
        schools_to_delete
    );
END $;

-- =====================================================
-- STEP 3: DELETE ALL DATA FROM UNWANTED SCHOOLS
-- =====================================================

SELECT 'STEP 3: Deleting data from unwanted schools' as status;

-- Delete academic scores
DELETE FROM public.academic_scores 
WHERE school_id = ANY(
    SELECT unnest(delete_ids) FROM temp_cleanup_schools WHERE delete_ids IS NOT NULL
);

-- Delete payments
DELETE FROM public.payments 
WHERE school_id = ANY(
    SELECT unnest(delete_ids) FROM temp_cleanup_schools WHERE delete_ids IS NOT NULL
);

-- Delete fee collections
DELETE FROM public.fee_collections 
WHERE school_id = ANY(
    SELECT unnest(delete_ids) FROM temp_cleanup_schools WHERE delete_ids IS NOT NULL
);

-- Delete teacher class assignments
DELETE FROM public.teacher_classes 
WHERE school_id = ANY(
    SELECT unnest(delete_ids) FROM temp_cleanup_schools WHERE delete_ids IS NOT NULL
);

-- Delete attendance records
DELETE FROM public.attendance 
WHERE school_id = ANY(
    SELECT unnest(delete_ids) FROM temp_cleanup_schools WHERE delete_ids IS NOT NULL
);

-- Delete students
DELETE FROM public.students 
WHERE school_id = ANY(
    SELECT unnest(delete_ids) FROM temp_cleanup_schools WHERE delete_ids IS NOT NULL
);

-- Delete staff
DELETE FROM public.staff 
WHERE school_id = ANY(
    SELECT unnest(delete_ids) FROM temp_cleanup_schools WHERE delete_ids IS NOT NULL
);

-- Delete users (be careful with auth users)
DELETE FROM public.users 
WHERE school_id = ANY(
    SELECT unnest(delete_ids) FROM temp_cleanup_schools WHERE delete_ids IS NOT NULL
);

-- Delete class fees
DELETE FROM public.class_fees 
WHERE school_id = ANY(
    SELECT unnest(delete_ids) FROM temp_cleanup_schools WHERE delete_ids IS NOT NULL
);

-- Delete staff salaries
DELETE FROM public.staff_salaries 
WHERE school_id = ANY(
    SELECT unnest(delete_ids) FROM temp_cleanup_schools WHERE delete_ids IS NOT NULL
);

-- Delete activity logs
DELETE FROM public.activity_log 
WHERE school_id = ANY(
    SELECT unnest(delete_ids) FROM temp_cleanup_schools WHERE delete_ids IS NOT NULL
);

-- Delete grading scales
DELETE FROM public.grading_scale 
WHERE school_id = ANY(
    SELECT unnest(delete_ids) FROM temp_cleanup_schools WHERE delete_ids IS NOT NULL
);

-- Finally delete the school settings
DELETE FROM public.school_settings 
WHERE id = ANY(
    SELECT unnest(delete_ids) FROM temp_cleanup_schools WHERE delete_ids IS NOT NULL
);

-- =====================================================
-- STEP 4: CLEAN UP REMAINING DATA IN KEPT SCHOOLS
-- =====================================================

SELECT 'STEP 4: Cleaning up data in remaining schools' as status;

-- Clear all students from both schools (we'll start fresh)
DELETE FROM public.students 
WHERE school_id IN (
    SELECT nhyiaeso_id FROM temp_cleanup_schools WHERE nhyiaeso_id IS NOT NULL
    UNION ALL
    SELECT mount_olivet_id FROM temp_cleanup_schools WHERE mount_olivet_id IS NOT NULL
);

-- Clear all staff except admin users
DELETE FROM public.staff 
WHERE school_id IN (
    SELECT nhyiaeso_id FROM temp_cleanup_schools WHERE nhyiaeso_id IS NOT NULL
    UNION ALL
    SELECT mount_olivet_id FROM temp_cleanup_schools WHERE mount_olivet_id IS NOT NULL
);

-- Clear teacher class assignments
DELETE FROM public.teacher_classes 
WHERE school_id IN (
    SELECT nhyiaeso_id FROM temp_cleanup_schools WHERE nhyiaeso_id IS NOT NULL
    UNION ALL
    SELECT mount_olivet_id FROM temp_cleanup_schools WHERE mount_olivet_id IS NOT NULL
);

-- Clear academic scores
DELETE FROM public.academic_scores 
WHERE school_id IN (
    SELECT nhyiaeso_id FROM temp_cleanup_schools WHERE nhyiaeso_id IS NOT NULL
    UNION ALL
    SELECT mount_olivet_id FROM temp_cleanup_schools WHERE mount_olivet_id IS NOT NULL
);

-- Clear payments and fee collections
DELETE FROM public.payments 
WHERE school_id IN (
    SELECT nhyiaeso_id FROM temp_cleanup_schools WHERE nhyiaeso_id IS NOT NULL
    UNION ALL
    SELECT mount_olivet_id FROM temp_cleanup_schools WHERE mount_olivet_id IS NOT NULL
);

DELETE FROM public.fee_collections 
WHERE school_id IN (
    SELECT nhyiaeso_id FROM temp_cleanup_schools WHERE nhyiaeso_id IS NOT NULL
    UNION ALL
    SELECT mount_olivet_id FROM temp_cleanup_schools WHERE mount_olivet_id IS NOT NULL
);

-- Clear attendance
DELETE FROM public.attendance 
WHERE school_id IN (
    SELECT nhyiaeso_id FROM temp_cleanup_schools WHERE nhyiaeso_id IS NOT NULL
    UNION ALL
    SELECT mount_olivet_id FROM temp_cleanup_schools WHERE mount_olivet_id IS NOT NULL
);

-- Clear activity logs
DELETE FROM public.activity_log 
WHERE school_id IN (
    SELECT nhyiaeso_id FROM temp_cleanup_schools WHERE nhyiaeso_id IS NOT NULL
    UNION ALL
    SELECT mount_olivet_id FROM temp_cleanup_schools WHERE mount_olivet_id IS NOT NULL
);

-- Keep only admin users, remove teacher/staff users
DELETE FROM public.users 
WHERE school_id IN (
    SELECT nhyiaeso_id FROM temp_cleanup_schools WHERE nhyiaeso_id IS NOT NULL
    UNION ALL
    SELECT mount_olivet_id FROM temp_cleanup_schools WHERE mount_olivet_id IS NOT NULL
)
AND role != 'admin';

-- =====================================================
-- STEP 5: ENSURE PROPER SCHOOL NAMES
-- =====================================================

SELECT 'STEP 5: Ensuring proper school names' as status;

-- Update school names to be consistent
UPDATE public.school_settings 
SET school_name = 'Nhyiaeso International School'
WHERE school_name ILIKE '%nhyiaeso%';

UPDATE public.school_settings 
SET school_name = 'Mount Olivet Methodist Academy'
WHERE school_name ILIKE '%mount%olivet%' OR school_name ILIKE '%moma%';

-- =====================================================
-- STEP 6: FIX STUDENT ID GENERATION SYSTEM
-- =====================================================

SELECT 'STEP 6: Setting up proper student ID generation' as status;

-- Drop old triggers and functions
DROP TRIGGER IF EXISTS generate_school_specific_student_id_trigger ON public.students;
DROP TRIGGER IF EXISTS auto_assign_student_id_trigger ON public.students;
DROP TRIGGER IF EXISTS auto_generate_proper_student_id_trigger ON public.students;
DROP FUNCTION IF EXISTS generate_school_specific_student_id();
DROP FUNCTION IF EXISTS auto_assign_student_id();
DROP FUNCTION IF EXISTS auto_generate_proper_student_id();

-- Create the proper student ID generation function
CREATE OR REPLACE FUNCTION auto_generate_proper_student_id()
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
        
        -- Generate prefix based on actual school name
        IF school_name_val ILIKE '%nhyiaeso%' THEN
            school_prefix := 'NHY';
        ELSIF school_name_val ILIKE '%mount%olivet%' OR school_name_val ILIKE '%moma%' THEN
            school_prefix := 'MOU';
        ELSE
            -- Use first 3 letters of school name (remove spaces and dots)
            school_prefix := UPPER(LEFT(REPLACE(REPLACE(COALESCE(school_name_val, 'STU'), ' ', ''), '.', ''), 3));
            -- Ensure we have 3 characters
            IF LENGTH(school_prefix) < 3 THEN
                school_prefix := RPAD(school_prefix, 3, 'X');
            END IF;
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
        
        RAISE NOTICE 'Generated % for school %', new_student_id, school_name_val;
        
    END IF;
    
    RETURN NEW;
END;
$ LANGUAGE plpgsql;

-- Create the trigger
CREATE TRIGGER auto_generate_proper_student_id_trigger
    BEFORE INSERT ON public.students
    FOR EACH ROW
    EXECUTE FUNCTION auto_generate_proper_student_id();

-- =====================================================
-- STEP 7: VERIFICATION
-- =====================================================

SELECT 'STEP 7: Final verification' as status;

-- Show remaining schools
SELECT 
  id,
  school_name,
  CASE 
    WHEN school_name ILIKE '%nhyiaeso%' THEN 'NHY (Nhyiaeso International School)'
    WHEN school_name ILIKE '%mount%olivet%' OR school_name ILIKE '%moma%' THEN 'MOU (Mount Olivet Methodist Academy)'
    ELSE 'UNKNOWN'
  END as expected_prefix
FROM public.school_settings
ORDER BY school_name;

-- Show data counts
SELECT 
  'Schools' as table_name,
  COUNT(*) as record_count
FROM public.school_settings
UNION ALL
SELECT 
  'Students' as table_name,
  COUNT(*) as record_count
FROM public.students
UNION ALL
SELECT 
  'Staff' as table_name,
  COUNT(*) as record_count
FROM public.staff
UNION ALL
SELECT 
  'Users (Admin only)' as table_name,
  COUNT(*) as record_count
FROM public.users
UNION ALL
SELECT 
  'Teacher Classes' as table_name,
  COUNT(*) as record_count
FROM public.teacher_classes
UNION ALL
SELECT 
  'Academic Scores' as table_name,
  COUNT(*) as record_count
FROM public.academic_scores
UNION ALL
SELECT 
  'Payments' as table_name,
  COUNT(*) as record_count
FROM public.payments
UNION ALL
SELECT 
  'Fee Collections' as table_name,
  COUNT(*) as record_count
FROM public.fee_collections;

-- Show admin users remaining
SELECT 
  u.email,
  u.full_name,
  u.role,
  ss.school_name
FROM public.users u
JOIN public.school_settings ss ON ss.id = u.school_id
ORDER BY ss.school_name, u.full_name;

-- Clean up temp table
DROP TABLE IF EXISTS temp_cleanup_schools;

-- =====================================================
-- SUCCESS MESSAGE
-- =====================================================

SELECT 
  '🎉 DATABASE CLEANUP COMPLETE!' as result,
  'Only 2 schools remain: Nhyiaeso International School & Mount Olivet Methodist Academy' as schools,
  'All student/staff data cleared - ready for fresh start' as data_status,
  'Student IDs will be: NHY0001, NHY0002... and MOU0001, MOU0002...' as id_format,
  'Admin users preserved for both schools' as admin_status,
  'Ready to add new students and staff!' as next_step;