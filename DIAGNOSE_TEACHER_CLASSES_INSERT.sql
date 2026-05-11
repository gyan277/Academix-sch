-- Diagnose why teacher_classes records aren't being created

-- 1. Check if teacher_classes table exists and its structure
SELECT 
    '=== TABLE STRUCTURE ===' as section,
    column_name,
    data_type,
    is_nullable,
    column_default
FROM information_schema.columns
WHERE table_name = 'teacher_classes'
ORDER BY ordinal_position;

-- 2. Check RLS policies on teacher_classes
SELECT 
    '=== RLS POLICIES ===' as section,
    schemaname,
    tablename,
    policyname,
    permissive,
    roles,
    cmd,
    qual,
    with_check
FROM pg_policies
WHERE tablename = 'teacher_classes';

-- 3. Check if RLS is enabled
SELECT 
    '=== RLS STATUS ===' as section,
    tablename,
    rowsecurity as rls_enabled
FROM pg_tables
WHERE tablename = 'teacher_classes';

-- 4. Check for triggers on teacher_classes
SELECT 
    '=== TRIGGERS ===' as section,
    trigger_name,
    event_manipulation,
    event_object_table,
    action_statement,
    action_timing
FROM information_schema.triggers
WHERE event_object_table = 'teacher_classes';

-- 5. Check current teacher_classes records
SELECT 
    '=== EXISTING RECORDS ===' as section,
    tc.id,
    tc.teacher_id,
    u.email as teacher_email,
    u.full_name as teacher_name,
    tc.class,
    tc.academic_year,
    tc.school_id,
    ss.school_name,
    ss.current_academic_year as school_current_year,
    tc.created_at
FROM teacher_classes tc
LEFT JOIN users u ON u.id = tc.teacher_id
LEFT JOIN school_settings ss ON ss.id = tc.school_id
ORDER BY tc.created_at DESC;

-- 6. Try to manually insert a test record (will show exact error if it fails)
DO $$
DECLARE
    test_teacher_id UUID;
    test_school_id UUID;
    test_academic_year TEXT;
BEGIN
    -- Get a teacher from Mount Olivet
    SELECT u.id, u.school_id, ss.current_academic_year
    INTO test_teacher_id, test_school_id, test_academic_year
    FROM users u
    JOIN school_settings ss ON ss.id = u.school_id
    WHERE u.email = 'georgegyan@gmail.com';
    
    IF test_teacher_id IS NULL THEN
        RAISE NOTICE '❌ Teacher not found';
        RETURN;
    END IF;
    
    RAISE NOTICE '=== MANUAL INSERT TEST ===';
    RAISE NOTICE 'Teacher ID: %', test_teacher_id;
    RAISE NOTICE 'School ID: %', test_school_id;
    RAISE NOTICE 'Academic Year: %', test_academic_year;
    
    -- Delete existing record first
    DELETE FROM teacher_classes 
    WHERE teacher_id = test_teacher_id 
      AND school_id = test_school_id;
    
    -- Try to insert
    BEGIN
        INSERT INTO teacher_classes (
            teacher_id,
            class,
            academic_year,
            school_id
        ) VALUES (
            test_teacher_id,
            'Primary 1',
            test_academic_year,
            test_school_id
        );
        
        RAISE NOTICE '✅ Manual insert SUCCESSFUL!';
        
        -- Verify it was inserted
        IF EXISTS (
            SELECT 1 FROM teacher_classes 
            WHERE teacher_id = test_teacher_id 
              AND class = 'Primary 1'
        ) THEN
            RAISE NOTICE '✅ Record verified in database';
        ELSE
            RAISE NOTICE '❌ Record NOT found after insert (RLS might be hiding it)';
        END IF;
        
    EXCEPTION WHEN OTHERS THEN
        RAISE NOTICE '❌ Manual insert FAILED: %', SQLERRM;
    END;
END $$;

-- 7. Check what the teacher would see (simulate their RLS context)
SELECT 
    '=== WHAT TEACHER SEES ===' as section,
    tc.*
FROM teacher_classes tc
WHERE tc.teacher_id = (SELECT id FROM users WHERE email = 'georgegyan@gmail.com');
