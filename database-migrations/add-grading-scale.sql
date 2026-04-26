-- =====================================================
-- ADD GRADING SCALE TABLE
-- =====================================================
-- This table stores the school's grading scale configuration

-- Create grading_scale table
CREATE TABLE IF NOT EXISTS public.grading_scale (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  grade TEXT NOT NULL UNIQUE,
  min_score INTEGER NOT NULL CHECK (min_score >= 0 AND min_score <= 100),
  max_score INTEGER NOT NULL CHECK (max_score >= 0 AND max_score <= 100),
  sort_order INTEGER NOT NULL DEFAULT 0,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  CONSTRAINT valid_score_range CHECK (max_score >= min_score)
);

-- Create index for faster lookups
CREATE INDEX IF NOT EXISTS idx_grading_scale_sort ON public.grading_scale(sort_order DESC);

-- Add RLS policies
ALTER TABLE public.grading_scale ENABLE ROW LEVEL SECURITY;

-- Allow authenticated users to read grading scale
CREATE POLICY "authenticated_users_can_read_grading_scale"
  ON public.grading_scale FOR SELECT
  TO authenticated
  USING (true);

-- Allow authenticated users to insert/update/delete (admin check in app)
CREATE POLICY "authenticated_users_can_modify_grading_scale"
  ON public.grading_scale FOR ALL
  TO authenticated
  USING (true)
  WITH CHECK (true);

-- Create trigger to update updated_at
CREATE OR REPLACE FUNCTION update_grading_scale_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER update_grading_scale_timestamp
  BEFORE UPDATE ON public.grading_scale
  FOR EACH ROW
  EXECUTE FUNCTION update_grading_scale_updated_at();

-- Insert default Ghanaian grading scale
INSERT INTO public.grading_scale (grade, min_score, max_score, sort_order) VALUES
  ('A1', 80, 100, 9),
  ('B2', 75, 79, 8),
  ('B3', 70, 74, 7),
  ('C4', 65, 69, 6),
  ('C5', 60, 64, 5),
  ('C6', 55, 59, 4),
  ('D7', 50, 54, 3),
  ('E8', 41, 49, 2),
  ('F9', 0, 40, 1),

ON CONFLICT (grade) DO NOTHING;

-- Grant permissions
GRANT ALL ON public.grading_scale TO authenticated;

-- Verification
SELECT * FROM public.grading_scale ORDER BY sort_order DESC;
