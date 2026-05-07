# Staff Deletion Setup Guide

## Overview
This guide sets up proper staff deletion functionality that removes staff members from the database along with their associated user accounts and related records.

## What This Fixes
- ✅ Deletes staff records from the `staff` table
- ✅ Deletes associated user accounts from the `users` table
- ✅ Cascades to delete related records (teacher_classes, etc.)
- ✅ Provides feedback on whether user account was also deleted
- ✅ Handles errors gracefully

## Database Setup

### Step 1: Run the Migration
Execute the following SQL in your Supabase SQL Editor:

```sql
-- Copy and paste the contents of database-migrations/add-staff-deletion-function.sql
```

Or run this file directly: `database-migrations/add-staff-deletion-function.sql`

### Step 2: Verify the Function
Check that the function was created:

```sql
SELECT routine_name, routine_type
FROM information_schema.routines
WHERE routine_name = 'delete_staff_member'
AND routine_schema = 'public';
```

You should see one row returned.

### Step 3: Test the Function (Optional)
You can test with a dummy staff record:

```sql
-- Create a test staff member
INSERT INTO staff (staff_id, full_name, phone, position, email)
VALUES ('TEST001', 'Test User', '1234567890', 'Test Position', 'test@example.com')
RETURNING id;

-- Delete using the function (replace with actual ID)
SELECT delete_staff_member('YOUR-TEST-ID-HERE');

-- Verify deletion
SELECT * FROM staff WHERE staff_id = 'TEST001';
-- Should return no rows
```

## Frontend Changes
The frontend has been updated to:
1. Use the new `delete_staff_member` RPC function
2. Show appropriate success messages
3. Indicate whether a user account was also deleted
4. Handle errors properly

## How It Works

### When you delete a staff member:
1. The system checks if the staff member has an email
2. If yes, it looks for an associated user account
3. If a user account exists:
   - Deletes from `teacher_classes` table
   - Deletes from `users` table
   - (Auth user deletion requires admin privileges)
4. Deletes the staff record
5. Returns success with details

### Cascading Deletes
The function handles these related records:
- `teacher_classes` - Class assignments for teachers
- `users` - User account records
- Any other records with foreign key constraints

## Important Notes

⚠️ **Permanent Action**: Staff deletion is permanent and cannot be undone.

⚠️ **Auth Users**: Deleting from `auth.users` requires admin privileges. The function handles `users` table deletion, but auth user cleanup may need to be done separately or through Supabase dashboard.

⚠️ **Multi-tenancy**: The function respects school_id constraints through existing RLS policies.

## Testing

After setup, test the deletion:
1. Go to Registrar page
2. Find a test staff member
3. Click the delete button (trash icon)
4. Confirm the deletion
5. Verify the staff member is removed from the list
6. Check the database to confirm deletion

## Troubleshooting

### Error: "function delete_staff_member does not exist"
- Run the migration SQL again
- Check that you're connected to the correct database
- Verify the function exists with the verification query above

### Error: "permission denied"
- Ensure the GRANT statement was executed
- Check your RLS policies on the staff table
- Verify you're logged in as an admin user

### Staff deleted but user account remains
- This is expected if the staff member had no email
- Or if the email doesn't match any user account
- Check the success message for details

## Rollback (if needed)

To remove the function:

```sql
DROP FUNCTION IF EXISTS delete_staff_member(UUID);
```

## Next Steps

After successful setup:
1. Test with a non-critical staff member
2. Verify all related records are cleaned up
3. Document any staff members that need special handling
4. Consider adding an "archive" feature instead of hard delete for important records
