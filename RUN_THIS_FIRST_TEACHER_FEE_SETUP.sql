-- COMPLETE SETUP: Teacher Fee Collection System
-- Run this ENTIRE script in Supabase SQL Editor

-- ============================================
-- PART 1: Fix RLS on users table (if not done)
-- ============================================
ALTER TABLE users DISABLE ROW LEVEL SECURITY;

DO $$ 
DECLARE
    r RECORD;
BEGIN
    FOR r IN (SELECT policyname FROM pg_policies WHERE tablename = 'users') LOOP
        EXECUTE 'DROP POLICY IF EXISTS "' || r.policyname || '" ON users';
    END LOOP;
END $$;

CREATE POLICY "users_select_own"
  ON users FOR SELECT
  USING (auth.uid() = id);

CREATE POLICY "users_update_own"
  ON users FOR UPDATE
  USING (auth.uid() = id)
  WITH CHECK (auth.uid() = id);

ALTER TABLE users ENABLE ROW LEVEL SECURITY;

SELECT '✅ Step 1: Users RLS fixed' as status;

-- ============================================
-- PART 2: Add Teacher Fee Collection Feature
-- ============================================

-- Add setting to enable/disable teacher fee collection
ALTER TABLE school_settings 
ADD COLUMN IF NOT EXISTS enable_teacher_fee_collection BOOLEAN DEFAULT false;

SELECT '✅ Step 2: Added enable_teacher_fee_collection column' as status;

-- Create teacher_fee_collections table
CREATE TABLE IF NOT EXISTS teacher_fee_collections (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  school_id UUID NOT NULL REFERENCES schools(id) ON DELETE CASCADE,
  teacher_id UUID NOT NULL REFERENCES teachers(id) ON DELETE CASCADE,
  student_id UUID NOT NULL REFERENCES students(id) ON DELETE CASCADE,
  payment_id UUID REFERENCES payments(id) ON DELETE SET NULL,
  
  -- Collection details
  collection_type TEXT NOT NULL CHECK (collection_type IN ('bus', 'canteen')),
  amount DECIMAL(10, 2) NOT NULL CHECK (amount > 0),
  collection_date DATE NOT NULL DEFAULT CURRENT_DATE,
  
  -- Status tracking
  status TEXT NOT NULL DEFAULT 'pending' CHECK (status IN ('pending', 'confirmed', 'rejected')),
  confirmed_by UUID REFERENCES auth.users(id) ON DELETE SET NULL,
  confirmed_at TIMESTAMPTZ,
  rejection_reason TEXT,
  
  -- Metadata
  notes TEXT,
  academic_year TEXT NOT NULL,
  term TEXT NOT NULL,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

SELECT '✅ Step 3: Created teacher_fee_collections table' as status;

-- Create indexes
CREATE INDEX IF NOT EXISTS idx_teacher_collections_school ON teacher_fee_collections(school_id);
CREATE INDEX IF NOT EXISTS idx_teacher_collections_teacher ON teacher_fee_collections(teacher_id);
CREATE INDEX IF NOT EXISTS idx_teacher_collections_student ON teacher_fee_collections(student_id);
CREATE INDEX IF NOT EXISTS idx_teacher_collections_status ON teacher_fee_collections(status);
CREATE INDEX IF NOT EXISTS idx_teacher_collections_date ON teacher_fee_collections(collection_date);

SELECT '✅ Step 4: Created indexes' as status;

-- Enable RLS
ALTER TABLE teacher_fee_collections ENABLE ROW LEVEL SECURITY;

-- RLS Policies
DROP POLICY IF EXISTS "Users can view collections from their school" ON teacher_fee_collections;
CREATE POLICY "Users can view collections from their school"
  ON teacher_fee_collections FOR SELECT
  USING (
    school_id IN (
      SELECT school_id FROM users WHERE id = auth.uid()
    )
  );

DROP POLICY IF EXISTS "Teachers can insert collections for their school" ON teacher_fee_collections;
CREATE POLICY "Teachers can insert collections for their school"
  ON teacher_fee_collections FOR INSERT
  WITH CHECK (
    school_id IN (
      SELECT school_id FROM users WHERE id = auth.uid()
    )
    AND teacher_id IN (
      SELECT id FROM teachers WHERE user_id = auth.uid()
    )
  );

DROP POLICY IF EXISTS "Admins can update collections" ON teacher_fee_collections;
CREATE POLICY "Admins can update collections"
  ON teacher_fee_collections FOR UPDATE
  USING (
    school_id IN (
      SELECT school_id FROM users WHERE id = auth.uid() AND role = 'admin'
    )
  );

SELECT '✅ Step 5: Created RLS policies' as status;

-- Function to auto-update updated_at
CREATE OR REPLACE FUNCTION update_teacher_collection_timestamp()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trigger_update_teacher_collection_timestamp ON teacher_fee_collections;
CREATE TRIGGER trigger_update_teacher_collection_timestamp
  BEFORE UPDATE ON teacher_fee_collections
  FOR EACH ROW
  EXECUTE FUNCTION update_teacher_collection_timestamp();

SELECT '✅ Step 6: Created timestamp trigger' as status;

-- Function to create payment when collection is confirmed
CREATE OR REPLACE FUNCTION create_payment_from_collection()
RETURNS TRIGGER AS $$
DECLARE
  student_record RECORD;
BEGIN
  -- Only create payment when status changes to 'confirmed'
  IF NEW.status = 'confirmed' AND OLD.status = 'pending' THEN
    -- Get student info
    SELECT * INTO student_record FROM students WHERE id = NEW.student_id;
    
    -- Create payment record
    INSERT INTO payments (
      school_id,
      student_id,
      amount,
      payment_type,
      payment_date,
      payment_method,
      notes,
      recorded_by
    ) VALUES (
      NEW.school_id,
      NEW.student_id,
      NEW.amount,
      NEW.collection_type,
      NEW.collection_date,
      'cash',
      'Collected by teacher - ' || COALESCE(NEW.notes, ''),
      NEW.confirmed_by
    )
    RETURNING id INTO NEW.payment_id;
  END IF;
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

DROP TRIGGER IF EXISTS trigger_create_payment_from_collection ON teacher_fee_collections;
CREATE TRIGGER trigger_create_payment_from_collection
  BEFORE UPDATE ON teacher_fee_collections
  FOR EACH ROW
  WHEN (NEW.status = 'confirmed' AND OLD.status = 'pending')
  EXECUTE FUNCTION create_payment_from_collection();

SELECT '✅ Step 7: Created payment creation trigger' as status;

-- Create view for teacher collection summary
CREATE OR REPLACE VIEW teacher_collection_summary AS
SELECT 
  tc.teacher_id,
  tc.school_id,
  tc.academic_year,
  tc.term,
  tc.collection_type,
  tc.status,
  COUNT(*) as collection_count,
  SUM(tc.amount) as total_amount,
  t.full_name as teacher_name,
  t.class_assigned
FROM teacher_fee_collections tc
JOIN teachers t ON tc.teacher_id = t.id
GROUP BY 
  tc.teacher_id, 
  tc.school_id, 
  tc.academic_year, 
  tc.term, 
  tc.collection_type, 
  tc.status,
  t.full_name,
  t.class_assigned;

SELECT '✅ Step 8: Created summary view' as status;

-- ============================================
-- FINAL VERIFICATION
-- ============================================
SELECT 
  '✅✅✅ SETUP COMPLETE! ✅✅✅' as result,
  'Teacher fee collection system is ready!' as message;

-- Check what was created
SELECT 'Tables created:' as info;
SELECT table_name 
FROM information_schema.tables 
WHERE table_schema = 'public' 
AND table_name IN ('teacher_fee_collections');

SELECT 'Columns added to school_settings:' as info;
SELECT column_name, data_type 
FROM information_schema.columns 
WHERE table_name = 'school_settings' 
AND column_name = 'enable_teacher_fee_collection';

SELECT 'Now refresh your app and the error should be gone!' as next_step;
