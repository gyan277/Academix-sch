-- =====================================================
-- QUICK SETUP FOR ENHANCED STAFF MANAGEMENT
-- =====================================================
-- Run this to enable teacher creation in Registrar
-- =====================================================

-- Step 1: Ensure staff table has email column
ALTER TABLE staff 
ADD COLUMN IF NOT EXISTS email TEXT;

-- Step 2: Update existing staff records to have proper email links
UPDATE staff 
SET email = u.email
FROM users u
WHERE staff.id = u.id 
  AND staff.email IS NULL 
  AND u.email IS NOT NULL;

-- Step 3: Create indexes for better performance
CREATE INDEX IF NOT EXISTS idx_staff_position ON staff(position);
CREATE INDEX IF NOT EXISTS idx_staff_school_id ON staff(school_id);
CREATE INDEX IF NOT EXISTS idx_staff_email ON staff(email);

-- Step 4: Verification
SELECT 
  'ENHANCED STAFF MANAGEMENT READY!' as status,
  'You can now create teachers in Registrar → Staff' as message;

-- Show current staff overview
SELECT 
  'CURRENT STAFF OVERVIEW:' as info,
  COUNT(*) as total_staff,
  COUNT(CASE WHEN position LIKE '%eacher%' THEN 1 END) as teachers,
  COUNT(CASE WHEN email IS NOT NULL THEN 1 END) as staff_with_email
FROM staff
WHERE status = 'active';

-- =====================================================
-- INSTRUCTIONS:
-- =====================================================
-- 
-- 1. Run this script in Supabase SQL Editor
-- 2. Go to Registrar → Staff tab
-- 3. Click "Add Staff" 
-- 4. Select "Teacher" as position
-- 5. Check "Create login account"
-- 6. Fill in email and password
-- 7. Teacher will be created with login access!
-- 
-- =====================================================