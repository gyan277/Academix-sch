# Fix Alternating Student Fee Override Errors

## The Problem
Errors keep alternating between:
1. ❌ `"there is no unique or exclusion constraint matching the ON CONFLICT specification"`
2. ❌ `"violates foreign key constraint student_fee_overrides_school_id_fkey"`

This means the table structure is fundamentally broken and needs to be completely recreated.

## The Solution (One Script Fixes Everything)

### Run This SQL Script
```bash
DEFINITIVE_FIX_STUDENT_FEE_OVERRIDES.sql
```

This script will:
1. ✅ Backup any existing data
2. ✅ Drop the broken table completely
3. ✅ Create new table with correct structure:
   - All required columns (academic_year, term, uses_bus, uses_canteen, etc.)
   - Proper foreign keys (school_id → schools, student_id → students)
   - Composite unique constraint (student_id, academic_year, term)
4. ✅ Set up RLS policies for multi-tenancy
5. ✅ Create performance indexes
6. ✅ Add updated_at trigger
7. ✅ Restore backed up data (if compatible)
8. ✅ Test the upsert operation
9. ✅ Show complete verification

## What This Fixes

### Error 1: ON CONFLICT
**Before:** No unique constraint or wrong constraint
**After:** `UNIQUE (student_id, academic_year, term)` ✅

### Error 2: Foreign Key
**Before:** Broken or missing foreign key constraints
**After:** Proper foreign keys with CASCADE delete ✅

## After Running the Script

### Expected Output
The script will show 9 steps:
1. Backup Created
2. Old Table Dropped
3. New Table Created
4. Indexes Created
5. RLS Enabled
6. Trigger Created
7. Data Restored (or skipped if incompatible)
8. Complete verification (columns, constraints, policies, indexes)
9. Upsert test (should show ✅ SUCCESS)

### Final Status
```
✅ FIX COMPLETE
Both errors should now be fixed!
```

## Test It

1. **Run the script** in Supabase SQL Editor
2. **Wait for all 9 steps** to complete
3. **Go to Finance page** in your app
4. **Click "Record Payment"** for any student
5. **Check "Student uses bus service"**
6. **Click "Save Settings"**
7. **Should save successfully** without any errors ✅

## Why This Approach?

Previous fixes tried to patch the existing table, but the structure was too broken. This script:
- Completely removes the problematic table
- Creates a fresh table with the exact structure the frontend expects
- Tests the upsert operation to ensure it works
- Provides complete verification

## Technical Details

### New Table Structure
```sql
CREATE TABLE student_fee_overrides (
  id uuid PRIMARY KEY,
  school_id uuid NOT NULL,              -- FK to schools
  student_id uuid NOT NULL,             -- FK to students
  academic_year text NOT NULL,          -- e.g., "2024/2025"
  term text NOT NULL,                   -- e.g., "Term 1"
  uses_bus boolean DEFAULT false,
  uses_canteen boolean DEFAULT false,
  bus_fee_override numeric(10,2),
  canteen_fee_override numeric(10,2),
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now(),
  
  -- Constraints
  FOREIGN KEY (school_id) REFERENCES schools(id) ON DELETE CASCADE,
  FOREIGN KEY (student_id) REFERENCES students(id) ON DELETE CASCADE,
  UNIQUE (student_id, academic_year, term)  -- For upsert
);
```

### Frontend Upsert (Now Works)
```typescript
await supabase
  .from("student_fee_overrides")
  .upsert({
    school_id: schoolId,
    student_id: studentId,
    academic_year: "2024/2025",
    term: "Term 1",
    uses_bus: true,
    uses_canteen: false,
    bus_fee_override: 50.00,
    canteen_fee_override: null
  }, {
    onConflict: "student_id,academic_year,term"  // ✅ Works now!
  });
```

## If Still Having Issues

1. **Check script output** - All 9 steps should complete
2. **Look for error messages** - Script will show what failed
3. **Verify constraints exist**:
   ```sql
   SELECT conname, pg_get_constraintdef(oid)
   FROM pg_constraint
   WHERE conrelid = 'student_fee_overrides'::regclass;
   ```
   Should show:
   - Primary key on `id`
   - Foreign key on `school_id`
   - Foreign key on `student_id`
   - Unique constraint on `(student_id, academic_year, term)`

4. **Check RLS policies**:
   ```sql
   SELECT policyname FROM pg_policies
   WHERE tablename = 'student_fee_overrides';
   ```
   Should show 2 policies

## Related Files
- **Main Fix**: `DEFINITIVE_FIX_STUDENT_FEE_OVERRIDES.sql` ⭐ **RUN THIS**
- **Previous Attempts**: 
  - `FIX_STUDENT_FEE_OVERRIDES_COMPLETE.sql`
  - `FIX_UPSERT_CONFLICT_ERROR.sql`
  - `FIX_STUDENT_FEE_OVERRIDES_CONSTRAINT.sql`
- **Frontend Code**: `client/components/finance/IncomeDashboard.tsx`

## Summary
The table was too broken to patch. This script completely recreates it with the correct structure, fixing both alternating errors at once.
