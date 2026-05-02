# Grading Scale Management Guide

## Overview

Each school can now customize their own grading system through the Settings page. The grading scale determines how total scores are converted to letter grades (A1, B2, C3, etc.).

## Features

✅ **Customizable Grading Scale** - Each school has its own grading system
✅ **Easy Management** - Add, edit, and delete grades through the UI
✅ **Visual Preview** - See how grades will be assigned
✅ **Default Scale** - Starts with a standard grading scale
✅ **Validation** - Prevents overlapping ranges and invalid scores
✅ **Auto-Apply** - Changes automatically affect all grade calculations

## How to Configure Grading Scale

### Step 1: Access Settings

1. Log in as **Admin**
2. Go to **Settings** page
3. Click on the **Grades** tab

### Step 2: View Current Grading Scale

You'll see:
- List of all grades with their score ranges
- Visual preview of the grading system
- Add/Edit/Delete options

### Step 3: Modify Grading Scale

**Add a New Grade:**
1. Click **"Add Grade"** button
2. Enter grade name (e.g., "A1", "B+")
3. Set min score (e.g., 80)
4. Set max score (e.g., 100)

**Edit Existing Grade:**
1. Change the grade name, min score, or max score directly in the form
2. Scores must be between 0-100
3. Min score must be less than max score

**Delete a Grade:**
1. Click the trash icon next to the grade
2. Confirm deletion

**Reset to Default:**
1. Click **"Reset to Default"** button
2. This restores the standard grading scale

### Step 4: Save Changes

1. Click **"Save Grading Scale"** button
2. Changes are saved to the database
3. All future grade calculations will use the new scale

## Default Grading Scale

| Grade | Min Score | Max Score |
|-------|-----------|-----------|
| A1    | 80        | 100       |
| A2    | 75        | 79        |
| B1    | 70        | 74        |
| B2    | 65        | 69        |
| B3    | 60        | 64        |
| C1    | 55        | 59        |
| C2    | 50        | 54        |
| C3    | 45        | 49        |
| D1    | 40        | 44        |
| D2    | 35        | 39        |
| E1    | 30        | 34        |
| F     | 0         | 29        |

## How Grades Are Calculated

When a teacher enters scores:
1. **Class Score** + **Exam Score** = **Total Score**
2. System looks up the total score in the grading scale
3. Finds the grade where: `min_score ≤ total_score ≤ max_score`
4. Assigns that grade to the student

### Example:
- Class Score: 45
- Exam Score: 38
- **Total Score: 83**
- Grade: **A1** (because 83 is between 80-100)

## Multi-Tenancy

- Each school has its **own grading scale**
- Changes in one school don't affect other schools
- Grading scale is tied to `school_id`

## Validation Rules

✅ Grade names cannot be empty
✅ Scores must be between 0-100
✅ Min score must be ≤ Max score
✅ No overlapping ranges (recommended)

## Database Structure

```sql
CREATE TABLE grading_scale (
  id UUID PRIMARY KEY,
  school_id UUID REFERENCES schools(id),
  grade TEXT NOT NULL,
  min_score INTEGER NOT NULL,
  max_score INTEGER NOT NULL,
  created_at TIMESTAMP DEFAULT NOW()
);
```

## Setup for New Schools

Run this SQL to set up the default grading scale:

```sql
INSERT INTO grading_scale (school_id, grade, min_score, max_score)
SELECT 
  (SELECT id FROM schools WHERE school_name = 'YOUR_SCHOOL_NAME' LIMIT 1),
  grade,
  min_score,
  max_score
FROM (VALUES
  ('A1', 80, 100),
  ('A2', 75, 79),
  ('B1', 70, 74),
  ('B2', 65, 69),
  ('B3', 60, 64),
  ('C1', 55, 59),
  ('C2', 50, 54),
  ('C3', 45, 49),
  ('D1', 40, 44),
  ('D2', 35, 39),
  ('E1', 30, 34),
  ('F', 0, 29)
) AS grades(grade, min_score, max_score);
```

## Troubleshooting

### All Grades Showing "F"

**Problem:** No grading scale configured for your school

**Solution:** 
1. Go to Settings → Grades tab
2. Click "Reset to Default"
3. Click "Save Grading Scale"
4. Refresh the Academic page

### Grades Not Updating

**Problem:** Browser cache or old data

**Solution:**
1. Hard refresh the page (Ctrl + Shift + R)
2. Re-enter scores if needed
3. Check that grading scale was saved successfully

### Can't Save Grading Scale

**Problem:** Validation errors or database permissions

**Solution:**
1. Check that all grades have names
2. Verify min/max scores are valid (0-100)
3. Ensure min ≤ max for each grade
4. Check browser console for errors

## Best Practices

1. **Plan Your Scale** - Design your grading system before entering it
2. **No Gaps** - Ensure all scores from 0-100 are covered
3. **No Overlaps** - Each score should map to only one grade
4. **Test First** - Enter a few test scores to verify grades calculate correctly
5. **Communicate Changes** - Inform teachers before changing the grading scale

## Impact of Changes

⚠️ **Important:** Changing the grading scale affects:
- All future score entries
- Grade calculations in reports
- Student report cards

Existing scores in the database are NOT automatically recalculated. The grade is recalculated when:
- Viewing the Academic page
- Generating new reports
- Re-entering or updating scores

## Support

If you need help:
1. Check this guide first
2. Verify your grading scale in Settings → Grades
3. Run the setup SQL if needed
4. Contact support if issues persist

---

**Status**: ✅ Feature Complete
**Location**: Settings → Grades Tab
**Access**: Admin Only
