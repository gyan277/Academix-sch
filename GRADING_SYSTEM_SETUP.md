# Grading System Setup Guide

The grading system is now fully integrated with Supabase and persists across sessions.

## Database Setup

### Step 1: Run the Migration

1. Open your Supabase Dashboard
2. Go to **SQL Editor**
3. Open the file `database-migrations/add-grading-scale.sql`
4. Copy the entire contents
5. Paste into SQL Editor
6. Click **Run**

This will:
- ✅ Create the `grading_scale` table
- ✅ Add RLS policies for security
- ✅ Insert default Ghanaian grading scale (A1-F)
- ✅ Set up automatic timestamp updates

### Step 2: Verify Installation

Run this query in SQL Editor:
```sql
SELECT * FROM public.grading_scale ORDER BY sort_order DESC;
```

You should see 12 grades (A1, A2, B1, B2, B3, C1, C2, C3, D1, D2, E1, F).

## How It Works

### For Admins

1. **View Grades**
   - Go to Settings → Grades tab
   - All grades load from database automatically
   - Sorted by score (highest first)

2. **Add New Grade**
   - Click "Add Grade" button
   - Enter grade name, min score, max score
   - Click "Add Grade"
   - Saved to database immediately
   - All users see the new grade

3. **Edit Grade**
   - Click "Edit" on any grade
   - Modify values
   - Click green checkmark ✓ to save
   - Click red X to cancel
   - Changes saved to database
   - All users see updated grade

4. **Delete Grade**
   - Click trash icon
   - Grade removed from database
   - All users see the change

5. **Save Grading Scale**
   - Click "Save Grading Scale" button
   - Confirms all changes are saved
   - Message: "All student grades will be recalculated"

### For Teachers

- Teachers see the same grading scale
- When entering scores, grades are calculated automatically
- Uses the current grading scale from database
- If admin changes grades, teacher's calculations update automatically

## Default Grading Scale (Ghanaian System)

| Grade | Min Score | Max Score | Description |
|-------|-----------|-----------|-------------|
| A1    | 80        | 100       | Excellent   |
| A2    | 75        | 79        | Very Good   |
| B1    | 70        | 74        | Good        |
| B2    | 65        | 69        | Credit      |
| B3    | 60        | 64        | Credit      |
| C1    | 55        | 59        | Pass        |
| C2    | 50        | 54        | Pass        |
| C3    | 45        | 49        | Pass        |
| D1    | 40        | 44        | Weak Pass   |
| D2    | 35        | 39        | Weak Pass   |
| E1    | 30        | 34        | Poor        |
| F     | 0         | 29        | Fail        |

## Customization

Schools can customize the grading scale to match their system:

### Example: American GPA System
```sql
-- Clear existing grades
DELETE FROM public.grading_scale;

-- Insert American grades
INSERT INTO public.grading_scale (grade, min_score, max_score, sort_order) VALUES
  ('A+', 97, 100, 13),
  ('A', 93, 96, 12),
  ('A-', 90, 92, 11),
  ('B+', 87, 89, 10),
  ('B', 83, 86, 9),
  ('B-', 80, 82, 8),
  ('C+', 77, 79, 7),
  ('C', 73, 76, 6),
  ('C-', 70, 72, 5),
  ('D+', 67, 69, 4),
  ('D', 63, 66, 3),
  ('D-', 60, 62, 2),
  ('F', 0, 59, 1);
```

### Example: UK System
```sql
-- Clear existing grades
DELETE FROM public.grading_scale;

-- Insert UK grades
INSERT INTO public.grading_scale (grade, min_score, max_score, sort_order) VALUES
  ('A*', 90, 100, 9),
  ('A', 80, 89, 8),
  ('B', 70, 79, 7),
  ('C', 60, 69, 6),
  ('D', 50, 59, 5),
  ('E', 40, 49, 4),
  ('F', 30, 39, 3),
  ('G', 20, 29, 2),
  ('U', 0, 19, 1);
```

## Features

### Validation
- ✅ No overlapping score ranges
- ✅ Min score must be ≤ max score
- ✅ Scores must be between 0-100
- ✅ Grade names must be unique

### Security
- ✅ Row Level Security (RLS) enabled
- ✅ Only authenticated users can access
- ✅ Admin check in application layer
- ✅ All changes logged with timestamps

### Performance
- ✅ Indexed for fast lookups
- ✅ Cached in application state
- ✅ Automatic sorting by score
- ✅ Efficient database queries

## Integration with Academic System

When teachers enter scores in the Academic page:

1. Score is entered (e.g., 85)
2. System queries `grading_scale` table
3. Finds matching grade (A1: 80-100)
4. Displays grade on report card
5. If admin changes grading scale, grades recalculate automatically

## Troubleshooting

### Grades Not Loading

**Problem**: Settings page shows "No grades" or loading forever

**Solution**:
1. Check if migration ran successfully
2. Run verification query:
   ```sql
   SELECT COUNT(*) FROM public.grading_scale;
   ```
3. Should return 12 (or your custom count)
4. Check browser console for errors

### Cannot Add/Edit Grades

**Problem**: Changes don't save or show errors

**Solution**:
1. Check RLS policies are enabled:
   ```sql
   SELECT * FROM pg_policies WHERE tablename = 'grading_scale';
   ```
2. Verify user is authenticated
3. Check Supabase logs for errors

### Grades Not Updating for Teachers

**Problem**: Teachers see old grading scale

**Solution**:
1. Teachers need to refresh the page
2. Or logout and login again
3. Grades are loaded on page mount

## Best Practices

1. **Test Before Changing**: Test new grading scale with sample data first
2. **Communicate Changes**: Inform teachers before changing grading scale
3. **Backup First**: Export current grades before major changes
4. **Avoid Overlaps**: Ensure no score ranges overlap
5. **Use Standard Names**: Stick to recognized grade names (A1, B+, etc.)

## Support

For issues:
1. Check browser console (F12) for errors
2. Check Supabase logs in Dashboard
3. Verify migration ran successfully
4. Check RLS policies are correct

---

**Status**: ✅ Grading system fully integrated with database and ready for production!
