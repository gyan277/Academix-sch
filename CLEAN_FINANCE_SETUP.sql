-- =====================================================
-- CLEAN FINANCE SETUP - Start Fresh
-- =====================================================
-- This script will clean up and recreate the finance system properly

-- =====================================================
-- STEP 1: Clean up existing finance data (if any)
-- =====================================================

-- Drop existing tables (this will remove all finance data)
DROP TABLE IF EXISTS public.payments CASCADE;
DROP TABLE IF EXISTS public.student_fees CASCADE;
DROP TABLE IF EXISTS public.class_fees CASCADE;

-- Drop existing functions
DROP FUNCTION IF EXISTS public.update_student_fee_total_paid() CASCADE;
DROP FUNCTION IF EXISTS public.auto_bill_students_for_class_fee() CASCADE;
DROP FUNCTION IF EXISTS public.auto_bill_new_student() CASCADE;

-- =====================================================
-- STEP 2: Create tables
-- =====================================================

-- Class fees table
CREATE TABLE public.class_fees (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  school_id UUID NOT NULL REFERENCES public.school_settings(id) ON DELETE CASCADE,
  class TEXT NOT NULL,
  academic_year TEXT NOT NULL,
  term TEXT,
  fee_amount DECIMAL(10, 2) NOT NULL CHECK (fee_amount >= 0),
  description TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  created_by UUID REFERENCES public.users(id),
  UNIQUE(school_id, class, academic_year, term)
);

CREATE INDEX idx_class_fees_school_id ON public.class_fees(school_id);
CREATE INDEX idx_class_fees_class ON public.class_fees(class);

-- Student fees table
CREATE TABLE public.student_fees (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  school_id UUID NOT NULL REFERENCES public.school_settings(id) ON DELETE CASCADE,
  student_id UUID NOT NULL REFERENCES public.students(id) ON DELETE CASCADE,
  class_fee_id UUID NOT NULL REFERENCES public.class_fees(id) ON DELETE CASCADE,
  class TEXT NOT NULL,
  academic_year TEXT NOT NULL,
  term TEXT,
  total_fee_amount DECIMAL(10, 2) NOT NULL CHECK (total_fee_amount >= 0),
  total_paid DECIMAL(10, 2) DEFAULT 0 CHECK (total_paid >= 0),
  balance DECIMAL(10, 2) GENERATED ALWAYS AS (total_fee_amount - total_paid) STORED,
  payment_status TEXT GENERATED ALWAYS AS (
    CASE 
      WHEN total_paid >= total_fee_amount THEN 'paid'
      WHEN total_paid > 0 THEN 'partial'
      ELSE 'unpaid'
    END
  ) STORED,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(student_id, class_fee_id)
);

CREATE INDEX idx_student_fees_school_id ON public.student_fees(school_id);
CREATE INDEX idx_student_fees_student_id ON public.student_fees(student_id);
CREATE INDEX idx_student_fees_class_fee_id ON public.student_fees(class_fee_id);

-- Payments table
CREATE TABLE public.payments (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  school_id UUID NOT NULL REFERENCES public.school_settings(id) ON DELETE CASCADE,
  student_fee_id UUID NOT NULL REFERENCES public.student_fees(id) ON DELETE CASCADE,
  student_id UUID NOT NULL REFERENCES public.students(id) ON DELETE CASCADE,
  amount DECIMAL(10, 2) NOT NULL CHECK (amount > 0),
  payment_date DATE NOT NULL DEFAULT CURRENT_DATE,
  payment_method TEXT,
  reference_number TEXT,
  notes TEXT,
  recorded_by UUID REFERENCES public.users(id),
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_payments_school_id ON public.payments(school_id);
CREATE INDEX idx_payments_student_fee_id ON public.payments(student_fee_id);
CREATE INDEX idx_payments_student_id ON public.payments(student_id);
CREATE INDEX idx_payments_payment_date ON public.payments(payment_date);

-- =====================================================
-- STEP 3: Create trigger to update total_paid
-- =====================================================

CREATE OR REPLACE FUNCTION public.update_student_fee_total_paid()
RETURNS TRIGGER AS $$
BEGIN
  UPDATE public.student_fees
  SET 
    total_paid = (
      SELECT COALESCE(SUM(amount), 0)
      FROM public.payments
      WHERE student_fee_id = COALESCE(NEW.student_fee_id, OLD.student_fee_id)
    ),
    updated_at = NOW()
  WHERE id = COALESCE(NEW.student_fee_id, OLD.student_fee_id);
  
  RETURN COALESCE(NEW, OLD);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE TRIGGER trigger_update_total_paid_on_insert
AFTER INSERT ON public.payments
FOR EACH ROW
EXECUTE FUNCTION update_student_fee_total_paid();

CREATE TRIGGER trigger_update_total_paid_on_update
AFTER UPDATE ON public.payments
FOR EACH ROW
EXECUTE FUNCTION update_student_fee_total_paid();

CREATE TRIGGER trigger_update_total_paid_on_delete
AFTER DELETE ON public.payments
FOR EACH ROW
EXECUTE FUNCTION update_student_fee_total_paid();

-- =====================================================
-- STEP 4: Create trigger to auto-bill students
-- =====================================================

CREATE OR REPLACE FUNCTION public.auto_bill_students_for_class_fee()
RETURNS TRIGGER AS $$
BEGIN
  -- Insert student_fees for all active students in the class
  INSERT INTO public.student_fees (
    school_id,
    student_id,
    class_fee_id,
    class,
    academic_year,
    term,
    total_fee_amount
  )
  SELECT 
    NEW.school_id,
    s.id,
    NEW.id,
    NEW.class,
    NEW.academic_year,
    NEW.term,
    NEW.fee_amount
  FROM public.students s
  WHERE s.school_id = NEW.school_id
    AND s.class = NEW.class
    AND s.status = 'active'
  ON CONFLICT (student_id, class_fee_id) DO NOTHING;
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE TRIGGER trigger_auto_bill_students
AFTER INSERT ON public.class_fees
FOR EACH ROW
EXECUTE FUNCTION auto_bill_students_for_class_fee();

-- =====================================================
-- STEP 5: Create trigger to bill new students
-- =====================================================

CREATE OR REPLACE FUNCTION public.auto_bill_new_student()
RETURNS TRIGGER AS $$
BEGIN
  IF NEW.status = 'active' THEN
    INSERT INTO public.student_fees (
      school_id,
      student_id,
      class_fee_id,
      class,
      academic_year,
      term,
      total_fee_amount
    )
    SELECT 
      cf.school_id,
      NEW.id,
      cf.id,
      cf.class,
      cf.academic_year,
      cf.term,
      cf.fee_amount
    FROM public.class_fees cf
    WHERE cf.school_id = NEW.school_id
      AND cf.class = NEW.class
    ON CONFLICT (student_id, class_fee_id) DO NOTHING;
  END IF;
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE TRIGGER trigger_auto_bill_new_student
AFTER INSERT ON public.students
FOR EACH ROW
EXECUTE FUNCTION auto_bill_new_student();

-- =====================================================
-- STEP 6: Enable RLS
-- =====================================================

ALTER TABLE public.class_fees ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.student_fees ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.payments ENABLE ROW LEVEL SECURITY;

-- Simple policies (no recursion)
CREATE POLICY "allow_authenticated_all_class_fees"
  ON public.class_fees FOR ALL
  TO authenticated
  USING (true)
  WITH CHECK (true);

CREATE POLICY "allow_authenticated_all_student_fees"
  ON public.student_fees FOR ALL
  TO authenticated
  USING (true)
  WITH CHECK (true);

CREATE POLICY "allow_authenticated_all_payments"
  ON public.payments FOR ALL
  TO authenticated
  USING (true)
  WITH CHECK (true);

-- =====================================================
-- STEP 7: Verify setup
-- =====================================================

SELECT 'Tables created successfully!' as status;

SELECT 
  table_name,
  'EXISTS' as status
FROM information_schema.tables 
WHERE table_schema = 'public' 
  AND table_name IN ('class_fees', 'student_fees', 'payments')
ORDER BY table_name;

SELECT 
  trigger_name,
  event_object_table,
  'ACTIVE' as status
FROM information_schema.triggers
WHERE event_object_schema = 'public'
  AND trigger_name IN (
    'trigger_auto_bill_students',
    'trigger_auto_bill_new_student',
    'trigger_update_total_paid_on_insert'
  )
ORDER BY trigger_name;

-- =====================================================
-- SETUP COMPLETE!
-- =====================================================
-- 
-- The finance system is now ready!
-- 
-- When you set a class fee:
-- 1. All active students in that class are automatically billed
-- 2. Each student gets a student_fees record
-- 3. Balance is automatically calculated
-- 
-- When you record a payment:
-- 1. Payment is recorded in payments table
-- 2. total_paid is automatically updated
-- 3. Balance is automatically recalculated
-- 4. Status is automatically updated (paid/partial/unpaid)
-- 
-- =====================================================
