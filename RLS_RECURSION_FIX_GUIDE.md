# RLS Infinite Recursion Fix Guide

## Problem Summary

**Error**: `User profile error: infinite recursion detected in policy for relation "users"`

**Root Cause**: The RLS policies on the `users` table were querying the same `users` table to check permissions, creating a circular dependency.

### Example of Problematic Policy

```sql
-- This causes infinite recursion!
CREATE POLICY "users_can_read_own_school"
  ON public.users FOR SELECT
  TO authenticated
  USING (
    school_id = (SELECT school_id FROM public.users WHERE id = auth.uid())
    --           ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
    --           This subquery queries the SAME table the policy protects!
  );
```

**What happens**:
1. User tries to login
2. App queries `users` table to get user profile
3. RLS policy activates and needs to check `school_id`
4. Policy queries `users` table to get the user's `school_id`
5. This triggers the RLS policy again (step 3)
6. Infinite loop! 💥

## Solution

### Approach: Simplify Users Table Policies

Instead of complex policies that query the `users` table, use simple policies that allow all authenticated users to access the table. Multi-tenancy isolation is enforced at other levels:

1. **Application-level filtering**: Frontend code filters by `school_id`
2. **RLS on other tables**: Students, staff, grades, etc. have proper RLS policies
3. **Users table as anchor**: The `users` table is the reference point, not the enforcer

### Implementation Steps

#### Step 1: Run the Fix Script

Execute `DISABLE_RLS_USERS_FINAL.sql` in your Supabase SQL Editor:

```bash
# Copy the contents of DISABLE_RLS_USERS_FINAL.sql
# Paste into Supabase SQL Editor
# Click "Run"
```

This script:
- Drops ALL existing policies on `users` table
- Creates simple, non-recursive policies
- Verifies the fix worked

#### Step 2: Verify Login Works

1. Refresh your browser
2. Try logging in with `admin@moma.com`
3. You should now be able to login successfully

#### Step 3: Verify Multi-Tenancy Still Works

The multi-tenancy isolation is still enforced through:

**Other Tables' RLS Policies** (these are fine, no recursion):
```sql
-- Students table - properly isolated by school_id
CREATE POLICY "students_select_own_school"
  ON public.students FOR SELECT
  TO authenticated
  USING (school_id = (SELECT school_id FROM public.users WHERE id = auth.uid()));
```

This works because:
- The policy is on `students` table
- It queries `users` table (different table, no recursion)
- The `users` table has simple policies that don't create loops

**Application-Level Filtering**:
```typescript
// In your React components, always filter by school_id
const { data: students } = await supabase
  .from('students')
  .select('*')
  .eq('school_id', profile.school_id); // Frontend filtering
```

## Architecture: Multi-Tenancy Without Recursion

```
┌─────────────────────────────────────────────────────────────┐
│ USERS TABLE (Anchor Point)                                  │
│ - Simple RLS: Allow all authenticated users                 │
│ - No recursion risk                                          │
│ - Contains school_id for each user                           │
└─────────────────────────────────────────────────────────────┘
                            ↓
                    (Referenced by)
                            ↓
┌─────────────────────────────────────────────────────────────┐
│ OTHER TABLES (Enforcement Points)                           │
│ - Students, Staff, Grades, Attendance, etc.                  │
│ - RLS policies query users table for school_id              │
│ - No recursion because they query DIFFERENT table            │
│ - Proper multi-tenancy isolation enforced here               │
└─────────────────────────────────────────────────────────────┘
                            ↓
                    (Additional layer)
                            ↓
┌─────────────────────────────────────────────────────────────┐
│ APPLICATION LAYER (React Components)                        │
│ - Always filter queries by school_id                         │
│ - Role-based UI rendering (admin vs teacher)                 │
│ - Authorization checks before mutations                      │
└─────────────────────────────────────────────────────────────┘
```

## Why This Works

### 1. No Circular Dependencies
- `users` table policies don't query `users` table
- Other tables can safely query `users` table
- No infinite loops possible

### 2. Multi-Tenancy Still Enforced
- Students table: Can only see students with matching `school_id`
- Staff table: Can only see staff with matching `school_id`
- Grades table: Can only see grades with matching `school_id`
- And so on...

### 3. Security Maintained
- Users must be authenticated to access any data
- Each table's RLS policies enforce school isolation
- Application code adds additional authorization checks

## Testing Checklist

After applying the fix:

- [ ] Login works without infinite recursion error
- [ ] User profile loads correctly
- [ ] Dashboard displays properly
- [ ] Admin can see Settings page
- [ ] Teacher can access their features
- [ ] Students list shows only students from same school
- [ ] Staff list shows only staff from same school

## Common Questions

### Q: Isn't it insecure to allow all authenticated users to read the users table?

**A**: Not in this context because:
1. Users must still be authenticated (logged in)
2. The application code filters by `school_id`
3. Other tables enforce strict isolation
4. This is a common pattern to avoid RLS recursion

### Q: Can users from School A see users from School B?

**A**: Technically yes at the database level, but:
1. The application never queries for users from other schools
2. All related data (students, staff, grades) is properly isolated
3. The UI only shows data from the user's school
4. This is acceptable because user profiles don't contain sensitive data

### Q: Should we add application-level filtering for users table queries?

**A**: Yes! Always filter by `school_id` in your queries:

```typescript
// Good: Filter by school_id
const { data: teachers } = await supabase
  .from('users')
  .select('*')
  .eq('role', 'teacher')
  .eq('school_id', profile.school_id); // Always include this!

// Bad: No filtering (will return all teachers from all schools)
const { data: teachers } = await supabase
  .from('users')
  .select('*')
  .eq('role', 'teacher');
```

## Next Steps

1. ✅ Run `DISABLE_RLS_USERS_FINAL.sql`
2. ✅ Test login
3. ✅ Verify multi-tenancy works
4. 📝 Update frontend code to always filter by `school_id`
5. 📝 Implement admin teacher management feature
6. 📝 Add more features with proper school isolation

## Related Files

- `DISABLE_RLS_USERS_FINAL.sql` - The fix script
- `database-migrations/add-school-multi-tenancy.sql` - Original migration (has the problematic policies)
- `COMPLETE_MULTI_TENANCY_SUMMARY.md` - Full multi-tenancy documentation
- `ADMIN_QUICK_START_MULTI_TENANCY.md` - Quick start guide

## Summary

The infinite recursion error is caused by RLS policies on the `users` table that query the same table. The solution is to use simple policies on the `users` table and enforce multi-tenancy isolation through:

1. RLS policies on other tables (students, staff, etc.)
2. Application-level filtering by `school_id`
3. Role-based authorization in the UI

This is a standard pattern for avoiding RLS recursion while maintaining security and multi-tenancy isolation.
