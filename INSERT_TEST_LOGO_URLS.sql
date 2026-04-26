-- Insert Test Logo and Signature URLs
-- This will let you test the PDF generation before uploading actual images

-- Update Mount Olivet Methodist Academy with test images
UPDATE school_settings
SET 
  school_logo_url = 'https://via.placeholder.com/150/0066CC/FFFFFF?text=MOMA',
  headmaster_signature_url = 'https://via.placeholder.com/200x80/000000/FFFFFF?text=Headmaster+Signature'
WHERE school_id IN (
  SELECT id FROM schools WHERE name = 'Mount Olivet Methodist Academy'
);

-- Verify the update
SELECT 
  s.name as school_name,
  ss.school_logo_url,
  ss.headmaster_signature_url,
  ss.current_academic_year,
  ss.current_term
FROM school_settings ss
JOIN schools s ON s.id = ss.school_id
WHERE s.name = 'Mount Olivet Methodist Academy';

-- Now you can test:
-- 1. Go to Academic page
-- 2. Click Reports tab
-- 3. Generate reports for any class
-- 4. Download a report card
-- 5. You should see the placeholder logo and signature in the PDF
