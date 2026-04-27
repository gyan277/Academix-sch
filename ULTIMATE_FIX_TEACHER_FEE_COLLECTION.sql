-- ULTIMATE FIX: Teacher Fee Collection System
-- This script does EVERYTHING needed in one go

-- ============================================
-- PART 1: CREATE ALL MISSING OBJECTS
-- ============================================

-- Create teacher_fee_collections table if not exists
CREATE TABLE IF NOT EXISTS teacher_fee_collections (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  school_id UUID NOT NULL REFERENCES schools(id) ON DELETE CASCADE,
  teacher_id UUID NOT NULL REFERENCES teachers(id) ON DELETE CASCADE,
  student_id UUID NOT NULL REFERENCES students(id) ON DELETE CASCADE,
  payment_id UUID REFERENCES payments(id) ON DELETE SET NULL,
  collection_type TEXT NOT NULL CHECK (collection_type IN ('bus', 'canteen')),
  amount DECIMAL(10, 2) NOT NULL CHECK (amount > 0),
  collection_date DATE NOT NULL DEFAULT CURRENT_DATE,
  status TEXT NOT NULL DEFAULT 'pending' CHECK (status IN ('pending', 'confirmed', 'rejected')),
  confirmed_by UUID REFERENCES auth.users(id) ON DELETE SET NULL,
  confirmed_at TIMESTAMPTZ,
  rejection_reason TEXT,
  notes TEXT,
  academic_year TEXT NOT NULL,
  term TEXT NOT NULL,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Add column to school_settings if not exists
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_name = 'school_settings' 
    AND column_name = 'enable_teacher_fee_collection'
  ) THEN
    ALTER TABLE school_settings 
    ADD COLUMN enable_teacher_fee_collection BOOLEAN DEFAULT false;
  END IF;
END $$;

-- ============================================
-- PART 2: ENABLE RLS
-- ============================================

ALTER TABLE teacher_fee_collections ENABLE ROW LEVEL SECURITY;

-- ============================================
-- PART 3: DROP OLD POLICIES (if they exist)
-- ============================================

DROP POLICY IF EXISTS "Users can view collections from their school" ON teacher_fee_collections;
DROP POLICY IF EXISTS "Teachers can insert collections" ON teacher_fee_collections;
DROP POLICY IF EXISTS "Admins can update collections" ON teacher_fee_collections;

-- ============================================
-- PART 4: CREATE NEW POLICIES
-- ============================================

CREATE POLICY "Users can view collections from their school"
  ON teacher_fee_collections FOR SELECT
  USING (
    school_id IN (
      SELECT school_id FROM users WHERE id = auth.uid()
    )
  );

CREATE POLICY "Teachers can insert collections"
  ON teacher_fee_collections FOR INSERT
  WITH CHECK (
    school_id IN (
      SELECT school_id FROM users WHERE id = auth.uid()
    )
  );

CREATE POLICY "Admins can update collections"
  ON teacher_fee_collections FOR UPDATE
  USING (
    school_id IN (
      SELECT school_id FROM users WHERE id = auth.uid() AND role = 'admin'
    )
  );

-- ============================================
-- PART 5: CREATE TRIGGER FOR AUTO-PAYMENT
-- ============================================

-- Drop trigger if exists
DROP TRIGGER IF EXISTS create_payment_on_confirmation ON teacher_fee_collections;
DROP FUNCTION IF EXISTS create_payment_from_collection();

-- Create function
CREATE OR REPLACE FUNCTION create_payment_from_collection()
RETURNS TRIGGER AS $$
DECLARE
  v_student_record RECORD;
BEGIN
  -- Only proceed if status changed to 'confirmed' and no payment exists yet
  IF NEW.status = 'confirmed' AND OLD.status = 'pending' AND NEW.payment_id IS NULL THEN
    
    -- Get student info
    SELECT student_number, full_name, class 
    INTO v_student_record
    FROM students 
    WHERE id = NEW.student_id;
    
    -- Create payment
    INSERT INTO payments (
      school_id,
      student_id,
      student_number,
      student_name,
      class,
      amount,
      payment_date,
      payment_method,
      category,
      description,
      academic_year,
      term,
      recorded_by
    ) VALUES (
      NEW.school_id,
      NEW.student_id,
      v_student_record.student_number,
      v_student_record.full_name,
      v_student_record.class,
      NEW.amount,
      NEW.collection_date,
      'Cash',
      CASE 
        WHEN NEW.collection_type = 'bus' THEN 'Bus Fee'
        WHEN NEW.collection_type = 'canteen' THEN 'Canteen Fee'
      END,
      'Collected by teacher - ' || COALESCE(NEW.notes, ''),
      NEW.academic_year,
      NEW.term,
      NEW.confirmed_by
    )
    RETURNING id INTO NEW.payment_id;
    
  END IF;
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Create trigger
CREATE TRIGGER create_payment_on_confirmation
  BEFORE UPDATE ON teacher_fee_collections
  FOR EACH ROW
  EXECUTE FUNCTION create_payment_from_collection();

-- ============================================
-- PART 6: GRANT PERMISSIONS
-- ============================================

GRANT ALL ON teacher_fee_collections TO authenticated;
GRANT ALL ON teacher_fee_collections TO service_role;

-- ============================================
-- PART 7: FORCE SCHEMA REFRESH (MULTIPLE METHODS)
-- ============================================

-- Method 1: Standard NOTIFY
NOTIFY pgrst, 'reload schema';

-- Method 2: Reload config
NOTIFY pgrst, 'reload config';

-- Method 3: Wait for processing
SELECT pg_sleep(2);

-- ============================================
-- PART 8: VERIFICATION
-- ============================================

-- Check table exists
SELECT 
  '1. Table Check' as step,
  CASE 
    WHEN COUNT(*) > 0 THEN '✅ teacher_fee_collections table exists'
    ELSE '❌ Table missing'
  END as result
FROM information_schema.tables 
WHERE table_name = 'teacher_fee_collections';

-- Check column exists
SELECT 
  '2. Column Check' as step,
  CASE 
    WHEN COUNT(*) > 0 THEN '✅ enable_teacher_fee_collection column exists'
    ELSE '❌ Column missing'
  END as result
FROM information_schema.columns 
WHERE table_name = 'school_settings' 
AND column_name = 'enable_teacher_fee_collection';

-- Check policies
SELECT 
  '3. Policies Check' as step,
  COUNT(*)::text || ' policies created' as result
FROM pg_policies 
WHERE tablename = 'teacher_fee_collections';

-- Check trigger
SELECT 
  '4. Trigger Check' as step,
  CASE 
    WHEN COUNT(*) > 0 THEN '✅ Trigger exists'
    ELSE '❌ Trigger missing'
  END as result
FROM pg_trigger 
WHERE tgname = 'create_payment_on_confirmation';

-- Final message
SELECT 
  '✅ SETUP COMPLETE!' as status,
  'IMPORTANT: Wait 10 seconds before refreshing your app!' as instruction,
  'Then press F5 in your browser' as step1,
  'The error should be gone' as step2;

-- ============================================
-- PART 9: ADDITIONAL SCHEMA REFRESH
-- ============================================

-- Send one more notification after verification
NOTIFY pgrst, 'reload schema';

SELECT '🔄 Final schema refresh sent. Wait 10 seconds, then refresh app (F5)' as final_step;
