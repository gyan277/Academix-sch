# Implementation Plan: Admin Teacher Management

## Overview

This implementation plan breaks down the Admin Teacher Management feature into discrete, actionable coding tasks. The feature enables administrators to create, manage, and control teacher accounts through a dedicated interface integrated into the Settings page. Each task builds incrementally on previous work, with checkpoints to ensure quality and correctness.

## Tasks

- [ ] 1. Database schema updates and utility functions
  - Add `status` column to users table via SQL migration
  - Create `client/lib/teacher-utils.ts` with validation and helper functions
  - _Requirements: 3.1, 3.2, 3.3, 3.4, 7.2, 7.3, 8.2, 11.4_

- [ ]* 1.1 Write unit tests for validation functions
  - Test `validateEmail()` with valid and invalid formats
  - Test `validateName()` with various lengths
  - Test `validatePhone()` with different formats
  - Test `validatePassword()` with strength requirements
  - Test `generateSecurePassword()` produces valid passwords
  - Test `mapAuthError()` with different Supabase error messages
  - _Requirements: 3.1, 3.2, 3.3, 3.4_

- [ ] 2. Shared type definitions
  - Add teacher-related TypeScript interfaces to `shared/types.ts`
  - Define `TeacherProfile`, `CreateTeacherRequest`, `CreateTeacherResponse`
  - Define `UpdateTeacherRequest`, `UpdateTeacherResponse`, `ResetPasswordResponse`
  - _Requirements: 2.3, 6.4, 8.3, 10.1_

- [ ] 3. Create TeacherManagement component structure
  - [ ] 3.1 Create `client/components/TeacherManagement.tsx` with main container component
    - Implement `TeacherManagementInterface` component with state management
    - Add admin role verification using `useAuth` hook
    - Set up loading states and error handling
    - _Requirements: 1.2, 1.3, 5.1, 11.1_

  - [ ] 3.2 Implement `loadTeachers()` method
    - Fetch all teachers from Supabase with role filter
    - Join with teacher_classes to get assigned classes
    - Sort teachers alphabetically by full name
    - Handle loading and error states
    - _Requirements: 5.1, 5.2, 5.3, 5.5, 10.2_

  - [ ] 3.3 Implement CreateTeacherForm sub-component
    - Create form with email, full_name, phone, password fields
    - Add optional multi-select class assignment field
    - Implement client-side validation with error display
    - Add form submission handler
    - _Requirements: 2.1, 2.2, 3.1, 3.2, 3.3, 3.4, 3.5, 3.6, 4.1, 4.2_

  - [ ] 3.4 Implement TeacherList and TeacherCard sub-components
    - Display teacher information (name, email, phone, status)
    - Show assigned classes as badges
    - Add action buttons (edit, toggle status, reset password)
    - Handle empty state when no teachers exist
    - _Requirements: 5.1, 5.2, 5.3, 5.4_

- [ ] 4. Implement teacher creation workflow
  - [ ] 4.1 Implement `handleCreateTeacher()` method
    - Call Supabase Auth API to create user with email and password
    - Create user profile in users table with role "teacher"
    - Create class assignment records in teacher_classes table
    - Handle success and error cases with appropriate toasts
    - _Requirements: 2.2, 2.3, 2.4, 4.3, 4.4, 10.1, 10.2, 11.1, 11.2_

  - [ ] 4.2 Implement CredentialsDialog sub-component
    - Display email and password after successful creation
    - Add copy-to-clipboard functionality
    - Show security warning message
    - Prevent reopening after close
    - _Requirements: 9.1, 9.2, 9.3, 9.4, 9.5_

  - [ ] 4.3 Handle duplicate email errors
    - Map Supabase auth error for duplicate email
    - Display user-friendly error message
    - Keep form open for correction
    - _Requirements: 2.5, 11.2, 11.4_

  - [ ] 4.4 Fetch available classes for assignment
    - Query students table for unique class values
    - Sort classes alphabetically
    - Populate class selector dropdown
    - _Requirements: 4.2_

- [ ] 5. Checkpoint - Verify teacher creation flow
  - Ensure all tests pass, ask the user if questions arise.

- [ ] 6. Implement teacher editing workflow
  - [ ] 6.1 Implement EditTeacherDialog sub-component
    - Create dialog with form for full_name, phone, and classes
    - Display email as read-only field
    - Pre-populate form with current teacher data
    - Add save and cancel buttons
    - _Requirements: 6.1, 6.2, 6.3_

  - [ ] 6.2 Implement `handleEditTeacher()` method
    - Update users table with new full_name and phone
    - Delete existing class assignments for teacher
    - Insert new class assignments based on selection
    - Refresh teacher list after successful update
    - Display success toast
    - _Requirements: 6.4, 6.5, 6.6, 10.2, 11.1_

  - [ ]* 6.3 Write integration tests for teacher edit flow
    - Test opening edit dialog with current data
    - Test updating teacher information
    - Test modifying class assignments
    - Test error handling for failed updates
    - _Requirements: 6.1, 6.4, 6.6_

- [ ] 7. Implement account status management
  - [ ] 7.1 Implement `handleToggleStatus()` method
    - Update users table status field (active/inactive)
    - Refresh teacher list to show updated status
    - Display success toast with status change
    - _Requirements: 7.2, 7.3, 7.6, 11.1_

  - [ ] 7.2 Add status badge display in TeacherCard
    - Show green badge for active status
    - Show gray badge for inactive status
    - Add toggle button for status change
    - _Requirements: 7.1, 7.6_

  - [ ]* 7.3 Write integration tests for status toggle
    - Test activating inactive teacher account
    - Test deactivating active teacher account
    - Test status badge display updates
    - Test error handling for failed status changes
    - _Requirements: 7.2, 7.3, 7.4, 7.5_

- [ ] 8. Implement password reset functionality
  - [ ] 8.1 Implement `handleResetPassword()` method
    - Generate new secure password using utility function
    - Call Supabase Auth API to update user password
    - Display CredentialsDialog with new password
    - Show success toast
    - _Requirements: 8.1, 8.2, 8.3, 8.4, 8.5, 11.1_

  - [ ] 8.2 Add reset password button to TeacherCard
    - Add button with appropriate icon
    - Wire up to `handleResetPassword()` method
    - Handle loading state during password reset
    - _Requirements: 8.1_

  - [ ]* 8.3 Write integration tests for password reset
    - Test password reset generates valid password
    - Test credentials dialog displays new password
    - Test error handling for failed password reset
    - _Requirements: 8.2, 8.3, 8.4_

- [ ] 9. Checkpoint - Verify all CRUD operations
  - Ensure all tests pass, ask the user if questions arise.

- [ ] 10. Integrate TeacherManagement into Settings page
  - [ ] 10.1 Update `client/pages/Settings.tsx`
    - Import TeacherManagementInterface component
    - Add "Teachers" tab to TabsList (admin-only)
    - Add TabsContent for Teachers tab
    - Implement role-based visibility check
    - _Requirements: 1.1, 1.2, 1.3, 12.1, 12.2, 12.3_

  - [ ] 10.2 Add admin role check for tab visibility
    - Use `useAuth` hook to get current user profile
    - Conditionally render Teachers tab only for admin role
    - Hide tab for teacher and registrar roles
    - _Requirements: 1.2, 1.3_

  - [ ] 10.3 Ensure responsive design
    - Test layout on desktop, tablet, and mobile viewports
    - Ensure dialogs fit properly on small screens
    - Verify forms are scrollable when needed
    - _Requirements: 12.5_

- [ ] 11. Implement comprehensive error handling
  - [ ] 11.1 Add network error handling
    - Detect offline state and display appropriate message
    - Handle request timeouts with user-friendly errors
    - Add retry logic for transient failures
    - _Requirements: 11.3, 11.5_

  - [ ] 11.2 Add database error handling
    - Map common PostgreSQL error codes to user messages
    - Handle unique constraint violations
    - Handle foreign key constraint violations
    - Log all errors to console for debugging
    - _Requirements: 11.2, 11.4, 11.5_

  - [ ] 11.3 Add permission error handling
    - Redirect non-admin users attempting direct access
    - Display access denied message
    - Verify RLS policies block unauthorized operations
    - _Requirements: 1.3, 1.4_

  - [ ]* 11.4 Write integration tests for error scenarios
    - Test duplicate email error handling
    - Test network error handling
    - Test permission denied scenarios
    - Test validation error display
    - _Requirements: 2.5, 2.6, 11.2, 11.3, 11.4_

- [ ] 12. Final integration and polish
  - [ ] 12.1 Add loading states and spinners
    - Show loading spinner while fetching teachers
    - Show loading state during form submissions
    - Disable buttons during async operations
    - _Requirements: 11.1_

  - [ ] 12.2 Implement toast notifications for all operations
    - Success toast for teacher creation
    - Success toast for teacher updates
    - Success toast for status changes
    - Success toast for password resets
    - Error toasts for all failure scenarios
    - _Requirements: 11.1, 11.2_

  - [ ] 12.3 Add accessibility attributes
    - Add ARIA labels to form fields
    - Add ARIA descriptions to buttons
    - Ensure keyboard navigation works properly
    - Test with screen reader
    - _Requirements: 12.5_

  - [ ] 12.4 Verify data persistence and referential integrity
    - Test cascade delete behavior for teacher accounts
    - Verify unique email constraint enforcement
    - Test foreign key relationships between tables
    - _Requirements: 10.1, 10.2, 10.3, 10.4, 10.5_

- [ ] 13. Final checkpoint - Complete end-to-end testing
  - Ensure all tests pass, ask the user if questions arise.

## Notes

- Tasks marked with `*` are optional testing tasks and can be skipped for faster MVP delivery
- Each task references specific requirements from the requirements document for traceability
- The implementation uses TypeScript throughout for type safety
- All database operations use Supabase client with automatic RLS policy enforcement
- UI components follow existing Radix UI patterns from the Settings page
- Checkpoints ensure incremental validation and provide opportunities for user feedback
- Testing tasks validate correctness but are optional to allow faster iteration
- All async operations include proper error handling and user feedback via toast notifications
