-- Fix school_settings NOT NULL constraints
-- Allow school_name and other fields to be nullable

-- 1. Check current column constraints
SELECT 
  column_name,
  data_type,
  is_nullable,
  column_default
FROM information_schema.columns
WHERE table_name = 'school_settings'
ORDER BY ordinal_position;

-- 2. Make school_name nullable (it's currently NOT NULL)
ALTER TABLE school_settings
ALTER COLUMN school_name DROP NOT NULL;

-- 3. Make other text fields nullable too (if they're NOT NULL)
ALTER TABLE school_settings
ALTER COLUMN school_address DROP NOT NULL;

ALTER TABLE school_settings
ALTER COLUMN school_phone DROP NOT NULL;

ALTER TABLE school_settings
ALTER COLUMN school_email DROP NOT NULL;

-- 4. Verify the changes
SELECT 
  column_name,
  data_type,
  is_nullable,
  column_default
FROM information_schema.columns
WHERE table_name = 'school_settings'
  AND column_name IN ('school_name', 'school_address', 'school_phone', 'school_email')
ORDER BY ordinal_position;

-- Now Save Changes should work even if fields are empty
