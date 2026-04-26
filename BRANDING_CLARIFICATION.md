# Branding Clarification - EduManage vs School Names

## System Architecture

### EduManage = The Software Platform
**EduManage** is the name of the school management system software itself.
- This is the product name
- Shows in the sidebar logo area
- Shows in browser title
- Shows in footer copyright
- Consistent across all schools using the system

### School Name = Individual School Identity
Each school using EduManage has its own name:
- **MOMA** - One school using EduManage
- **Other School** - Another school using EduManage
- **Your School** - Default placeholder

---

## Where Each Name Appears

### EduManage (System Name):
✅ **Sidebar Logo Area**: "EduManage" with logo.png  
✅ **Browser Tab Title**: "EduManage - School Management System"  
✅ **Footer**: "© 2026 EduManage - School Management System"  
✅ **Meta Description**: "EduManage - School Management System..."  

### School Name (Configurable):
✅ **Report Cards**: Shows school name (e.g., "MOMA")  
✅ **Settings Page**: Admin can configure school name  
✅ **School Profile**: Stored in database `school_settings` table  
✅ **Documents**: Generated PDFs show school name  

---

## How It Works

### Multi-Tenant System:
```
EduManage Platform
    ├── MOMA School
    │   ├── Students
    │   ├── Staff
    │   └── Settings (school_name: "MOMA")
    │
    ├── Another School
    │   ├── Students
    │   ├── Staff
    │   └── Settings (school_name: "Another School")
    │
    └── Your School
        ├── Students
        ├── Staff
        └── Settings (school_name: "Your School")
```

### School Name Configuration:

**In Settings Page:**
```typescript
// Admin configures their school name
schoolName: "MOMA"
schoolAddress: "123 School Street"
schoolPhone: "+233..."
schoolEmail: "info@moma.edu.gh"
```

**In Report Cards:**
```typescript
// Uses school name from settings
const schoolName = localStorage.getItem("schoolName") || "Your School";
generateStudentReportCard(studentData, schoolName);
```

---

## Files Updated

### System Branding (EduManage):
1. ✅ `client/components/Sidebar.tsx` - Logo + "EduManage"
2. ✅ `index.html` - Title: "EduManage - School Management System"
3. ✅ `client/components/Layout.tsx` - Footer: "© 2026 EduManage"
4. ✅ `client/pages/Dashboard.tsx` - Subtitle: "Welcome back to EduManage"

### School-Specific Branding:
1. ✅ `client/pages/Academic.tsx` - Uses `schoolName` from localStorage
2. ✅ `client/pages/Settings.tsx` - Admin can set school name
3. ✅ Database: `school_settings` table stores school info

---

## For Different Schools

### MOMA School Setup:
```sql
UPDATE school_settings
SET school_name = 'MOMA',
    school_address = 'MOMA Address',
    school_phone = '+233...',
    school_email = 'info@moma.edu.gh';
```

### Another School Setup:
```sql
UPDATE school_settings
SET school_name = 'Bright Future Academy',
    school_address = 'Academy Road',
    school_phone = '+233...',
    school_email = 'info@brightfuture.edu.gh';
```

---

## User Experience

### What Users See:

**Sidebar:**
```
┌─────────────────────┐
│ [Logo] EduManage    │ ← System name (same for all)
│ School Management   │
├─────────────────────┤
│ Dashboard           │
│ Registrar           │
│ ...                 │
└─────────────────────┘
```

**Report Card Header:**
```
┌─────────────────────────────┐
│        MOMA SCHOOL          │ ← School name (different per school)
│    123 School Street        │
│    +233 50 123 4567         │
├─────────────────────────────┤
│   STUDENT REPORT CARD       │
│   ...                       │
└─────────────────────────────┘
```

**Browser Tab:**
```
[Favicon] EduManage - School Management System
```

---

## Benefits of This Approach

### For Software Provider:
✅ **Consistent Branding**: EduManage name everywhere  
✅ **Professional**: Clear product identity  
✅ **Scalable**: Can serve multiple schools  
✅ **Marketing**: Schools see "Powered by EduManage"  

### For Schools:
✅ **Own Identity**: School name on reports  
✅ **Customizable**: Can set their own details  
✅ **Professional**: Reports show their branding  
✅ **Flexible**: Each school independent  

---

## Summary

- **EduManage** = The software platform (like "Microsoft Office")
- **MOMA** = One school using it (like "ABC Company using Office")
- **Other Schools** = Other schools using it (like "XYZ Company using Office")

The system shows "EduManage" as the platform name, while each school's name appears in their specific documents and settings.

This is the standard multi-tenant SaaS model! 🎯
