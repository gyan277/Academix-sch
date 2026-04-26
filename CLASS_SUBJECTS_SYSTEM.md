# Class Subjects Management System

## Overview
This system allows admins to configure which subjects are taught in each class, recognizing that different grade levels have different curricula.

## Problem Solved
- **KG1/KG2** don't need advanced subjects like ICT or French
- **Primary 1-3** have basic subjects
- **Primary 4-6** add more subjects
- **JHS 1-3** have the full curriculum including electives
- Teachers should only see relevant subjects for their selected class

---

## Database Structure

### Table: `class_subjects`
Stores the relationship between classes and subjects.

```sql
CREATE TABLE public.class_subjects (
  id UUID PRIMARY KEY,
  class TEXT NOT NULL,                    -- e.g., 'KG1', 'P1', 'JHS1'
  subject_id UUID REFERENCES subjects(id), -- Links to subjects table
  academic_year TEXT NOT NULL,             -- e.g., '2024/2025'
  is_active BOOLEAN DEFAULT true,          -- Can deactivate without deleting
  created_at TIMESTAMPTZ,
  updated_at TIMESTAMPTZ,
  UNIQUE(class, subject_id, academic_year) -- One subject per class per year
);
```

### Relationships:
```
subjects (existing)
    ↓
class_subjects (new)
    ↓
Used by Academic page to show only relevant subjects
```

---

## Default Subject Assignments

### KG1 & KG2 (Kindergarten)
- English Language
- Mathematics
- Creative Arts
- Physical Education

### P1, P2, P3 (Primary Lower)
- English Language
- Mathematics
- Science
- Social Studies
- Creative Arts
- Physical Education
- Religious & Moral Education

### P4, P5, P6 (Primary Upper)
- English Language
- Mathematics
- Science
- Social Studies
- Creative Arts
- Physical Education
- ICT
- Religious & Moral Education

### JHS1, JHS2, JHS3 (Junior High)
- English Language
- Mathematics
- Science
- Social Studies
- Creative Arts
- Physical Education
- ICT
- Religious & Moral Education

---

## Setup Instructions

### Step 1: Run Database Migration
```bash
# In Supabase SQL Editor, run:
database-migrations/add-class-subjects.sql
```

This will:
- ✅ Create `class_subjects` table
- ✅ Set up indexes for performance
- ✅ Enable Row Level Security
- ✅ Create default subject assignments for all classes
- ✅ Set up triggers for automatic timestamps

### Step 2: Verify Installation
```sql
-- Check subjects per class
SELECT 
  cs.class,
  s.subject_name,
  cs.academic_year
FROM class_subjects cs
JOIN subjects s ON cs.subject_id = s.id
WHERE cs.is_active = true
ORDER BY cs.class, s.subject_name;

-- Count subjects per class
SELECT 
  class,
  COUNT(*) as subject_count
FROM class_subjects
WHERE is_active = true
GROUP BY class
ORDER BY class;
```

---

## How It Works

### For Admins (Settings Page):
1. Go to **Settings** → **Subjects** tab
2. Select a class (e.g., KG1)
3. See all available subjects with checkboxes
4. Check/uncheck subjects for that class
5. Save changes
6. Repeat for other classes

### For Teachers (Academic Page):
1. Select a class (e.g., P1)
2. Subject dropdown **automatically loads** only subjects assigned to P1
3. Enter scores for those subjects only
4. Switch to P4 → Different subjects appear
5. Generate reports with only relevant subjects

---

## Example Scenarios

### Scenario 1: KG1 Teacher
```
Teacher selects: KG1
Subjects shown:
  - English Language
  - Mathematics
  - Creative Arts
  - Physical Education

NOT shown:
  - Science (too advanced)
  - ICT (not taught at KG level)
  - Social Studies (not in KG curriculum)
```

### Scenario 2: P4 Teacher
```
Teacher selects: P4
Subjects shown:
  - English Language
  - Mathematics
  - Science
  - Social Studies
  - Creative Arts
  - Physical Education
  - ICT (added in upper primary)
  - Religious & Moral Education
```

### Scenario 3: JHS2 Teacher
```
Teacher selects: JHS2
Subjects shown:
  - All 8 core subjects
  - Plus any electives configured by admin
```

---

## Admin Management Interface (Future)

### Features to Implement:

**1. Class Subject Assignment**
```
┌─────────────────────────────────────┐
│ Select Class: [P1 ▼]                │
├─────────────────────────────────────┤
│ Available Subjects:                  │
│ ☑ English Language                   │
│ ☑ Mathematics                        │
│ ☑ Science                            │
│ ☑ Social Studies                     │
│ ☐ ICT (not assigned)                 │
│ ☑ Creative Arts                      │
│ ☑ Physical Education                 │
│ ☑ Religious & Moral Education        │
├─────────────────────────────────────┤
│ [Save Changes]                       │
└─────────────────────────────────────┘
```

**2. Bulk Assignment**
```
Copy subjects from P1 to P2, P3
Apply template to all Primary classes
```

**3. Subject Management**
```
Add new subjects (e.g., French, Music)
Edit subject names
Deactivate subjects (soft delete)
```

---

## API Queries

### Get Subjects for a Class
```typescript
const { data: classSubjects } = await supabase
  .from('class_subjects')
  .select(`
    id,
    subject_id,
    subjects (
      subject_code,
      subject_name
    )
  `)
  .eq('class', 'P1')
  .eq('academic_year', '2024/2025')
  .eq('is_active', true);
```

### Add Subject to Class
```typescript
const { data, error } = await supabase
  .from('class_subjects')
  .insert({
    class: 'P1',
    subject_id: subjectId,
    academic_year: '2024/2025',
    is_active: true
  });
```

### Remove Subject from Class
```typescript
const { error } = await supabase
  .from('class_subjects')
  .update({ is_active: false })
  .eq('class', 'P1')
  .eq('subject_id', subjectId);
```

---

## Integration with Academic Page

### Current Code (Hardcoded):
```typescript
const subjects = [
  "English Language",
  "Mathematics",
  "Science",
  // ... all subjects for all classes
];
```

### Updated Code (Dynamic):
```typescript
const [subjects, setSubjects] = useState<string[]>([]);

useEffect(() => {
  if (selectedClass) {
    loadSubjectsForClass();
  }
}, [selectedClass]);

const loadSubjectsForClass = async () => {
  const { data } = await supabase
    .from('class_subjects')
    .select(`
      subjects (
        subject_name
      )
    `)
    .eq('class', selectedClass)
    .eq('academic_year', '2024/2025')
    .eq('is_active', true);
    
  const subjectNames = data.map(cs => cs.subjects.subject_name);
  setSubjects(subjectNames);
};
```

---

## Benefits

### For School Administration:
✅ **Curriculum Control**: Define exactly what's taught in each class  
✅ **Flexibility**: Easy to add/remove subjects per class  
✅ **Academic Year Support**: Different subjects per year  
✅ **No Code Changes**: Admins manage via UI, not code  

### For Teachers:
✅ **Relevant Subjects Only**: No confusion with irrelevant subjects  
✅ **Cleaner Interface**: Shorter dropdown lists  
✅ **Accurate Reports**: Only subjects actually taught  
✅ **Less Errors**: Can't enter scores for wrong subjects  

### For Students/Parents:
✅ **Accurate Report Cards**: Only subjects actually taken  
✅ **Clear Curriculum**: Know what's taught at each level  
✅ **Professional**: Report cards match actual curriculum  

---

## Migration Path

### Phase 1: Database Setup ✅
- Run SQL migration
- Verify default assignments
- Test queries

### Phase 2: Admin UI (To Do)
- Build class subject management interface
- Add/remove subjects per class
- Bulk operations
- Visual feedback

### Phase 3: Teacher Integration (To Do)
- Update Academic page to load subjects dynamically
- Filter subjects by selected class
- Update report generation
- Test with different classes

### Phase 4: Enhancements (Future)
- Subject prerequisites (e.g., Advanced Math requires Basic Math)
- Elective subjects
- Subject groupings (Core vs Elective)
- Teacher-subject assignments
- Subject scheduling

---

## Files

### Database:
- `database-migrations/add-class-subjects.sql` - Creates table and default data

### Frontend (To Update):
- `client/pages/Settings.tsx` - Add admin management UI
- `client/pages/Academic.tsx` - Load subjects dynamically
- `client/lib/supabase.ts` - Add helper functions

### Documentation:
- `CLASS_SUBJECTS_SYSTEM.md` - This file

---

## Testing Checklist

### Database:
- [ ] Table created successfully
- [ ] Default subjects assigned to all classes
- [ ] RLS policies working
- [ ] Indexes created
- [ ] Triggers working

### Admin UI:
- [ ] Can view subjects per class
- [ ] Can add subject to class
- [ ] Can remove subject from class
- [ ] Changes save to database
- [ ] Changes persist after refresh

### Teacher Experience:
- [ ] KG teacher sees only KG subjects
- [ ] Primary teacher sees only Primary subjects
- [ ] JHS teacher sees only JHS subjects
- [ ] Subjects change when class changes
- [ ] Can enter scores for all assigned subjects
- [ ] Reports show only assigned subjects

---

## Support

For questions or issues:
1. Check database migration ran successfully
2. Verify subjects exist in `subjects` table
3. Check `class_subjects` table has data
4. Review RLS policies
5. Check browser console for errors

---

## Summary

This system provides flexible, admin-controlled subject assignment per class, ensuring teachers only see relevant subjects and students receive accurate report cards that match their actual curriculum.
