-- TEACHER CLASS ASSIGNMENT VALIDATION
-- Ensures teacher's school_id matches the students in the assigned class

-- Function to validate teacher-class assignment
CREATE OR REPLACE FUNCTION validate_teacher_class_assignment()
RETURNS TRIGGER AS $$
DECLARE
  teacher_school_id UUID;
  class_school_ids UUID[];
  mismatched_count INTEGER;
BEGIN
  -- Get the teacher's school_id
  SELECT school_id INTO teacher_school_id
  FROM users
  WHERE id = NEW.teacher_id;

  -- Check if teacher has a school_id
  IF teacher_school_id IS NULL THEN
    RAISE EXCEPTION 'Teacher must have a school_id before being assigned to a class';
  END IF;

  -- Get all unique school_ids of students in this class
  SELECT ARRAY_AGG(DISTINCT school_id)
  INTO class_school_ids
  FROM students
  WHERE class = NEW.class
    AND status = 'active';

  -- If there are students in the class, validate school_id match
  IF class_school_ids IS NOT NULL AND array_length(class_school_ids, 1) > 0 THEN
    -- Check if any student has a different school_id
    SELECT COUNT(*)
    INTO mismatched_count
    FROM students
    WHERE class = NEW.class
      AND status = 'active'
      AND (school_id IS NULL OR school_id != teacher_school_id);

    IF mismatched_count > 0 THEN
      RAISE EXCEPTION 'Cannot assign teacher to class %. Teacher school_id (%) does not match % student(s) in this class. Please ensure all students have the same school_id as the teacher.',
        NEW.class, teacher_school_id, mismatched_count;
    END IF;
  END IF;

  -- All validations passed
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create trigger on teacher_classes table
DROP TRIGGER IF EXISTS validate_teacher_class_before_insert ON teacher_classes;
CREATE TRIGGER validate_teacher_class_before_insert
  BEFORE INSERT OR UPDATE ON teacher_classes
  FOR EACH ROW
  EXECUTE FUNCTION validate_teacher_class_assignment();

-- Function to validate student class assignment (reverse check)
CREATE OR REPLACE FUNCTION validate_student_class_assignment()
RETURNS TRIGGER AS $$
DECLARE
  teacher_school_id UUID;
  student_school_id UUID;
  current_academic_year TEXT := '2024/2025';
BEGIN
  -- Get the student's school_id
  student_school_id := NEW.school_id;

  -- Check if student has a school_id
  IF student_school_id IS NULL THEN
    RAISE EXCEPTION 'Student must have a school_id before being assigned to a class';
  END IF;

  -- Check if there's a teacher assigned to this class
  SELECT u.school_id INTO teacher_school_id
  FROM teacher_classes tc
  JOIN users u ON tc.teacher_id = u.id
  WHERE tc.class = NEW.class
    AND tc.academic_year = current_academic_year
  LIMIT 1;

  -- If there's a teacher assigned, validate school_id match
  IF teacher_school_id IS NOT NULL THEN
    IF student_school_id != teacher_school_id THEN
      RAISE EXCEPTION 'Cannot assign student to class %. Student school_id (%) does not match teacher school_id (%) for this class.',
        NEW.class, student_school_id, teacher_school_id;
    END IF;
  END IF;

  -- All validations passed
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create trigger on students table
DROP TRIGGER IF EXISTS validate_student_class_before_insert ON students;
CREATE TRIGGER validate_student_class_before_insert
  BEFORE INSERT OR UPDATE OF class, school_id ON students
  FOR EACH ROW
  EXECUTE FUNCTION validate_student_class_assignment();

-- Helper function to check and report school_id mismatches
CREATE OR REPLACE FUNCTION check_teacher_class_mismatches()
RETURNS TABLE (
  teacher_email TEXT,
  teacher_school_id UUID,
  class TEXT,
  student_count INTEGER,
  mismatched_students INTEGER,
  student_school_ids TEXT
) AS $$
BEGIN
  RETURN QUERY
  SELECT 
    u.email,
    u.school_id,
    tc.class,
    COUNT(s.id)::INTEGER as student_count,
    COUNT(CASE WHEN s.school_id != u.school_id OR s.school_id IS NULL THEN 1 END)::INTEGER as mismatched_students,
    STRING_AGG(DISTINCT s.school_id::TEXT, ', ') as student_school_ids
  FROM teacher_classes tc
  JOIN users u ON tc.teacher_id = u.id
  LEFT JOIN students s ON s.class = tc.class AND s.status = 'active'
  WHERE tc.academic_year = '2024/2025'
  GROUP BY u.email, u.school_id, tc.class
  HAVING COUNT(CASE WHEN s.school_id != u.school_id OR s.school_id IS NULL THEN 1 END) > 0;
END;
$$ LANGUAGE plpgsql;

-- Run a check to see current mismatches
SELECT * FROM check_teacher_class_mismatches();

-- Comment explaining the system
COMMENT ON FUNCTION validate_teacher_class_assignment() IS 
'Validates that a teacher being assigned to a class has the same school_id as all students in that class. Prevents multi-tenancy violations.';

COMMENT ON FUNCTION validate_student_class_assignment() IS 
'Validates that a student being assigned to a class has the same school_id as the teacher assigned to that class. Prevents multi-tenancy violations.';

COMMENT ON FUNCTION check_teacher_class_mismatches() IS 
'Helper function to identify existing teacher-class assignments where school_ids do not match between teacher and students.';
