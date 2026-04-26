# Multi-Tenancy Quick Reference Card

## 🚀 QUICK START (3 Steps)

### 1. Run Migration (Once)
```bash
# In Supabase SQL Editor, run:
database-migrations/add-school-multi-tenancy.sql
```

### 2. Register School
```sql
INSERT INTO public.school_settings (
  school_name, school_address, school_phone, 
  school_email, current_academic_year
) VALUES (
  'Your School Name', 'Address', 'Phone', 'Email', '2024/2025'
) RETURNING id;
-- Copy the returned ID!
```

### 3. Create Admin User
```
Supabase Dashboard → Authentication → Users → Add User

User Metadata:
{
  "full_name": "Admin Name",
  "role": "admin",
  "phone": "+233...",
  "school_id": "PASTE_ID_FROM_STEP_2"
}
```

## 📝 CHEAT SHEET

### Register New School
```sql
-- 1. Create school
INSERT INTO school_settings (...) VALUES (...) RETURNING id;

-- 2. Create admin in Supabase Dashboard with school_id in metadata

-- 3. Copy defaults
INSERT INTO class_subjects (class, subject_id, academic_year, school_id)
SELECT class, subject_id, academic_year, 'SCHOOL_ID'::UUID
FROM class_subjects WHERE school_id IS NULL;

INSERT INTO grading_scale (grade, min_score, max_score, sort_order, school_id)
SELECT grade, min_score, max_score, sort_order, 'SCHOOL_ID'::UUID
FROM grading_scale WHERE school_id IS NULL;
```

### Check School Data
```sql
-- List all schools
SELECT * FROM school_settings;

-- Check user assignments
SELECT u.email, u.role, s.school_name
FROM users u
JOIN school_settings s ON u.school_id = s.id;

-- Count data by school
SELECT 
  s.school_name,
  COUNT(DISTINCT st.id) as students,
  COUNT(DISTINCT sf.id) as staff
FROM school_settings s
LEFT JOIN students st ON s.id = st.school_id
LEFT JOIN staff sf ON s.id = sf.school_id
GROUP BY s.school_name;
```

## 🔧 TROUBLESHOOTING

| Problem | Solution |
|---------|----------|
| Can't login | Check "Auto Confirm User" was enabled |
| No data visible | Verify school_id in user metadata |
| Error adding students | Check migration ran successfully |
| Sees other school's data | **CRITICAL** - Check RLS policies |

## 📋 VERIFICATION CHECKLIST

- [ ] Migration ran without errors
- [ ] School created in school_settings
- [ ] Admin user has school_id in metadata
- [ ] Default subjects copied
- [ ] Default grading scale copied
- [ ] Can login successfully
- [ ] Can add students
- [ ] Students have school_id in database
- [ ] Cannot see other schools' data

## 🎯 KEY CONCEPTS

### What is school_id?
- Unique identifier for each school
- Links all data to a specific school
- Stored in user metadata

### How does isolation work?
- RLS (Row Level Security) policies
- Automatic filtering at database level
- No manual filtering needed in code

### What needs school_id?
- ✅ All INSERT operations
- ❌ SELECT operations (RLS handles it)
- ✅ User metadata
- ✅ All data tables

## 📞 QUICK HELP

### Files to Check:
- Migration: `database-migrations/add-school-multi-tenancy.sql`
- Admin Guide: `ADMIN_QUICK_START_MULTI_TENANCY.md`
- Full Summary: `COMPLETE_MULTI_TENANCY_SUMMARY.md`

### Common Queries:
```sql
-- Find my school_id
SELECT school_id FROM users WHERE email = 'your@email.com';

-- Check if migration ran
SELECT column_name FROM information_schema.columns 
WHERE table_name = 'students' AND column_name = 'school_id';

-- Verify RLS is enabled
SELECT tablename, rowsecurity FROM pg_tables 
WHERE schemaname = 'public' AND tablename = 'students';
```

## ✅ SUCCESS INDICATORS

You know it's working when:
1. ✅ Can login as admin
2. ✅ Can add students/staff
3. ✅ Data appears in database with school_id
4. ✅ Different schools can't see each other's data
5. ✅ No errors in browser console

---

**Need more details?** See `ADMIN_QUICK_START_MULTI_TENANCY.md`
