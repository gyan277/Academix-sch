-- Refresh Schema Cache
-- This forces Supabase to reload the schema cache
-- Run this in Supabase SQL Editor

-- Method 1: Use NOTIFY to refresh PostgREST schema cache
NOTIFY pgrst, 'reload schema';

-- Method 2: Verify the columns exist
SELECT 
  table_name,
  column_name,
  data_type,
  is_nullable
FROM information_schema.columns
WHERE table_name = 'class_fees'
  AND column_name IN ('amount', 'bus_fee', 'canteen_fee')
ORDER BY ordinal_position;

-- Method 3: Check if there are any pending migrations
SELECT * FROM information_schema.columns 
WHERE table_name = 'class_fees';
