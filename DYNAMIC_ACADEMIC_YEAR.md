# Dynamic Academic Year Implementation

## Overview
The academic year is now fully dynamic and can be changed from the Settings page. All modules automatically use the current academic year from the database instead of hardcoded values.

## What Changed

### Before
- Academic year was hardcoded as "2024/2025" in every page
- Changing the year required code changes in multiple files
- No central management of academic year

### After
- Academic year is stored in the `schools` table (`current_academic_year` column)
- All pages load the academic year dynamically from the database
- Can be changed from Settings → Profile tab
- Changes apply immediately across all modules

## How It Works

### 1. Database Storage
The academic year is stored in the `schools` table:
```sql
CREATE TABLE schools (
  id UUID PRIMARY KEY,
  school_name TEXT,
  school_address TEXT,
  school_phone TEXT,
  school_email TEXT,
  current_academic_year TEXT,  -- e.g., "2024/2025"
  ...
);
```

### 2. Custom Hook
Created `client/hooks/use-academic-year.ts`:
```typescript
export function useAcademicYear() {
  const { profile } = useAuth();
  const [academicYear, setAcademicYear] = useState<string>("2024/2025");
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    // Load academic year from schools table
    // Falls back to "2024/2025" if not set
  }, [profile?.school_id]);

  return { academicYear, loading };
}
```

### 3. Usage in Components
All pages now use the hook:
```typescript
import { useAcademicYear } from "@/hooks/use-academic-year";

export default function MyPage() {
  const { academicYear } = useAcademicYear();
  
  // Use academicYear instead of hardcoded "2024/2025"
}
```

## Updated Pages

### 1. Academic Page (`client/pages/Academic.tsx`)
- ✅ Uses `useAcademicYear()` hook
- Loads scores for current academic year
- Generates reports for current academic year

### 2. Attendance Page (`client/pages/Attendance.tsx`)
- ✅ Uses `useAcademicYear()` hook
- Loads teacher class assignments for current year
- Saves attendance records with current year

### 3. Teacher Management (`client/components/TeacherManagement.tsx`)
- ✅ Uses `useAcademicYear()` hook
- Assigns teachers to classes for current year
- Loads teacher assignments for current year

### 4. Settings Page (`client/pages/Settings.tsx`)
- ✅ Uses `useAcademicYear()` hook for loading terms/subjects
- ✅ Provides UI to edit academic year
- ✅ Saves academic year to database
- Shows academic year input field with helpful description

### 5. Finance Page (`client/pages/Finance.tsx`)
- ✅ Already loads academic year from database dynamically
- Uses it for fee calculations and payment tracking

## How to Change Academic Year

### For Admins (UI Method)
1. Go to **Settings** page
2. Click on **Profile** tab
3. Find the **Academic Year** field
4. Enter new year (e.g., "2025/2026")
5. Click **Save School Settings** button
6. Changes apply immediately across all modules

### For Developers (Database Method)
```sql
-- Update academic year for a school
UPDATE schools
SET current_academic_year = '2025/2026'
WHERE id = 'your-school-id';
```

## Important Notes

### Data Isolation by Academic Year
Many tables store data with `academic_year` column:
- `academic_scores` - Student grades
- `teacher_classes` - Teacher assignments
- `class_subjects` - Subject assignments
- `academic_terms` - Term definitions

When you change the academic year:
- **Old data is preserved** - Previous years' data remains in the database
- **New year starts fresh** - No scores, assignments, or terms for the new year
- **You need to**:
  1. Assign teachers to classes for the new year
  2. Configure subjects for each class
  3. Set up terms for the new year
  4. Set fee structures for the new year

### Fallback Behavior
If academic year is not set in the database:
- System falls back to "2024/2025"
- No errors or crashes
- Admin should set it in Settings

### Multi-Tenancy
Each school has its own academic year:
- School A can be in "2024/2025"
- School B can be in "2025/2026"
- Complete isolation between schools

## Testing

### Test Changing Academic Year
1. Login as admin
2. Go to Settings → Profile
3. Change academic year to "2025/2026"
4. Click Save
5. Navigate to Academic page - should show "2025/2026"
6. Navigate to Attendance page - should show "2025/2026"
7. Check teacher assignments - should be empty for new year

### Test Data Isolation
1. Create some scores in "2024/2025"
2. Change to "2025/2026"
3. Academic page should show no scores (new year)
4. Change back to "2024/2025"
5. Scores should reappear (data preserved)

## Migration Guide

### Moving to a New Academic Year
When starting a new academic year:

1. **Backup Data** (optional but recommended)
   ```sql
   -- Export current year's data
   COPY academic_scores TO '/backup/scores_2024_2025.csv' CSV HEADER;
   ```

2. **Change Academic Year**
   - Go to Settings → Profile
   - Update academic year to new year
   - Save settings

3. **Set Up New Year**
   - Assign teachers to classes (Settings → Teachers)
   - Configure subjects for each class (Settings → Subjects)
   - Define terms (Settings → Terms)
   - Set fee structures (Finance → Set Fees)

4. **Promote Students** (if needed)
   - Go to Registrar → Classes
   - Use "Promote All" button for each class
   - JHS3 students will be graduated

5. **Verify**
   - Check Academic page - should be empty
   - Check Attendance - should be empty
   - Check Finance - should show new fee structure

## Benefits

### For Users
- ✅ Easy to change academic year from UI
- ✅ No technical knowledge required
- ✅ Changes apply everywhere automatically
- ✅ Historical data preserved

### For Developers
- ✅ Single source of truth for academic year
- ✅ No hardcoded values scattered in code
- ✅ Easy to maintain and update
- ✅ Consistent behavior across all modules

### For Schools
- ✅ Can manage multiple years of data
- ✅ Can review historical records
- ✅ Smooth transition between years
- ✅ No data loss

## Files Modified

1. **Created:**
   - `client/hooks/use-academic-year.ts` - Custom hook for academic year

2. **Updated:**
   - `client/pages/Academic.tsx` - Use dynamic academic year
   - `client/pages/Attendance.tsx` - Use dynamic academic year
   - `client/components/TeacherManagement.tsx` - Use dynamic academic year
   - `client/pages/Settings.tsx` - Add save function and use dynamic year
   - `client/pages/Finance.tsx` - Import hook (already dynamic)

3. **Documentation:**
   - `DYNAMIC_ACADEMIC_YEAR.md` - This file

## Status
**COMPLETED** ✅

The academic year is now fully dynamic and manageable from the Settings page!
