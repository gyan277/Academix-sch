-- Complete Settings Integration
-- Adds academic terms and calendar events tables
-- Updates school_settings to link with schools table

-- Update school_settings to link with schools
ALTER TABLE school_settings 
ADD COLUMN IF NOT EXISTS school_id UUID REFERENCES schools(id) ON DELETE CASCADE;

CREATE INDEX IF NOT EXISTS idx_school_settings_school_id ON school_settings(school_id);

-- Academic Terms Table
CREATE TABLE IF NOT EXISTS academic_terms (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  school_id UUID NOT NULL REFERENCES schools(id) ON DELETE CASCADE,
  name TEXT NOT NULL, -- e.g., "Term 1", "Term 2", "Term 3"
  start_date DATE NOT NULL,
  end_date DATE NOT NULL,
  academic_year TEXT NOT NULL,
  is_current BOOLEAN DEFAULT false,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  
  UNIQUE(school_id, name, academic_year)
);

CREATE INDEX IF NOT EXISTS idx_academic_terms_school ON academic_terms(school_id);
CREATE INDEX IF NOT EXISTS idx_academic_terms_year ON academic_terms(academic_year);

-- Calendar Events Table
CREATE TABLE IF NOT EXISTS calendar_events (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  school_id UUID NOT NULL REFERENCES schools(id) ON DELETE CASCADE,
  title TEXT NOT NULL,
  event_date DATE NOT NULL,
  event_type TEXT NOT NULL CHECK (event_type IN ('holiday', 'exam', 'event')),
  description TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_calendar_events_school ON calendar_events(school_id);
CREATE INDEX IF NOT EXISTS idx_calendar_events_date ON calendar_events(event_date);
CREATE INDEX IF NOT EXISTS idx_calendar_events_type ON calendar_events(event_type);

-- Enable RLS
ALTER TABLE academic_terms ENABLE ROW LEVEL SECURITY;
ALTER TABLE calendar_events ENABLE ROW LEVEL SECURITY;

-- RLS Policies for academic_terms
CREATE POLICY "Users can view terms from their school"
  ON academic_terms FOR SELECT
  USING (
    school_id IN (
      SELECT school_id FROM users WHERE id = auth.uid()
    )
  );

CREATE POLICY "Admins can manage terms"
  ON academic_terms FOR ALL
  USING (
    school_id IN (
      SELECT school_id FROM users 
      WHERE id = auth.uid() AND role = 'admin'
    )
  );

-- RLS Policies for calendar_events
CREATE POLICY "Users can view events from their school"
  ON calendar_events FOR SELECT
  USING (
    school_id IN (
      SELECT school_id FROM users WHERE id = auth.uid()
    )
  );

CREATE POLICY "Admins can manage events"
  ON calendar_events FOR ALL
  USING (
    school_id IN (
      SELECT school_id FROM users 
      WHERE id = auth.uid() AND role = 'admin'
    )
  );

-- Grant permissions
GRANT ALL ON academic_terms TO authenticated;
GRANT ALL ON calendar_events TO authenticated;

COMMENT ON TABLE academic_terms IS 'Academic term definitions per school';
COMMENT ON TABLE calendar_events IS 'School calendar events (holidays, exams, etc.)';
