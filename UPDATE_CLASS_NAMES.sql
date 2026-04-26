-- Update Class Names to New Format
-- From: P1, P2, P3, etc.
-- To: Creche, Nursery 1, Nursery 2, KG1, KG2, Primary 1, Primary 2, etc.

-- IMPORTANT: Run this script in your Supabase SQL Editor
-- This will update all class references across the entire system

BEGIN;

-- Update students table
UPDATE students SET class = 'Creche' WHERE class = 'Creche';
UPDATE students SET class = 'Nursery 1' WHERE class = 'Nursery 1';
UPDATE students SET class = 'Nursery 2' WHERE class = 'Nursery 2';
UPDATE students SET class = 'KG1' WHERE class = 'KG1';
UPDATE students SET class = 'KG2' WHERE class = 'KG2';
UPDATE students SET class = 'Primary 1' WHERE class = 'P1';
UPDATE students SET class = 'Primary 2' WHERE class = 'P2';
UPDATE students SET class = 'Primary 3' WHERE class = 'P3';
UPDATE students SET class = 'Primary 4' WHERE class = 'P4';
UPDATE students SET class = 'Primary 5' WHERE class = 'P5';
UPDATE students SET class = 'Primary 6' WHERE class = 'P6';
UPDATE students SET class = 'JHS 1' WHERE class = 'JHS 1';
UPDATE students SET class = 'JHS 2' WHERE class = 'JHS 2';
UPDATE students SET class = 'JHS 3' WHERE class = 'JHS 3';

-- Update teachers table
UPDATE teachers SET class_assigned = 'Creche' WHERE class_assigned = 'Creche';
UPDATE teachers SET class_assigned = 'Nursery 1' WHERE class_assigned = 'Nursery 1';
UPDATE teachers SET class_assigned = 'Nursery 2' WHERE class_assigned = 'Nursery 2';
UPDATE teachers SET class_assigned = 'KG1' WHERE class_assigned = 'KG1';
UPDATE teachers SET class_assigned = 'KG2' WHERE class_assigned = 'KG2';
UPDATE teachers SET class_assigned = 'Primary 1' WHERE class_assigned = 'P1';
UPDATE teachers SET class_assigned = 'Primary 2' WHERE class_assigned = 'P2';
UPDATE teachers SET class_assigned = 'Primary 3' WHERE class_assigned = 'P3';
UPDATE teachers SET class_assigned = 'Primary 4' WHERE class_assigned = 'P4';
UPDATE teachers SET class_assigned = 'Primary 5' WHERE class_assigned = 'P5';
UPDATE teachers SET class_assigned = 'Primary 6' WHERE class_assigned = 'P6';
UPDATE teachers SET class_assigned = 'JHS 1' WHERE class_assigned = 'JHS 1';
UPDATE teachers SET class_assigned = 'JHS 2' WHERE class_assigned = 'JHS 2';
UPDATE teachers SET class_assigned = 'JHS 3' WHERE class_assigned = 'JHS 3';

-- Update attendance table
UPDATE attendance SET class = 'Creche' WHERE class = 'Creche';
UPDATE attendance SET class = 'Nursery 1' WHERE class = 'Nursery 1';
UPDATE attendance SET class = 'Nursery 2' WHERE class = 'Nursery 2';
UPDATE attendance SET class = 'KG1' WHERE class = 'KG1';
UPDATE attendance SET class = 'KG2' WHERE class = 'KG2';
UPDATE attendance SET class = 'Primary 1' WHERE class = 'P1';
UPDATE attendance SET class = 'Primary 2' WHERE class = 'P2';
UPDATE attendance SET class = 'Primary 3' WHERE class = 'P3';
UPDATE attendance SET class = 'Primary 4' WHERE class = 'P4';
UPDATE attendance SET class = 'Primary 5' WHERE class = 'P5';
UPDATE attendance SET class = 'Primary 6' WHERE class = 'P6';
UPDATE attendance SET class = 'JHS 1' WHERE class = 'JHS 1';
UPDATE attendance SET class = 'JHS 2' WHERE class = 'JHS 2';
UPDATE attendance SET class = 'JHS 3' WHERE class = 'JHS 3';

-- Update class_fees table
UPDATE class_fees SET class = 'Creche' WHERE class = 'Creche';
UPDATE class_fees SET class = 'Nursery 1' WHERE class = 'Nursery 1';
UPDATE class_fees SET class = 'Nursery 2' WHERE class = 'Nursery 2';
UPDATE class_fees SET class = 'KG1' WHERE class = 'KG1';
UPDATE class_fees SET class = 'KG2' WHERE class = 'KG2';
UPDATE class_fees SET class = 'Primary 1' WHERE class = 'P1';
UPDATE class_fees SET class = 'Primary 2' WHERE class = 'P2';
UPDATE class_fees SET class = 'Primary 3' WHERE class = 'P3';
UPDATE class_fees SET class = 'Primary 4' WHERE class = 'P4';
UPDATE class_fees SET class = 'Primary 5' WHERE class = 'P5';
UPDATE class_fees SET class = 'Primary 6' WHERE class = 'P6';
UPDATE class_fees SET class = 'JHS 1' WHERE class = 'JHS 1';
UPDATE class_fees SET class = 'JHS 2' WHERE class = 'JHS 2';
UPDATE class_fees SET class = 'JHS 3' WHERE class = 'JHS 3';

-- Update class_subjects table
UPDATE class_subjects SET class = 'Creche' WHERE class = 'Creche';
UPDATE class_subjects SET class = 'Nursery 1' WHERE class = 'Nursery 1';
UPDATE class_subjects SET class = 'Nursery 2' WHERE class = 'Nursery 2';
UPDATE class_subjects SET class = 'KG1' WHERE class = 'KG1';
UPDATE class_subjects SET class = 'KG2' WHERE class = 'KG2';
UPDATE class_subjects SET class = 'Primary 1' WHERE class = 'P1';
UPDATE class_subjects SET class = 'Primary 2' WHERE class = 'P2';
UPDATE class_subjects SET class = 'Primary 3' WHERE class = 'P3';
UPDATE class_subjects SET class = 'Primary 4' WHERE class = 'P4';
UPDATE class_subjects SET class = 'Primary 5' WHERE class = 'P5';
UPDATE class_subjects SET class = 'Primary 6' WHERE class = 'P6';
UPDATE class_subjects SET class = 'JHS 1' WHERE class = 'JHS 1';
UPDATE class_subjects SET class = 'JHS 2' WHERE class = 'JHS 2';
UPDATE class_subjects SET class = 'JHS 3' WHERE class = 'JHS 3';

-- Update academic_scores table
UPDATE academic_scores SET class = 'Creche' WHERE class = 'Creche';
UPDATE academic_scores SET class = 'Nursery 1' WHERE class = 'Nursery 1';
UPDATE academic_scores SET class = 'Nursery 2' WHERE class = 'Nursery 2';
UPDATE academic_scores SET class = 'KG1' WHERE class = 'KG1';
UPDATE academic_scores SET class = 'KG2' WHERE class = 'KG2';
UPDATE academic_scores SET class = 'Primary 1' WHERE class = 'P1';
UPDATE academic_scores SET class = 'Primary 2' WHERE class = 'P2';
UPDATE academic_scores SET class = 'Primary 3' WHERE class = 'P3';
UPDATE academic_scores SET class = 'Primary 4' WHERE class = 'P4';
UPDATE academic_scores SET class = 'Primary 5' WHERE class = 'P5';
UPDATE academic_scores SET class = 'Primary 6' WHERE class = 'P6';
UPDATE academic_scores SET class = 'JHS 1' WHERE class = 'JHS 1';
UPDATE academic_scores SET class = 'JHS 2' WHERE class = 'JHS 2';
UPDATE academic_scores SET class = 'JHS 3' WHERE class = 'JHS 3';

COMMIT;

-- Verify the changes
SELECT 'Students' as table_name, class, COUNT(*) as count FROM students GROUP BY class ORDER BY class;
SELECT 'Teachers' as table_name, class_assigned as class, COUNT(*) as count FROM teachers WHERE class_assigned IS NOT NULL GROUP BY class_assigned ORDER BY class_assigned;
SELECT 'Class Fees' as table_name, class, COUNT(*) as count FROM class_fees GROUP BY class ORDER BY class;
