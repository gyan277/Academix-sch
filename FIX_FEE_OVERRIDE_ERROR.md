# Fix Student Fee Override Error

## Error Message
```
insert or update on table "student_fee_overrides" 
violates foreign key constraint "student_fee_overrides_school_id_fkey"
```

## Root Cause
The `student_fee_overrides` table has incorrect structure:
1. Missing `academic_year` and `term` columns
2. Wrong unique constraint (should be composite: `student_id, academic_year, term`)
3. Possibly missing or incorrect foreign key constraints

## Solution

### Step 1: Run the Fix Script
Execute this SQL in Supabase SQL Editor:
```bash
FIX_STUDENT_FEE_OVERRIDES_COMPLETE.sql
```

This will:
- ✅ Drop and recreate the table with correct structure
- ✅ Add `academic_year` and `term` columns
- ✅ Create composite unique constraint matching frontend expectations
- ✅ Set up proper foreign key constraints
- ✅ Configure RLS policies for multi-tenancy
- ✅ Add updated_at trigger

### Step 2: Verify the Fix
The script will show:
- New table structure with all columns
- All constraints (primary key, foreign keys, unique)
- RLS policies
- Success message

### Step 3: Test in Frontend
1. Go to Finance page
2. Click on a student's "Record Payment" button
3. Check the "Student uses bus service" checkbox
4. Enter a bus fee override (optional)
5. Click "Save Settings"
6. Should save without errors ✅

## What Changed

### Before (Incorrect)
```sql
CREATE TABLE student_fee_overrides (
  id uuid PRIMARY KEY,
  school_id uuid REFERENCES schools(id),
  student_id uuid REFERENCES students(id),
  bus_fee numeric(10,2),
  canteen_fee numeric(10,2),
  UNIQUE(student_id)  -- ❌ Wrong constraint
);
```

### After (Correct)
```sql
CREATE TABLE student_fee_overrides (
  id uuid PRIMARY KEY,
  school_id uuid NOT NULL REFERENCES schools(id) ON DELETE CASCADE,
  student_id uuid NOT NULL REFERENCES students(id) ON DELETE CASCADE,
  academic_year text NOT NULL,  -- ✅ Added
  term text NOT NULL,           -- ✅ Added
  uses_bus boolean DEFAULT false,
  uses_canteen boolean DEFAULT false,
  bus_fee_override numeric(10,2),
  canteen_fee_override numeric(10,2),
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now(),
  UNIQUE(student_id, academic_year, term)  -- ✅ Composite constraint
);
```

## Frontend Data Format
The frontend sends this data:
```typescript
{
  school_id: "uuid",
  student_id: "uuid",
  academic_year: "2024/2025",
  term: "Term 1",
  uses_bus: true,
  uses_canteen: false,
  bus_fee_override: 50.00,
  canteen_fee_override: null
}
```

With upsert conflict resolution:
```typescript
.upsert(overrideData, {
  onConflict: "student_id,academic_year,term"
})
```

## Why This Happened
The table was likely created with an older schema that didn't include `academic_year` and `term` columns. The frontend was updated to include these fields, but the database table wasn't migrated.

## Related Files
- **Fix Script**: `FIX_STUDENT_FEE_OVERRIDES_COMPLETE.sql`
- **Frontend Code**: `client/components/finance/IncomeDashboard.tsx` (line 330-350)
- **Alternative Fix**: `FIX_STUDENT_FEE_OVERRIDES_CONSTRAINT.sql` (simpler version)

## Testing Checklist
- [ ] Run `FIX_STUDENT_FEE_OVERRIDES_COMPLETE.sql`
- [ ] Verify all 8 steps show success
- [ ] Login to Finance page
- [ ] Select a student
- [ ] Configure bus/canteen fees
- [ ] Save settings
- [ ] Verify no error appears
- [ ] Check data saved in database

## Verification Query
After running the fix, verify the table structure:
```sql
SELECT 
  column_name,
  data_type,
  is_nullable
FROM information_schema.columns
WHERE table_name = 'student_fee_overrides'
ORDER BY ordinal_position;
```

Should show:
- id (uuid)
- school_id (uuid, NOT NULL)
- student_id (uuid, NOT NULL)
- academic_year (text, NOT NULL) ✅
- term (text, NOT NULL) ✅
- uses_bus (boolean)
- uses_canteen (boolean)
- bus_fee_override (numeric)
- canteen_fee_override (numeric)
- created_at (timestamptz)
- updated_at (timestamptz)
