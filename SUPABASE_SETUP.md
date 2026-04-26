# Supabase Setup Guide

## Step 1: Create Supabase Project

1. Go to [https://supabase.com](https://supabase.com)
2. Sign up or log in
3. Click "New Project"
4. Fill in:
   - **Name:** School Management System
   - **Database Password:** (create a strong password and save it)
   - **Region:** Choose closest to you
5. Click "Create new project"
6. Wait for project to be ready (2-3 minutes)

## Step 2: Get Your Credentials

1. In your Supabase project dashboard, go to **Settings** → **API**
2. Copy these values:
   - **Project URL** (looks like: `https://xxxxx.supabase.co`)
   - **anon/public key** (starts with `eyJ...`)

## Step 3: Add Environment Variables

Create a `.env` file in your project root (if it doesn't exist) and add:

```env
VITE_SUPABASE_URL=your_project_url_here
VITE_SUPABASE_ANON_KEY=your_anon_key_here
```

**Example:**
```env
VITE_SUPABASE_URL=https://abcdefghijk.supabase.co
VITE_SUPABASE_ANON_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...
```

## Step 4: Create Database Tables

Go to **SQL Editor** in your Supabase dashboard and run this SQL:

```sql
-- Enable UUID extension
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- Users table (extends Supabase auth.users)
CREATE TABLE public.users (
  id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  email TEXT UNIQUE NOT NULL,
  full_name TEXT NOT NULL,
  role TEXT NOT NULL CHECK (role IN ('admin', 'teacher', 'registrar')),
  phone TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Students table
CREATE TABLE public.students (
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
  status TEXT DEFAULT 'active' CHECK (status IN ('active', 'inactive', 'graduated')),
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Staff table
CREATE TABLE public.staff (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  staff_id TEXT UNIQUE NOT NULL,
  full_name TEXT NOT NULL,
  phone TEXT NOT NULL,
  email TEXT,
  position TEXT NOT NULL,
  specialization TEXT,
  employment_date DATE NOT NULL DEFAULT CURRENT_DATE,
  photo_url TEXT,
  status TEXT DEFAULT 'active' CHECK (status IN ('active', 'inactive')),
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Teacher class assignments
CREATE TABLE public.teacher_classes (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  teacher_id UUID REFERENCES public.users(id) ON DELETE CASCADE,
  class_name TEXT NOT NULL,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Subjects table
CREATE TABLE public.subjects (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  name TEXT NOT NULL,
  code TEXT UNIQUE NOT NULL,
  description TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Grades/Scores table
CREATE TABLE public.grades (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  student_id UUID REFERENCES public.students(id) ON DELETE CASCADE,
  subject_id UUID REFERENCES public.subjects(id) ON DELETE CASCADE,
  class TEXT NOT NULL,
  term TEXT NOT NULL,
  academic_year TEXT NOT NULL,
  class_score DECIMAL(5,2) CHECK (class_score >= 0 AND class_score <= 30),
  exam_score DECIMAL(5,2) CHECK (exam_score >= 0 AND exam_score <= 70),
  total_score DECIMAL(5,2) GENERATED ALWAYS AS (class_score + exam_score) STORED,
  grade TEXT,
  teacher_id UUID REFERENCES public.users(id),
  remarks TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  UNIQUE(student_id, subject_id, term, academic_year)
);

-- Attendance table
CREATE TABLE public.attendance (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  student_id UUID REFERENCES public.students(id) ON DELETE CASCADE,
  class TEXT NOT NULL,
  date DATE NOT NULL,
  status TEXT NOT NULL CHECK (status IN ('present', 'absent', 'late')),
  marked_by UUID REFERENCES public.users(id),
  notes TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  UNIQUE(student_id, date)
);

-- Staff attendance table
CREATE TABLE public.staff_attendance (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  staff_id UUID REFERENCES public.staff(id) ON DELETE CASCADE,
  date DATE NOT NULL,
  status TEXT NOT NULL CHECK (status IN ('present', 'absent', 'late')),
  clock_in TIME,
  clock_out TIME,
  notes TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  UNIQUE(staff_id, date)
);

-- SMS/Communication log
CREATE TABLE public.sms_log (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  recipient_type TEXT NOT NULL CHECK (recipient_type IN ('student', 'staff', 'parent', 'all')),
  recipient_ids UUID[],
  message TEXT NOT NULL,
  status TEXT DEFAULT 'pending' CHECK (status IN ('pending', 'sent', 'failed')),
  sent_by UUID REFERENCES public.users(id),
  sent_at TIMESTAMP WITH TIME ZONE,
  delivery_status JSONB,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Academic terms
CREATE TABLE public.terms (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  name TEXT NOT NULL,
  academic_year TEXT NOT NULL,
  start_date DATE NOT NULL,
  end_date DATE NOT NULL,
  is_current BOOLEAN DEFAULT FALSE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- School settings
CREATE TABLE public.school_settings (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  school_name TEXT NOT NULL,
  school_address TEXT,
  school_phone TEXT,
  school_email TEXT,
  school_logo_url TEXT,
  headmaster_signature_url TEXT,
  current_academic_year TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Calendar events
CREATE TABLE public.calendar_events (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  title TEXT NOT NULL,
  description TEXT,
  event_date DATE NOT NULL,
  event_type TEXT NOT NULL CHECK (event_type IN ('holiday', 'exam', 'event', 'meeting')),
  created_by UUID REFERENCES public.users(id),
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create indexes for better performance
CREATE INDEX idx_students_class ON public.students(class);
CREATE INDEX idx_students_status ON public.students(status);
CREATE INDEX idx_grades_student ON public.grades(student_id);
CREATE INDEX idx_grades_term ON public.grades(term, academic_year);
CREATE INDEX idx_attendance_date ON public.attendance(date);
CREATE INDEX idx_attendance_student ON public.attendance(student_id);
CREATE INDEX idx_staff_attendance_date ON public.staff_attendance(date);

-- Create updated_at trigger function
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ language 'plpgsql';

-- Add triggers for updated_at
CREATE TRIGGER update_users_updated_at BEFORE UPDATE ON public.users
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_students_updated_at BEFORE UPDATE ON public.students
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_staff_updated_at BEFORE UPDATE ON public.staff
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_grades_updated_at BEFORE UPDATE ON public.grades
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_attendance_updated_at BEFORE UPDATE ON public.attendance
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_terms_updated_at BEFORE UPDATE ON public.terms
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_school_settings_updated_at BEFORE UPDATE ON public.school_settings
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_calendar_events_updated_at BEFORE UPDATE ON public.calendar_events
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
```

## Step 5: Set Up Row Level Security (RLS)

Run this SQL to enable security:

```sql
-- Enable RLS on all tables
ALTER TABLE public.users ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.students ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.staff ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.teacher_classes ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.subjects ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.grades ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.attendance ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.staff_attendance ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.sms_log ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.terms ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.school_settings ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.calendar_events ENABLE ROW LEVEL SECURITY;

-- Users policies
CREATE POLICY "Users can view their own data" ON public.users
    FOR SELECT USING (auth.uid() = id);

CREATE POLICY "Admins can view all users" ON public.users
    FOR SELECT USING (
        EXISTS (
            SELECT 1 FROM public.users
            WHERE id = auth.uid() AND role = 'admin'
        )
    );

-- Students policies
CREATE POLICY "Anyone authenticated can view students" ON public.students
    FOR SELECT USING (auth.role() = 'authenticated');

CREATE POLICY "Admins and registrars can insert students" ON public.students
    FOR INSERT WITH CHECK (
        EXISTS (
            SELECT 1 FROM public.users
            WHERE id = auth.uid() AND role IN ('admin', 'registrar')
        )
    );

CREATE POLICY "Admins and registrars can update students" ON public.students
    FOR UPDATE USING (
        EXISTS (
            SELECT 1 FROM public.users
            WHERE id = auth.uid() AND role IN ('admin', 'registrar')
        )
    );

CREATE POLICY "Admins can delete students" ON public.students
    FOR DELETE USING (
        EXISTS (
            SELECT 1 FROM public.users
            WHERE id = auth.uid() AND role = 'admin'
        )
    );

-- Grades policies
CREATE POLICY "Teachers and admins can view grades" ON public.grades
    FOR SELECT USING (
        EXISTS (
            SELECT 1 FROM public.users
            WHERE id = auth.uid() AND role IN ('admin', 'teacher')
        )
    );

CREATE POLICY "Teachers can insert grades" ON public.grades
    FOR INSERT WITH CHECK (
        EXISTS (
            SELECT 1 FROM public.users
            WHERE id = auth.uid() AND role = 'teacher'
        )
    );

CREATE POLICY "Teachers can update their grades" ON public.grades
    FOR UPDATE USING (teacher_id = auth.uid());

-- Attendance policies
CREATE POLICY "Teachers and admins can view attendance" ON public.attendance
    FOR SELECT USING (
        EXISTS (
            SELECT 1 FROM public.users
            WHERE id = auth.uid() AND role IN ('admin', 'teacher')
        )
    );

CREATE POLICY "Teachers can mark attendance" ON public.attendance
    FOR INSERT WITH CHECK (
        EXISTS (
            SELECT 1 FROM public.users
            WHERE id = auth.uid() AND role = 'teacher'
        )
    );

-- School settings policies
CREATE POLICY "Anyone can view school settings" ON public.school_settings
    FOR SELECT USING (true);

CREATE POLICY "Only admins can update school settings" ON public.school_settings
    FOR ALL USING (
        EXISTS (
            SELECT 1 FROM public.users
            WHERE id = auth.uid() AND role = 'admin'
        )
    );
```

## Step 6: Insert Sample Data

```sql
-- Insert default school settings
INSERT INTO public.school_settings (school_name, school_address, school_phone, school_email, current_academic_year)
VALUES ('Springhill Academy', '123 Education Street, Accra, Ghana', '+233 (0) 501 234 567', 'info@springhillacademy.edu.gh', '2023/2024');

-- Insert subjects
INSERT INTO public.subjects (name, code) VALUES
('English Language', 'ENG'),
('Mathematics', 'MATH'),
('Science', 'SCI'),
('Social Studies', 'SOC'),
('Physical Education', 'PE'),
('Arts', 'ART'),
('Music', 'MUS');

-- Insert current term
INSERT INTO public.terms (name, academic_year, start_date, end_date, is_current)
VALUES ('Term 1', '2023/2024', '2024-01-15', '2024-03-30', true);
```

## Step 7: Create Admin User

1. Go to **Authentication** → **Users** in Supabase
2. Click "Add user" → "Create new user"
3. Fill in:
   - **Email:** admin@school.edu
   - **Password:** (create a password)
   - **Auto Confirm User:** Yes
4. Click "Create user"
5. Copy the user ID

6. Go back to **SQL Editor** and run:

```sql
-- Replace 'USER_ID_HERE' with the actual user ID from step 5
INSERT INTO public.users (id, email, full_name, role)
VALUES ('USER_ID_HERE', 'admin@school.edu', 'Administrator', 'admin');
```

## Step 8: Test Connection

Restart your development server:
```bash
pnpm dev
```

Your app should now connect to Supabase!

## Next Steps

1. ✅ Database schema created
2. ✅ Security policies set up
3. ✅ Sample data inserted
4. ✅ Admin user created
5. 🔄 Update frontend to use Supabase (I'll do this next)

## Useful Supabase Dashboard Links

- **Table Editor:** View and edit data
- **SQL Editor:** Run custom queries
- **Authentication:** Manage users
- **Storage:** Upload files (logos, signatures)
- **API Docs:** Auto-generated API documentation

## Troubleshooting

### Can't connect?
- Check `.env` file has correct URL and key
- Restart dev server after adding `.env`
- Make sure variables start with `VITE_`

### RLS errors?
- Check user is authenticated
- Verify user role in `public.users` table
- Review RLS policies in Table Editor

### Need help?
- Check Supabase docs: https://supabase.com/docs
- View logs in Supabase dashboard
