-- Insert a test collection to verify the system works
-- Only run this if you want to test with fake data

-- This will:
-- 1. Find a teacher
-- 2. Find a student in that teacher's class
-- 3. Create a test collection
-- 4. Show the result

DO $$
DECLARE
  v_school_id UUID;
  v_teacher_id UUID;
  v_teacher_name TEXT;
  v_student_id UUID;
  v_student_name TEXT;
  v_academic_year TEXT;
  v_term TEXT;
  v_collection_id UUID;
BEGIN
  -- Get school settings
  SELECT id, current_academic_year, current_term
  INTO v_school_id, v_academic_year, v_term
  FROM school_settings
  LIMIT 1;
  
  -- Get a teacher with a class assigned
  SELECT id, full_name, class_assigned
  INTO v_teacher_id, v_teacher_name
  FROM teachers
  WHERE class_assigned IS NOT NULL
    AND class_assigned != ''
  LIMIT 1;
  
  IF v_teacher_id IS NULL THEN
    RAISE EXCEPTION '❌ No teacher found with class assigned';
  END IF;
  
  -- Get a student from that teacher's class
  SELECT s.id, s.full_name
  INTO v_student_id, v_student_name
  FROM students s
  JOIN teachers t ON t.class_assigned = s.class
  WHERE t.id = v_teacher_id
    AND s.status = 'active'
  LIMIT 1;
  
  IF v_student_id IS NULL THEN
    RAISE EXCEPTION '❌ No student found in teacher''s class';
  END IF;
  
  -- Insert test collection
  INSERT INTO teacher_fee_collections (
    school_id,
    teacher_id,
    student_id,
    collection_type,
    amount,
    collection_date,
    notes,
    academic_year,
    term,
    status
  ) VALUES (
    v_school_id,
    v_teacher_id,
    v_student_id,
    'bus',
    50.00,
    CURRENT_DATE,
    'TEST COLLECTION - Created by script',
    v_academic_year,
    v_term,
    'pending'
  )
  RETURNING id INTO v_collection_id;
  
  RAISE NOTICE '✅ TEST COLLECTION CREATED!';
  RAISE NOTICE 'Collection ID: %', v_collection_id;
  RAISE NOTICE 'Teacher: %', v_teacher_name;
  RAISE NOTICE 'Student: %', v_student_name;
  RAISE NOTICE 'Amount: GHS 50.00';
  RAISE NOTICE 'Academic Year: %', v_academic_year;
  RAISE NOTICE 'Term: %', v_term;
  RAISE NOTICE '';
  RAISE NOTICE '👉 Now refresh the admin Finance → Teacher Collections page';
END $$;

-- Show the test collection
SELECT 
  '📋 Test Collection Details' as info,
  tfc.id,
  t.full_name as teacher,
  s.full_name as student,
  tfc.collection_type,
  tfc.amount,
  tfc.collection_date,
  tfc.status,
  tfc.academic_year,
  tfc.term,
  tfc.notes
FROM teacher_fee_collections tfc
JOIN teachers t ON t.id = tfc.teacher_id
JOIN students s ON s.id = tfc.student_id
WHERE tfc.notes LIKE '%TEST COLLECTION%'
ORDER BY tfc.created_at DESC
LIMIT 1;
