-- Create Activity Log System for Notifications
-- This tracks all important activities in the system

-- Create activity_log table
CREATE TABLE IF NOT EXISTS activity_log (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  school_id UUID NOT NULL REFERENCES schools(id) ON DELETE CASCADE,
  user_id UUID REFERENCES auth.users(id) ON DELETE SET NULL,
  activity_type TEXT NOT NULL, -- 'payment', 'student_registered', 'attendance_marked', 'expense_added', 'score_entered', etc.
  title TEXT NOT NULL,
  description TEXT,
  metadata JSONB, -- Store additional data like student_id, amount, etc.
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Create index for faster queries
CREATE INDEX IF NOT EXISTS idx_activity_log_school_id ON activity_log(school_id);
CREATE INDEX IF NOT EXISTS idx_activity_log_created_at ON activity_log(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_activity_log_type ON activity_log(activity_type);

-- Enable RLS
ALTER TABLE activity_log ENABLE ROW LEVEL SECURITY;

-- RLS Policies
CREATE POLICY "Users can view activities from their school"
  ON activity_log FOR SELECT
  USING (
    school_id IN (
      SELECT school_id FROM users WHERE id = auth.uid()
    )
  );

CREATE POLICY "Users can insert activities for their school"
  ON activity_log FOR INSERT
  WITH CHECK (
    school_id IN (
      SELECT school_id FROM users WHERE id = auth.uid()
    )
  );

-- Function to automatically log payment activities
CREATE OR REPLACE FUNCTION log_payment_activity()
RETURNS TRIGGER AS $$
DECLARE
  student_name TEXT;
  payment_type_display TEXT;
BEGIN
  -- Get student name
  SELECT full_name INTO student_name
  FROM students
  WHERE id = NEW.student_id;

  -- Format payment type
  payment_type_display := CASE NEW.payment_type
    WHEN 'tuition' THEN 'Tuition'
    WHEN 'bus' THEN 'Bus Fee'
    WHEN 'canteen' THEN 'Canteen Fee'
    ELSE NEW.payment_type
  END;

  -- Insert activity log
  INSERT INTO activity_log (
    school_id,
    user_id,
    activity_type,
    title,
    description,
    metadata
  ) VALUES (
    NEW.school_id,
    NEW.recorded_by,
    'payment',
    'Payment Received',
    student_name || ' paid GHS ' || NEW.amount || ' for ' || payment_type_display,
    jsonb_build_object(
      'student_id', NEW.student_id,
      'student_name', student_name,
      'amount', NEW.amount,
      'payment_type', NEW.payment_type,
      'payment_method', NEW.payment_method
    )
  );

  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Create trigger for payments
DROP TRIGGER IF EXISTS trigger_log_payment ON payments;
CREATE TRIGGER trigger_log_payment
  AFTER INSERT ON payments
  FOR EACH ROW
  EXECUTE FUNCTION log_payment_activity();

-- Function to log student registration
CREATE OR REPLACE FUNCTION log_student_registration()
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO activity_log (
    school_id,
    user_id,
    activity_type,
    title,
    description,
    metadata
  ) VALUES (
    NEW.school_id,
    auth.uid(),
    'student_registered',
    'New Student Registered',
    NEW.full_name || ' (' || NEW.student_number || ') enrolled in ' || NEW.class,
    jsonb_build_object(
      'student_id', NEW.id,
      'student_name', NEW.full_name,
      'student_number', NEW.student_number,
      'class', NEW.class
    )
  );

  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Create trigger for student registration
DROP TRIGGER IF EXISTS trigger_log_student_registration ON students;
CREATE TRIGGER trigger_log_student_registration
  AFTER INSERT ON students
  FOR EACH ROW
  EXECUTE FUNCTION log_student_registration();

-- Function to log expense additions
CREATE OR REPLACE FUNCTION log_expense_activity()
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO activity_log (
    school_id,
    user_id,
    activity_type,
    title,
    description,
    metadata
  ) VALUES (
    NEW.school_id,
    NEW.recorded_by,
    'expense_added',
    'Expense Recorded',
    NEW.category || ': GHS ' || NEW.amount || ' - ' || NEW.description,
    jsonb_build_object(
      'expense_id', NEW.id,
      'category', NEW.category,
      'amount', NEW.amount,
      'description', NEW.description
    )
  );

  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Create trigger for expenses
DROP TRIGGER IF EXISTS trigger_log_expense ON expenses;
CREATE TRIGGER trigger_log_expense
  AFTER INSERT ON expenses
  FOR EACH ROW
  EXECUTE FUNCTION log_expense_activity();

-- Success message
SELECT 'Activity log system created successfully!' as result;
