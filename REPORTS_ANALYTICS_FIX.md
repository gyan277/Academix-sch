# Reports & Analytics Fix

## Issue
The Reports page was showing:
- School Average: 0.0%
- Top Performer: - (no data)
- Classes Assessed: 0 out of 11

## Root Causes
1. The Reports page (`client/pages/Reports.tsx`) was querying from a non-existent table called `exam_scores` instead of the correct `academic_scores` table
2. The `current_term` field in `school_settings` table was NULL, causing the query to return no results

## What Was Fixed

### 1. Updated Database Query
**Before:**
```typescript
const { data: scores, error } = await supabase
  .from("exam_scores")  // ❌ Wrong table
  .select(`
    score,
    student_id,
    students!inner(class, full_name, school_id)
  `)
  .eq("students.school_id", schoolId);
```

**After:**
```typescript
// Build query - start with base filters
let query = supabase
  .from("academic_scores")  // ✅ Correct table
  .select(`
    total_score,
    student_id,
    class,
    students!inner(full_name, school_id)
  `)
  .eq("school_id", schoolId)
  .eq("academic_year", academicYear);

// Only filter by term if it's set (not null)
if (term && term !== "NULL") {
  query = query.eq("term", term);
}
```

### 2. Added Academic Year and Term Filtering
The fix now:
- Loads current academic year and term from `school_settings` table
- Filters scores by the current academic year
- Only filters by term if it's set (handles NULL gracefully)
- Falls back to "2024/2025" and "Term 1" if not set

### 3. Fixed NULL Current Term Issue
**Database Fix:**
- Created `FIX_NULL_CURRENT_TERM.sql` to set default term to "Term 1" for all schools
- Run this SQL in Supabase SQL Editor:
```sql
UPDATE school_settings
SET current_term = 'Term 1'
WHERE current_term IS NULL;
```

**Frontend Fix:**
- Added `currentTerm` state to Settings page
- Added dropdown selector for Current Term (Term 1, Term 2, Term 3)
- Updated `handleSaveSchoolSettings` to save current_term to database
- Updated `loadSchoolSettings` to load current_term from database

### 4. Improved Score Calculation
**Student Average Calculation:**
- Each student may have multiple subject scores
- Calculate average of all subjects per student
- Use this average for class rankings and school average

**Class Average Calculation:**
- Group students by class
- Calculate average of student averages per class
- Find top performer in each class

**School-Wide Metrics:**
- School Average: Average of all class averages
- Top Performer: Student with highest average across all subjects
- Classes Assessed: Count of classes with at least one score

### 5. Added Console Logging
Added comprehensive logging to help debug:
```typescript
console.log("Loading academic data for school:", schoolId);
console.log("Using academic year:", academicYear, "term:", term);
console.log("Fetched academic scores:", scores?.length || 0, "records");
console.log("Calculated averages for", studentAverages.size, "students");
console.log("Grouped data by class:", grouped);
```

## How to Verify the Fix

### Step 1: Fix NULL Current Term in Database
Run `FIX_NULL_CURRENT_TERM.sql` in Supabase SQL Editor:
```sql
UPDATE school_settings
SET current_term = 'Term 1'
WHERE current_term IS NULL;
```

### Step 2: Set Current Term in Settings
1. Go to **Settings** page
2. In the **Profile** tab, you'll now see two fields:
   - Academic Year (text input)
   - Current Term (dropdown: Term 1, Term 2, Term 3)
3. Select the appropriate term
4. Click "Save School Settings"

### Step 3: Check if Academic Data Exists
Run the SQL file `CHECK_ACADEMIC_SCORES_DATA.sql` in Supabase SQL Editor to verify:
1. If there are any academic scores in the database
2. Which schools have scores
3. Which academic year and term the scores are for
4. What the calculated averages should be

### Step 4: Ensure Academic Scores Are Entered
If no data exists:
1. Go to **Academic** page
2. Select a class, term, and grading period
3. Enter scores for students in various subjects
4. Click "Save Scores"

### Step 5: Check Reports Page
1. Navigate to **Reports & Analytics** page (admin only)
2. Click on the **Academic** tab
3. You should now see:
   - School Average (percentage)
   - Top Performer (student name and score)
   - Classes Assessed (number of classes with scores)
   - Class Performance Comparison table

### Step 6: Check Browser Console
Open browser DevTools (F12) and check the Console tab for:
- "Loading academic data for school: [school_id]"
- "Using academic year: 2024/2025 term: Term 1"
- "Fetched academic scores: X records"
- "Calculated averages for X students"
- "Grouped data by class: [array]"

## Database Schema Reference

### academic_scores Table Structure
```sql
- id: UUID (primary key)
- school_id: UUID (references schools)
- student_id: UUID (references students)
- subject_id: UUID (references subjects)
- class: VARCHAR(10)
- academic_year: VARCHAR(20) DEFAULT '2024/2025'
- term: VARCHAR(20) -- 'Term 1', 'Term 2', 'Term 3'
- grading_period: VARCHAR(20) -- 'mid-term' or 'end-term'
- class_score: DECIMAL(5,2) -- Max 50
- exam_score: DECIMAL(5,2) -- Max 50
- total_score: DECIMAL(5,2) -- Auto-calculated (class_score + exam_score)
- grade: VARCHAR(5) -- Auto-calculated based on grading scale
- remarks: TEXT
- recorded_by: UUID
- created_at: TIMESTAMP
- updated_at: TIMESTAMP
```

### school_settings Table Structure
```sql
- id: UUID (primary key, references schools)
- school_id: UUID (references schools)
- school_name: VARCHAR
- school_address: TEXT
- school_phone: VARCHAR
- school_email: VARCHAR
- current_academic_year: VARCHAR(20) DEFAULT '2024/2025'
- current_term: VARCHAR(20) -- 'Term 1', 'Term 2', 'Term 3' (NOW REQUIRED)
- school_logo_url: TEXT
- headmaster_signature_url: TEXT
- created_at: TIMESTAMP
- updated_at: TIMESTAMP
```

### Key Points
- Each student has multiple records (one per subject)
- `total_score` is auto-calculated (max 100)
- Scores are filtered by `school_id`, `academic_year`, and optionally `term`
- Multi-tenancy is enforced via RLS policies
- `current_term` must be set in school_settings for Reports to work properly

## Expected Behavior After Fix

### When Academic Data Exists:
- **School Average**: Shows average percentage across all students and subjects
- **Top Performer**: Shows the student with highest average score and their class
- **Classes Assessed**: Shows count of classes that have at least one score entered
- **Performance Table**: Lists all classes with scores, showing:
  - Class name
  - Average score for the class
  - Performance bar (visual representation)
  - Top student in that class
  - Top student's score

### When No Academic Data Exists:
- Shows "No academic data available yet"
- Prompts user to "Enter exam scores in the Academic page to see performance reports"

## Files Modified
- `client/pages/Reports.tsx` - Fixed academic data loading function, made term filter optional
- `client/pages/Settings.tsx` - Added current_term field with dropdown selector

## Files Created
- `FIX_NULL_CURRENT_TERM.sql` - Sets default term to "Term 1" for all schools
- `CHECK_ACADEMIC_SCORES_DATA.sql` - Diagnostic queries
- `REPORTS_ANALYTICS_FIX.md` - This documentation

## Related Features
- Academic page: Where scores are entered
- Dashboard page: Shows basic stats (enrollment, attendance)
- Reports page: Shows detailed analytics (academic, attendance, enrollment)
- Settings page: Where academic year and current term are configured

## Notes
- The Dashboard page (`client/pages/Dashboard.tsx`) does NOT show academic analytics
- Academic analytics are only available on the Reports page
- Reports page is accessible only to admin users
- The fix maintains multi-tenancy (filters by school_id)
- The fix respects the dynamic academic year and term from school settings
- Current term can now be changed in Settings page and will affect all modules
