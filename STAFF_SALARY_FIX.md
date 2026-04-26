# Staff Salary System - Support for Non-Login Staff

## Problem
Staff members registered through the Registrar screen (stored in the `staff` table) were not appearing in the Finance → Expenses → Staff Salaries section. The system was only loading staff from the `users` table (staff with login accounts like teachers, admins, registrars).

## Solution
Updated the ExpensesDashboard component to load staff from BOTH sources:
1. `users` table - Staff with login accounts (teachers, admins, registrars)
2. `staff` table - Staff without login accounts (registered via Registrar)

## Changes Made

### File: `client/components/finance/ExpensesDashboard.tsx`

#### 1. Updated `loadStaffList()` function
**Before:** Only loaded from `users` table
```typescript
const { data, error } = await supabase
  .from("users")
  .select("id, full_name, email, role")
  .eq("school_id", schoolId)
  .in("role", ["teacher", "admin", "registrar"])
```

**After:** Loads from BOTH tables and combines them
```typescript
// Load from users table
const { data: usersData } = await supabase
  .from("users")
  .select("id, full_name, email, role")
  ...

// Load from staff table
const { data: staffData } = await supabase
  .from("staff")
  .select("id, full_name, staff_number, position")
  ...

// Combine both lists
const combinedStaff = [...usersData, ...staffData]
```

#### 2. Updated `loadStaffSalaries()` function
**Before:** Used Supabase join to get staff details from `users` table only
```typescript
.select(`
  *,
  staff:users(full_name, email, role)
`)
```

**After:** Manually fetches staff details from BOTH tables
- First tries to find staff in `users` table
- If not found, tries `staff` table
- If not found in either, shows "Unknown"

#### 3. Updated `loadSalaryPayments()` function
**Before:** Used Supabase join to get staff details from `users` table only

**After:** Manually fetches staff details from BOTH tables (same logic as above)

## How It Works Now

### Adding a Salary:
1. Admin goes to Finance → Expenses → Staff Salaries
2. Clicks "Add Salary"
3. Staff dropdown now shows:
   - Teachers (from users table) - e.g., "Sir Isaac (teacher)"
   - Admins (from users table) - e.g., "Admin User (admin)"
   - Registrars (from users table) - e.g., "Registrar User (registrar)"
   - **Non-login staff (from staff table)** - e.g., "John Doe (Janitor)"
4. Admin selects any staff member and sets their salary

### Recording Payments:
1. All staff (both with and without login accounts) appear in the salaries list
2. Admin can record payments for any staff member
3. Payment history shows the correct staff name regardless of source table

### Staff Display:
- Staff with login accounts show their role (teacher, admin, registrar)
- Staff without login accounts show their position (from staff table)
- All staff are sorted alphabetically by name

## Database Structure

### `users` table (Staff with login accounts):
- `id` - UUID
- `full_name` - Name
- `email` - Email address
- `role` - teacher, admin, registrar
- `school_id` - School reference

### `staff` table (Staff without login accounts):
- `id` - UUID
- `full_name` - Name
- `staff_number` - e.g., MOU0001
- `position` - e.g., Janitor, Security, Cook
- `school_id` - School reference

### `staff_salaries` table:
- `staff_id` - Can reference EITHER users.id OR staff.id
- Works with both types of staff seamlessly

## Testing

### Test Case 1: Add salary for Registrar staff
1. Go to Registrar screen
2. Add a new staff member (e.g., "Jane Doe - Janitor")
3. Go to Finance → Expenses → Staff Salaries
4. Click "Add Salary"
5. ✅ Verify "Jane Doe" appears in the dropdown
6. Set salary and save
7. ✅ Verify salary appears in the table with correct name

### Test Case 2: Add salary for Teacher
1. Go to Admin → Teacher Management
2. Create a teacher account
3. Go to Finance → Expenses → Staff Salaries
4. Click "Add Salary"
5. ✅ Verify teacher appears in the dropdown
6. Set salary and save
7. ✅ Verify salary appears in the table

### Test Case 3: Record payment for both types
1. Record payment for Registrar staff
2. ✅ Verify payment appears with correct name
3. Record payment for Teacher
4. ✅ Verify payment appears with correct name

## Benefits

1. **Unified Staff Management**: All staff members (with or without login accounts) can receive salaries
2. **Flexible System**: Supports both teaching staff (who need accounts) and non-teaching staff (who don't)
3. **No Data Loss**: Existing salaries and payments continue to work
4. **Multi-Tenancy Safe**: All queries still filter by school_id

## Notes

- Staff members in the `staff` table do NOT have login accounts
- They are managed through the Registrar screen
- They can still receive salaries and have payment history
- The system automatically detects which table the staff member is from
- No database migration needed - this is a frontend-only fix

---

**Status: ✅ COMPLETE**

All staff members (both with and without login accounts) now appear in the Finance salary management system.
