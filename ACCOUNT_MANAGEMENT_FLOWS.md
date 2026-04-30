# Account Management - User Flows

## Visual Flow Diagrams

### 1. Forgot Password Flow

```
┌─────────────────────────────────────────────────────────────────┐
│                        FORGOT PASSWORD FLOW                      │
└─────────────────────────────────────────────────────────────────┘

User                    Frontend                 Supabase              Email
  │                        │                        │                   │
  │  1. Click "Forgot      │                        │                   │
  │     password?"         │                        │                   │
  ├───────────────────────>│                        │                   │
  │                        │                        │                   │
  │  2. Enter email        │                        │                   │
  ├───────────────────────>│                        │                   │
  │                        │                        │                   │
  │                        │  3. Check if email     │                   │
  │                        │     exists in DB       │                   │
  │                        ├───────────────────────>│                   │
  │                        │                        │                   │
  │                        │  4. Email found ✅     │                   │
  │                        │<───────────────────────┤                   │
  │                        │                        │                   │
  │                        │  5. Request password   │                   │
  │                        │     reset              │                   │
  │                        ├───────────────────────>│                   │
  │                        │                        │                   │
  │                        │                        │  6. Send reset    │
  │                        │                        │     email         │
  │                        │                        ├──────────────────>│
  │                        │                        │                   │
  │  7. "Check your email" │                        │                   │
  │<───────────────────────┤                        │                   │
  │                        │                        │                   │
  │  8. Receive email      │                        │                   │
  │<───────────────────────────────────────────────────────────────────┤
  │                        │                        │                   │
  │  9. Click reset link   │                        │                   │
  ├───────────────────────>│                        │                   │
  │                        │                        │                   │
  │                        │  10. Verify token      │                   │
  │                        ├───────────────────────>│                   │
  │                        │                        │                   │
  │                        │  11. Token valid ✅    │                   │
  │                        │<───────────────────────┤                   │
  │                        │                        │                   │
  │  12. Show reset page   │                        │                   │
  │<───────────────────────┤                        │                   │
  │                        │                        │                   │
  │  13. Enter new         │                        │                   │
  │      password          │                        │                   │
  ├───────────────────────>│                        │                   │
  │                        │                        │                   │
  │                        │  14. Update password   │                   │
  │                        ├───────────────────────>│                   │
  │                        │                        │                   │
  │                        │  15. Password updated  │                   │
  │                        │<───────────────────────┤                   │
  │                        │                        │                   │
  │  16. Redirect to login │                        │                   │
  │<───────────────────────┤                        │                   │
  │                        │                        │                   │
  │  17. Login with new    │                        │                   │
  │      password ✅       │                        │                   │
  └────────────────────────┴────────────────────────┴───────────────────┘
```

### 2. Change Password Flow

```
┌─────────────────────────────────────────────────────────────────┐
│                       CHANGE PASSWORD FLOW                       │
└─────────────────────────────────────────────────────────────────┘

User                    Frontend                 Supabase
  │                        │                        │
  │  1. Login              │                        │
  ├───────────────────────>│                        │
  │                        │                        │
  │  2. Go to Settings     │                        │
  │     → Account          │                        │
  ├───────────────────────>│                        │
  │                        │                        │
  │  3. Enter current      │                        │
  │     password           │                        │
  ├───────────────────────>│                        │
  │                        │                        │
  │  4. Enter new          │                        │
  │     password (8+ chars)│                        │
  ├───────────────────────>│                        │
  │                        │                        │
  │  5. Confirm new        │                        │
  │     password           │                        │
  ├───────────────────────>│                        │
  │                        │                        │
  │  6. Click "Update      │                        │
  │     Password"          │                        │
  ├───────────────────────>│                        │
  │                        │                        │
  │                        │  7. Verify current     │
  │                        │     password           │
  │                        ├───────────────────────>│
  │                        │                        │
  │                        │  8. Password correct ✅│
  │                        │<───────────────────────┤
  │                        │                        │
  │                        │  9. Update to new      │
  │                        │     password           │
  │                        ├───────────────────────>│
  │                        │                        │
  │                        │  10. Password updated  │
  │                        │<───────────────────────┤
  │                        │                        │
  │  11. Success message   │                        │
  │<───────────────────────┤                        │
  │                        │                        │
  │  12. Old password      │                        │
  │      no longer works ❌│                        │
  │                        │                        │
  │  13. New password      │                        │
  │      works ✅          │                        │
  └────────────────────────┴────────────────────────┘
```

### 3. Change Email Flow

```
┌─────────────────────────────────────────────────────────────────┐
│                        CHANGE EMAIL FLOW                         │
└─────────────────────────────────────────────────────────────────┘

User                    Frontend                 Supabase              Email
  │                        │                        │                   │
  │  1. Login              │                        │                   │
  ├───────────────────────>│                        │                   │
  │                        │                        │                   │
  │  2. Go to Settings     │                        │                   │
  │     → Account          │                        │                   │
  ├───────────────────────>│                        │                   │
  │                        │                        │                   │
  │  3. Enter new email    │                        │                   │
  ├───────────────────────>│                        │                   │
  │                        │                        │                   │
  │  4. Enter password     │                        │                   │
  ├───────────────────────>│                        │                   │
  │                        │                        │                   │
  │  5. Click "Update      │                        │                   │
  │     Email"             │                        │                   │
  ├───────────────────────>│                        │                   │
  │                        │                        │                   │
  │                        │  6. Verify password    │                   │
  │                        ├───────────────────────>│                   │
  │                        │                        │                   │
  │                        │  7. Password correct ✅│                   │
  │                        │<───────────────────────┤                   │
  │                        │                        │                   │
  │                        │  8. Request email      │                   │
  │                        │     change             │                   │
  │                        ├───────────────────────>│                   │
  │                        │                        │                   │
  │                        │                        │  9. Send          │
  │                        │                        │     verification  │
  │                        │                        ├──────────────────>│
  │                        │                        │                   │
  │  10. "Check your       │                        │                   │
  │       new email"       │                        │                   │
  │<───────────────────────┤                        │                   │
  │                        │                        │                   │
  │  11. Receive email     │                        │                   │
  │<───────────────────────────────────────────────────────────────────┤
  │                        │                        │                   │
  │  12. Click verify link │                        │                   │
  ├───────────────────────>│                        │                   │
  │                        │                        │                   │
  │                        │  13. Verify token      │                   │
  │                        ├───────────────────────>│                   │
  │                        │                        │                   │
  │                        │  14. Email updated ✅  │                   │
  │                        │<───────────────────────┤                   │
  │                        │                        │                   │
  │  15. Redirect to login │                        │                   │
  │<───────────────────────┤                        │                   │
  │                        │                        │                   │
  │  16. Login with new    │                        │                   │
  │      email ✅          │                        │                   │
  └────────────────────────┴────────────────────────┴───────────────────┘
```

### 4. User Registration Flow (Admin Only)

```
┌─────────────────────────────────────────────────────────────────┐
│                    USER REGISTRATION FLOW                        │
│                      (Admin Only)                                │
└─────────────────────────────────────────────────────────────────┘

Admin                   Frontend                 Supabase
  │                        │                        │
  │  1. Login as admin     │                        │
  ├───────────────────────>│                        │
  │                        │                        │
  │  2. Go to Settings     │                        │
  │     → Teachers         │                        │
  ├───────────────────────>│                        │
  │                        │                        │
  │  3. Click "Add         │                        │
  │     Teacher"           │                        │
  ├───────────────────────>│                        │
  │                        │                        │
  │  4. Enter user details:│                        │
  │     - Name             │                        │
  │     - Email            │                        │
  │     - Password         │                        │
  │     - Role             │                        │
  ├───────────────────────>│                        │
  │                        │                        │
  │  5. Click "Create"     │                        │
  ├───────────────────────>│                        │
  │                        │                        │
  │                        │  6. Create auth account│
  │                        ├───────────────────────>│
  │                        │                        │
  │                        │  7. Auth account       │
  │                        │     created ✅         │
  │                        │<───────────────────────┤
  │                        │                        │
  │                        │  8. Create user record │
  │                        ├───────────────────────>│
  │                        │                        │
  │                        │  9. User record        │
  │                        │     created ✅         │
  │                        │<───────────────────────┤
  │                        │                        │
  │  10. Success message   │                        │
  │<───────────────────────┤                        │
  │                        │                        │
  │  11. User can now:     │                        │
  │      - Login ✅        │                        │
  │      - Change password │                        │
  │      - Change email    │                        │
  │      - Reset password  │                        │
  └────────────────────────┴────────────────────────┘
```

## Security Checkpoints

### Forgot Password Security

```
┌─────────────────────────────────────────────────────────────────┐
│                    SECURITY CHECKPOINTS                          │
└─────────────────────────────────────────────────────────────────┘

Checkpoint 1: Email Exists?
├─ YES → Send reset email
└─ NO  → Show error "Email not registered"

Checkpoint 2: Reset Link Valid?
├─ YES → Show reset password page
└─ NO  → Show error "Link expired or invalid"

Checkpoint 3: Link Already Used?
├─ YES → Show error "Link already used"
└─ NO  → Allow password reset

Checkpoint 4: Link Expired?
├─ YES → Show error "Link expired (1 hour limit)"
└─ NO  → Allow password reset

Checkpoint 5: Password Strong Enough?
├─ YES (8+ chars) → Update password
└─ NO  → Show error "Password too short"
```

### Change Password Security

```
┌─────────────────────────────────────────────────────────────────┐
│                    SECURITY CHECKPOINTS                          │
└─────────────────────────────────────────────────────────────────┘

Checkpoint 1: User Logged In?
├─ YES → Continue
└─ NO  → Redirect to login

Checkpoint 2: Current Password Correct?
├─ YES → Continue
└─ NO  → Show error "Incorrect password"

Checkpoint 3: New Password Strong?
├─ YES (8+ chars) → Continue
└─ NO  → Show error "Password too short"

Checkpoint 4: Passwords Match?
├─ YES → Update password
└─ NO  → Show error "Passwords don't match"
```

### Change Email Security

```
┌─────────────────────────────────────────────────────────────────┐
│                    SECURITY CHECKPOINTS                          │
└─────────────────────────────────────────────────────────────────┘

Checkpoint 1: User Logged In?
├─ YES → Continue
└─ NO  → Redirect to login

Checkpoint 2: Password Correct?
├─ YES → Continue
└─ NO  → Show error "Incorrect password"

Checkpoint 3: Email Format Valid?
├─ YES → Continue
└─ NO  → Show error "Invalid email format"

Checkpoint 4: Email Already Exists?
├─ YES → Show error "Email already in use"
└─ NO  → Send verification email

Checkpoint 5: Verification Link Clicked?
├─ YES → Update email
└─ NO  → Email not changed
```

## Error Handling

### User-Friendly Error Messages

```
Technical Error              →  User-Friendly Message
─────────────────────────────────────────────────────────────────
"User not found"             →  "This email is not registered. 
                                 Contact your administrator."

"Invalid credentials"        →  "Current password is incorrect"

"Password too short"         →  "Password must be at least 8 
                                 characters long"

"Passwords don't match"      →  "New password and confirmation 
                                 don't match"

"Invalid email format"       →  "Please enter a valid email 
                                 address"

"Email already exists"       →  "This email is already in use"

"Token expired"              →  "This link has expired. Please 
                                 request a new one."

"Token invalid"              →  "This link is invalid or has 
                                 already been used."

"Network error"              →  "Connection error. Please check 
                                 your internet and try again."
```

## Success States

### Visual Feedback

```
Action                       Success Message
─────────────────────────────────────────────────────────────────
Password Changed             "✅ Password updated successfully"

Email Change Requested       "✅ Verification email sent. Check 
                              your inbox."

Email Changed                "✅ Email updated successfully"

Password Reset Requested     "✅ Reset instructions sent. Check 
                              your email."

Password Reset Complete      "✅ Password reset successfully. 
                              You can now log in."

User Created (Admin)         "✅ User account created 
                              successfully"
```

---

**These flows ensure:**
- ✅ Secure authentication
- ✅ User-friendly experience
- ✅ Clear error messages
- ✅ Proper validation at each step
- ✅ No unauthorized access
