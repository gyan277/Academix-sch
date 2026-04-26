-- Set the school name for Mount Olivet Methodist Academy
-- This updates the school with the correct school_id
UPDATE school_settings
SET 
  school_name = 'Mount Olivet Methodist Academy',
  school_address = 'Dansoman, Accra',
  school_phone = '+233 50 123 4567',
  school_email = 'info@moma.edu.gh'
WHERE school_id = 'f3c2cfe9-0a1b-494c-bd25-cc787ab28f77';

-- Verify the update
SELECT 
  school_id,
  school_name,
  school_address,
  school_phone,
  school_email,
  '✅ Updated successfully' as status
FROM school_settings
WHERE school_id = 'f3c2cfe9-0a1b-494c-bd25-cc787ab28f77';
