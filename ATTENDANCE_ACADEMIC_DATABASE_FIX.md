# Attendance & Academic Pages - Database Integration Fix

## Problem
Teachers couldn't see the students that were added in the Registrar page. The Attendance and Academic pages were not loading students from the database.

## Root Cause
Both pages had empty mock data arrays and no database queries to load actual students from the `students` table.

## Solution
Connected both pages to Supabase to load students dynamically from the database.

---

## Changes Made

### 1. Attendance Page (`client/pages/Attendance.tsx`)

#### Added Imports:
```typescript
import { supabase } from "@/lib/supabase";
import { useToast } from "@/hooks/use-toast";
```

#### New State:
- `loadingData` - Shows loading spinner while fetching students/staff

#### New Functions:

**`loadStudents()`** - Loads students for selected class
```typescript
- Fetches students from database filtered by class
- Only loads active students
- Orders by full name
- Converts to attendance records with default "present" status
- Shows error toast if loading fails
```

**`loadStaff()`** - Loads all staff members (for admin)
```typescript
- Fetches all active staff from database
- Orders by full name
- Converts to attendance records with default "present" status
- Shows error toast if loading fails
```

#### useEffect Hooks:
- **For Teachers**: Loads students when class changes
- **For Admins**: Loads staff when staff tab is selected

#### UI Improvements:
- Loading spinner while fetching data
- Empty state message when no students/staff found
- Helpful message directing users to Registrar page
- Toast notifications instead of alert()

---

### 2. Academic Page (`client/pages/Academic.tsx`)

#### Added Imports:
```typescript
import { useEffect } from "react";
import { supabase } from "@/lib/supabase";
```

#### New State:
- `loadingData` - Shows loading spinner while fetching students

#### New Function:

**`loadStudents()`** - Loads students for selected class
```typescript
- Fetches students from database filtered by class
- Only loads active students
- Orders by full name
- Converts to score records with default 0 scores
- Shows error toast if loading fails
```

#### useEffect Hook:
- Loads students automatically when class changes

#### UI Improvements:
- Loading spinner while fetching data
- Empty state message when no students found
- Helpful message directing users to Registrar page
- Disabled "Generate Reports" button when no students
- Changed school name default to "MOMA"

---

## How It Works Now

### For Teachers (Attendance Page):

1. **Login as Teacher**
2. **Go to Attendance page**
3. **Select a class** (e.g., P1, P2, JHS1)
4. **Students automatically load** from database
5. **Mark attendance** (Present/Late/Absent)
6. **Save attendance**

**If no students appear:**
- Check that students were added in the Registrar page
- Verify students are assigned to the correct class
- Ensure students have "active" status

### For Teachers (Academic Page):

1. **Login as Teacher**
2. **Go to Academic Engine page**
3. **Select a class** (e.g., P1, P2, JHS1)
4. **Students automatically load** from database
5. **Enter class scores** (0-30)
6. **Enter exam scores** (0-70)
7. **Generate reports**
8. **Download individual or all report cards**

**If no students appear:**
- Check that students were added in the Registrar page
- Verify students are assigned to the correct class
- Ensure students have "active" status

### For Admins (Attendance Page):

1. **Login as Admin**
2. **Go to Attendance page**
3. **Staff tab is selected by default**
4. **All staff automatically load** from database
5. **Mark staff attendance** (Present/Absent)
6. **Save attendance**

---

## Database Queries

### Load Students by Class:
```sql
SELECT id, student_id, full_name
FROM students
WHERE class = 'P1'
  AND status = 'active'
ORDER BY full_name;
```

### Load All Active Staff:
```sql
SELECT id, staff_id, full_name
FROM staff
WHERE status = 'active'
ORDER BY full_name;
```

---

## Features

### Attendance Page:
✅ Teachers see students from selected class  
✅ Admins see all staff members  
✅ Auto-loads data when class/tab changes  
✅ Loading spinner during data fetch  
✅ Empty state with helpful message  
✅ Toast notifications for errors  
✅ Real-time data from database  

### Academic Page:
✅ Teachers see students from selected class  
✅ Auto-loads data when class changes  
✅ Loading spinner during data fetch  
✅ Empty state with helpful message  
✅ Toast notifications for errors  
✅ Real-time data from database  
✅ Score entry for class and exam marks  
✅ Auto-calculated grades  
✅ Report card generation  
✅ PDF download functionality  

---

## Testing Checklist

### Attendance Page:
- [x] Teacher logs in
- [x] Selects a class with students
- [x] Students appear in the list
- [x] Can mark attendance
- [x] Can save attendance
- [x] Empty state shows when no students
- [x] Loading spinner appears while loading
- [x] Admin sees staff instead of students

### Academic Page:
- [x] Teacher logs in
- [x] Selects a class with students
- [x] Students appear in the score table
- [x] Can enter class scores (0-30)
- [x] Can enter exam scores (0-70)
- [x] Total and grade calculate automatically
- [x] Can generate reports
- [x] Can download report cards
- [x] Empty state shows when no students
- [x] Loading spinner appears while loading

---

## Files Modified
- `client/pages/Attendance.tsx` - Added database integration for students/staff
- `client/pages/Academic.tsx` - Added database integration for students

## Database Tables Used
- `public.students` - Student records filtered by class
- `public.staff` - Staff records for admin attendance

## Dependencies
- Supabase client (`@/lib/supabase`)
- Toast notifications (`@/hooks/use-toast`)
- React hooks (useState, useEffect)

---

## Next Steps (Optional Enhancements)

1. **Save Attendance to Database**: Currently attendance is only saved in local state
2. **Load Previous Attendance**: Load existing attendance records for selected date
3. **Attendance History**: Show attendance trends and statistics
4. **Save Grades to Database**: Save entered scores to the `grades` table
5. **Load Previous Grades**: Load existing grades for editing
6. **Subject Management**: Load subjects from database instead of hardcoded list
7. **Class Management**: Load classes from database based on school setup
8. **Teacher Class Assignment**: Filter classes based on teacher's assigned classes

---

## Important Notes

- Students must be added via the **Registrar page** first
- Students must have **"active" status** to appear
- Students must be assigned to a **valid class** (KG1-JHS3)
- The **class filter** determines which students load
- **Empty states** guide users to add students if none exist
- **Loading states** prevent confusion during data fetch
- **Error handling** shows toast notifications for failures
