# Quick Fix: ON CONFLICT Error

## Error Message
```
there is no unique or exclusion constraint 
matching the ON CONFLICT specification
```

## What This Means
The frontend is trying to use `.upsert()` with `onConflict: "student_id,academic_year,term"`, but the database table doesn't have a unique constraint on those three columns together.

## The Fix (2 minutes)

### Run This SQL Script
```bash
FIX_UPSERT_CONFLICT_ERROR.sql
```

This will:
1. ✅ Check current table structure
2. ✅ Add `academic_year` column if missing
3. ✅ Add `term` column if missing
4. ✅ Drop old unique constraint (if any)
5. ✅ Create new composite unique constraint: `UNIQUE (student_id, academic_year, term)`
6. ✅ Verify everything works

### What It Does
The script adds a composite unique constraint that matches what the frontend expects:

**Before:**
```sql
-- Either no unique constraint, or just:
UNIQUE (student_id)  ❌
```

**After:**
```sql
UNIQUE (student_id, academic_year, term)  ✅
```

## Why This Happened
The frontend code uses:
```typescript
.upsert(overrideData, {
  onConflict: "student_id,academic_year,term"
})
```

But the database table was created with a different unique constraint (or none at all).

## After Running the Fix
1. The error will disappear ✅
2. You can save student fee overrides ✅
3. Upsert will work correctly (insert new or update existing) ✅

## Test It
After running the SQL:
1. Go to Finance page
2. Click "Record Payment" for a student
3. Check "Student uses bus service"
4. Click "Save Settings"
5. Should save without error ✅

## Related Files
- **Fix Script**: `FIX_UPSERT_CONFLICT_ERROR.sql` ⭐ **RUN THIS**
- **Complete Fix**: `FIX_STUDENT_FEE_OVERRIDES_COMPLETE.sql` (full table recreation)
- **Frontend Code**: `client/components/finance/IncomeDashboard.tsx` (line 344-347)

## Technical Details

### Frontend Upsert Code
```typescript
const { error } = await supabase
  .from("student_fee_overrides")
  .upsert(overrideData, {
    onConflict: "student_id,academic_year,term"  // Requires unique constraint
  });
```

### Required Database Constraint
```sql
ALTER TABLE student_fee_overrides
ADD CONSTRAINT student_fee_overrides_unique_per_year_term 
UNIQUE (student_id, academic_year, term);
```

### Why Composite Constraint?
- Allows same student to have different fees in different years/terms
- Example: Student A in 2024/2025 Term 1 can have different fees than 2024/2025 Term 2
- Prevents duplicate entries for same student in same year/term

## Verification
After running the fix, check the constraint exists:
```sql
SELECT 
  conname,
  pg_get_constraintdef(oid)
FROM pg_constraint
WHERE conrelid = 'student_fee_overrides'::regclass
AND contype = 'u';
```

Should show:
```
student_fee_overrides_unique_per_year_term | UNIQUE (student_id, academic_year, term)
```

## If Still Not Working
1. Make sure the script completed all steps
2. Check that `academic_year` and `term` columns exist
3. Verify the unique constraint was created
4. Try the complete fix: `FIX_STUDENT_FEE_OVERRIDES_COMPLETE.sql`
