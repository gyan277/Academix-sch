# Loading Screen Fix - Admin/Teacher View Flashing

## Problem
When logging in as an admin, the UI was briefly showing teacher navigation items and the role badge showed "Teacher" before switching to admin items. This created a jarring "flashing" effect between the two views.

## Root Cause
The authentication hook (`useAuth`) loads user data asynchronously from Supabase. During this loading period:
1. The `userRole` defaulted to "teacher" 
2. Components rendered immediately with this default value
3. Once the actual role loaded, components re-rendered with correct data
4. This caused visible flashing between teacher and admin views

## Solution
Added loading state checks to all components that display role-specific content:

### 1. Sidebar Component (`client/components/Sidebar.tsx`)
**Changes:**
- Added `loading` state from `useAuth` hook
- Show loading skeleton (animated placeholder) while auth data loads
- Only render filtered navigation items after loading completes
- Loading skeleton shows 4 placeholder items with pulse animation

**Before:**
```typescript
const { userRole } = useAuth();
// Immediately renders nav items with default "teacher" role
```

**After:**
```typescript
const { userRole, loading } = useAuth();
{loading ? (
  // Show loading skeleton
  <div className="space-y-2">
    {[1, 2, 3, 4].map((i) => (
      <div key={i} className="px-4 py-3 rounded-lg bg-sidebar-accent/50 animate-pulse">
        <div className="h-5 bg-sidebar-accent rounded w-3/4"></div>
      </div>
    ))}
  </div>
) : (
  // Show actual nav items after loading
  filteredNavItems.map((item) => { ... })
)}
```

### 2. Layout Component (`client/components/Layout.tsx`)
**Changes:**
- Added `loading` state from `useAuth` hook
- Show loading skeleton for user name and role badge while auth data loads
- Only render actual user info after loading completes
- Loading skeleton matches the size and position of actual content

**Before:**
```typescript
const { userName, userRole } = useAuth();
// Immediately shows userName and role (with default values)
```

**After:**
```typescript
const { userName, userRole, loading } = useAuth();
{loading ? (
  // Show loading skeleton
  <>
    <div className="hidden sm:block text-right space-y-1">
      <div className="h-4 w-24 bg-muted rounded animate-pulse"></div>
      <div className="h-3 w-20 bg-muted rounded animate-pulse"></div>
    </div>
    <div className="w-10 h-10 rounded-full bg-muted animate-pulse"></div>
  </>
) : (
  // Show actual user info after loading
  <>
    <div className="hidden sm:block text-right">
      <p className="text-sm font-medium text-foreground">{userName}</p>
      <p className="text-xs text-muted-foreground">{getRoleBadge()}</p>
    </div>
    <Button ... />
  </>
)}
```

### 3. Attendance Page (`client/pages/Attendance.tsx`)
**Already Fixed:**
- Shows full-page loading spinner while auth data loads
- Only renders tabs after loading completes
- Sets correct default tab based on user role

## Result
✅ No more flashing between teacher and admin views
✅ Smooth loading experience with skeleton placeholders
✅ User never sees incorrect role information
✅ Consistent loading behavior across all pages

## Testing
To verify the fix:
1. Log in as admin - should see loading skeletons briefly, then admin navigation
2. Log in as teacher - should see loading skeletons briefly, then teacher navigation
3. No flashing or switching between roles should occur
4. User name and role badge should only appear once with correct values

## Files Modified
- `client/components/Sidebar.tsx` - Added loading skeleton for navigation items
- `client/components/Layout.tsx` - Added loading skeleton for user info section
- `client/pages/Attendance.tsx` - Already had loading screen (reference implementation)

## Technical Details
- Loading state comes from `client/hooks/use-auth.ts`
- Loading is `true` until Supabase session and user profile are loaded
- Skeleton animations use Tailwind's `animate-pulse` utility
- Loading skeletons match the size and layout of actual content for smooth transition
