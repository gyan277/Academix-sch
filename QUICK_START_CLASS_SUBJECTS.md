# Quick Start: Class Subjects System

## What This Does
Allows admins to configure which subjects are taught in each class, so:
- **KG1/KG2** can have basic subjects (English, Math, Arts, PE)
- **P1-P3** can have more subjects (add Science, Social Studies)
- **P4-P6** can have even more (add ICT)
- **JHS1-JHS3** can have the full curriculum

Teachers will only see subjects assigned to their selected class.

---

## Quick Setup (3 Steps)

### Step 1: Run Database Migration
1. Open **Supabase Dashboard**
2. Go to **SQL Editor**
3. Copy and paste the contents of: `database-migrations/add-class-subjects.sql`
4. Click **Run**
5. ✅ Done! Default subjects are now assigned to all classes

### Step 2: Verify It Worked
Run this query in Supabase SQL Editor:
```sql
SELECT 
  class,
  COUNT(*) as subject_count
FROM class_subjects
WHERE is_active = true
GROUP BY class
ORDER BY class;
```

You should see:
```
KG1  → 4 subjects
KG2  → 4 subjects
P1   → 7 subjects
P2   → 7 subjects
P3   → 7 subjects
P4   → 8 subjects
P5   → 8 subjects
P6   → 8 subjects
JHS1 → 8 subjects
JHS2 → 8 subjects
JHS3 → 8 subjects
```

### Step 3: Check Settings Page
1. Login as **Admin**
2. Go to **Settings** → **Subjects** tab
3. You'll see a placeholder (full UI coming soon)

---

## What's Included

### Default Subject Assignments:

**KG1 & KG2:**
- English Language
- Mathematics
- Creative Arts
- Physical Education

**P1, P2, P3:**
- English Language
- Mathematics
- Science
- Social Studies
- Creative Arts
- Physical Education
- Religious & Moral Education

**P4, P5, P6:**
- All P1-P3 subjects PLUS:
- ICT

**JHS1, JHS2, JHS3:**
- All P4-P6 subjects

---

## Next Steps (Future Updates)

### Admin UI (Coming Soon):
- Select a class
- Check/uncheck subjects for that class
- Save changes
- Subjects update immediately for teachers

### Teacher Experience (Coming Soon):
- Select class → Only see subjects for that class
- KG teacher won't see ICT or Science
- JHS teacher sees all subjects
- Report cards only show assigned subjects

---

## Current Status

✅ **Database**: Ready (run the migration)  
✅ **Default Data**: Configured for all classes  
✅ **Settings Tab**: Added (placeholder UI)  
⏳ **Admin Management**: Coming in next update  
⏳ **Teacher Integration**: Coming in next update  

---

## Files Created

1. **`database-migrations/add-class-subjects.sql`**
   - Creates `class_subjects` table
   - Sets up default assignments
   - Ready to run in Supabase

2. **`CLASS_SUBJECTS_SYSTEM.md`**
   - Complete documentation
   - Technical details
   - API examples

3. **`QUICK_START_CLASS_SUBJECTS.md`**
   - This file
   - Quick setup guide

4. **`client/pages/Settings.tsx`**
   - Added "Subjects" tab
   - Placeholder UI (full UI coming soon)

---

## For Now

The database is ready! You can:
1. Run the migration
2. Verify the data
3. Wait for the next update with full admin UI

Or if you're comfortable with SQL, you can manually manage subjects:

```sql
-- Add a new subject to P1
INSERT INTO class_subjects (class, subject_id, academic_year)
SELECT 'P1', id, '2024/2025'
FROM subjects
WHERE subject_code = 'MUSIC';

-- Remove a subject from KG1
UPDATE class_subjects
SET is_active = false
WHERE class = 'KG1'
  AND subject_id = (SELECT id FROM subjects WHERE subject_code = 'MATH');
```

---

## Questions?

See `CLASS_SUBJECTS_SYSTEM.md` for complete documentation including:
- Database structure
- API queries
- Integration examples
- Testing checklist
