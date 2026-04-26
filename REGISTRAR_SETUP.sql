-- =====================================================
-- REGISTRAR MODULE - DATABASE SETUP
-- =====================================================
-- This SQL creates only the tables needed for the Registrar page
-- Run this in your Supabase SQL Editor

-- =====================================================
-- 1. ENABLE EXTENSIONS
-- =====================================================
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- =====================================================
-- 2. CREATE TABLES
-- =====================================================

-- Students Table
CREATE TABLE IF NOT EXISTS public.students (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  student_id TEXT UNIQUE NOT NULL,
  full_name TEXT NOT NULL,
  date_of_birth DATE NOT NULL,
  gender TEXT NOT NULL CHECK (gender IN ('Male', 'Female')),
  class TEXT NOT NULL,
  home_address TEXT,
  admission_date DATE NOT NULL DEFAULT CURRENT_DATE,
  parent_name TEXT NOT NULL,
  parent_phone TEXT NOT NULL,
  parent_email TEXT,
  photo_url TEXT,
  status TEXT NOT NULL DEFAULT 'active' CHECK (status IN ('active', 'inactive', 'graduated')),
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Staff Table
CREATE TABLE IF NOT EXISTS public.staff (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  staff_id TEXT UNIQUE NOT NULL,
  full_name TEXT NOT NULL,
  phone TEXT NOT NULL,
  email TEXT,
  position TEXT NOT NULL,
  specialization TEXT,
  employment_date DATE NOT NULL DEFAULT CURRENT_DATE,
  photo_url TEXT,
  status TEXT NOT NULL DEFAULT 'active' CHECK (status IN ('active', 'inactive')),
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- =====================================================
-- 3. CREATE INDEXES FOR PERFORMANCE
-- =====================================================
CREATE INDEX IF NOT EXISTS idx_students_class ON public.students(class);
CREATE INDEX IF NOT EXISTS idx_students_status ON public.students(status);
CREATE INDEX IF NOT EXISTS idx_students_student_id ON public.students(student_id);
CREATE INDEX IF NOT EXISTS idx_students_full_name ON public.students(full_name);

CREATE INDEX IF NOT EXISTS idx_staff_status ON public.staff(status);
CREATE INDEX IF NOT EXISTS idx_staff_staff_id ON public.staff(staff_id);
CREATE INDEX IF NOT EXISTS idx_staff_full_name ON public.staff(full_name);

-- =====================================================
-- 4. CREATE FUNCTIONS
-- =====================================================

-- Function to automatically update updated_at timestamp
CREATE OR REPLACE FUNCTION public.handle_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- =====================================================
-- 5. CREATE TRIGGERS
-- =====================================================

-- Triggers for updated_at on students
DROP TRIGGER IF EXISTS set_updated_at_students ON public.students;
CREATE TRIGGER set_updated_at_students
  BEFORE UPDATE ON public.students
  FOR EACH ROW
  EXECUTE FUNCTION public.handle_updated_at();

-- Triggers for updated_at on staff
DROP TRIGGER IF EXISTS set_updated_at_staff ON public.staff;
CREATE TRIGGER set_updated_at_staff
  BEFORE UPDATE ON public.staff
  FOR EACH ROW
  EXECUTE FUNCTION public.handle_updated_at();

-- =====================================================
-- 6. ENABLE ROW LEVEL SECURITY (RLS)
-- =====================================================

ALTER TABLE public.students ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.staff ENABLE ROW LEVEL SECURITY;

-- =====================================================
-- 7. CREATE RLS POLICIES
-- =====================================================

-- Students Table Policies
DROP POLICY IF EXISTS "authenticated_users_can_view_students" ON public.students;
CREATE POLICY "authenticated_users_can_view_students"
  ON public.students FOR SELECT
  TO authenticated
  USING (true);

DROP POLICY IF EXISTS "authenticated_users_can_insert_students" ON public.students;
CREATE POLICY "authenticated_users_can_insert_students"
  ON public.students FOR INSERT
  TO authenticated
  WITH CHECK (true);

DROP POLICY IF EXISTS "authenticated_users_can_update_students" ON public.students;
CREATE POLICY "authenticated_users_can_update_students"
  ON public.students FOR UPDATE
  TO authenticated
  USING (true);

DROP POLICY IF EXISTS "authenticated_users_can_delete_students" ON public.students;
CREATE POLICY "authenticated_users_can_delete_students"
  ON public.students FOR DELETE
  TO authenticated
  USING (true);

-- Staff Table Policies
DROP POLICY IF EXISTS "authenticated_users_can_view_staff" ON public.staff;
CREATE POLICY "authenticated_users_can_view_staff"
  ON public.staff FOR SELECT
  TO authenticated
  USING (true);

DROP POLICY IF EXISTS "authenticated_users_can_insert_staff" ON public.staff;
CREATE POLICY "authenticated_users_can_insert_staff"
  ON public.staff FOR INSERT
  TO authenticated
  WITH CHECK (true);

DROP POLICY IF EXISTS "authenticated_users_can_update_staff" ON public.staff;
CREATE POLICY "authenticated_users_can_update_staff"
  ON public.staff FOR UPDATE
  TO authenticated
  USING (true);

DROP POLICY IF EXISTS "authenticated_users_can_delete_staff" ON public.staff;
CREATE POLICY "authenticated_users_can_delete_staff"
  ON public.staff FOR DELETE
  TO authenticated
  USING (true);

-- =====================================================
-- 8. GRANT PERMISSIONS
-- =====================================================

-- Grant usage on schema
GRANT USAGE ON SCHEMA public TO anon, authenticated;

-- Grant permissions on tables
GRANT ALL ON public.students TO authenticated;
GRANT SELECT ON public.students TO anon;

GRANT ALL ON public.staff TO authenticated;
GRANT SELECT ON public.staff TO anon;

-- Grant permissions on sequences
GRANT ALL ON ALL SEQUENCES IN SCHEMA public TO authenticated;

-- =====================================================
-- 9. VERIFICATION QUERIES
-- =====================================================

-- Check that tables were created
SELECT table_name 
FROM information_schema.tables 
WHERE table_schema = 'public' 
  AND table_name IN ('students', 'staff')
ORDER BY table_name;

-- Check that triggers were created
SELECT trigger_name, event_object_table 
FROM information_schema.triggers 
WHERE trigger_schema = 'public'
  AND event_object_table IN ('students', 'staff')
ORDER BY event_object_table, trigger_name;

-- Check that RLS policies were created
SELECT tablename, policyname 
FROM pg_policies 
WHERE schemaname = 'public'
  AND tablename IN ('students', 'staff')
ORDER BY tablename, policyname;

-- =====================================================
-- SETUP COMPLETE!
-- =====================================================
-- The Registrar module is now ready to use.
-- 
-- Tables created:
-- - public.students (for student records)
-- - public.staff (for staff records)
--
-- Features enabled:
-- - Auto-generated UUIDs for primary keys
-- - Automatic updated_at timestamp updates
-- - Row Level Security (RLS) for data protection
-- - Indexes for fast queries
-- - Status tracking (active/inactive/graduated)
--
-- Next steps:
-- 1. Login to your application as admin
-- 2. Go to the Registrar page
-- 3. Start adding students and staff
-- 4. Data will be saved to these tables automatically
-- =====================================================
