# Academic Year - Complete Setup & Verification

## ✅ System is Now Fully Linked to Database

The academic year system is now completely dynamic and connected to your database. Here's the complete flow:

## Database Flow

```
school_settings table
    ↓
    current_academic_year column (TEXT)
    ↓
    useAcademicYear() hook
    ↓
    All pages (Academic, Attendance, Teachers, Finance, Settings)
```

## How It Works

### 1. Database Storage
```sql
-- Table: school_settings
-- Column: current_academic_year
-- Type: TEXT
-- Example: "2024/2025"

SELECT current_academic_year 
FROM school_settings 
WHERE id = 'your-school-id';
```

### 2. Frontend Hook
```typescript
// client/hooks/use-academic-year.ts
const { academicYear } = useAcademicYear();
// Returns: "2024/2025" (or whatever is in database)
```

### 3. All Pages Use It
- ✅ **Academic.tsx** - Loads scores for current year
- ✅ **Attendance.tsx** - Loads attendance for current year
- ✅ **TeacherManagement.tsx** - Assigns teachers for current year
- ✅ **Settings.tsx** - Displays and edits current year
- ✅ **Finance.tsx** - Tracks fees for current year

## Setup Instructions

### Step 1: Run Database Setup (One Time)
Run this in Supabase SQL Editor:
```sql
-- File: ENSURE_ACADEMIC_YEAR_SETUP.sql
```

This will:
- ✅ Ensure the column exists
- ✅ Set default value "2024/2025" for all schools
- ✅ Verify everything is ready

### Step 2: Verify Setup (Optional)
Run this to check everything:
```sql
-- File: VERIFY_ACADEMIC_YEAR_FLOW.sql
```

This will:
- ✅ Check column exists
- ✅ Show all schools and their academic years
- ✅ Test update functionality
- ✅ Show data distribution by year

### Step 3: Use the UI
1. Login as admin
2. Go to **Settings → Profile**
3. See the **Academic Year** field
4. Change it if needed (e.g., "2025/2026")
5. Click **Save School Settings**
6. Done! All pages now use the new year

## Complete Data Flow Example

### Scenario: Changing from 2024/2025 to 2025/2026

1. **Admin goes to Settings**
   ```
   Settings Page loads → useAcademicYear() → Fetches from database → Shows "2024/2025"
   ```

2. **Admin changes to "2025/2026" and saves**
   ```
   Click Save → UPDATE school_settings SET current_academic_year = '2025/2026' → Success!
   ```

3. **Admin goes to Academic Page**
   ```
   Academic Page loads → useAcademicYear() → Fetches from database → Shows "2025/2026"
   Academic Page queries scores WHERE academic_year = '2025/2026' → Empty (new year)
   ```

4. **Admin goes to Attendance Page**
   ```
   Attendance Page loads → useAcademicYear() → Fetches from database → Shows "2025/2026"
   Loads teacher assignments WHERE academic_year = '2025/2026' → Empty (new year)
   ```

5. **All historical data preserved**
   ```
   Scores from 2024/2025 still in database
   Attendance from 2024/2025 still in database
   Can switch back anytime to view old data
   ```

## Database Tables Using Academic Year

All these tables have `academic_year` column:

1. **academic_scores** - Student grades
   ```sql
   SELECT * FROM academic_scores WHERE academic_year = '2024/2025';
   ```

2. **teacher_classes** - Teacher assignments
   ```sql
   SELECT * FROM teacher_classes WHERE academic_year = '2024/2025';
   ```

3. **class_subjects** - Subject assignments
   ```sql
   SELECT * FROM class_subjects WHERE academic_year = '2024/2025';
   ```

4. **academic_terms** - Term definitions
   ```sql
   SELECT * FROM academic_terms WHERE academic_year = '2024/2025';
   ```

## Testing the Flow

### Test 1: Verify Database Connection
```sql
-- Run in Supabase SQL Editor
SELECT 
  id,
  school_name,
  current_academic_year
FROM school_settings;
```
Expected: Should show your school with academic year

### Test 2: Update via SQL
```sql
-- Update academic year
UPDATE school_settings
SET current_academic_year = '2025/2026'
WHERE school_name = 'Mount Olivet Methodist Academy';

-- Verify
SELECT current_academic_year FROM school_settings;
```
Expected: Should show "2025/2026"

### Test 3: Verify in UI
1. Refresh your browser
2. Go to any page (Academic, Attendance, etc.)
3. Check browser console: `console.log(academicYear)`
4. Should show "2025/2026"

### Test 4: Update via UI
1. Go to Settings → Profile
2. Change academic year to "2024/2025"
3. Click Save
4. Go to Academic page
5. Should show "2024/2025"

## Troubleshooting

### Issue: Academic year not changing
**Solution:**
1. Check browser console for errors
2. Verify you clicked "Save School Settings"
3. Refresh the page
4. Check database: `SELECT current_academic_year FROM school_settings;`

### Issue: Shows "2024/2025" even after changing
**Solution:**
1. Clear browser cache
2. Hard refresh (Ctrl+Shift+R or Cmd+Shift+R)
3. Check if save was successful in database

### Issue: Different pages show different years
**Solution:**
- This shouldn't happen! All pages use the same hook
- Check browser console for errors
- Verify database has only one value

## Files Involved

### Frontend
- `client/hooks/use-academic-year.ts` - Hook that loads from database
- `client/pages/Academic.tsx` - Uses the hook
- `client/pages/Attendance.tsx` - Uses the hook
- `client/components/TeacherManagement.tsx` - Uses the hook
- `client/pages/Settings.tsx` - Displays and saves to database
- `client/pages/Finance.tsx` - Uses the hook

### Database
- `school_settings` table - Stores the academic year
- `academic_scores` table - Uses academic_year for filtering
- `teacher_classes` table - Uses academic_year for filtering
- `class_subjects` table - Uses academic_year for filtering
- `academic_terms` table - Uses academic_year for filtering

### SQL Scripts
- `ENSURE_ACADEMIC_YEAR_SETUP.sql` - Setup script
- `VERIFY_ACADEMIC_YEAR_FLOW.sql` - Verification script

## Summary

✅ **Database**: `school_settings.current_academic_year` column exists and stores the value

✅ **Hook**: `useAcademicYear()` loads from database and provides to all pages

✅ **Pages**: All pages use the hook and query data for current year

✅ **Settings**: UI to view and edit academic year with save functionality

✅ **Multi-tenancy**: Each school has its own academic year

✅ **Data isolation**: Historical data preserved when changing years

## Status: FULLY OPERATIONAL ✅

The academic year system is now completely linked to the database and working end-to-end!
