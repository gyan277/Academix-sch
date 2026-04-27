-- Enable bus and canteen services for Jessica
-- This will make her fees show up in the teacher portal

-- Get current academic year and term (adjust if needed)
DO $$
DECLARE
  v_student_id UUID;
  v_school_id UUID;
  v_academic_year TEXT := '2024/2025'; -- Adjust if different
  v_term TEXT := 'Term 1'; -- Adjust if different
  v_bus_fee DECIMAL := 50.00; -- Adjust amount
  v_canteen_fee DECIMAL := 30.00; -- Adjust amount
BEGIN
  -- Find Jessica
  SELECT id, school_id INTO v_student_id, v_school_id
  FROM students
  WHERE student_number = 'MOU2008'
  LIMIT 1;

  IF v_student_id IS NULL THEN
    RAISE EXCEPTION 'Jessica (MOU2008) not found!';
  END IF;

  -- Check if override already exists
  IF EXISTS (
    SELECT 1 FROM student_fee_overrides
    WHERE student_id = v_student_id
      AND academic_year = v_academic_year
      AND term = v_term
  ) THEN
    -- Update existing
    UPDATE student_fee_overrides
    SET 
      uses_bus = true,
      uses_canteen = true,
      bus_fee_override = v_bus_fee,
      canteen_fee_override = v_canteen_fee
    WHERE student_id = v_student_id
      AND academic_year = v_academic_year
      AND term = v_term;
    
    RAISE NOTICE '✅ Updated Jessica service enrollment';
  ELSE
    -- Insert new
    INSERT INTO student_fee_overrides (
      school_id,
      student_id,
      academic_year,
      term,
      uses_bus,
      uses_canteen,
      bus_fee_override,
      canteen_fee_override
    ) VALUES (
      v_school_id,
      v_student_id,
      v_academic_year,
      v_term,
      true,
      true,
      v_bus_fee,
      v_canteen_fee
    );
    
    RAISE NOTICE '✅ Created Jessica service enrollment';
  END IF;
END $$;

-- Verify
SELECT 
  '✅ Jessica is now enrolled in bus and canteen!' as status,
  s.full_name,
  s.student_number,
  sfo.uses_bus,
  sfo.uses_canteen,
  sfo.bus_fee_override as bus_fee,
  sfo.canteen_fee_override as canteen_fee
FROM students s
JOIN student_fee_overrides sfo ON sfo.student_id = s.id
WHERE s.student_number = 'MOU2008';

SELECT 'Now refresh the teacher portal and the fees should appear!' as next_step;
