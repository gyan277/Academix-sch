# Academic Page - Multi-Subject Score Entry & Report Generation

## Problem
Teachers could only enter scores for one subject at a time, and when switching subjects, the previous scores were lost. There was no way to generate comprehensive report cards with all subjects.

## Solution
Implemented a multi-subject scoring system where teachers can:
1. Enter scores for English and save them
2. Switch to Mathematics and enter scores (English scores are preserved)
3. Continue for all subjects
4. Generate comprehensive report cards with all subjects

---

## How It Works Now

### Teacher Workflow:

**Step 1: Enter Scores for First Subject**
1. Select Class (e.g., P1)
2. Select Subject (e.g., English Language)
3. Enter class scores (0-30) and exam scores (0-70) for all students
4. Click **"Save English Language Scores"**
5. ✅ Scores are saved and subject is marked with a checkmark

**Step 2: Enter Scores for Next Subject**
1. Select Subject (e.g., Mathematics)
2. Score fields reset to 0 (ready for new subject)
3. Enter class scores and exam scores for all students
4. Click **"Save Mathematics Scores"**
5. ✅ Scores are saved and subject is marked with a checkmark

**Step 3: Repeat for All Subjects**
- Continue entering and saving scores for:
  - Science
  - Social Studies
  - Physical Education
  - Arts
  - Music

**Step 4: Generate Comprehensive Reports**
1. After saving scores for all subjects (or at least one)
2. Click **"Generate All Reports"**
3. View comprehensive reports with:
   - All subject scores
   - Total score across all subjects
   - Average percentage
   - Class rank
   - Individual grades per subject

**Step 5: Download Report Cards**
1. Add teacher's remarks for each student
2. Download individual report cards (PDF)
3. Or download all report cards at once

---

## New Features

### 1. Per-Subject Score Saving
- **Save Button**: "Save [Subject] Scores" button for each subject
- **Persistent Storage**: Scores are kept in memory when switching subjects
- **Visual Feedback**: Toast notification confirms scores are saved

### 2. Progress Tracking
- **Subject Dropdown**: Shows checkmark (✓) next to saved subjects
- **Progress Indicator**: Shows "Saved Subjects (3/7)" with visual badges
- **Color Coding**: 
  - Green badges for saved subjects
  - Gray badges for pending subjects

### 3. Comprehensive Reports
- **Multi-Subject Display**: Shows all subjects with individual scores
- **Subject Breakdown**: Each subject shows:
  - Class score
  - Exam score
  - Total score
  - Grade (A1-F)
- **Overall Statistics**:
  - Total score (sum of all subjects)
  - Average percentage
  - Class rank (based on average)

### 4. Smart Validation
- **Save Button**: Disabled if no students loaded
- **Generate Button**: Disabled if no subjects saved
- **Error Messages**: Clear guidance on what to do next

---

## Technical Implementation

### New State Variables:

```typescript
// Stores scores for all subjects
savedScores: {
  "English Language": {
    "STU0001": { classScore: 25, examScore: 65 },
    "STU0002": { classScore: 28, examScore: 70 }
  },
  "Mathematics": {
    "STU0001": { classScore: 22, examScore: 60 },
    "STU0002": { classScore: 30, examScore: 68 }
  }
}

// List of students (persists across subject changes)
studentList: [
  { id: "STU0001", name: "John Doe" },
  { id: "STU0002", name: "Jane Smith" }
]
```

### Key Functions:

**`loadScoresForSubject()`**
- Loads saved scores when subject changes
- If no scores saved, defaults to 0
- Preserves student list

**`handleSaveSubjectScores()`**
- Saves current scores for selected subject
- Updates savedScores state
- Shows success toast

**`handleGenerateReports()`**
- Combines scores from all saved subjects
- Calculates total and average
- Ranks students by average score
- Generates comprehensive reports

---

## UI Components

### Score Entry Tab:
```
┌─────────────────────────────────────────┐
│ Class: P1  │ Subject: English ✓  │ Term │
├─────────────────────────────────────────┤
│ Saved Subjects (3/7)                    │
│ [English ✓] [Math ✓] [Science ✓]       │
│ [Social] [PE] [Arts] [Music]            │
├─────────────────────────────────────────┤
│ Student Table with Score Entry          │
├─────────────────────────────────────────┤
│ [Save English Scores] [Generate Reports]│
└─────────────────────────────────────────┘
```

### Reports Tab:
```
┌─────────────────────────────────────────┐
│ Student: John Doe (STU0001)             │
│ Total: 580  Average: 82.9%  Rank: #1    │
├─────────────────────────────────────────┤
│ Subject Scores:                          │
│ ┌─────────────┬─────────────┬──────────┐│
│ │ English     │ Mathematics │ Science  ││
│ │ Class: 25   │ Class: 22   │ Class: 28││
│ │ Exam: 65    │ Exam: 60    │ Exam: 68 ││
│ │ Total: 90 A1│ Total: 82 A2│ Total: 96││
│ └─────────────┴─────────────┴──────────┘│
├─────────────────────────────────────────┤
│ Remarks: [Excellent performance]         │
│ [Download Report Card]                   │
└─────────────────────────────────────────┘
```

---

## Report Card Features

### Includes:
✅ Student name and ID  
✅ Class and term  
✅ All subject scores (class + exam)  
✅ Individual grades per subject  
✅ Total score across all subjects  
✅ Average percentage  
✅ Class rank  
✅ Teacher's remarks  
✅ School name  

---

## Example Workflow

**Teacher enters scores for P1 class:**

1. **English Language**
   - John: Class 25, Exam 65 = 90 (A1)
   - Jane: Class 28, Exam 70 = 98 (A1)
   - Click "Save English Language Scores" ✓

2. **Mathematics**
   - John: Class 22, Exam 60 = 82 (A2)
   - Jane: Class 30, Exam 68 = 98 (A1)
   - Click "Save Mathematics Scores" ✓

3. **Science**
   - John: Class 28, Exam 68 = 96 (A1)
   - Jane: Class 26, Exam 65 = 91 (A1)
   - Click "Save Science Scores" ✓

4. **Generate Reports**
   - Click "Generate All Reports"
   - John: Total 268, Average 89.3%, Rank #2
   - Jane: Total 287, Average 95.7%, Rank #1

5. **Download**
   - Add remarks for each student
   - Download individual or all report cards

---

## Benefits

### For Teachers:
✅ **No Data Loss**: Scores are preserved when switching subjects  
✅ **Flexible Entry**: Enter subjects in any order  
✅ **Progress Tracking**: See which subjects are complete  
✅ **Comprehensive Reports**: All subjects in one report card  
✅ **Time Saving**: Enter scores once, generate multiple reports  

### For Students/Parents:
✅ **Complete Picture**: See performance across all subjects  
✅ **Clear Grades**: Individual grades for each subject  
✅ **Overall Performance**: Total score and average  
✅ **Class Position**: Know where student ranks  
✅ **Professional Format**: PDF report cards  

---

## Files Modified
- `client/pages/Academic.tsx` - Complete multi-subject scoring system

## Next Steps (Optional Enhancements)

1. **Database Integration**: Save scores to `grades` table in Supabase
2. **Load Previous Scores**: Load existing grades for editing
3. **Subject Management**: Load subjects from database
4. **Term Management**: Support multiple terms per academic year
5. **Bulk Import**: Import scores from Excel/CSV
6. **Print Preview**: Preview report cards before downloading
7. **Email Reports**: Send report cards directly to parents
8. **Analytics**: Show class performance statistics
9. **Grade Boundaries**: Load grading scale from database
10. **Attendance Integration**: Include attendance data in reports

---

## Important Notes

- Scores are currently stored in **component state** (memory)
- Scores are **lost on page refresh** (until database integration)
- Teachers should **complete all subjects in one session**
- Or implement **localStorage** as temporary solution
- Full database integration recommended for production use

---

## Testing Checklist

- [x] Enter scores for first subject
- [x] Save scores for first subject
- [x] Switch to second subject
- [x] First subject scores are preserved
- [x] Second subject fields are empty (ready for entry)
- [x] Save scores for second subject
- [x] Progress indicator shows saved subjects
- [x] Subject dropdown shows checkmarks
- [x] Generate reports with multiple subjects
- [x] Reports show all subject scores
- [x] Total and average calculated correctly
- [x] Class rank assigned correctly
- [x] Download individual report cards
- [x] Download all report cards
- [x] Remarks can be added per student
