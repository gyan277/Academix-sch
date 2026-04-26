-- Run Finance Migration
-- This adds the enhanced finance system tables and columns
-- Run this in Supabase SQL Editor

-- First, check if the migration has already been run
DO $$
BEGIN
  -- Check if bus_fee column exists in class_fees
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_name = 'class_fees' AND column_name = 'bus_fee'
  ) THEN
    RAISE NOTICE 'Adding bus_fee and canteen_fee columns to class_fees...';
    
    -- Add new columns to class_fees
    ALTER TABLE class_fees 
    ADD COLUMN IF NOT EXISTS bus_fee DECIMAL(10,2) DEFAULT 0,
    ADD COLUMN IF NOT EXISTS canteen_fee DECIMAL(10,2) DEFAULT 0;
    
    RAISE NOTICE 'Columns added successfully!';
  ELSE
    RAISE NOTICE 'Columns already exist, skipping...';
  END IF;
END $$;

-- Check if payment_type column exists in payments
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_name = 'payments' AND column_name = 'payment_type'
  ) THEN
    RAISE NOTICE 'Adding payment_type column to payments...';
    
    -- Add payment_type column
    ALTER TABLE payments
    ADD COLUMN IF NOT EXISTS payment_type VARCHAR(20) DEFAULT 'tuition' 
    CHECK (payment_type IN ('tuition', 'bus', 'canteen', 'other'));
    
    RAISE NOTICE 'Column added successfully!';
  ELSE
    RAISE NOTICE 'Column already exists, skipping...';
  END IF;
END $$;

-- Create student_fee_overrides table if it doesn't exist
CREATE TABLE IF NOT EXISTS student_fee_overrides (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  school_id UUID NOT NULL REFERENCES schools(id) ON DELETE CASCADE,
  student_id UUID NOT NULL REFERENCES students(id) ON DELETE CASCADE,
  academic_year VARCHAR(20) NOT NULL,
  term VARCHAR(20) NOT NULL,
  
  -- Fee overrides (NULL means use class default)
  bus_fee_override DECIMAL(10,2),
  canteen_fee_override DECIMAL(10,2),
  
  -- Enrollment flags
  uses_bus BOOLEAN DEFAULT false,
  uses_canteen BOOLEAN DEFAULT false,
  
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  
  UNIQUE(student_id, academic_year, term)
);

-- Create staff_salaries table if it doesn't exist
CREATE TABLE IF NOT EXISTS staff_salaries (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  school_id UUID NOT NULL REFERENCES schools(id) ON DELETE CASCADE,
  staff_id UUID NOT NULL,
  
  -- Salary details
  monthly_salary DECIMAL(10,2) NOT NULL,
  currency VARCHAR(10) DEFAULT 'GHS',
  effective_date DATE NOT NULL,
  
  -- Status
  is_active BOOLEAN DEFAULT true,
  
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create salary_payments table if it doesn't exist
CREATE TABLE IF NOT EXISTS salary_payments (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  school_id UUID NOT NULL REFERENCES schools(id) ON DELETE CASCADE,
  staff_id UUID NOT NULL,
  
  -- Payment details
  amount DECIMAL(10,2) NOT NULL,
  payment_month VARCHAR(7) NOT NULL, -- Format: YYYY-MM
  payment_date DATE NOT NULL,
  payment_method VARCHAR(50),
  
  -- Reference
  reference_number VARCHAR(100),
  notes TEXT,
  
  -- Tracking
  paid_by UUID REFERENCES users(id),
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  
  UNIQUE(staff_id, payment_month)
);

-- Create custom_expenses table if it doesn't exist
CREATE TABLE IF NOT EXISTS custom_expenses (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  school_id UUID NOT NULL REFERENCES schools(id) ON DELETE CASCADE,
  
  -- Expense details
  expense_category VARCHAR(100) NOT NULL,
  description TEXT NOT NULL,
  amount DECIMAL(10,2) NOT NULL,
  expense_date DATE NOT NULL,
  
  -- Optional class linkage
  class VARCHAR(10),
  
  -- Payment details
  payment_method VARCHAR(50),
  reference_number VARCHAR(100),
  
  -- Tracking
  recorded_by UUID REFERENCES users(id),
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create indexes
CREATE INDEX IF NOT EXISTS idx_student_fee_overrides_student ON student_fee_overrides(student_id);
CREATE INDEX IF NOT EXISTS idx_student_fee_overrides_school ON student_fee_overrides(school_id);
CREATE INDEX IF NOT EXISTS idx_student_fee_overrides_year_term ON student_fee_overrides(academic_year, term);

CREATE INDEX IF NOT EXISTS idx_staff_salaries_staff ON staff_salaries(staff_id);
CREATE INDEX IF NOT EXISTS idx_staff_salaries_school ON staff_salaries(school_id);

CREATE INDEX IF NOT EXISTS idx_salary_payments_staff ON salary_payments(staff_id);
CREATE INDEX IF NOT EXISTS idx_salary_payments_month ON salary_payments(payment_month);
CREATE INDEX IF NOT EXISTS idx_salary_payments_school ON salary_payments(school_id);

CREATE INDEX IF NOT EXISTS idx_custom_expenses_school ON custom_expenses(school_id);
CREATE INDEX IF NOT EXISTS idx_custom_expenses_date ON custom_expenses(expense_date);
CREATE INDEX IF NOT EXISTS idx_custom_expenses_class ON custom_expenses(class);
CREATE INDEX IF NOT EXISTS idx_custom_expenses_category ON custom_expenses(expense_category);

CREATE INDEX IF NOT EXISTS idx_payments_type ON payments(payment_type);

-- Enable RLS on new tables
ALTER TABLE student_fee_overrides ENABLE ROW LEVEL SECURITY;
ALTER TABLE staff_salaries ENABLE ROW LEVEL SECURITY;
ALTER TABLE salary_payments ENABLE ROW LEVEL SECURITY;
ALTER TABLE custom_expenses ENABLE ROW LEVEL SECURITY;

-- Drop existing policies if they exist (to avoid conflicts)
DROP POLICY IF EXISTS "Users can view fee overrides from their school" ON student_fee_overrides;
DROP POLICY IF EXISTS "Admins can manage fee overrides" ON student_fee_overrides;
DROP POLICY IF EXISTS "Admins can view salaries from their school" ON staff_salaries;
DROP POLICY IF EXISTS "Admins can manage salaries" ON staff_salaries;
DROP POLICY IF EXISTS "Admins can view salary payments from their school" ON salary_payments;
DROP POLICY IF EXISTS "Admins can manage salary payments" ON salary_payments;
DROP POLICY IF EXISTS "Admins can view expenses from their school" ON custom_expenses;
DROP POLICY IF EXISTS "Admins can manage expenses" ON custom_expenses;

-- Create RLS policies
CREATE POLICY "Users can view fee overrides from their school"
  ON student_fee_overrides FOR SELECT
  USING (school_id IN (SELECT school_id FROM users WHERE id = auth.uid()));

CREATE POLICY "Admins can manage fee overrides"
  ON student_fee_overrides FOR ALL
  USING (
    school_id IN (
      SELECT school_id FROM users WHERE id = auth.uid() AND role = 'admin'
    )
  );

CREATE POLICY "Admins can view salaries from their school"
  ON staff_salaries FOR SELECT
  USING (
    school_id IN (
      SELECT school_id FROM users WHERE id = auth.uid() AND role = 'admin'
    )
  );

CREATE POLICY "Admins can manage salaries"
  ON staff_salaries FOR ALL
  USING (
    school_id IN (
      SELECT school_id FROM users WHERE id = auth.uid() AND role = 'admin'
    )
  );

CREATE POLICY "Admins can view salary payments from their school"
  ON salary_payments FOR SELECT
  USING (
    school_id IN (
      SELECT school_id FROM users WHERE id = auth.uid() AND role = 'admin'
    )
  );

CREATE POLICY "Admins can manage salary payments"
  ON salary_payments FOR ALL
  USING (
    school_id IN (
      SELECT school_id FROM users WHERE id = auth.uid() AND role = 'admin'
    )
  );

CREATE POLICY "Admins can view expenses from their school"
  ON custom_expenses FOR SELECT
  USING (
    school_id IN (
      SELECT school_id FROM users WHERE id = auth.uid() AND role = 'admin'
    )
  );

CREATE POLICY "Admins can manage expenses"
  ON custom_expenses FOR ALL
  USING (
    school_id IN (
      SELECT school_id FROM users WHERE id = auth.uid() AND role = 'admin'
    )
  );

-- Grant permissions
GRANT ALL ON student_fee_overrides TO authenticated;
GRANT ALL ON staff_salaries TO authenticated;
GRANT ALL ON salary_payments TO authenticated;
GRANT ALL ON custom_expenses TO authenticated;

-- Verify the migration
SELECT 
  'class_fees columns' as check_name,
  EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_name = 'class_fees' AND column_name = 'bus_fee'
  ) as bus_fee_exists,
  EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_name = 'class_fees' AND column_name = 'canteen_fee'
  ) as canteen_fee_exists
UNION ALL
SELECT 
  'payments column',
  EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_name = 'payments' AND column_name = 'payment_type'
  ),
  true
UNION ALL
SELECT 
  'new tables',
  EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'student_fee_overrides'),
  EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'staff_salaries');

-- Success message
DO $$
BEGIN
  RAISE NOTICE '✅ Finance migration completed successfully!';
  RAISE NOTICE 'You can now use the Finance module.';
END $$;
