-- Fix school_settings table to allow upsert on school_id
-- The error "no unique or exclusion constraint matching ON CONFLICT" means
-- we need to add a unique constraint on school_id

-- 1. Check current constraints on school_settings
SELECT 
  conname as constraint_name,
  contype as constraint_type,
  pg_get_constraintdef(oid) as definition
FROM pg_constraint
WHERE conrelid = 'school_settings'::regclass;

-- 2. Add unique constraint on school_id if it doesn't exist
-- This allows upsert operations using ON CONFLICT (school_id)
ALTER TABLE school_settings
ADD CONSTRAINT school_settings_school_id_unique UNIQUE (school_id);

-- 3. Verify the constraint was added
SELECT 
  conname as constraint_name,
  contype as constraint_type,
  pg_get_constraintdef(oid) as definition
FROM pg_constraint
WHERE conrelid = 'school_settings'::regclass;

-- Now the upsert in Settings page will work!
