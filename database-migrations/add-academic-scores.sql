-- Academic Scores System
-- Stores student scores for class work and exams
-- Uses school's custom grading scale from grading_scale table

-- Create academic_scores table
CREATE TABLE IF NOT EXISTS academic_scores (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  school_id UUID NOT NULL REFERENCES schools(id) ON DELETE CASCADE,
  student_id UUID NOT NULL REFERENCES students(id) ON DELETE CASCADE,
  subject_id UUID NOT NULL REFERENCES subjects(id) ON DELETE CASCADE,
  class VARCHAR(10) NOT NULL,
  academic_year VARCHAR(20) NOT NULL DEFAULT '2024/2025',
  term VARCHAR(20) NOT NULL, -- 'Term 1', 'Term 2', 'Term 3'
  grading_period VARCHAR(20) NOT NULL, -- 'mid-term' or 'end-term'
  class_score DECIMAL(5,2) DEFAULT 0 CHECK (class_score >= 0 AND class_score <= 50),
  exam_score DECIMAL(5,2) DEFAULT 0 CHECK (exam_score >= 0 AND exam_score <= 50),
  total_score DECIMAL(5,2) GENERATED ALWAYS AS (class_score + exam_score) STORED,
  grade VARCHAR(5),
  remarks TEXT,
  recorded_by UUID REFERENCES users(id),
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  
  -- Ensure one score record per student per subject per term per grading period
  UNIQUE(student_id, subject_id, academic_year, term, grading_period)
);

-- Create index for faster queries
CREATE INDEX IF NOT EXISTS idx_academic_scores_student ON academic_scores(student_id);
CREATE INDEX IF NOT EXISTS idx_academic_scores_class ON academic_scores(class);
CREATE INDEX IF NOT EXISTS idx_academic_scores_subject ON academic_scores(subject_id);
CREATE INDEX IF NOT EXISTS idx_academic_scores_school ON academic_scores(school_id);
CREATE INDEX IF NOT EXISTS idx_academic_scores_term ON academic_scores(academic_year, term, grading_period);

-- Enable RLS
ALTER TABLE academic_scores ENABLE ROW LEVEL SECURITY;

-- RLS Policies
CREATE POLICY "Users can view scores from their school"
  ON academic_scores FOR SELECT
  USING (
    school_id IN (
      SELECT school_id FROM users WHERE id = auth.uid()
    )
  );

CREATE POLICY "Teachers and admins can insert scores"
  ON academic_scores FOR INSERT
  WITH CHECK (
    school_id IN (
      SELECT school_id FROM users WHERE id = auth.uid()
    )
  );

CREATE POLICY "Teachers and admins can update scores"
  ON academic_scores FOR UPDATE
  USING (
    school_id IN (
      SELECT school_id FROM users WHERE id = auth.uid()
    )
  );

CREATE POLICY "Admins can delete scores"
  ON academic_scores FOR DELETE
  USING (
    school_id IN (
      SELECT school_id FROM users 
      WHERE id = auth.uid() AND role = 'admin'
    )
  );

-- Function to calculate grade based on total score using school's custom grading scale
CREATE OR REPLACE FUNCTION calculate_grade_from_scale(total DECIMAL, school_id_param UUID)
RETURNS VARCHAR(5) AS $$
DECLARE
  grade_result VARCHAR(5);
BEGIN
  -- Get grade from school's grading scale
  SELECT grade INTO grade_result
  FROM grading_scale
  WHERE school_id = school_id_param
    AND total >= min_score
    AND total <= max_score
  ORDER BY min_score DESC
  LIMIT 1;
  
  -- If no match found, return F
  IF grade_result IS NULL THEN
    RETURN 'F';
  END IF;
  
  RETURN grade_result;
END;
$$ LANGUAGE plpgsql STABLE;

-- Trigger to auto-calculate grade when scores are inserted/updated
CREATE OR REPLACE FUNCTION update_academic_grade()
RETURNS TRIGGER AS $$
BEGIN
  NEW.grade := calculate_grade_from_scale(NEW.class_score + NEW.exam_score, NEW.school_id);
  NEW.updated_at := NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_update_academic_grade
  BEFORE INSERT OR UPDATE ON academic_scores
  FOR EACH ROW
  EXECUTE FUNCTION update_academic_grade();

-- Grant permissions
GRANT ALL ON academic_scores TO authenticated;

COMMENT ON TABLE academic_scores IS 'Stores student academic scores for class work and exams';
COMMENT ON COLUMN academic_scores.class_score IS 'Class work score (max 50)';
COMMENT ON COLUMN academic_scores.exam_score IS 'Exam score (max 50)';
COMMENT ON COLUMN academic_scores.total_score IS 'Auto-calculated total (class_score + exam_score)';
COMMENT ON COLUMN academic_scores.grade IS 'Auto-calculated grade based on school grading scale';
