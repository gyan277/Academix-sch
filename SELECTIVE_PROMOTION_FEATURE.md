# Selective Student Promotion Feature

## Overview
Admins can now choose which students to promote to the next class and which students should repeat the current class. This provides flexibility for handling students who may need to repeat a year due to academic performance or other reasons.

## How It Works

### 1. Navigate to Classes Tab
- Go to **Registrar → Classes** tab
- Click on any class to view its students

### 2. Select Students for Promotion
- Each student has a checkbox next to their name
- Check the boxes for students you want to promote
- Uncheck boxes for students who should repeat the class

### 3. Quick Selection Options
- **Select All** button - Selects all students in the class
- **Deselect All** button - Clears all selections
- **Clear Selection** link - Removes all selections

### 4. Promotion Options

#### Option A: Promote All Students
- Click **"Promote All to [Next Class]"** button
- All students in the class will be promoted
- No students will repeat

#### Option B: Selective Promotion (NEW!)
- Select specific students using checkboxes
- Click **"Promote Selected (X)"** button
- Selected students move to next class
- Unselected students remain in current class (repeat)

## User Interface

### Selection Counter
```
[X] student(s) selected for promotion
```
Shows how many students are selected

### Repeat Counter
```
[Y] student(s) will repeat [Class]
```
Shows how many students will stay in current class

### Two Buttons
1. **Promote All** - Traditional bulk promotion
2. **Promote Selected** - New selective promotion (disabled if no students selected)

## Examples

### Example 1: Some Students Repeat
**Scenario:** P3 class has 30 students, 3 need to repeat

**Steps:**
1. Go to Registrar → Classes
2. Click on P3
3. Click "Select All" (all 30 selected)
4. Uncheck the 3 students who should repeat
5. Click "Promote Selected (27)"
6. Confirm the action

**Result:**
- 27 students promoted to P4
- 3 students remain in P3

### Example 2: Graduate Some JHS3 Students
**Scenario:** JHS3 has 25 students, 2 failed and need to repeat

**Steps:**
1. Go to Registrar → Classes
2. Click on JHS3
3. Click "Select All" (all 25 selected)
4. Uncheck the 2 students who failed
5. Click "Graduate Selected (23)"
6. Confirm the action

**Result:**
- 23 students graduated (status = "graduated")
- 2 students remain in JHS3

### Example 3: Promote All (Traditional)
**Scenario:** All P1 students passed

**Steps:**
1. Go to Registrar → Classes
2. Click on P1
3. Click "Promote All to P2"
4. Confirm the action

**Result:**
- All P1 students promoted to P2
- No students repeat

## Confirmation Messages

### Selective Promotion
```
Promote [X] students to [Next Class] and keep [Y] students in [Current Class]?
```

### Selective Graduation
```
Graduate [X] students and keep [Y] students in JHS3?
```

### Promote All
```
Promote all [X] students to [Next Class]?
```

### Graduate All
```
Graduate all [X] students from JHS3?
```

## Success Messages

### Selective Promotion
```
✅ Promoted [X] students to [Next Class]. [Y] students will repeat [Current Class].
```

### Selective Graduation
```
✅ Graduated [X] students. [Y] students will repeat JHS3.
```

## Technical Details

### Database Operations
- **Promotion**: Updates `class` field for selected students
- **Repeat**: No database change (students stay in current class)
- **Graduation**: Updates `status` to "graduated" and sets `graduation_date`

### State Management
```typescript
const [selectedStudentsForPromotion, setSelectedStudentsForPromotion] = useState<Set<string>>(new Set());
```

### Functions
1. `toggleStudentSelection(studentId)` - Toggle individual student
2. `toggleSelectAll(classLevel)` - Select/deselect all in class
3. `handleSelectivePromotion(fromClass)` - Promote selected students
4. `handlePromoteClass(fromClass)` - Promote all students (existing)

## Benefits

### For Schools
- ✅ Handle students who need to repeat a year
- ✅ Flexible promotion based on academic performance
- ✅ Maintain accurate class rosters
- ✅ Support for remedial students

### For Admins
- ✅ Easy to use checkbox interface
- ✅ Clear visual feedback on selections
- ✅ Confirmation before making changes
- ✅ Both bulk and selective options available

### For Students
- ✅ Appropriate class placement
- ✅ Opportunity to repeat if needed
- ✅ Fair academic progression

## Use Cases

1. **Academic Performance**
   - Students who failed exams repeat the class
   - High performers move to next class

2. **Attendance Issues**
   - Students with poor attendance repeat
   - Regular attendees promoted

3. **Age Considerations**
   - Younger students may repeat for maturity
   - Age-appropriate class placement

4. **Special Circumstances**
   - Medical leave students repeat
   - Transfer students need class adjustment

5. **Partial Graduation**
   - Some JHS3 students graduate
   - Others repeat for better preparation

## Best Practices

### Before Promotion
1. Review student performance records
2. Check attendance records
3. Consult with teachers
4. Consider parent feedback
5. Review academic scores

### During Promotion
1. Double-check selections
2. Verify student counts
3. Read confirmation message carefully
4. Ensure correct class selected

### After Promotion
1. Verify class rosters
2. Inform parents of decisions
3. Update student records
4. Communicate with teachers
5. Plan support for repeating students

## Troubleshooting

### Issue: Can't select students
**Solution:** Make sure you're on the Classes tab and have clicked on a class

### Issue: "Promote Selected" button disabled
**Solution:** Select at least one student using checkboxes

### Issue: Wrong students promoted
**Solution:** Use "Clear Selection" and start over. Changes are permanent after confirmation.

### Issue: Need to undo promotion
**Solution:** Manually change student's class in Students tab using edit button

## Files Modified
- `client/pages/Registrar.tsx` - Added selective promotion feature

## Status
**COMPLETED** ✅

Admins can now selectively promote students while keeping others in the same class to repeat!
