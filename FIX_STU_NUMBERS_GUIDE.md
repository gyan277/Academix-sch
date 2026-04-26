# Fix Old STU Student Numbers

## Problem
The first two students still have old format numbers like `STU0001`, `STU0002` instead of the new school-based format like `MOU0001`, `MOU0002`.

## Quick Solution

### Option 1: Simple Replace (Recommended)
This keeps the same numbers but changes the prefix.

**Run this in Supabase SQL Editor**:
```sql
-- File: QUICK_FIX_STU_NUMBERS.sql
```

**Result**:
- `STU0001` → `MOU0001`
- `STU0002` → `MOU0002`

**Steps**:
1. Open Supabase Dashboard
2. Go to SQL Editor
3. Copy and paste contents of `QUICK_FIX_STU_NUMBERS.sql`
4. Click "Run"
5. Refresh your browser (F5)

### Option 2: Renumber Sequentially
This gives them new sequential numbers after existing ones.

**Run this in Supabase SQL Editor**:
```sql
-- File: FIX_OLD_STUDENT_NUMBERS.sql
```

**Result**:
- If you already have `MOU0001`, `MOU0002`
- Old students become `MOU0003`, `MOU0004`

## Which Option to Choose?

### Use Option 1 (Simple Replace) if:
- ✅ You want to keep the original numbers
- ✅ You want `STU0001` to become `MOU0001`
- ✅ Simpler and faster

### Use Option 2 (Renumber) if:
- ✅ You want all numbers in strict sequential order
- ✅ You don't mind changing the numbers
- ✅ You want newer students to have lower numbers

## Recommended: Option 1

Just run `QUICK_FIX_STU_NUMBERS.sql` - it's the simplest solution!

---

## After Running the Fix

1. **Refresh browser** (F5)
2. Go to Registrar page
3. Check the first two students
4. **Expected**: Numbers now show `MOU0001`, `MOU0002` instead of `STU0001`, `STU0002`

---

## Verification

After running the script, you can verify with this query:

```sql
-- Check if any STU numbers remain
SELECT COUNT(*) FROM public.students WHERE student_number LIKE 'STU%';
-- Should return 0

-- View all student numbers
SELECT student_number, full_name, class 
FROM public.students 
ORDER BY student_number;
```

---

## Status
✅ **Ready to fix** - Just run `QUICK_FIX_STU_NUMBERS.sql` in Supabase!
