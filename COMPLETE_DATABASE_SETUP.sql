-- =====================================================
-- MOMA SCHOOL MANAGEMENT SYSTEM - COMPLETE DATABASE SETUP
-- =====================================================
-- Run this entire script in your Supabase SQL Editor
-- This will create all tables, relationships, RLS policies, functions, and sample data

-- =====================================================
-- 1. ENABLE EXTENSIONS
-- =====================================================
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- =====================================================
-- 2. DROP EXISTING TABLES (if you want a fresh start)
-- =====================================================
-- Uncomment these lines if you want to completely reset the database
-- DROP TABLE IF EXISTS public.teacher_classes CASCADE;
-- DROP TABLE IF EXISTS public.attendance CASCADE;
-- DROP TABLE IF EXISTS public.grades CASCADE;
-- DROP TABLE IF EXISTS public.subjects CASCADE;
-- DROP TABLE IF EXISTS public.staff CASCADE;
-- DROP TABLE IF EXISTS public.students CASCADE;
-- DROP TABLE IF EXISTS public.school_settings CASCADE;
-- DROP TABLE IF EXISTS public.users CASCADE;

-- =====================================================
-- 3. CREATE TABLES
-- =====================================================

-- Users Table (extends Supabase auth.users)
CREATE TABLE IF NOT EXISTS public.users (
  id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  email TEXT UNIQUE NOT NULL,
  full_name TEXT NOT NULL,
  role TEXT NOT NULL CHECK (role IN ('admin', 'teacher', 'registrar')),
  phone TEXT,
  status TEXT NOT NULL DEFAULT 'active' CHECK (status IN ('active', 'inactive')),
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

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

-- Subjects Table
CREATE TABLE IF NOT EXISTS public.subjects (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  subject_code TEXT UNIQUE NOT NULL,
  subject_name TEXT NOT NULL,
  description TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Grades Table
CREATE TABLE IF NOT EXISTS public.grades (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  student_id UUID NOT NULL REFERENCES public.students(id) ON DELETE CASCADE,
  subject_id UUID NOT NULL REFERENCES public.subjects(id) ON DELETE CASCADE,
  class TEXT NOT NULL,
  term TEXT NOT NULL,
  academic_year TEXT NOT NULL,
  class_score NUMERIC(5,2) NOT NULL CHECK (class_score >= 0 AND class_score <= 40),
  exam_score NUMERIC(5,2) NOT NULL CHECK (exam_score >= 0 AND exam_score <= 60),
  total_score NUMERIC(5,2) GENERATED ALWAYS AS (class_score + exam_score) STORED,
  grade TEXT,
  teacher_id UUID REFERENCES public.users(id) ON DELETE SET NULL,
  remarks TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(student_id, subject_id, term, academic_year)
);

-- Attendance Table
CREATE TABLE IF NOT EXISTS public.attendance (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  student_id UUID NOT NULL REFERENCES public.students(id) ON DELETE CASCADE,
  class TEXT NOT NULL,
  date DATE NOT NULL DEFAULT CURRENT_DATE,
  status TEXT NOT NULL CHECK (status IN ('present', 'absent', 'late')),
  marked_by UUID REFERENCES public.users(id) ON DELETE SET NULL,
  notes TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(student_id, date)
);

-- Teacher Class Assignments Table
CREATE TABLE IF NOT EXISTS public.teacher_classes (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  teacher_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
  class TEXT NOT NULL,
  subject_id UUID REFERENCES public.subjects(id) ON DELETE CASCADE,
  academic_year TEXT NOT NULL DEFAULT '2024/2025',
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(teacher_id, class, academic_year)
);

-- School Settings Table
CREATE TABLE IF NOT EXISTS public.school_settings (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  school_name TEXT NOT NULL,
  school_address TEXT,
  school_phone TEXT,
  school_email TEXT,
  school_logo_url TEXT,
  headmaster_signature_url TEXT,
  current_academic_year TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- =====================================================
-- 4. CREATE INDEXES FOR PERFORMANCE
-- =====================================================
CREATE INDEX IF NOT EXISTS idx_users_role ON public.users(role);
CREATE INDEX IF NOT EXISTS idx_users_status ON public.users(status);
CREATE INDEX IF NOT EXISTS idx_students_class ON public.students(class);
CREATE INDEX IF NOT EXISTS idx_students_status ON public.students(status);
CREATE INDEX IF NOT EXISTS idx_students_student_id ON public.students(student_id);
CREATE INDEX IF NOT EXISTS idx_grades_student_id ON public.grades(student_id);
CREATE INDEX IF NOT EXISTS idx_grades_subject_id ON public.grades(subject_id);
CREATE INDEX IF NOT EXISTS idx_grades_teacher_id ON public.grades(teacher_id);
CREATE INDEX IF NOT EXISTS idx_attendance_student_id ON public.attendance(student_id);
CREATE INDEX IF NOT EXISTS idx_attendance_date ON public.attendance(date);
CREATE INDEX IF NOT EXISTS idx_teacher_classes_teacher_id ON public.teacher_classes(teacher_id);
CREATE INDEX IF NOT EXISTS idx_teacher_classes_class ON public.teacher_classes(class);

-- =====================================================
-- 5. CREATE FUNCTIONS
-- =====================================================

-- Function to automatically update updated_at timestamp
CREATE OR REPLACE FUNCTION public.handle_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Function to calculate grade from total score
CREATE OR REPLACE FUNCTION public.calculate_grade(total NUMERIC)
RETURNS TEXT AS $$
BEGIN
  IF total >= 80 THEN RETURN 'A';
  ELSIF total >= 70 THEN RETURN 'B';
  ELSIF total >= 60 THEN RETURN 'C';
  ELSIF total >= 50 THEN RETURN 'D';
  ELSIF total >= 40 THEN RETURN 'E';
  ELSE RETURN 'F';
  END IF;
END;
$$ LANGUAGE plpgsql;

-- Function to auto-calculate grade when scores are inserted/updated
CREATE OR REPLACE FUNCTION public.auto_calculate_grade()
RETURNS TRIGGER AS $$
BEGIN
  NEW.grade = public.calculate_grade(NEW.class_score + NEW.exam_score);
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Function to handle new user creation
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO public.users (id, email, full_name, role, phone, status)
  VALUES (
    NEW.id,
    NEW.email,
    COALESCE(NEW.raw_user_meta_data->>'full_name', 'New User'),
    COALESCE(NEW.raw_user_meta_data->>'role', 'teacher'),
    NEW.raw_user_meta_data->>'phone',
    'active'
  )
  ON CONFLICT (id) DO NOTHING;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- =====================================================
-- 6. CREATE TRIGGERS
-- =====================================================

-- Triggers for updated_at
DROP TRIGGER IF EXISTS set_updated_at_users ON public.users;
CREATE TRIGGER set_updated_at_users
  BEFORE UPDATE ON public.users
  FOR EACH ROW
  EXECUTE FUNCTION public.handle_updated_at();

DROP TRIGGER IF EXISTS set_updated_at_students ON public.students;
CREATE TRIGGER set_updated_at_students
  BEFORE UPDATE ON public.students
  FOR EACH ROW
  EXECUTE FUNCTION public.handle_updated_at();

DROP TRIGGER IF EXISTS set_updated_at_staff ON public.staff;
CREATE TRIGGER set_updated_at_staff
  BEFORE UPDATE ON public.staff
  FOR EACH ROW
  EXECUTE FUNCTION public.handle_updated_at();

DROP TRIGGER IF EXISTS set_updated_at_subjects ON public.subjects;
CREATE TRIGGER set_updated_at_subjects
  BEFORE UPDATE ON public.subjects
  FOR EACH ROW
  EXECUTE FUNCTION public.handle_updated_at();

DROP TRIGGER IF EXISTS set_updated_at_grades ON public.grades;
CREATE TRIGGER set_updated_at_grades
  BEFORE UPDATE ON public.grades
  FOR EACH ROW
  EXECUTE FUNCTION public.handle_updated_at();

DROP TRIGGER IF EXISTS set_updated_at_attendance ON public.attendance;
CREATE TRIGGER set_updated_at_attendance
  BEFORE UPDATE ON public.attendance
  FOR EACH ROW
  EXECUTE FUNCTION public.handle_updated_at();

DROP TRIGGER IF EXISTS set_updated_at_teacher_classes ON public.teacher_classes;
CREATE TRIGGER set_updated_at_teacher_classes
  BEFORE UPDATE ON public.teacher_classes
  FOR EACH ROW
  EXECUTE FUNCTION public.handle_updated_at();

DROP TRIGGER IF EXISTS set_updated_at_school_settings ON public.school_settings;
CREATE TRIGGER set_updated_at_school_settings
  BEFORE UPDATE ON public.school_settings
  FOR EACH ROW
  EXECUTE FUNCTION public.handle_updated_at();

-- Trigger for auto-calculating grades
DROP TRIGGER IF EXISTS calculate_grade_on_insert ON public.grades;
CREATE TRIGGER calculate_grade_on_insert
  BEFORE INSERT ON public.grades
  FOR EACH ROW
  EXECUTE FUNCTION public.auto_calculate_grade();

DROP TRIGGER IF EXISTS calculate_grade_on_update ON public.grades;
CREATE TRIGGER calculate_grade_on_update
  BEFORE UPDATE ON public.grades
  FOR EACH ROW
  EXECUTE FUNCTION public.auto_calculate_grade();

-- Trigger for new user creation
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW
  EXECUTE FUNCTION public.handle_new_user();

-- =====================================================
-- 7. ENABLE ROW LEVEL SECURITY (RLS)
-- =====================================================

ALTER TABLE public.users ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.students ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.staff ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.subjects ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.grades ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.attendance ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.teacher_classes ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.school_settings ENABLE ROW LEVEL SECURITY;

-- =====================================================
-- 8. CREATE RLS POLICIES (NON-RECURSIVE)
-- =====================================================

-- Drop all existing policies first
DROP POLICY IF EXISTS "authenticated_users_can_read_all" ON public.users;
DROP POLICY IF EXISTS "authenticated_users_can_insert" ON public.users;
DROP POLICY IF EXISTS "authenticated_users_can_update" ON public.users;
DROP POLICY IF EXISTS "authenticated_users_can_delete" ON public.users;

-- Users Table Policies (simplified to avoid recursion)
CREATE POLICY "authenticated_users_can_read_all"
  ON public.users FOR SELECT
  TO authenticated
  USING (true);

CREATE POLICY "authenticated_users_can_insert"
  ON public.users FOR INSERT
  TO authenticated
  WITH CHECK (true);

CREATE POLICY "authenticated_users_can_update"
  ON public.users FOR UPDATE
  TO authenticated
  USING (true);

CREATE POLICY "authenticated_users_can_delete"
  ON public.users FOR DELETE
  TO authenticated
  USING (true);

-- Students Table Policies
DROP POLICY IF EXISTS "authenticated_users_can_view_students" ON public.students;
CREATE POLICY "authenticated_users_can_view_students"
  ON public.students FOR SELECT
  TO authenticated
  USING (true);

DROP POLICY IF EXISTS "authenticated_users_can_manage_students" ON public.students;
CREATE POLICY "authenticated_users_can_manage_students"
  ON public.students FOR ALL
  TO authenticated
  USING (true);

-- Staff Table Policies
DROP POLICY IF EXISTS "authenticated_users_can_view_staff" ON public.staff;
CREATE POLICY "authenticated_users_can_view_staff"
  ON public.staff FOR SELECT
  TO authenticated
  USING (true);

DROP POLICY IF EXISTS "authenticated_users_can_manage_staff" ON public.staff;
CREATE POLICY "authenticated_users_can_manage_staff"
  ON public.staff FOR ALL
  TO authenticated
  USING (true);

-- Subjects Table Policies
DROP POLICY IF EXISTS "authenticated_users_can_view_subjects" ON public.subjects;
CREATE POLICY "authenticated_users_can_view_subjects"
  ON public.subjects FOR SELECT
  TO authenticated
  USING (true);

DROP POLICY IF EXISTS "authenticated_users_can_manage_subjects" ON public.subjects;
CREATE POLICY "authenticated_users_can_manage_subjects"
  ON public.subjects FOR ALL
  TO authenticated
  USING (true);

-- Grades Table Policies
DROP POLICY IF EXISTS "authenticated_users_can_view_grades" ON public.grades;
CREATE POLICY "authenticated_users_can_view_grades"
  ON public.grades FOR SELECT
  TO authenticated
  USING (true);

DROP POLICY IF EXISTS "authenticated_users_can_manage_grades" ON public.grades;
CREATE POLICY "authenticated_users_can_manage_grades"
  ON public.grades FOR ALL
  TO authenticated
  USING (true);

-- Attendance Table Policies
DROP POLICY IF EXISTS "authenticated_users_can_view_attendance" ON public.attendance;
CREATE POLICY "authenticated_users_can_view_attendance"
  ON public.attendance FOR SELECT
  TO authenticated
  USING (true);

DROP POLICY IF EXISTS "authenticated_users_can_manage_attendance" ON public.attendance;
CREATE POLICY "authenticated_users_can_manage_attendance"
  ON public.attendance FOR ALL
  TO authenticated
  USING (true);

-- Teacher Classes Policies
DROP POLICY IF EXISTS "authenticated_users_can_view_teacher_classes" ON public.teacher_classes;
CREATE POLICY "authenticated_users_can_view_teacher_classes"
  ON public.teacher_classes FOR SELECT
  TO authenticated
  USING (true);

DROP POLICY IF EXISTS "authenticated_users_can_manage_teacher_classes" ON public.teacher_classes;
CREATE POLICY "authenticated_users_can_manage_teacher_classes"
  ON public.teacher_classes FOR ALL
  TO authenticated
  USING (true);

-- School Settings Policies
DROP POLICY IF EXISTS "authenticated_users_can_view_school_settings" ON public.school_settings;
CREATE POLICY "authenticated_users_can_view_school_settings"
  ON public.school_settings FOR SELECT
  TO authenticated
  USING (true);

DROP POLICY IF EXISTS "authenticated_users_can_manage_school_settings" ON public.school_settings;
CREATE POLICY "authenticated_users_can_manage_school_settings"
  ON public.school_settings FOR ALL
  TO authenticated
  USING (true);

-- =====================================================
-- 9. INSERT DEFAULT DATA
-- =====================================================

-- Insert default school settings (admin should update this)
INSERT INTO public.school_settings (school_name, current_academic_year)
VALUES ('Your School Name', '2024/2025')
ON CONFLICT DO NOTHING;

-- Insert default subjects (admin can add more)
INSERT INTO public.subjects (subject_code, subject_name, description) VALUES
  ('MATH', 'Mathematics', 'Core mathematics curriculum'),
  ('ENG', 'English Language', 'English language and literature'),
  ('SCI', 'Science', 'General science'),
  ('SST', 'Social Studies', 'Social studies and history'),
  ('OWOP', 'Our World Our People', 'Our World Our People'),
  ('PHE', 'Physical Education', 'Physical education and sports'),
  ('ART', 'Creative Arts', 'Arts and crafts'),
  ('COMP', 'Computing', 'Computing and digital literacy'),
  ('CT', 'Career Technology', 'Career and technical education'),
  ('RME', 'Religious & Moral Education', 'Religious and moral studies')
ON CONFLICT (subject_code) DO NOTHING;

-- NOTE: No sample students, staff, or users are inserted
-- The admin will create the first admin account through Supabase Dashboard
-- Then the admin can create teachers, students, and staff through the application

-- =====================================================
-- 10. GRANT PERMISSIONS
-- =====================================================

-- Grant usage on schema
GRANT USAGE ON SCHEMA public TO anon, authenticated;

-- Grant permissions on tables
GRANT ALL ON ALL TABLES IN SCHEMA public TO authenticated;
GRANT SELECT ON ALL TABLES IN SCHEMA public TO anon;

-- Grant permissions on sequences
GRANT ALL ON ALL SEQUENCES IN SCHEMA public TO authenticated;

-- =====================================================
-- 11. VERIFICATION QUERIES
-- =====================================================

-- Check that all tables were created
SELECT table_name 
FROM information_schema.tables 
WHERE table_schema = 'public' 
  AND table_type = 'BASE TABLE'
ORDER BY table_name;

-- Check that all triggers were created
SELECT trigger_name, event_object_table 
FROM information_schema.triggers 
WHERE trigger_schema = 'public'
ORDER BY event_object_table, trigger_name;

-- Check that all RLS policies were created
SELECT schemaname, tablename, policyname 
FROM pg_policies 
WHERE schemaname = 'public'
ORDER BY tablename, policyname;

-- Check default data
SELECT * FROM public.subjects ORDER BY subject_code;
SELECT * FROM public.school_settings;

-- =====================================================
-- 12. NEXT STEPS
-- =====================================================
-- 1. Create your first admin user in Supabase Dashboard:
--    - Go to Authentication → Users → Add User
--    - Enter email and password
--    - After creating, run this SQL to make them admin:
--      UPDATE public.users SET role = 'admin' WHERE email = 'your-admin@email.com';
--
-- 2. Login to the application with admin credentials
-- 3. Use the Settings page to create teacher accounts
-- 4. Use the Registrar page to add students and staff
-- 5. Update school settings in the Settings page
--
-- =====================================================
-- SETUP COMPLETE!
-- =====================================================
-- Next steps:
-- 1. Create your first admin user via Supabase Dashboard:
--    - Go to Authentication → Users
--    - Click "Add user" → "Create new user"
--    - Email: admin@moma.com
--    - Password: (choose a strong password)
--    - Check "Auto Confirm User"
--    - Click "Create user"
--
-- 2. The trigger will automatically create the user profile
--    with role 'teacher' by default. Update it to 'admin':
--
--    UPDATE public.users 
--    SET role = 'admin', full_name = 'Admin User'
--    WHERE email = 'admin@moma.com';
--
-- 3. Start your application and login!
-- =====================================================
