# Updated Subjects List

## All Available Subjects

1. **English Language** (ENG)
2. **Mathematics** (MATH)
3. **Science** (SCI)
4. **Social Studies** (SST)
5. **Our World Our People** (OWOP) ✨ NEW
6. **Creative Arts** (ART)
7. **Physical Education** (PHE)
8. **Computing** (COMP) ✨ UPDATED (was ICT)
9. **Career Technology** (CT) ✨ NEW
10. **Religious & Moral Education** (RME)

---

## Default Assignments by Class

### KG1 & KG2 (4 subjects)
- English Language
- Mathematics
- Creative Arts
- Physical Education

### P1, P2, P3 (8 subjects)
- English Language
- Mathematics
- Science
- Social Studies
- **Our World Our People** ✨
- Creative Arts
- Physical Education
- Religious & Moral Education

### P4, P5, P6 (9 subjects)
- All P1-P3 subjects PLUS:
- **Computing** ✨

### JHS1, JHS2, JHS3 (10 subjects)
- All P4-P6 subjects PLUS:
- **Career Technology** ✨

---

## How to Update

### Option 1: Fresh Installation
If you haven't run the migrations yet:
1. Run `COMPLETE_DATABASE_SETUP.sql` (already updated)
2. Run `database-migrations/add-class-subjects.sql` (already updated)
3. ✅ Done! All subjects are correct

### Option 2: Update Existing Database
If you already ran the old migrations:
1. Run `UPDATE_SUBJECTS.sql` in Supabase SQL Editor
2. This will:
   - Update ICT → Computing
   - Add Our World Our People
   - Add Career Technology
3. ✅ Done! Subjects are updated

---

## Changes Made

### Files Updated:
1. ✅ `COMPLETE_DATABASE_SETUP.sql` - Updated subjects list
2. ✅ `database-migrations/add-class-subjects.sql` - Updated default assignments
3. ✅ `UPDATE_SUBJECTS.sql` - New file to update existing databases

### What Changed:
- ❌ Removed: ICT
- ✅ Added: Computing (replaces ICT)
- ✅ Added: Our World Our People
- ✅ Added: Career Technology

---

## Verification

After running the update, verify with:

```sql
SELECT subject_code, subject_name
FROM public.subjects
ORDER BY subject_name;
```

You should see all 10 subjects listed above.

---

## Admin Can Still Customize

Remember, admins can:
- Add more subjects via Settings → Subjects
- Assign/remove subjects per class
- Copy subjects between classes

The list above is just the default starting point!
