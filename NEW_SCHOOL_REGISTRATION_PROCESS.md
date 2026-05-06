# New School Registration Process

This guide shows you how to register new schools in your production system after the database reset.

## 🏫 Current Situation

Your system doesn't have a public school registration form yet. Schools need to be registered manually through the database, then admin accounts created for them.

## Method 1: Manual Registration (Current Process)

### Step 1: Register School in Database

Go to your Supabase SQL Editor and run this query (replace with actual school details):

```sql
-- Insert new school
INSERT INTO public.school_settings (
  school_name,
  address,
  phone,
  email,
  current_term,
  current_academic_year
) VALUES (
  'Greenwood Academy',                    -- School name
  '123 Education Street, Accra, Ghana',  -- Address
  '+233-24-123-4567',                     -- Phone
  'admin@greenwoodacademy.edu.gh',        -- Email
  'Term 1',                               -- Current term
  '2024/2025'                             -- Academic year
);

-- Get the school ID (you'll need this)
SELECT 
  id,
  school_name,
  UPPER(LEFT(REGEXP_REPLACE(school_name, '[^A-Za-z]', '', 'g'), 3)) as prefix
FROM public.school_settings 
WHERE school_name = 'Greenwood Academy';
```

### Step 2: Create Admin Account

#### Option A: Through Supabase Auth Dashboard
1. Go to **Authentication > Users** in Supabase
2. Click **Add User**
3. Fill in:
   - **Email**: `admin@greenwoodacademy.edu.gh`
   - **Password**: Create a secure password
   - **Email Confirm**: ✅ Check this
4. Click **Create User**
5. Copy the User ID

#### Option B: Through SQL (Advanced)
```sql
-- This requires service role key - use Auth dashboard instead for simplicity
```

### Step 3: Link Admin to School

```sql
-- Replace these values with actual data
DO $
DECLARE
    school_uuid UUID;
    admin_email TEXT := 'admin@greenwoodacademy.edu.gh';
    admin_name TEXT := 'John Smith';
    auth_user_id UUID := 'PASTE_USER_ID_FROM_STEP_2_HERE';
BEGIN
    -- Get school ID
    SELECT id INTO school_uuid 
    FROM public.school_settings 
    WHERE school_name = 'Greenwood Academy';
    
    -- Insert into users table
    INSERT INTO public.users (
        id,
        email,
        role,
        full_name,
        school_id
    ) VALUES (
        auth_user_id,
        admin_email,
        'admin',
        admin_name,
        school_uuid
    );
    
    RAISE NOTICE 'Admin account created for % at %', admin_name, 'Greenwood Academy';
END $;
```

## Method 2: Quick Registration Script

Here's a complete script that registers a school and creates an admin account:

```sql
-- COMPLETE SCHOOL REGISTRATION SCRIPT
-- Replace the values in the DECLARE section with actual school details

DO $
DECLARE
    -- CHANGE THESE VALUES FOR EACH SCHOOL
    school_name_val TEXT := 'Greenwood Academy';
    school_address TEXT := '123 Education Street, Accra, Ghana';
    school_phone TEXT := '+233-24-123-4567';
    school_email TEXT := 'admin@greenwoodacademy.edu.gh';
    admin_full_name TEXT := 'John Smith';
    admin_password TEXT := 'SecurePassword123!';
    
    -- Variables for processing
    new_school_id UUID;
    school_prefix TEXT;
BEGIN
    -- Step 1: Insert school
    INSERT INTO public.school_settings (
        school_name,
        address,
        phone,
        email,
        current_term,
        current_academic_year
    ) VALUES (
        school_name_val,
        school_address,
        school_phone,
        school_email,
        'Term 1',
        '2024/2025'
    ) RETURNING id INTO new_school_id;
    
    -- Generate school prefix
    school_prefix := UPPER(LEFT(REGEXP_REPLACE(school_name_val, '[^A-Za-z]', '', 'g'), 3));
    
    RAISE NOTICE '✅ School registered: % (ID: %)', school_name_val, new_school_id;
    RAISE NOTICE '📋 School prefix will be: %', school_prefix;
    RAISE NOTICE '🎓 Student IDs will be: %0001, %0002, %0003...', school_prefix, school_prefix, school_prefix;
    RAISE NOTICE '👥 Staff IDs will be: %0001, %0002, %0003...', school_prefix, school_prefix, school_prefix;
    RAISE NOTICE '';
    RAISE NOTICE '⚠️  NEXT STEP: Create admin account manually in Supabase Auth dashboard';
    RAISE NOTICE '📧 Email: %', school_email;
    RAISE NOTICE '👤 Name: %', admin_full_name;
    RAISE NOTICE '🏫 School ID: %', new_school_id;
END $;
```

## Method 3: Multiple Schools at Once

```sql
-- Register multiple schools at once
DO $
DECLARE
    school_record RECORD;
    new_school_id UUID;
    school_prefix TEXT;
BEGIN
    -- Define schools to register
    FOR school_record IN 
        SELECT * FROM (VALUES
            ('Greenwood Academy', '123 Education St, Accra', '+233-24-123-4567', 'admin@greenwood.edu.gh', 'John Smith'),
            ('St. Mary''s College', '456 Church Rd, Kumasi', '+233-24-234-5678', 'admin@stmarys.edu.gh', 'Mary Johnson'),
            ('International School', '789 Global Ave, Tema', '+233-24-345-6789', 'admin@international.edu.gh', 'David Wilson')
        ) AS schools(name, address, phone, email, admin_name)
    LOOP
        -- Insert school
        INSERT INTO public.school_settings (
            school_name,
            address,
            phone,
            email,
            current_term,
            current_academic_year
        ) VALUES (
            school_record.name,
            school_record.address,
            school_record.phone,
            school_record.email,
            'Term 1',
            '2024/2025'
        ) RETURNING id INTO new_school_id;
        
        -- Generate prefix
        school_prefix := UPPER(LEFT(REGEXP_REPLACE(school_record.name, '[^A-Za-z]', '', 'g'), 3));
        
        RAISE NOTICE '✅ %: ID %, Prefix %, Email %', 
                     school_record.name, new_school_id, school_prefix, school_record.email;
    END LOOP;
    
    RAISE NOTICE '';
    RAISE NOTICE '⚠️  Create admin accounts manually in Supabase Auth dashboard for each school';
END $;
```

## Step-by-Step Example: Registering "Greenwood Academy"

### 1. Run School Registration
```sql
INSERT INTO public.school_settings (
  school_name,
  address,
  phone,
  email,
  current_term,
  current_academic_year
) VALUES (
  'Greenwood Academy',
  '123 Education Street, Accra, Ghana',
  '+233-24-123-4567',
  'admin@greenwoodacademy.edu.gh',
  'Term 1',
  '2024/2025'
);

-- Get the school details
SELECT 
  id,
  school_name,
  email,
  UPPER(LEFT(REGEXP_REPLACE(school_name, '[^A-Za-z]', '', 'g'), 3)) as student_prefix
FROM public.school_settings 
WHERE school_name = 'Greenwood Academy';
```

### 2. Create Admin in Supabase Auth
1. Go to **Authentication > Users**
2. Click **Add User**
3. Email: `admin@greenwoodacademy.edu.gh`
4. Password: `GreenAdmin2024!`
5. ✅ Email Confirm
6. Click **Create User**
7. **Copy the User ID**

### 3. Link Admin to School
```sql
-- Replace 'PASTE_USER_ID_HERE' with actual UUID from step 2
INSERT INTO public.users (
    id,
    email,
    role,
    full_name,
    school_id
) VALUES (
    'PASTE_USER_ID_HERE',  -- UUID from Supabase Auth
    'admin@greenwoodacademy.edu.gh',
    'admin',
    'John Smith',
    (SELECT id FROM public.school_settings WHERE school_name = 'Greenwood Academy')
);
```

### 4. Test Login
1. Go to your app: `https://academix-man.netlify.app`
2. Login with:
   - Email: `admin@greenwoodacademy.edu.gh`
   - Password: `GreenAdmin2024!`
3. Should see Greenwood Academy dashboard
4. Students will get IDs: **GRE0001, GRE0002, GRE0003...**

## 🚀 Future Enhancement: Automated Registration

You could build a school registration form that:
1. Collects school details
2. Creates school record
3. Sends email verification
4. Auto-creates admin account
5. Sends welcome email with login details

But for now, the manual process above works perfectly for production!

## 📋 Registration Checklist

For each new school:
- [ ] Run school registration SQL
- [ ] Note the school ID and prefix
- [ ] Create admin user in Supabase Auth
- [ ] Link admin to school in users table
- [ ] Test login
- [ ] Verify student/staff ID generation works

## 🎯 What Schools Get

After registration, each school gets:
- ✅ **Isolated dashboard** - Only see their data
- ✅ **Unique student IDs** - School-specific prefixes
- ✅ **Complete system access** - All features available
- ✅ **Multi-tenant security** - Cannot see other schools' data

Perfect for production use! 🎉