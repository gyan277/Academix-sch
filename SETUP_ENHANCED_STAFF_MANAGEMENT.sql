-- =====================================================
-- SETUP ENHANCED STAFF MANAGEMENT SYSTEM
-- =====================================================
-- This sets up the database for the new unified staff management
-- =====================================================

-- Step 1: Ensure staff table has email column
ALTER TABLE staff 
ADD COLUMN IF NOT EXISTS email TEXT;

-- Step 2: Create teacher_class_assignments table if it doesn't exist
CREATE TABLE IF NOT EXISTS teacher_class_assignments (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  teacher_id UUID REFERENCES users(id) ON DELETE CASCADE,
  class_name TEXT NOT NULL,
  subject TEXT,
  school_id UUID REFERENCES schools(id) ON DELETE CASCADE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  UNIQUE(teacher_id, class_name, subject, school_id)
);

-- Step 3: Enable RLS on teacher_class_assignments
ALTER TABLE teacher_class_assignments ENABLE ROW LEVEL SECURITY;

-- Step 4: Create RLS policies for teacher_class_assignments
DROP POLICY IF EXISTS "Users can view their school's teacher assignments" ON teacher_class_assignments;
CREATE POLICY "Users can view their school's teacher assignments" ON teacher_class_assignments
  FOR SELECT USING (
    school_id IN (
      SELECT school_id FROM users WHERE id = auth.uid()
    )
  );

DROP POLICY IF EXISTS "Admins can manage teacher assignments" ON teacher_class_assignments;
CREATE POLICY "Admins can manage teacher assignments" ON teacher_class_assignments
  FOR ALL USING (
    EXISTS (
      SELECT 1 FROM users 
      WHERE id = auth.uid() 
      AND role = 'admin' 
      AND school_id = teacher_class_assignments.school_id
    )
  );

-- Step 5: Create function to create teacher assignments table (for RPC call)
CREATE OR REPLACE FUNCTION create_teacher_assignments_table()
RETURNS VOID AS $$
BEGIN
  -- This function ensures the table exists
  -- It's called from the frontend to handle cases where table doesn't exist
  CREATE TABLE IF NOT EXISTS teacher_class_assignments (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    teacher_id UUID REFERENCES users(id) ON DELETE CASCADE,
    class_name TEXT NOT NULL,
    subject TEXT,
    school_id UUID REFERENCES schools(id) ON DELETE CASCADE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(teacher_id, class_name, subject, school_id)
  );
  
  -- Enable RLS if not already enabled
  ALTER TABLE teacher_class_assignments ENABLE ROW LEVEL SECURITY;
END;
$$ LANGUAGE plpgsql;

-- Step 6: Update existing staff records to have proper email links
UPDATE staff 
SET email = u.email
FROM users u
WHERE staff.id = u.id 
  AND staff.email IS NULL 
  AND u.email IS NOT NULL;

-- Step 7: Create index for better performance
CREATE INDEX IF NOT EXISTS idx_teacher_assignments_teacher_id ON teacher_class_assignments(teacher_id);
CREATE INDEX IF NOT EXISTS idx_teacher_assignments_school_id ON teacher_class_assignments(school_id);
CREATE INDEX IF NOT EXISTS idx_staff_position ON staff(position);
CREATE INDEX IF NOT EXISTS idx_staff_school_id ON staff(school_id);

-- Step 8: Create view for enhanced staff data (optional, for easier querying)
CREATE OR REPLACE VIEW enhanced_staff_view AS
SELECT 
  s.*,
  u.email as user_email,
  u.role as user_role,
  CASE WHEN u.id IS NOT NULL THEN true ELSE false END as can_login,
  COALESCE(
    ARRAY_AGG(DISTINCT tca.class_name) FILTER (WHERE tca.class_name IS NOT NULL),
    ARRAY[]::TEXT[]
  ) as assigned_classes,
  COALESCE(
    ARRAY_AGG(DISTINCT tca.subject) FILTER (WHERE tca.subject IS NOT NULL),
    ARRAY[]::TEXT[]
  ) as subjects
FROM staff s
LEFT JOIN users u ON s.id = u.id
LEFT JOIN teacher_class_assignments tca ON s.id = tca.teacher_id
GROUP BY s.id, s.staff_number, s.full_name, s.email, s.phone, s.position, 
         s.specialization, s.employment_date, s.status, s.school_id, s.created_at,
         u.email, u.role;

-- Step 9: Verification queries
SELECT 
  'ENHANCED STAFF MANAGEMENT SETUP COMPLETE!' as status,
  'Tables and policies created successfully' as message;

-- Check what we have
SELECT 
  'CURRENT STAFF OVERVIEW:' as info,
  COUNT(*) as total_staff,
  COUNT(CASE WHEN position LIKE '%eacher%' THEN 1 END) as teachers,
  COUNT(CASE WHEN email IS NOT NULL THEN 1 END) as staff_with_email
FROM staff
WHERE status = 'active';

-- Check teacher assignments
SELECT 
  'TEACHER ASSIGNMENTS:' as info,
  COUNT(*) as total_assignments,
  COUNT(DISTINCT teacher_id) as teachers_with_assignments
FROM teacher_class_assignments;

-- Show sample enhanced staff data
SELECT 
  'SAMPLE ENHANCED STAFF DATA:' as info,
  full_name,
  position,
  CASE WHEN can_login THEN 'Yes' ELSE 'No' END as can_login,
  array_length(assigned_classes, 1) as num_classes
FROM enhanced_staff_view
WHERE position LIKE '%eacher%'
LIMIT 5;

-- =====================================================
-- INSTRUCTIONS:
-- =====================================================
-- 
-- 1. Run this script in Supabase SQL Editor
-- 2. This sets up the enhanced staff management system
-- 3. The new Registrar will be able to:
--    ✅ Create staff with login accounts
--    ✅ Assign teachers to classes and subjects
--    ✅ Manage all staff types in one place
--    ✅ View teacher assignments and login status
-- 
-- 4. After running this, update the Registrar component
--    with the enhanced staff management code
-- 
-- =====================================================