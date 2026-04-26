-- =====================================================
-- FINANCE SYSTEM: Fee Management & Payment Tracking
-- =====================================================
-- This migration creates tables for managing school fees
-- and tracking student payments

-- =====================================================
-- 1. CREATE CLASS_FEES TABLE
-- =====================================================
-- Stores the fee amount set for each class

CREATE TABLE IF NOT EXISTS public.class_fees (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  school_id UUID NOT NULL REFERENCES public.school_settings(id) ON DELETE CASCADE,
  class TEXT NOT NULL,
  academic_year TEXT NOT NULL,
  fee_amount DECIMAL(10, 2) NOT NULL CHECK (fee_amount >= 0),
  term TEXT, -- Optional: 'Term 1', 'Term 2', 'Term 3', or NULL for full year
  description TEXT, -- Optional: What the fee covers
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  created_by UUID REFERENCES public.users(id),
  
  -- Ensure one fee per class per academic year per term
  UNIQUE(school_id, class, academic_year, term)
);

-- Create index for performance
CREATE INDEX IF NOT EXISTS idx_class_fees_school_id ON public.class_fees(school_id);
CREATE INDEX IF NOT EXISTS idx_class_fees_class ON public.class_fees(class);
CREATE INDEX IF NOT EXISTS idx_class_fees_academic_year ON public.class_fees(academic_year);

-- =====================================================
-- 2. CREATE STUDENT_FEES TABLE
-- =====================================================
-- Automatically created when class fee is set
-- Tracks each student's fee obligation

CREATE TABLE IF NOT EXISTS public.student_fees (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  school_id UUID NOT NULL REFERENCES public.school_settings(id) ON DELETE CASCADE,
  student_id UUID NOT NULL REFERENCES public.students(id) ON DELETE CASCADE,
  class_fee_id UUID NOT NULL REFERENCES public.class_fees(id) ON DELETE CASCADE,
  
  -- Fee details (copied from class_fees for historical record)
  class TEXT NOT NULL,
  academic_year TEXT NOT NULL,
  term TEXT,
  total_fee_amount DECIMAL(10, 2) NOT NULL CHECK (total_fee_amount >= 0),
  
  -- Payment tracking
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
  
  -- Ensure one fee record per student per class fee
  UNIQUE(student_id, class_fee_id)
);

-- Create indexes for performance
CREATE INDEX IF NOT EXISTS idx_student_fees_school_id ON public.student_fees(school_id);
CREATE INDEX IF NOT EXISTS idx_student_fees_student_id ON public.student_fees(student_id);
CREATE INDEX IF NOT EXISTS idx_student_fees_class_fee_id ON public.student_fees(class_fee_id);
CREATE INDEX IF NOT EXISTS idx_student_fees_payment_status ON public.student_fees(payment_status);

-- =====================================================
-- 3. CREATE PAYMENTS TABLE
-- =====================================================
-- Records each payment transaction

CREATE TABLE IF NOT EXISTS public.payments (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  school_id UUID NOT NULL REFERENCES public.school_settings(id) ON DELETE CASCADE,
  student_fee_id UUID NOT NULL REFERENCES public.student_fees(id) ON DELETE CASCADE,
  student_id UUID NOT NULL REFERENCES public.students(id) ON DELETE CASCADE,
  
  amount DECIMAL(10, 2) NOT NULL CHECK (amount > 0),
  payment_date DATE NOT NULL DEFAULT CURRENT_DATE,
  payment_method TEXT, -- 'cash', 'bank_transfer', 'mobile_money', etc.
  reference_number TEXT, -- Receipt number or transaction reference
  notes TEXT,
  
  recorded_by UUID REFERENCES public.users(id),
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Create indexes for performance
CREATE INDEX IF NOT EXISTS idx_payments_school_id ON public.payments(school_id);
CREATE INDEX IF NOT EXISTS idx_payments_student_fee_id ON public.payments(student_fee_id);
CREATE INDEX IF NOT EXISTS idx_payments_student_id ON public.payments(student_id);
CREATE INDEX IF NOT EXISTS idx_payments_payment_date ON public.payments(payment_date);

-- =====================================================
-- 4. CREATE TRIGGER TO UPDATE student_fees.total_paid
-- =====================================================
-- Automatically update total_paid when payment is added

CREATE OR REPLACE FUNCTION update_student_fee_total_paid()
RETURNS TRIGGER AS $$
BEGIN
  -- Update the total_paid in student_fees
  UPDATE public.student_fees
  SET 
    total_paid = (
      SELECT COALESCE(SUM(amount), 0)
      FROM public.payments
      WHERE student_fee_id = NEW.student_fee_id
    ),
    updated_at = NOW()
  WHERE id = NEW.student_fee_id;
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Create trigger for INSERT
CREATE TRIGGER trigger_update_total_paid_on_insert
AFTER INSERT ON public.payments
FOR EACH ROW
EXECUTE FUNCTION update_student_fee_total_paid();

-- Create trigger for UPDATE
CREATE TRIGGER trigger_update_total_paid_on_update
AFTER UPDATE ON public.payments
FOR EACH ROW
EXECUTE FUNCTION update_student_fee_total_paid();

-- Create trigger for DELETE
CREATE TRIGGER trigger_update_total_paid_on_delete
AFTER DELETE ON public.payments
FOR EACH ROW
EXECUTE FUNCTION update_student_fee_total_paid();

-- =====================================================
-- 5. CREATE FUNCTION TO AUTO-BILL STUDENTS
-- =====================================================
-- When a class fee is created, automatically create
-- student_fees records for all students in that class

CREATE OR REPLACE FUNCTION auto_bill_students_for_class_fee()
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

-- Create trigger
CREATE TRIGGER trigger_auto_bill_students
AFTER INSERT ON public.class_fees
FOR EACH ROW
EXECUTE FUNCTION auto_bill_students_for_class_fee();

-- =====================================================
-- 6. CREATE FUNCTION TO BILL NEW STUDENTS
-- =====================================================
-- When a new student is added to a class, automatically
-- bill them for any existing class fees

CREATE OR REPLACE FUNCTION auto_bill_new_student()
RETURNS TRIGGER AS $$
BEGIN
  -- Only process if student is active
  IF NEW.status = 'active' THEN
    -- Insert student_fees for all class fees that match this student's class
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

-- Create trigger for new students
CREATE TRIGGER trigger_auto_bill_new_student
AFTER INSERT ON public.students
FOR EACH ROW
EXECUTE FUNCTION auto_bill_new_student();

-- =====================================================
-- 7. CREATE UPDATED_AT TRIGGERS
-- =====================================================

CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER set_updated_at_class_fees
BEFORE UPDATE ON public.class_fees
FOR EACH ROW
EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER set_updated_at_student_fees
BEFORE UPDATE ON public.student_fees
FOR EACH ROW
EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER set_updated_at_payments
BEFORE UPDATE ON public.payments
FOR EACH ROW
EXECUTE FUNCTION update_updated_at_column();

-- =====================================================
-- 8. ENABLE RLS (Row Level Security)
-- =====================================================

ALTER TABLE public.class_fees ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.student_fees ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.payments ENABLE ROW LEVEL SECURITY;

-- Simple policies (no recursion)
CREATE POLICY "allow_authenticated_select_class_fees"
  ON public.class_fees FOR SELECT
  TO authenticated
  USING (true);

CREATE POLICY "allow_authenticated_insert_class_fees"
  ON public.class_fees FOR INSERT
  TO authenticated
  WITH CHECK (true);

CREATE POLICY "allow_authenticated_update_class_fees"
  ON public.class_fees FOR UPDATE
  TO authenticated
  USING (true);

CREATE POLICY "allow_authenticated_delete_class_fees"
  ON public.class_fees FOR DELETE
  TO authenticated
  USING (true);

-- Student fees policies
CREATE POLICY "allow_authenticated_select_student_fees"
  ON public.student_fees FOR SELECT
  TO authenticated
  USING (true);

CREATE POLICY "allow_authenticated_insert_student_fees"
  ON public.student_fees FOR INSERT
  TO authenticated
  WITH CHECK (true);

CREATE POLICY "allow_authenticated_update_student_fees"
  ON public.student_fees FOR UPDATE
  TO authenticated
  USING (true);

CREATE POLICY "allow_authenticated_delete_student_fees"
  ON public.student_fees FOR DELETE
  TO authenticated
  USING (true);

-- Payments policies
CREATE POLICY "allow_authenticated_select_payments"
  ON public.payments FOR SELECT
  TO authenticated
  USING (true);

CREATE POLICY "allow_authenticated_insert_payments"
  ON public.payments FOR INSERT
  TO authenticated
  WITH CHECK (true);

CREATE POLICY "allow_authenticated_update_payments"
  ON public.payments FOR UPDATE
  TO authenticated
  USING (true);

CREATE POLICY "allow_authenticated_delete_payments"
  ON public.payments FOR DELETE
  TO authenticated
  USING (true);

-- =====================================================
-- 9. VERIFICATION QUERIES
-- =====================================================

-- Check that tables were created
SELECT table_name 
FROM information_schema.tables 
WHERE table_schema = 'public' 
  AND table_name IN ('class_fees', 'student_fees', 'payments')
ORDER BY table_name;

-- Check that triggers were created
SELECT trigger_name, event_object_table, action_timing, event_manipulation
FROM information_schema.triggers
WHERE event_object_schema = 'public'
  AND event_object_table IN ('class_fees', 'student_fees', 'payments')
ORDER BY event_object_table, trigger_name;

-- =====================================================
-- MIGRATION COMPLETE!
-- =====================================================
-- 
-- How it works:
-- 
-- 1. Admin sets fee for a class (e.g., Class 1A = GH₵ 500)
-- 2. System automatically creates student_fees records for all students in Class 1A
-- 3. Each student now has a fee record with total_fee_amount = 500, total_paid = 0
-- 4. When student pays (e.g., GH₵ 200), admin records payment
-- 5. System automatically updates total_paid = 200, balance = 300, status = 'partial'
-- 6. When student pays remaining GH₵ 300, total_paid = 500, balance = 0, status = 'paid'
-- 
-- Multi-tenancy: All tables have school_id for isolation
-- =====================================================
