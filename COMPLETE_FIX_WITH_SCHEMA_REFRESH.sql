-- COMPLETE FIX: Teacher Fee Collection + Schema Refresh
-- Run this ENTIRE script in Supabase SQL Editor

-- Step 1: Add the column to school_settings
ALTER TABLE school_settings 
ADD COLUMN IF NOT EXISTS enable_teacher_fee_collection BOOLEAN DEFAULT false;

-- Step 2: Create the teacher_fee_collections table
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

-- Step 3: Enable RLS
ALTER TABLE teacher_fee_collections ENABLE ROW LEVEL SECURITY;

-- Step 4: Create RLS policies
DROP POLICY IF EXISTS "Users can view collections from their school" ON teacher_fee_collections;
CREATE POLICY "Users can view collections from their school"
  ON teacher_fee_collections FOR SELECT
  USING (
    school_id IN (
      SELECT school_id FROM users WHERE id = auth.uid()
    )
  );

DROP POLICY IF EXISTS "Teachers can insert collections" ON teacher_fee_collections;
CREATE POLICY "Teachers can insert collections"
  ON teacher_fee_collections FOR INSERT
  WITH CHECK (
    school_id IN (
      SELECT school_id FROM users WHERE id = auth.uid()
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

-- Step 5: CRITICAL - Notify PostgREST to reload schema
NOTIFY pgrst, 'reload schema';

-- Step 6: Verify
SELECT 
  '✅ Setup complete!' as status,
  'Table created: ' || COUNT(*)::text as teacher_fee_collections_exists
FROM information_schema.tables 
WHERE table_name = 'teacher_fee_collections';

SELECT 
  '✅ Column added!' as status,
  'enable_teacher_fee_collection exists: ' || (COUNT(*) > 0)::text as column_exists
FROM information_schema.columns 
WHERE table_name = 'school_settings' 
AND column_name = 'enable_teacher_fee_collection';

SELECT '🔄 Schema refreshed! Now refresh your app (F5)' as next_step;
