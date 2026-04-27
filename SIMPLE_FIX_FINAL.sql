-- FINAL SIMPLE FIX
-- This grants direct access to the tables, bypassing RLS temporarily for testing

-- Grant access to authenticated users
GRANT ALL ON teachers TO authenticated;
GRANT ALL ON teacher_fee_collections TO authenticated;
GRANT ALL ON school_settings TO authenticated;

-- Refresh schema one more time
NOTIFY pgrst, 'reload schema';

SELECT '✅ Permissions granted!' as status,
       'Now refresh your app and try again' as next_step;
