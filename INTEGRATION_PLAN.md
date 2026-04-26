# Supabase Integration Plan

## Current Status
✅ Supabase client configured (`client/lib/supabase.ts`)
✅ Database schema designed (12 tables)
✅ TypeScript types defined
✅ Environment variables set up
⏳ Frontend still using mock data
⏳ Authentication still using localStorage

## Integration Phases

### Phase 1: Authentication (PRIORITY 1) ⚡
**Files to Update:**
- `client/pages/Login.tsx` - Replace localStorage with Supabase Auth
- `client/hooks/use-auth.ts` - Use Supabase session management
- `client/components/ProtectedRoute.tsx` - Check Supabase auth state

**What Changes:**
- Replace mock user login with `supabase.auth.signInWithPassword()`
- Store user session in Supabase (not localStorage)
- Fetch user role from `public.users` table
- Implement proper logout with `supabase.auth.signOut()`

**Benefits:**
- Secure authentication
- Session persistence
- Password reset capability
- Multi-device support

---

### Phase 2: Dashboard (PRIORITY 2) 📊
**Files to Update:**
- `client/pages/Dashboard.tsx` - Fetch real statistics

**Database Queries:**
```typescript
// Total enrollment
const { count } = await supabase
  .from('students')
  .select('*', { count: 'exact', head: true })
  .eq('status', 'active');

// Today's attendance
const { data } = await supabase
  .from('attendance')
  .select('status')
  .eq('date', today);

// Staff present
const { data } = await supabase
  .from('staff_attendance')
  .select('status')
  .eq('date', today)
  .eq('status', 'present');
```

---

### Phase 3: Registrar (PRIORITY 3) 👥
**Files to Update:**
- `client/pages/Registrar.tsx` - CRUD operations for students and staff

**Database Operations:**
```typescript
// Fetch students
const { data } = await supabase
  .from('students')
  .select('*')
  .eq('status', 'active')
  .order('full_name');

// Add student
const { data, error } = await supabase
  .from('students')
  .insert({
    student_id: generateStudentId(),
    full_name: name,
    date_of_birth: dob,
    gender: gender,
    class: selectedClass,
    parent_name: parentName,
    parent_phone: parentPhone,
    admission_date: new Date().toISOString().split('T')[0],
    status: 'active'
  });

// Update student
const { error } = await supabase
  .from('students')
  .update({ class: newClass })
  .eq('id', studentId);

// Delete student (soft delete)
const { error } = await supabase
  .from('students')
  .update({ status: 'inactive' })
  .eq('id', studentId);
```

---

### Phase 4: Attendance (PRIORITY 4) ✅
**Files to Update:**
- `client/pages/Attendance.tsx` - Real-time attendance marking

**Database Operations:**
```typescript
// Mark attendance
const { error } = await supabase
  .from('attendance')
  .upsert({
    student_id: studentId,
    class: selectedClass,
    date: selectedDate,
    status: 'present',
    marked_by: teacherId
  });

// Fetch attendance history
const { data } = await supabase
  .from('attendance')
  .select(`
    *,
    students (full_name, student_id)
  `)
  .eq('class', selectedClass)
  .gte('date', startDate)
  .lte('date', endDate);
```

---

### Phase 5: Academic Engine (PRIORITY 5) 📚
**Files to Update:**
- `client/pages/Academic.tsx` - Grade entry and report generation

**Database Operations:**
```typescript
// Fetch students for grade entry
const { data } = await supabase
  .from('students')
  .select('id, student_id, full_name')
  .eq('class', selectedClass)
  .eq('status', 'active');

// Save grades
const { error } = await supabase
  .from('grades')
  .upsert({
    student_id: studentId,
    subject_id: subjectId,
    class: selectedClass,
    term: currentTerm,
    academic_year: currentYear,
    class_score: classScore,
    exam_score: examScore,
    teacher_id: teacherId
  });

// Fetch grades for reports
const { data } = await supabase
  .from('grades')
  .select(`
    *,
    students (full_name, student_id),
    subjects (name, code)
  `)
  .eq('class', selectedClass)
  .eq('term', selectedTerm);
```

---

### Phase 6: Settings (PRIORITY 6) ⚙️
**Files to Update:**
- `client/pages/Settings.tsx` - School configuration and file uploads

**Database Operations:**
```typescript
// Fetch school settings
const { data } = await supabase
  .from('school_settings')
  .select('*')
  .single();

// Update school settings
const { error } = await supabase
  .from('school_settings')
  .update({
    school_name: name,
    school_address: address,
    school_phone: phone,
    current_academic_year: year
  })
  .eq('id', settingsId);

// Upload logo
const { data, error } = await supabase.storage
  .from('school-assets')
  .upload(`logos/${fileName}`, file);

// Get public URL
const { data: { publicUrl } } = supabase.storage
  .from('school-assets')
  .getPublicUrl(`logos/${fileName}`);
```

---

### Phase 7: Communication (PRIORITY 7) 💬
**Files to Update:**
- `client/pages/Communication.tsx` - SMS logging

**Database Operations:**
```typescript
// Log SMS
const { error } = await supabase
  .from('sms_log')
  .insert({
    recipient_type: 'parent',
    recipient_ids: selectedStudentIds,
    message: messageText,
    status: 'sent',
    sent_by: userId,
    sent_at: new Date().toISOString()
  });

// Fetch SMS history
const { data } = await supabase
  .from('sms_log')
  .select('*')
  .order('created_at', { ascending: false })
  .limit(50);
```

---

### Phase 8: Reports (PRIORITY 8) 📈
**Files to Update:**
- `client/pages/Reports.tsx` - Generate reports from real data

**Database Queries:**
```typescript
// Academic performance report
const { data } = await supabase
  .from('grades')
  .select(`
    *,
    students (full_name, class),
    subjects (name)
  `)
  .eq('term', selectedTerm)
  .eq('academic_year', selectedYear);

// Attendance report
const { data } = await supabase
  .from('attendance')
  .select(`
    *,
    students (full_name, class)
  `)
  .gte('date', startDate)
  .lte('date', endDate);
```

---

## Helper Functions to Create

### 1. Student ID Generator
```typescript
// client/lib/utils.ts
export async function generateStudentId(): Promise<string> {
  const { count } = await supabase
    .from('students')
    .select('*', { count: 'exact', head: true });
  
  return `STU${String((count || 0) + 1).padStart(4, '0')}`;
}
```

### 2. Grade Calculator
```typescript
export function calculateGrade(total: number): string {
  if (total >= 80) return "A1";
  if (total >= 75) return "A2";
  if (total >= 70) return "B1";
  if (total >= 65) return "B2";
  if (total >= 60) return "B3";
  if (total >= 55) return "C1";
  if (total >= 50) return "C2";
  if (total >= 45) return "C3";
  if (total >= 40) return "D1";
  if (total >= 35) return "D2";
  if (total >= 30) return "E1";
  return "F";
}
```

### 3. Date Formatter
```typescript
export function formatDate(date: string): string {
  return new Date(date).toLocaleDateString('en-GB', {
    day: '2-digit',
    month: 'short',
    year: 'numeric'
  });
}
```

---

## Storage Buckets to Create

### In Supabase Dashboard → Storage:

1. **school-assets** (public)
   - `logos/` - School logos
   - `signatures/` - Headmaster signatures
   - `photos/students/` - Student photos
   - `photos/staff/` - Staff photos

### Storage Policies:
```sql
-- Allow authenticated users to upload
CREATE POLICY "Authenticated users can upload"
ON storage.objects FOR INSERT
TO authenticated
WITH CHECK (bucket_id = 'school-assets');

-- Allow public read access
CREATE POLICY "Public can view assets"
ON storage.objects FOR SELECT
TO public
USING (bucket_id = 'school-assets');
```

---

## Testing Checklist

### After Each Phase:
- [ ] Test CRUD operations
- [ ] Verify data persistence
- [ ] Check error handling
- [ ] Test with different user roles
- [ ] Verify RLS policies work
- [ ] Check loading states
- [ ] Test edge cases (empty data, network errors)

---

## Rollback Plan

If integration fails:
1. Keep mock data as fallback
2. Add feature flag: `USE_SUPABASE=true/false`
3. Implement graceful degradation
4. Log errors to console for debugging

---

## Performance Optimization

### After Integration:
1. **Add indexes** for frequently queried fields
2. **Implement pagination** for large datasets
3. **Use select()** to fetch only needed columns
4. **Cache** frequently accessed data
5. **Real-time subscriptions** for live updates (optional)

---

## Next Steps

1. ✅ Read this plan
2. 🔄 Start with Phase 1 (Authentication)
3. 🔄 Test thoroughly after each phase
4. 🔄 Move to next phase only when current is stable
5. 🔄 Document any issues encountered

---

**Ready to start? Let's begin with Phase 1: Authentication!** 🚀
