# Requirements Document: Admin Teacher Management

## Introduction

This feature enables administrators to create, manage, and control teacher accounts within the MOMA school management system. The system will provide a dedicated interface for admins to create teacher profiles, assign classes, manage credentials, and control teacher account status. This ensures proper access control and streamlines the teacher onboarding process.

## Glossary

- **Admin**: A user with the role "admin" who has full system access and management capabilities
- **Teacher**: A user with the role "teacher" who can access attendance and academic features
- **Teacher_Profile**: A record in the users table containing teacher account information
- **Teacher_Management_Interface**: The UI component accessible from Settings page for managing teachers
- **Supabase_Auth**: The authentication service provided by Supabase for user management
- **Teacher_Account**: The combination of authentication credentials and profile data for a teacher
- **Class_Assignment**: A record linking a teacher to specific classes they teach
- **Account_Status**: The state of a teacher account (active or inactive)

## Requirements

### Requirement 1: Admin Access Control

**User Story:** As an admin, I want exclusive access to teacher management features, so that only authorized personnel can create and manage teacher accounts.

#### Acceptance Criteria

1. THE Teacher_Management_Interface SHALL be accessible only from the Settings page
2. WHEN a user with role "admin" accesses the Settings page, THE System SHALL display the teacher management section
3. WHEN a user with role "teacher" or "registrar" accesses the Settings page, THE System SHALL NOT display the teacher management section
4. WHEN an unauthenticated user attempts to access the Settings page, THE System SHALL redirect to the login page

### Requirement 2: Teacher Profile Creation

**User Story:** As an admin, I want to create new teacher accounts with essential information, so that teachers can access the system with proper credentials.

#### Acceptance Criteria

1. WHEN an admin initiates teacher creation, THE Teacher_Management_Interface SHALL display a form with fields for email, full name, phone, and password
2. WHEN an admin submits a teacher creation form with valid data, THE System SHALL create a record in Supabase_Auth with the provided email and password
3. WHEN Supabase_Auth successfully creates the authentication record, THE System SHALL create a corresponding Teacher_Profile in the users table with role "teacher"
4. WHEN teacher creation succeeds, THE System SHALL display a success message containing the teacher's email and initial password
5. IF teacher creation fails due to duplicate email, THEN THE System SHALL display an error message indicating the email already exists
6. IF teacher creation fails due to invalid data, THEN THE System SHALL display validation errors for the specific fields

### Requirement 3: Input Validation

**User Story:** As an admin, I want the system to validate teacher information before creation, so that only valid data is stored in the system.

#### Acceptance Criteria

1. THE System SHALL require email field to contain a valid email address format
2. THE System SHALL require full name field to contain at least 2 characters
3. THE System SHALL require password field to contain at least 8 characters
4. WHEN phone field is provided, THE System SHALL validate it contains only digits, spaces, parentheses, hyphens, and plus signs
5. WHEN any required field is empty, THE System SHALL display an error message indicating which fields are required
6. THE System SHALL prevent form submission until all validation rules are satisfied

### Requirement 4: Optional Class Assignment During Creation

**User Story:** As an admin, I want to optionally assign classes to a teacher during account creation, so that I can complete the teacher setup in one step.

#### Acceptance Criteria

1. THE Teacher_Management_Interface SHALL provide an optional class selection field during teacher creation
2. WHEN an admin selects classes during teacher creation, THE System SHALL display available classes from the system
3. WHEN teacher creation succeeds with selected classes, THE System SHALL create records in the teacher_classes table linking the teacher to the selected classes
4. WHEN teacher creation succeeds without selected classes, THE System SHALL create the Teacher_Profile without class assignments
5. THE System SHALL allow multiple class selections for a single teacher

### Requirement 5: Teacher List Display

**User Story:** As an admin, I want to view a list of all teachers, so that I can see who has access to the system and their current status.

#### Acceptance Criteria

1. THE Teacher_Management_Interface SHALL display a list of all users with role "teacher"
2. FOR EACH teacher in the list, THE System SHALL display their full name, email, phone, and account status
3. FOR EACH teacher in the list, THE System SHALL display the classes assigned to them
4. WHEN no teachers exist in the system, THE System SHALL display a message indicating no teachers are registered
5. THE System SHALL sort the teacher list alphabetically by full name

### Requirement 6: Teacher Information Editing

**User Story:** As an admin, I want to edit teacher information, so that I can keep teacher profiles up to date.

#### Acceptance Criteria

1. WHEN an admin selects a teacher from the list, THE Teacher_Management_Interface SHALL display an edit form with the teacher's current information
2. THE System SHALL allow editing of full name, phone, and assigned classes
3. THE System SHALL NOT allow editing of email address
4. WHEN an admin submits updated teacher information, THE System SHALL update the Teacher_Profile in the users table
5. WHEN class assignments are modified, THE System SHALL update the teacher_classes table accordingly
6. WHEN the update succeeds, THE System SHALL display a success message and refresh the teacher list

### Requirement 7: Teacher Account Status Management

**User Story:** As an admin, I want to activate or deactivate teacher accounts, so that I can control who has access to the system without deleting accounts.

#### Acceptance Criteria

1. THE Teacher_Management_Interface SHALL provide a toggle or button to change teacher account status
2. WHEN an admin deactivates a teacher account, THE System SHALL update the Teacher_Profile status field to "inactive"
3. WHEN an admin activates a teacher account, THE System SHALL update the Teacher_Profile status field to "active"
4. WHEN a teacher account is deactivated, THE System SHALL prevent that teacher from logging in
5. WHEN a teacher account is activated, THE System SHALL allow that teacher to log in
6. THE System SHALL display the current account status for each teacher in the list

### Requirement 8: Password Reset Capability

**User Story:** As an admin, I want to reset a teacher's password, so that I can help teachers who have forgotten their credentials.

#### Acceptance Criteria

1. THE Teacher_Management_Interface SHALL provide a password reset option for each teacher
2. WHEN an admin initiates a password reset, THE System SHALL generate a new temporary password
3. WHEN password reset succeeds, THE System SHALL update the teacher's password in Supabase_Auth
4. WHEN password reset succeeds, THE System SHALL display the new temporary password to the admin
5. THE System SHALL require the new temporary password to meet the same validation rules as initial password creation

### Requirement 9: Teacher Credential Display

**User Story:** As an admin, I want to see the credentials after creating a teacher account, so that I can provide them to the teacher for their first login.

#### Acceptance Criteria

1. WHEN teacher creation succeeds, THE System SHALL display a confirmation dialog containing the teacher's email and initial password
2. THE System SHALL provide a copy button to copy the credentials to clipboard
3. THE System SHALL keep the credentials visible until the admin explicitly closes the dialog
4. THE System SHALL warn the admin to securely share the credentials with the teacher
5. THE System SHALL NOT store or display the password again after the dialog is closed

### Requirement 10: Data Persistence and Integrity

**User Story:** As a system administrator, I want teacher data to be properly stored and linked, so that the system maintains data integrity.

#### Acceptance Criteria

1. WHEN a Teacher_Profile is created, THE System SHALL ensure the id field references a valid Supabase_Auth user id
2. WHEN class assignments are created, THE System SHALL ensure the teacher_id field references a valid Teacher_Profile
3. WHEN a teacher account is deleted, THE System SHALL remove all associated class assignments from teacher_classes table
4. THE System SHALL enforce unique email addresses across all Teacher_Profiles
5. THE System SHALL maintain referential integrity between users table and teacher_classes table

### Requirement 11: Error Handling and User Feedback

**User Story:** As an admin, I want clear feedback when operations succeed or fail, so that I understand what happened and can take appropriate action.

#### Acceptance Criteria

1. WHEN any teacher management operation succeeds, THE System SHALL display a success toast notification
2. IF any teacher management operation fails, THEN THE System SHALL display an error message describing what went wrong
3. IF a network error occurs during an operation, THEN THE System SHALL display a message indicating connection issues
4. IF Supabase_Auth returns an error, THEN THE System SHALL display the error message in user-friendly language
5. THE System SHALL log all errors to the browser console for debugging purposes

### Requirement 12: UI Integration with Settings Page

**User Story:** As an admin, I want the teacher management interface to be integrated into the Settings page, so that all administrative functions are in one place.

#### Acceptance Criteria

1. THE Settings page SHALL include a new tab labeled "Teachers" for admin users
2. WHEN an admin selects the Teachers tab, THE System SHALL display the Teacher_Management_Interface
3. THE Teacher_Management_Interface SHALL follow the same design patterns and styling as other Settings tabs
4. THE System SHALL maintain the current tab selection when the page is refreshed
5. THE Teacher_Management_Interface SHALL be responsive and work on mobile and desktop devices
