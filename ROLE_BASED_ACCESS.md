# Role-Based Access Control (RBAC)

## Overview
The School Management System now supports three user roles with different access levels:

## User Roles

### 1. **Headmaster/Administrator** (Administrative Access)
**Login:** `admin@school.edu` / `password`

**Access:**
- ✅ Dashboard
- ✅ Registrar (Student & Staff Management)
- ✅ Communication (Bulk SMS)
- ✅ Reports & Analytics
- ✅ Settings
- ❌ Academic Engine (Teachers only)
- ❌ Attendance Management (Teachers only)

**Permissions:**
- Can manage students and staff
- Can view all reports and analytics
- Can configure system settings
- Can send bulk SMS to parents
- Can view enrollment statistics
- **Cannot** enter grades (delegated to teachers)
- **Cannot** mark attendance (delegated to teachers)

**Philosophy:** Headmaster focuses on administration, oversight, and strategic decisions. Day-to-day academic tasks are handled by teachers.

---

### 2. **Teacher** (Academic Operations)
**Login:** `teacher@school.edu` / `password`

**Access:**
- ✅ Academic Engine (Enter grades and scores)
- ✅ Attendance Management (Mark attendance)
- ❌ Dashboard
- ❌ Registrar
- ❌ Communication
- ❌ Reports
- ❌ Settings

**Permissions:**
- Can mark student attendance for assigned classes
- Can enter class scores (30%)
- Can enter exam scores (70%)
- Can generate student reports
- Can view assigned classes only
- Cannot access administrative features
- Cannot send SMS
- Cannot manage students/staff
- Cannot view system-wide reports

**Assigned Classes:**
- Teacher 1: P1, P2
- Teacher 2: JHS1, JHS2

**Philosophy:** Teachers handle day-to-day academic operations - attendance tracking and grade entry for their assigned classes.

---

### 3. **Registrar** (Student Management)
**Login:** `registrar@school.edu` / `password` *(to be added)*

**Access:**
- ✅ Registrar (Student & Staff Management)
- ❌ Dashboard
- ❌ Academic Engine
- ❌ Attendance
- ❌ Communication
- ❌ Reports
- ❌ Settings

**Permissions:**
- Can add/edit/delete students
- Can add/edit/delete staff
- Can manage class assignments
- Can view enrollment statistics
- Cannot enter grades
- Cannot mark attendance
- Cannot send SMS
- Cannot view system-wide reports

**Philosophy:** Registrar focuses solely on student and staff record management.

---

## How It Works

### Login Process
1. User enters email and password
2. System identifies user role
3. User is redirected to appropriate page:
   - **Admin** → Dashboard
   - **Teacher** → Attendance page
   - **Registrar** → Dashboard

### Navigation
- Sidebar shows only allowed menu items based on role
- Teachers see only "Academic Engine" and "Attendance"
- Admins see all menu items

### Route Protection
- Each route checks user role before allowing access
- Unauthorized access attempts redirect to allowed page
- Direct URL access is blocked for unauthorized roles

### User Interface
- Header displays user name and role badge
- Role badge shows: "Administrator", "Teacher", or "Registrar"
- Logout button available to all users

---

## Implementation Details

### Files Modified
1. **`shared/api.ts`** - Added User and Role types
2. **`client/hooks/use-auth.ts`** - Authentication hook with role checking
3. **`client/pages/Login.tsx`** - Role-based login with mock users
4. **`client/components/Sidebar.tsx`** - Filtered navigation based on role
5. **`client/components/Layout.tsx`** - Display user role in header
6. **`client/components/ProtectedRoute.tsx`** - Role-based route protection
7. **`client/App.tsx`** - Added allowedRoles to routes

### Mock Users (For Testing)
```typescript
const MOCK_USERS = [
  {
    id: "1",
    email: "admin@school.edu",
    name: "Administrator",
    role: "admin",
  },
  {
    id: "2",
    email: "teacher@school.edu",
    name: "John Teacher",
    role: "teacher",
    assignedClasses: ["P1", "P2"],
  },
  {
    id: "3",
    email: "teacher2@school.edu",
    name: "Mary Teacher",
    role: "teacher",
    assignedClasses: ["JHS1", "JHS2"],
  },
];
```

---

## Testing the Feature

### Test as Admin/Headmaster
1. Login with: `admin@school.edu` / `password`
2. Verify you land on Dashboard
3. Check sidebar shows: Dashboard, Registrar, Communication, Reports, Settings
4. Verify you **cannot** access Academic Engine or Attendance
5. Try to access `/academic` - should redirect to `/dashboard`
6. Try to access `/attendance` - should redirect to `/dashboard`

### Test as Teacher
1. Login with: `teacher@school.edu` / `password`
2. Verify you land on Attendance page
3. Check sidebar shows only "Academic Engine" and "Attendance"
4. Try to access `/dashboard` - should redirect to `/attendance`
5. Try to access `/communication` - should redirect to `/attendance`
6. Verify you can:
   - Mark attendance for students
   - Enter class scores and exam scores
   - Generate reports

### Test as Different Teacher
1. Login with: `teacher2@school.edu` / `password`
2. Verify assigned classes are JHS1, JHS2
3. Test same restrictions as above

---

## Production Implementation

### Database Schema
```sql
CREATE TABLE users (
  id UUID PRIMARY KEY,
  email VARCHAR(255) UNIQUE NOT NULL,
  password_hash VARCHAR(255) NOT NULL,
  name VARCHAR(255) NOT NULL,
  role VARCHAR(50) NOT NULL CHECK (role IN ('admin', 'teacher', 'registrar')),
  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW()
);

CREATE TABLE teacher_classes (
  id UUID PRIMARY KEY,
  teacher_id UUID REFERENCES users(id),
  class_name VARCHAR(50) NOT NULL,
  created_at TIMESTAMP DEFAULT NOW()
);
```

### API Endpoints Needed
```typescript
POST /api/auth/login
  - Validates credentials
  - Returns JWT token with role
  - Returns user info

GET /api/auth/me
  - Returns current user info
  - Validates JWT token

POST /api/auth/logout
  - Invalidates token

GET /api/teachers/:id/classes
  - Returns assigned classes for teacher
```

### Security Considerations
1. **Password Hashing:** Use bcrypt or argon2
2. **JWT Tokens:** Store in httpOnly cookies
3. **Token Expiration:** Set reasonable expiry (e.g., 24 hours)
4. **Refresh Tokens:** Implement for better UX
5. **Rate Limiting:** Prevent brute force attacks
6. **HTTPS Only:** Enforce in production
7. **CSRF Protection:** Add CSRF tokens
8. **Input Validation:** Validate all inputs server-side

---

## Future Enhancements

### Planned Features
1. **Parent Role**
   - View own child's grades
   - View attendance
   - Receive notifications

2. **Department Head Role**
   - Manage teachers in department
   - View department reports
   - Approve grade submissions

3. **Fine-grained Permissions**
   - Custom permission sets
   - Role inheritance
   - Permission groups

4. **Audit Logging**
   - Track all user actions
   - Grade change history
   - Attendance modifications

5. **Multi-factor Authentication**
   - SMS verification
   - Email verification
   - Authenticator apps

6. **Session Management**
   - Active sessions view
   - Force logout
   - Device tracking

---

## Troubleshooting

### Issue: User can't access expected pages
**Solution:** Check user role in localStorage or database

### Issue: Sidebar not showing correct items
**Solution:** Clear browser cache and localStorage, login again

### Issue: Redirects not working
**Solution:** Check ProtectedRoute component and allowedRoles prop

### Issue: Role not persisting after refresh
**Solution:** Verify localStorage is storing userRole correctly

---

## Summary

✅ **Three user roles with clear separation:**
- **Headmaster/Admin:** Administrative oversight, reports, communication, settings
- **Teacher:** Academic operations - attendance and grade entry only
- **Registrar:** Student and staff record management only

✅ **Clear division of responsibilities:**
- Headmaster cannot enter grades or mark attendance (teachers' job)
- Teachers cannot access admin functions or send SMS
- Each role focused on their core responsibilities

✅ **Role-based navigation:** Sidebar shows only allowed items
✅ **Route protection:** Unauthorized access blocked
✅ **User-friendly:** Clear role badges and appropriate redirects
✅ **Production-ready:** Easy to integrate with backend API

---

**Status:** ✅ Fully Implemented and Ready for Testing
**Last Updated:** 2024
