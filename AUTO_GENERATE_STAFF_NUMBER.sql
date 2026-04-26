-- =====================================================
-- AUTO-GENERATE STAFF NUMBER TRIGGER
-- =====================================================
-- This trigger automatically generates a unique staff_number
-- when a new staff member is inserted into the staff table
-- =====================================================

-- Drop existing trigger and function if they exist
DROP TRIGGER IF EXISTS generate_staff_number_trigger ON public.staff;
DROP FUNCTION IF EXISTS generate_staff_number();

-- Create function to generate staff number
CREATE OR REPLACE FUNCTION generate_staff_number()
RETURNS TRIGGER AS $$
DECLARE
  next_number INTEGER;
  new_staff_number TEXT;
  school_prefix TEXT;
BEGIN
  -- Only generate if staff_number is NULL or empty
  IF NEW.staff_number IS NULL OR NEW.staff_number = '' THEN
    
    -- Get the school prefix (first 3 letters of school name, or use 'STF' as default)
    SELECT COALESCE(
      UPPER(SUBSTRING(name FROM 1 FOR 3)),
      'STF'
    ) INTO school_prefix
    FROM public.school_settings
    WHERE id = NEW.school_id;
    
    -- If no school found, use default prefix
    IF school_prefix IS NULL THEN
      school_prefix := 'STF';
    END IF;
    
    -- Get the next number for this school
    SELECT COALESCE(MAX(
      CASE 
        WHEN staff_number ~ '^[A-Z]{3}[0-9]+$' 
        THEN CAST(SUBSTRING(staff_number FROM 4) AS INTEGER)
        ELSE 0
      END
    ), 0) + 1
    INTO next_number
    FROM public.staff
    WHERE school_id = NEW.school_id;
    
    -- Generate the new staff number (e.g., MOU-S001, MOU-S002, etc.)
    new_staff_number := school_prefix || '-S' || LPAD(next_number::TEXT, 3, '0');
    
    -- Assign the generated number
    NEW.staff_number := new_staff_number;
  END IF;
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create trigger that fires before insert
CREATE TRIGGER generate_staff_number_trigger
  BEFORE INSERT ON public.staff
  FOR EACH ROW
  EXECUTE FUNCTION generate_staff_number();

-- =====================================================
-- UPDATE EXISTING STAFF WITHOUT STAFF_NUMBER
-- =====================================================

DO $$
DECLARE
  staff_record RECORD;
  next_number INTEGER := 1;
  school_prefix TEXT;
  new_staff_number TEXT;
BEGIN
  -- Loop through staff without staff_number
  FOR staff_record IN 
    SELECT id, school_id 
    FROM public.staff 
    WHERE staff_number IS NULL OR staff_number = ''
    ORDER BY created_at, id
  LOOP
    -- Get school prefix
    SELECT COALESCE(
      UPPER(SUBSTRING(name FROM 1 FOR 3)),
      'STF'
    ) INTO school_prefix
    FROM public.school_settings
    WHERE id = staff_record.school_id;
    
    IF school_prefix IS NULL THEN
      school_prefix := 'STF';
    END IF;
    
    -- Get next available number for this school
    SELECT COALESCE(MAX(
      CASE 
        WHEN staff_number ~ '^[A-Z]{3}-S[0-9]+$' 
        THEN CAST(SUBSTRING(staff_number FROM 6) AS INTEGER)
        ELSE 0
      END
    ), 0) + 1
    INTO next_number
    FROM public.staff
    WHERE school_id = staff_record.school_id;
    
    -- Generate staff number
    new_staff_number := school_prefix || '-S' || LPAD(next_number::TEXT, 3, '0');
    
    -- Update the staff
    UPDATE public.staff
    SET staff_number = new_staff_number
    WHERE id = staff_record.id;
    
    RAISE NOTICE 'Generated staff number % for staff ID %', new_staff_number, staff_record.id;
  END LOOP;
END $$;

-- =====================================================
-- VERIFY RESULTS
-- =====================================================

SELECT 
  staff_number,
  full_name,
  position,
  employment_date
FROM public.staff
ORDER BY staff_number;

-- =====================================================
-- COMPLETE!
-- =====================================================
