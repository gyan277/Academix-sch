# Design Document: Admin Teacher Management

## Overview

The Admin Teacher Management feature provides a comprehensive interface for administrators to create, manage, and control teacher accounts within the MOMA school management system. This feature is integrated into the Settings page as a new "Teachers" tab, accessible only to users with the admin role.

### Key Capabilities

- **Teacher Account Creation**: Create new teacher accounts with authentication credentials via Supabase Auth
- **Profile Management**: Edit teacher information including name, phone, and class assignments
- **Class Assignment**: Assign and manage which classes each teacher can access
- **Account Status Control**: Activate or deactivate teacher accounts to control system access
- **Password Management**: Reset teacher passwords and provide temporary credentials
- **Teacher List View**: Display all teachers with their current status and assignments

### Design Goals

1. **Security First**: Ensure only admins can access teacher management functionality
2. **User-Friendly**: Provide clear feedback and intuitive workflows for all operations
3. **Data Integrity**: Maintain referential integrity between authentication, user profiles, and class assignments
4. **Seamless Integration**: Follow existing UI patterns and integrate smoothly with the Settings page
5. **Error Resilience**: Handle errors gracefully with clear user feedback

## Architecture

### Component Hierarchy

```
Settings Page (client/pages/Settings.tsx)
└── Tabs Component
    ├── Profile Tab (existing)
    ├── Terms Tab (existing)
    ├── Grades Tab (existing)
    ├── Calendar Tab (existing)
    └── Teachers Tab (NEW)
        ├── TeacherManagementInterface
        │   ├── CreateTeacherForm
        │   │   ├── Input fields (email, name, phone, password)
        │   │   ├── ClassSelector (multi-select)
        │   │   └── SubmitButton
        │   ├── TeacherList
        │   │   └── TeacherCard[] (for each teacher)
        │   │       ├── TeacherInfo (name, email, phone, status)
        │   │       ├── ClassBadges (assigned classes)
        │   │       └── ActionButtons (edit, toggle status, reset password)
        │   ├── EditTeacherDialog
        │   │   ├── Input fields (name, phone)
        │   │   ├── ClassSelector (multi-select)
        │   │   └── SaveButton
        │   └── CredentialsDialog
        │       ├── Email display
        │       ├── Password display
        │       ├── CopyButton
        │       └── Warning message
        └── Toast notifications (success/error feedback)
```

### Data Flow

#### Teacher Creation Flow
```
1. Admin fills CreateTeacherForm
2. Form validation (client-side)
3. Submit → Supabase Auth API (create user)
4. On success → Create user profile in users table
5. If classes selected → Create records in teacher_classes table
6. Display CredentialsDialog with email/password
7. Refresh TeacherList
8. Show success toast
```

#### Teacher Edit Flow
```
1. Admin clicks edit on TeacherCard
2. Open EditTeacherDialog with current data
3. Admin modifies fields
4. Submit → Update users table
5. Compare class assignments → Update teacher_classes table
6. Close dialog
7. Refresh TeacherList
8. Show success toast
```

#### Status Toggle Flow
```
1. Admin clicks status toggle on TeacherCard
2. Confirm action (optional)
3. Update users table (status field)
4. Refresh TeacherList
5. Show success toast
```

#### Password Reset Flow
```
1. Admin clicks reset password on TeacherCard
2. Generate new temporary password
3. Update Supabase Auth password
4. Display CredentialsDialog with new password
5. Show success toast
```

### Technology Stack Integration

- **Frontend**: React 18 + TypeScript + TailwindCSS
- **UI Components**: Radix UI (Dialog, Tabs, Input, Button, Card, Badge, Toast)
- **State Management**: React useState hooks (local component state)
- **Authentication**: Supabase Auth API
- **Database**: Supabase PostgreSQL (users, teacher_classes tables)
- **Routing**: React Router 6 (Settings page route)
- **Icons**: Lucide React

## Components and Interfaces

### 1. TeacherManagementInterface Component

**Location**: `client/components/TeacherManagement.tsx` (new file)

**Purpose**: Main container component for all teacher management functionality

**Props**:
```typescript
interface TeacherManagementInterfaceProps {
  // No props needed - uses useAuth hook for admin verification
}
```

**State**:
```typescript
const [teachers, setTeachers] = useState<TeacherProfile[]>([]);
const [loading, setLoading] = useState(true);
const [isCreateDialogOpen, setIsCreateDialogOpen] = useState(false);
const [editingTeacher, setEditingTeacher] = useState<TeacherProfile | null>(null);
const [credentialsToShow, setCredentialsToShow] = useState<{ email: string; password: string } | null>(null);
```

**Key Methods**:
- `loadTeachers()`: Fetch all teachers from database
- `handleCreateTeacher(data: CreateTeacherData)`: Create new teacher account
- `handleEditTeacher(id: string, data: EditTeacherData)`: Update teacher profile
- `handleToggleStatus(id: string, currentStatus: string)`: Activate/deactivate account
- `handleResetPassword(id: string)`: Generate and set new password

### 2. CreateTeacherForm Component

**Location**: `client/components/TeacherManagement.tsx` (sub-component)

**Purpose**: Form for creating new teacher accounts

**Props**:
```typescript
interface CreateTeacherFormProps {
  onSubmit: (data: CreateTeacherData) => Promise<void>;
  onCancel: () => void;
  availableClasses: string[];
}
```

**Form Data**:
```typescript
interface CreateTeacherData {
  email: string;
  full_name: string;
  phone: string;
  password: string;
  classes: string[]; // Optional class assignments
}
```

**Validation Rules**:
- `email`: Required, valid email format
- `full_name`: Required, minimum 2 characters
- `phone`: Optional, valid phone format (digits, spaces, parentheses, hyphens, plus signs)
- `password`: Required, minimum 8 characters
- `classes`: Optional, array of class names

### 3. TeacherList Component

**Location**: `client/components/TeacherManagement.tsx` (sub-component)

**Purpose**: Display list of all teachers with their information

**Props**:
```typescript
interface TeacherListProps {
  teachers: TeacherProfile[];
  onEdit: (teacher: TeacherProfile) => void;
  onToggleStatus: (id: string, currentStatus: string) => void;
  onResetPassword: (id: string) => void;
  loading: boolean;
}
```

**Display Fields per Teacher**:
- Full name
- Email address
- Phone number
- Account status (active/inactive badge)
- Assigned classes (badge list)
- Action buttons (edit, toggle status, reset password)

### 4. EditTeacherDialog Component

**Location**: `client/components/TeacherManagement.tsx` (sub-component)

**Purpose**: Dialog for editing existing teacher information

**Props**:
```typescript
interface EditTeacherDialogProps {
  teacher: TeacherProfile | null;
  isOpen: boolean;
  onClose: () => void;
  onSave: (id: string, data: EditTeacherData) => Promise<void>;
  availableClasses: string[];
}
```

**Editable Fields**:
```typescript
interface EditTeacherData {
  full_name: string;
  phone: string;
  classes: string[];
}
```

**Note**: Email is NOT editable (displayed as read-only)

### 5. CredentialsDialog Component

**Location**: `client/components/TeacherManagement.tsx` (sub-component)

**Purpose**: Display teacher credentials after creation or password reset

**Props**:
```typescript
interface CredentialsDialogProps {
  credentials: { email: string; password: string } | null;
  isOpen: boolean;
  onClose: () => void;
}
```

**Features**:
- Display email and password
- Copy to clipboard button
- Security warning message
- Cannot be reopened after closing

### Type Definitions

**Location**: `shared/types.ts` (additions)

```typescript
export interface TeacherProfile {
  id: string;
  email: string;
  full_name: string;
  role: 'teacher';
  phone: string | null;
  status: 'active' | 'inactive';
  created_at: string;
  updated_at: string;
  assigned_classes: string[]; // Populated from teacher_classes join
}

export interface CreateTeacherRequest {
  email: string;
  full_name: string;
  phone: string;
  password: string;
  classes?: string[];
}

export interface CreateTeacherResponse {
  success: boolean;
  teacher?: TeacherProfile;
  credentials?: {
    email: string;
    password: string;
  };
  error?: string;
}

export interface UpdateTeacherRequest {
  full_name: string;
  phone: string;
  classes: string[];
}

export interface UpdateTeacherResponse {
  success: boolean;
  teacher?: TeacherProfile;
  error?: string;
}

export interface ResetPasswordResponse {
  success: boolean;
  credentials?: {
    email: string;
    password: string;
  };
  error?: string;
}
```

## Data Models

### Database Tables

#### users Table (existing, no changes needed)

```sql
CREATE TABLE public.users (
  id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  email TEXT UNIQUE NOT NULL,
  full_name TEXT NOT NULL,
  role TEXT NOT NULL CHECK (role IN ('admin', 'teacher', 'registrar')),
  phone TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);
```

**Note**: The existing schema does NOT have a `status` field. We need to add it:

```sql
ALTER TABLE public.users 
ADD COLUMN IF NOT EXISTS status TEXT NOT NULL DEFAULT 'active' 
CHECK (status IN ('active', 'inactive'));
```

#### teacher_classes Table (existing, no changes needed)

```sql
CREATE TABLE public.teacher_classes (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  teacher_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
  class TEXT NOT NULL,
  subject_id UUID REFERENCES public.subjects(id) ON DELETE CASCADE,
  academic_year TEXT NOT NULL,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(teacher_id, class, subject_id, academic_year)
);
```

**Note**: For this feature, we'll use simplified class assignments without subject_id and academic_year requirements. We'll need to modify the UNIQUE constraint or handle it in the application logic.

### Data Relationships

```
auth.users (Supabase Auth)
    ↓ (1:1)
public.users (User Profiles)
    ↓ (1:N)
public.teacher_classes (Class Assignments)
```

### Query Patterns

#### Fetch All Teachers with Classes
```typescript
const { data: teachers, error } = await supabase
  .from('users')
  .select(`
    *,
    teacher_classes (
      class
    )
  `)
  .eq('role', 'teacher')
  .order('full_name', { ascending: true });
```

#### Create Teacher Profile
```typescript
// Step 1: Create auth user
const { data: authData, error: authError } = await supabase.auth.admin.createUser({
  email: email,
  password: password,
  email_confirm: true,
  user_metadata: {
    full_name: full_name,
    role: 'teacher',
    phone: phone
  }
});

// Step 2: Profile is auto-created by trigger, but we can update it
const { data: userData, error: userError } = await supabase
  .from('users')
  .update({ phone: phone })
  .eq('id', authData.user.id)
  .select()
  .single();

// Step 3: Create class assignments
if (classes && classes.length > 0) {
  const classRecords = classes.map(className => ({
    teacher_id: authData.user.id,
    class: className,
    academic_year: currentAcademicYear
  }));
  
  await supabase
    .from('teacher_classes')
    .insert(classRecords);
}
```

#### Update Teacher Profile
```typescript
// Update user profile
const { error: updateError } = await supabase
  .from('users')
  .update({
    full_name: full_name,
    phone: phone
  })
  .eq('id', teacherId);

// Update class assignments (delete old, insert new)
await supabase
  .from('teacher_classes')
  .delete()
  .eq('teacher_id', teacherId);

if (classes && classes.length > 0) {
  const classRecords = classes.map(className => ({
    teacher_id: teacherId,
    class: className,
    academic_year: currentAcademicYear
  }));
  
  await supabase
    .from('teacher_classes')
    .insert(classRecords);
}
```

#### Toggle Teacher Status
```typescript
const { error } = await supabase
  .from('users')
  .update({ status: newStatus })
  .eq('id', teacherId);
```

#### Reset Password
```typescript
const newPassword = generateSecurePassword(); // Utility function

const { error } = await supabase.auth.admin.updateUserById(
  teacherId,
  { password: newPassword }
);
```

### Available Classes

Classes will be fetched from the existing students table:

```typescript
const { data: classData } = await supabase
  .from('students')
  .select('class')
  .eq('status', 'active');

const uniqueClasses = [...new Set(classData.map(s => s.class))].sort();
```



## Error Handling

### Error Categories

#### 1. Validation Errors (Client-Side)

**Trigger**: User input fails validation rules before submission

**Handling Strategy**:
- Display inline error messages below each invalid field
- Prevent form submission until all fields are valid
- Use red text and border colors to indicate errors
- Clear errors when user corrects the input

**Example Validation Errors**:
```typescript
{
  email: "Please enter a valid email address",
  full_name: "Name must be at least 2 characters",
  password: "Password must be at least 8 characters",
  phone: "Please enter a valid phone number"
}
```

#### 2. Authentication Errors (Supabase Auth)

**Trigger**: Supabase Auth API returns an error during user creation or password reset

**Common Errors**:
- Email already exists
- Invalid email format
- Weak password
- Rate limit exceeded
- Network timeout

**Handling Strategy**:
```typescript
try {
  const { data, error } = await supabase.auth.admin.createUser({...});
  
  if (error) {
    // Map Supabase error codes to user-friendly messages
    const errorMessage = mapAuthError(error.message);
    toast({
      title: "Failed to Create Teacher",
      description: errorMessage,
      variant: "destructive"
    });
    return;
  }
} catch (err) {
  console.error("Auth error:", err);
  toast({
    title: "Connection Error",
    description: "Unable to connect to authentication service. Please try again.",
    variant: "destructive"
  });
}
```

**Error Mapping Function**:
```typescript
function mapAuthError(errorMessage: string): string {
  if (errorMessage.includes("already registered")) {
    return "This email address is already registered in the system.";
  }
  if (errorMessage.includes("invalid email")) {
    return "Please provide a valid email address.";
  }
  if (errorMessage.includes("password")) {
    return "Password must be at least 8 characters long.";
  }
  if (errorMessage.includes("rate limit")) {
    return "Too many requests. Please wait a moment and try again.";
  }
  return "An error occurred during authentication. Please try again.";
}
```

#### 3. Database Errors (Supabase Database)

**Trigger**: Database operations fail (insert, update, delete, select)

**Common Errors**:
- Foreign key constraint violation
- Unique constraint violation
- Permission denied (RLS policy)
- Connection timeout
- Invalid data type

**Handling Strategy**:
```typescript
try {
  const { data, error } = await supabase
    .from('users')
    .update({...})
    .eq('id', teacherId);
  
  if (error) {
    console.error("Database error:", error);
    
    if (error.code === '23505') { // Unique violation
      toast({
        title: "Duplicate Entry",
        description: "This information already exists in the system.",
        variant: "destructive"
      });
    } else if (error.code === '23503') { // Foreign key violation
      toast({
        title: "Invalid Reference",
        description: "Unable to complete operation due to data dependencies.",
        variant: "destructive"
      });
    } else {
      toast({
        title: "Database Error",
        description: "Unable to save changes. Please try again.",
        variant: "destructive"
      });
    }
    return;
  }
} catch (err) {
  console.error("Unexpected database error:", err);
  toast({
    title: "Connection Error",
    description: "Unable to connect to database. Please check your connection.",
    variant: "destructive"
  });
}
```

#### 4. Network Errors

**Trigger**: Network request fails or times out

**Handling Strategy**:
```typescript
try {
  // Set a timeout for the operation
  const timeoutPromise = new Promise((_, reject) => 
    setTimeout(() => reject(new Error('timeout')), 10000)
  );
  
  const operationPromise = performDatabaseOperation();
  
  await Promise.race([operationPromise, timeoutPromise]);
  
} catch (err) {
  if (err.message === 'timeout') {
    toast({
      title: "Request Timeout",
      description: "The operation took too long. Please try again.",
      variant: "destructive"
    });
  } else if (!navigator.onLine) {
    toast({
      title: "No Internet Connection",
      description: "Please check your internet connection and try again.",
      variant: "destructive"
    });
  } else {
    toast({
      title: "Network Error",
      description: "Unable to complete request. Please try again.",
      variant: "destructive"
    });
  }
}
```

#### 5. Permission Errors

**Trigger**: Non-admin user attempts to access teacher management features

**Handling Strategy**:
- Prevent rendering of Teachers tab for non-admin users
- Server-side validation via RLS policies
- Redirect to appropriate page if direct URL access attempted

```typescript
// In Settings.tsx
const { profile } = useAuth();

if (!profile || profile.role !== 'admin') {
  return <Navigate to="/dashboard" replace />;
}

// In TeacherManagementInterface
useEffect(() => {
  if (profile?.role !== 'admin') {
    toast({
      title: "Access Denied",
      description: "You do not have permission to access this feature.",
      variant: "destructive"
    });
    navigate('/dashboard');
  }
}, [profile]);
```

### Error Logging

All errors should be logged to the browser console for debugging:

```typescript
function logError(context: string, error: any) {
  console.error(`[TeacherManagement] ${context}:`, {
    message: error.message,
    code: error.code,
    details: error.details,
    timestamp: new Date().toISOString()
  });
}
```

### User Feedback Patterns

#### Success Messages
```typescript
toast({
  title: "Teacher Created",
  description: `${teacherName} has been added successfully.`,
});
```

#### Error Messages
```typescript
toast({
  title: "Operation Failed",
  description: "Specific error message here",
  variant: "destructive"
});
```

#### Loading States
```typescript
// Show loading spinner during async operations
{loading && <Spinner />}
{!loading && <TeacherList teachers={teachers} />}
```

## Testing Strategy

### Overview

This feature involves UI interactions, external service integration (Supabase Auth), and database operations. Property-based testing is **NOT appropriate** for this feature because:

1. **External Service Dependencies**: Testing Supabase Auth behavior (already tested by Supabase)
2. **UI Rendering and Interactions**: Form submissions, dialogs, button clicks
3. **Database Operations**: CRUD operations with specific business logic
4. **Side Effects**: Creating auth users, sending emails, updating multiple tables

Instead, we will use:
- **Unit Tests**: Test individual functions and validation logic
- **Integration Tests**: Test component interactions with mocked Supabase
- **Manual Testing**: Test end-to-end workflows in development environment

### Unit Tests

**Location**: `client/components/TeacherManagement.spec.tsx`

**Test Cases**:

1. **Validation Functions**
   - Test email validation with valid and invalid emails
   - Test name validation with various lengths
   - Test phone validation with different formats
   - Test password strength validation

2. **Error Mapping**
   - Test `mapAuthError()` with different Supabase error messages
   - Verify user-friendly messages are returned

3. **Data Transformation**
   - Test teacher data formatting for display
   - Test class assignment data structure conversion

4. **Password Generation**
   - Test `generateSecurePassword()` produces valid passwords
   - Verify password meets minimum requirements

**Example Test**:
```typescript
describe('TeacherManagement Validation', () => {
  it('should validate email format correctly', () => {
    expect(validateEmail('test@example.com')).toBe(true);
    expect(validateEmail('invalid-email')).toBe(false);
    expect(validateEmail('')).toBe(false);
  });

  it('should validate name length', () => {
    expect(validateName('John Doe')).toBe(true);
    expect(validateName('A')).toBe(false);
    expect(validateName('')).toBe(false);
  });

  it('should validate password strength', () => {
    expect(validatePassword('password123')).toBe(true);
    expect(validatePassword('short')).toBe(false);
    expect(validatePassword('')).toBe(false);
  });
});
```

### Integration Tests

**Location**: `client/components/TeacherManagement.integration.spec.tsx`

**Setup**: Mock Supabase client and auth methods

**Test Cases**:

1. **Teacher Creation Flow**
   - Render CreateTeacherForm
   - Fill in all fields
   - Submit form
   - Verify Supabase Auth API called with correct data
   - Verify user profile created in database
   - Verify class assignments created
   - Verify success toast displayed
   - Verify credentials dialog shown

2. **Teacher List Display**
   - Mock teacher data from database
   - Render TeacherList component
   - Verify all teachers displayed
   - Verify correct information shown for each teacher
   - Verify assigned classes displayed as badges

3. **Teacher Edit Flow**
   - Render TeacherList with mock data
   - Click edit button on a teacher
   - Verify EditTeacherDialog opens with current data
   - Modify fields
   - Submit changes
   - Verify database update called
   - Verify success toast displayed
   - Verify teacher list refreshed

4. **Status Toggle**
   - Render TeacherList with mock data
   - Click status toggle button
   - Verify database update called with new status
   - Verify teacher list refreshed
   - Verify success toast displayed

5. **Password Reset**
   - Render TeacherList with mock data
   - Click reset password button
   - Verify Supabase Auth API called
   - Verify credentials dialog shown with new password
   - Verify success toast displayed

6. **Error Handling**
   - Mock Supabase errors (duplicate email, network error)
   - Attempt teacher creation
   - Verify error toast displayed with appropriate message
   - Verify form remains open for correction

**Example Test**:
```typescript
describe('TeacherManagement Integration', () => {
  beforeEach(() => {
    // Mock Supabase client
    vi.mock('@/lib/supabase', () => ({
      supabase: {
        auth: {
          admin: {
            createUser: vi.fn(),
            updateUserById: vi.fn()
          }
        },
        from: vi.fn(() => ({
          select: vi.fn().mockReturnThis(),
          insert: vi.fn().mockReturnThis(),
          update: vi.fn().mockReturnThis(),
          delete: vi.fn().mockReturnThis(),
          eq: vi.fn().mockReturnThis(),
          order: vi.fn().mockReturnThis(),
          single: vi.fn()
        }))
      }
    }));
  });

  it('should create teacher successfully', async () => {
    const mockCreateUser = vi.fn().mockResolvedValue({
      data: { user: { id: '123', email: 'teacher@test.com' } },
      error: null
    });
    
    supabase.auth.admin.createUser = mockCreateUser;

    render(<TeacherManagementInterface />);
    
    // Fill form
    fireEvent.change(screen.getByLabelText('Email'), {
      target: { value: 'teacher@test.com' }
    });
    fireEvent.change(screen.getByLabelText('Full Name'), {
      target: { value: 'John Doe' }
    });
    fireEvent.change(screen.getByLabelText('Password'), {
      target: { value: 'password123' }
    });
    
    // Submit
    fireEvent.click(screen.getByText('Create Teacher'));
    
    // Verify
    await waitFor(() => {
      expect(mockCreateUser).toHaveBeenCalledWith({
        email: 'teacher@test.com',
        password: 'password123',
        email_confirm: true,
        user_metadata: expect.objectContaining({
          full_name: 'John Doe',
          role: 'teacher'
        })
      });
    });
    
    expect(screen.getByText('Teacher Created')).toBeInTheDocument();
  });
});
```

### Manual Testing Checklist

**Environment**: Development with real Supabase instance

**Test Scenarios**:

1. **Admin Access Control**
   - [ ] Login as admin user
   - [ ] Navigate to Settings page
   - [ ] Verify Teachers tab is visible
   - [ ] Login as teacher user
   - [ ] Navigate to Settings page
   - [ ] Verify Teachers tab is NOT visible
   - [ ] Login as registrar user
   - [ ] Navigate to Settings page
   - [ ] Verify Teachers tab is NOT visible

2. **Teacher Creation - Happy Path**
   - [ ] Click "Add New Teacher" button
   - [ ] Fill in all required fields with valid data
   - [ ] Select 2-3 classes
   - [ ] Submit form
   - [ ] Verify success toast appears
   - [ ] Verify credentials dialog shows email and password
   - [ ] Copy credentials to clipboard
   - [ ] Close dialog
   - [ ] Verify new teacher appears in list
   - [ ] Verify assigned classes shown as badges

3. **Teacher Creation - Validation Errors**
   - [ ] Try to submit with empty email → See error
   - [ ] Try to submit with invalid email → See error
   - [ ] Try to submit with name < 2 chars → See error
   - [ ] Try to submit with password < 8 chars → See error
   - [ ] Try to submit with invalid phone → See error

4. **Teacher Creation - Duplicate Email**
   - [ ] Create teacher with email "test@example.com"
   - [ ] Try to create another teacher with same email
   - [ ] Verify error toast: "Email already registered"

5. **Teacher List Display**
   - [ ] Verify all teachers displayed
   - [ ] Verify sorted alphabetically by name
   - [ ] Verify each teacher shows: name, email, phone, status, classes
   - [ ] Verify active status shown as green badge
   - [ ] Verify inactive status shown as gray badge

6. **Teacher Edit - Happy Path**
   - [ ] Click edit button on a teacher
   - [ ] Verify dialog opens with current data
   - [ ] Change name
   - [ ] Change phone
   - [ ] Add/remove classes
   - [ ] Save changes
   - [ ] Verify success toast
   - [ ] Verify teacher list updated with new data

7. **Teacher Edit - Email Not Editable**
   - [ ] Open edit dialog
   - [ ] Verify email field is read-only or not present

8. **Status Toggle - Deactivate**
   - [ ] Find active teacher
   - [ ] Click status toggle
   - [ ] Verify status changes to inactive (gray badge)
   - [ ] Verify success toast
   - [ ] Logout
   - [ ] Try to login as that teacher
   - [ ] Verify login fails or access denied

9. **Status Toggle - Activate**
   - [ ] Find inactive teacher
   - [ ] Click status toggle
   - [ ] Verify status changes to active (green badge)
   - [ ] Verify success toast
   - [ ] Logout
   - [ ] Login as that teacher
   - [ ] Verify login succeeds

10. **Password Reset**
    - [ ] Click reset password on a teacher
    - [ ] Verify credentials dialog shows new password
    - [ ] Copy new password
    - [ ] Close dialog
    - [ ] Logout
    - [ ] Login as that teacher with new password
    - [ ] Verify login succeeds

11. **Network Error Handling**
    - [ ] Disconnect internet
    - [ ] Try to create teacher
    - [ ] Verify error toast: "Connection error"
    - [ ] Reconnect internet
    - [ ] Retry operation
    - [ ] Verify success

12. **Responsive Design**
    - [ ] Test on desktop (1920x1080)
    - [ ] Test on tablet (768x1024)
    - [ ] Test on mobile (375x667)
    - [ ] Verify all elements visible and usable
    - [ ] Verify dialogs fit on screen
    - [ ] Verify forms are scrollable if needed

### Test Data

**Sample Teachers for Testing**:
```typescript
const testTeachers = [
  {
    email: 'john.doe@school.com',
    full_name: 'John Doe',
    phone: '+233 501 234 567',
    password: 'password123',
    classes: ['Class 1A', 'Class 1B']
  },
  {
    email: 'jane.smith@school.com',
    full_name: 'Jane Smith',
    phone: '+233 501 234 568',
    password: 'password123',
    classes: ['Class 2A']
  },
  {
    email: 'bob.wilson@school.com',
    full_name: 'Bob Wilson',
    phone: '+233 501 234 569',
    password: 'password123',
    classes: []
  }
];
```

### Performance Testing

**Scenarios**:
1. Load teacher list with 100+ teachers
2. Verify list renders in < 2 seconds
3. Verify search/filter (if implemented) responds in < 500ms
4. Verify form submission completes in < 3 seconds

### Security Testing

**Scenarios**:
1. Verify non-admin cannot access Teachers tab (UI hidden)
2. Verify non-admin cannot call teacher management APIs (RLS blocks)
3. Verify passwords are never logged to console
4. Verify credentials dialog cannot be reopened after closing
5. Verify teacher cannot edit their own role to admin

## Implementation Notes

### Phase 1: Database Schema Updates

1. Add `status` column to `users` table:
```sql
ALTER TABLE public.users 
ADD COLUMN IF NOT EXISTS status TEXT NOT NULL DEFAULT 'active' 
CHECK (status IN ('active', 'inactive'));
```

2. Update RLS policies to check status on login (optional, handled by application logic)

### Phase 2: Shared Types

1. Add new types to `shared/types.ts`:
   - `TeacherProfile`
   - `CreateTeacherRequest`
   - `CreateTeacherResponse`
   - `UpdateTeacherRequest`
   - `UpdateTeacherResponse`
   - `ResetPasswordResponse`

### Phase 3: UI Components

1. Create `client/components/TeacherManagement.tsx`
2. Implement all sub-components:
   - `TeacherManagementInterface`
   - `CreateTeacherForm`
   - `TeacherList`
   - `TeacherCard`
   - `EditTeacherDialog`
   - `CredentialsDialog`

### Phase 4: Settings Page Integration

1. Update `client/pages/Settings.tsx`:
   - Add "Teachers" tab to TabsList
   - Add TabsContent for Teachers
   - Import and render TeacherManagementInterface
   - Add role check to show/hide tab

### Phase 5: Utility Functions

1. Create `client/lib/teacher-utils.ts`:
   - `validateEmail(email: string): boolean`
   - `validateName(name: string): boolean`
   - `validatePhone(phone: string): boolean`
   - `validatePassword(password: string): boolean`
   - `generateSecurePassword(): string`
   - `mapAuthError(error: string): string`

### Phase 6: Testing

1. Write unit tests for validation functions
2. Write integration tests for components
3. Perform manual testing with checklist
4. Fix bugs and refine UX

### Phase 7: Documentation

1. Update user documentation
2. Add inline code comments
3. Document API patterns for future features

## Security Considerations

### Authentication & Authorization

1. **Admin-Only Access**: Teachers tab only visible to admin role
2. **RLS Policies**: Database enforces admin-only writes to users table
3. **Client-Side Checks**: useAuth hook verifies admin role before rendering
4. **Server-Side Validation**: Supabase RLS policies provide final security layer

### Password Management

1. **Minimum Length**: 8 characters enforced
2. **Secure Generation**: Use crypto.getRandomValues() for password generation
3. **No Storage**: Passwords never stored in application state after display
4. **One-Time Display**: Credentials dialog cannot be reopened
5. **HTTPS Only**: All communication over encrypted connection

### Data Protection

1. **Input Sanitization**: All user inputs validated and sanitized
2. **SQL Injection Prevention**: Supabase client uses parameterized queries
3. **XSS Prevention**: React automatically escapes rendered content
4. **CSRF Protection**: Supabase handles CSRF tokens

### Audit Trail

1. **Created/Updated Timestamps**: Automatically tracked in database
2. **Console Logging**: All operations logged for debugging
3. **Error Tracking**: All errors logged with context

## Future Enhancements

### Phase 2 Features (Not in Current Scope)

1. **Bulk Operations**
   - Import teachers from CSV
   - Bulk status updates
   - Bulk class assignments

2. **Advanced Search & Filtering**
   - Search by name, email, or phone
   - Filter by status (active/inactive)
   - Filter by assigned classes

3. **Teacher Activity Tracking**
   - Last login timestamp
   - Number of students graded
   - Attendance records marked

4. **Email Notifications**
   - Send credentials via email instead of manual copy
   - Password reset email links
   - Account status change notifications

5. **Role-Based Permissions**
   - Allow teachers to update their own profile
   - Allow teachers to change their own password
   - Restrict admin-only fields

6. **Audit Log**
   - Track all teacher management operations
   - Display who created/modified each teacher
   - Show history of status changes

7. **Teacher Dashboard**
   - Separate view for teachers to see their assignments
   - Quick access to assigned classes
   - Personal profile management

## Conclusion

This design provides a comprehensive, secure, and user-friendly interface for administrators to manage teacher accounts in the MOMA school management system. The implementation follows React best practices, integrates seamlessly with existing Supabase infrastructure, and maintains consistency with the current UI design patterns.

The feature prioritizes security through role-based access control, proper error handling, and secure password management. The testing strategy ensures reliability through unit tests, integration tests, and thorough manual testing procedures.

Future enhancements can build upon this foundation to add more advanced features like bulk operations, email notifications, and detailed audit logging.
