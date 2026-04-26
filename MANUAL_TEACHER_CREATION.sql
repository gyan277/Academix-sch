-- MANUAL TEACHER CREATION
-- Use this to create teachers when Supabase Auth signup is failing

-- INSTRUCTIONS:
-- 1. Replace the values below with actual teacher information
-- 2. Run this script in Supabase SQL Editor
-- 3. Teacher will be created with the specified credentials

-- ============================================
-- CONFIGURATION - EDIT THESE VALUES
-- ============================================
DO $$
DECLARE
  teacher_email TEXT := 'teacher@school.com';  -- CHANGE THIS
  teacher_password TEXT := 'password123';       -- CHANGE THIS
  teacher_name TEXT := 'John Doe';              -- CHANGE THIS
  teacher_phone TEXT := '+233501234567';        -- CHANGE THIS
  admin_school_id UUID := (SELECT school_id FROM users WHERE role = 'admin' LIMIT 1); -- Auto-detect
  new_user_id UUID;
BEGIN
  -- Step 1: Create auth user
  INSERT INTO auth.users (
    instance_id,
    id,
    aud,
    role,
    email,
    encrypted_password,
    email_confirmed_at,
    raw_user_meta_data,
    raw_app_meta_data,
    created_at,
    updated_at,
    confirmation_token,
    email_change,
    email_change_token_new,
    recovery_token
  )
  VALUES (
    '00000000-0000-0000-0000-000000000000',
    gen_random_uuid(),
    'authenticated',
    'authenticated',
    teacher_email,
    crypt(teacher_password, gen_salt('bf')),
    NOW(), -- Email confirmed immediately
    jsonb_build_object(
      'full_name', teacher_name,
      'role', 'teacher',
      'phone', teacher_phone,
      'school_id', admin_school_id
    ),
    jsonb_build_object('provider', 'email', 'providers', ARRAY['email']),
    NOW(),
    NOW(),
    '',
    '',
    '',
    ''
  )
  RETURNING id INTO new_user_id;

  RAISE NOTICE 'Created auth user with ID: %', new_user_id;

  -- Step 2: Create public.users record
  INSERT INTO public.users (
    id,
    email,
    full_name,
    role,
    phone,
    school_id,
    status,
    created_at,
    updated_at
  )
  VALUES (
    new_user_id,
    teacher_email,
    teacher_name,
    'teacher',
    teacher_phone,
    admin_school_id,
    'active',
    NOW(),
    NOW()
  )
  ON CONFLICT (id) DO UPDATE
  SET
    email = EXCLUDED.email,
    full_name = EXCLUDED.full_name,
    role = EXCLUDED.role,
    phone = EXCLUDED.phone,
    school_id = EXCLUDED.school_id,
    status = EXCLUDED.status;

  RAISE NOTICE 'Created public.users record';

  -- Step 3: Create identity record
  INSERT INTO auth.identities (
    id,
    user_id,
    identity_data,
    provider,
    last_sign_in_at,
    created_at,
    updated_at
  )
  VALUES (
    gen_random_uuid(),
    new_user_id,
    jsonb_build_object(
      'sub', new_user_id::text,
      'email', teacher_email
    ),
    'email',
    NOW(),
    NOW(),
    NOW()
  );

  RAISE NOTICE 'Created identity record';

  -- Success message
  RAISE NOTICE '========================================';
  RAISE NOTICE 'Teacher created successfully!';
  RAISE NOTICE 'Email: %', teacher_email;
  RAISE NOTICE 'Password: %', teacher_password;
  RAISE NOTICE 'User ID: %', new_user_id;
  RAISE NOTICE 'School ID: %', admin_school_id;
  RAISE NOTICE '========================================';
  RAISE NOTICE 'Teacher can now login with these credentials';
END $$;

-- Verify the teacher was created
SELECT 
  'Verification' as step,
  u.id,
  u.email,
  u.full_name,
  u.role,
  u.school_id,
  u.status,
  au.email_confirmed_at
FROM public.users u
JOIN auth.users au ON u.id = au.id
WHERE u.role = 'teacher'
ORDER BY u.created_at DESC
LIMIT 5;
