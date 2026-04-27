-- Add payment_id column to teacher_fee_collections if it doesn't exist

-- ============================================
-- 1. Check if column exists
-- ============================================
SELECT 
  '1️⃣ Checking payment_id column' as step,
  CASE 
    WHEN EXISTS (
      SELECT 1 FROM information_schema.columns 
      WHERE table_name = 'teacher_fee_collections' 
      AND column_name = 'payment_id'
    ) THEN '✅ Column exists'
    ELSE '❌ Column missing - will add it'
  END as status;

-- ============================================
-- 2. Add payment_id column if missing
-- ============================================
ALTER TABLE teacher_fee_collections 
ADD COLUMN IF NOT EXISTS payment_id UUID REFERENCES payments(id) ON DELETE SET NULL;

SELECT '✅ Step 2: payment_id column added' as status;

-- ============================================
-- 3. Update the trigger to not update payment_id
-- ============================================
-- Since we can't update in AFTER trigger, just create payment
DROP TRIGGER IF EXISTS trigger_create_payment_from_collection ON teacher_fee_collections;
DROP FUNCTION IF EXISTS create_payment_from_collection();

CREATE OR REPLACE FUNCTION create_payment_from_collection()
RETURNS TRIGGER AS $$
DECLARE
  v_payment_id UUID;
  v_student_fee_id UUID;
  v_student_record RECORD;
BEGIN
  -- Only create payment when status changes to 'confirmed'
  IF NEW.status = 'confirmed' AND OLD.status = 'pending' THEN
    
    -- Get student info
    SELECT * INTO v_student_record FROM students WHERE id = NEW.student_id;
    
    -- Find the student_fee record for this student's class, year, and term
    SELECT sf.id INTO v_student_fee_id
    FROM student_fees sf
    JOIN class_fees cf ON cf.id = sf.class_fee_id
    WHERE sf.student_id = NEW.student_id
      AND sf.school_id = NEW.school_id
      AND sf.academic_year = NEW.academic_year
      AND sf.term = NEW.term
    LIMIT 1;
    
    -- If no student_fee exists, try to find class_fee and create student_fee
    IF v_student_fee_id IS NULL THEN
      DECLARE
        v_class_fee_id UUID;
        v_total_fee DECIMAL;
      BEGIN
        -- Find the class_fee for this student's class
        SELECT id, total_fee INTO v_class_fee_id, v_total_fee
        FROM class_fees
        WHERE school_id = NEW.school_id
          AND class = v_student_record.class
          AND academic_year = NEW.academic_year
          AND term = NEW.term
        LIMIT 1;
        
        -- If class_fee exists, create student_fee
        IF v_class_fee_id IS NOT NULL THEN
          INSERT INTO student_fees (
            school_id,
            student_id,
            class_fee_id,
            class,
            academic_year,
            term,
            total_fee_amount
          ) VALUES (
            NEW.school_id,
            NEW.student_id,
            v_class_fee_id,
            v_student_record.class,
            NEW.academic_year,
            NEW.term,
            v_total_fee
          )
          RETURNING id INTO v_student_fee_id;
        END IF;
      END;
    END IF;
    
    -- Create payment record
    INSERT INTO payments (
      school_id,
      student_id,
      student_fee_id,
      amount,
      payment_type,
      payment_date,
      payment_method,
      notes,
      recorded_by
    ) VALUES (
      NEW.school_id,
      NEW.student_id,
      v_student_fee_id,  -- Can be NULL if no student_fee exists
      NEW.amount,
      NEW.collection_type,
      NEW.collection_date,
      'cash',
      'Collected by teacher - ' || NEW.collection_type || ' fee' || COALESCE(' - ' || NEW.notes, ''),
      NEW.confirmed_by
    )
    RETURNING id INTO v_payment_id;
    
    RAISE NOTICE 'Payment created: % for collection: %', v_payment_id, NEW.id;
  END IF;
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE TRIGGER trigger_create_payment_from_collection
  AFTER UPDATE ON teacher_fee_collections
  FOR EACH ROW
  WHEN (NEW.status = 'confirmed' AND OLD.status = 'pending')
  EXECUTE FUNCTION create_payment_from_collection();

SELECT '✅ Step 3: Trigger recreated (without payment_id update)' as status;

-- ============================================
-- 4. Test
-- ============================================
SELECT 
  '✅ READY!' as status,
  'Try confirming a collection now' as next_step,
  'Payment will be created automatically' as expected;
