# Activity Notifications System

## Overview
Implemented a real-time activity notification system that tracks and displays all important activities in the school management system.

## Features

### 1. Activity Tracking
The system automatically logs the following activities:
- **Payments** - When any payment is recorded (tuition, bus, canteen)
- **Student Registration** - When a new student is enrolled
- **Expenses** - When an expense is recorded
- **Future extensible** - Can easily add more activity types

### 2. Notification Bell
- Located in the header next to the user profile
- Shows a red badge with the count of unread activities
- Displays "9+" if more than 9 unread activities
- Real-time updates when new activities occur

### 3. Notification Dropdown
- Click the bell icon to open the activity feed
- Shows the 20 most recent activities
- Each activity displays:
  - Icon (color-coded by type)
  - Title
  - Description
  - Time ago (e.g., "5m ago", "2h ago", "3d ago")
- Scrollable list for easy browsing
- "Mark all as read" button to clear the badge

### 4. Activity Types & Icons
- 💰 **Payment** (Green) - "Payment Received"
- 👤 **Student Registered** (Blue) - "New Student Registered"
- 🧾 **Expense Added** (Orange) - "Expense Recorded"
- 📚 **Score Entered** (Purple) - Future feature

### 5. Real-time Updates
- Uses Supabase real-time subscriptions
- Automatically updates when new activities occur
- No page refresh needed

## Database Setup

**IMPORTANT:** Run `database-migrations/add-activity-log.sql` in your Supabase SQL Editor.

This creates:
- `activity_log` table to store all activities
- Automatic triggers for payments, student registration, and expenses
- RLS policies for security
- Indexes for performance

## Example Activities

### Payment Activity
```
Title: Payment Received
Description: John Doe paid GHS 500.00 for Tuition
Time: 5m ago
```

### Student Registration
```
Title: New Student Registered
Description: Jane Smith (MOU-2024-001) enrolled in Primary 1
Time: 1h ago
```

### Expense Activity
```
Title: Expense Recorded
Description: Utilities: GHS 200.00 - Electricity bill for January
Time: 3h ago
```

## Technical Details

### Database Table Structure
```sql
activity_log (
  id UUID PRIMARY KEY,
  school_id UUID NOT NULL,
  user_id UUID,
  activity_type TEXT NOT NULL,
  title TEXT NOT NULL,
  description TEXT,
  metadata JSONB,
  created_at TIMESTAMPTZ
)
```

### Automatic Logging
Activities are logged automatically via database triggers:
- `trigger_log_payment` - Logs payment activities
- `trigger_log_student_registration` - Logs new student enrollments
- `trigger_log_expense` - Logs expense records

### Frontend Components Updated
- `client/components/Layout.tsx` - Added notification bell and dropdown

## Future Enhancements

Can easily add more activity types:
- Attendance marked
- Academic scores entered
- Teacher assignments
- Class fee configurations
- Report card generation
- Communication sent
- Settings changes

## Benefits

1. **Transparency** - All staff can see recent activities
2. **Audit Trail** - Track who did what and when
3. **Real-time Updates** - No need to refresh the page
4. **User-friendly** - Clean, intuitive interface
5. **Scalable** - Easy to add new activity types
