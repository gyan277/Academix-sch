# Account Management - Quick Start Guide

## What Was Added

✅ **Change Password** - Users can update their password from Settings → Account
✅ **Change Email** - Users can update their email with verification
✅ **Forgot Password** - Password recovery via email link
✅ **Controlled Access** - Only admin-registered users can access the system

## Setup Steps (5 Minutes)

### Step 1: Configure Supabase Email (REQUIRED)

1. Go to https://supabase.com → Your Project
2. Click **Authentication** → **Email Templates**
3. Click **Reset Password**
4. Set **Redirect URL** to:
   - Production: `https://yourdomain.com/reset-password`
   - Development: `http://localhost:8080/reset-password`
5. Click **Save**

**That's it for basic setup!** The system will use Supabase's default SMTP (3 emails/hour limit).

### Step 2: Test the System

1. **Test Forgot Password:**
   ```
   1. Go to login page
   2. Click "Forgot password?"
   3. Enter your email
   4. Check email inbox
   5. Click reset link
   6. Create new password
   7. Log in with new password
   ```

2. **Test Change Password:**
   ```
   1. Log in
   2. Go to Settings → Account
   3. Enter current password
   4. Enter new password (8+ characters)
   5. Confirm new password
   6. Click "Update Password"
   7. Log out and log in with new password
   ```

3. **Test Change Email:**
   ```
   1. Log in
   2. Go to Settings → Account
   3. Enter new email
   4. Enter your password
   5. Click "Update Email"
   6. Check new email inbox
   7. Click verification link
   8. Log in with new email
   ```

### Step 3: Verify Database (Optional)

Run this in Supabase SQL Editor:
```sql
-- Check if users have email addresses
SELECT full_name, email, role 
FROM users 
WHERE email IS NOT NULL 
LIMIT 10;
```

All users should have email addresses to use forgot password.

## For Production (Optional but Recommended)

### Configure Custom SMTP

For production, use a custom SMTP provider for better email delivery:

1. Go to **Authentication** → **Settings** → **SMTP Settings**
2. Enable **Custom SMTP**
3. Enter your SMTP credentials (Gmail, SendGrid, Mailgun, etc.)
4. Click **Save**
5. Click **Send Test Email** to verify

**Popular Options:**
- **Gmail**: Free, 500 emails/day (use App Password)
- **SendGrid**: Free tier, 100 emails/day
- **Mailgun**: Free tier, 5,000 emails/month

See `SUPABASE_EMAIL_CONFIGURATION.md` for detailed SMTP setup.

## How It Works

### Security Model

1. **No Public Signup** ✅
   - Users cannot create accounts themselves
   - Admin must register users first in Settings → Teachers or Registrar page
   - This prevents unauthorized access

2. **Forgot Password** ✅
   - Only works for emails registered in database
   - Sends secure reset link via email
   - Link expires after 1 hour
   - Link can only be used once

3. **Change Password** ✅
   - Requires current password verification
   - New password must be 8+ characters
   - Immediate effect - old password stops working

4. **Change Email** ✅
   - Requires password verification
   - Sends verification email to new address
   - Must click link to confirm
   - Old email stops working after confirmation

## User Instructions

### For Teachers/Staff

**Forgot Your Password?**
1. Go to login page
2. Click "Forgot password?" link
3. Enter your email
4. Check your email inbox (and spam folder)
5. Click the reset link
6. Create a new password
7. Log in with your new password

**Change Your Password:**
1. Log in
2. Click Settings in sidebar
3. Go to Account tab
4. Fill in the Change Password form
5. Click "Update Password"

**Change Your Email:**
1. Log in
2. Click Settings in sidebar
3. Go to Account tab
4. Fill in the Change Email form
5. Click "Update Email"
6. Check your new email inbox
7. Click the verification link

### For Administrators

**Register New Users:**
1. Go to Settings → Teachers (for teachers)
2. Or Registrar page (for staff)
3. Create user with email and password
4. User can now log in and manage their account

**Help User Who Forgot Password:**
- Direct them to "Forgot password?" link on login page
- They'll receive reset email if registered
- If they can't access email, you can reset password in Supabase Dashboard

## Troubleshooting

### "Email not found" error
- User is not registered in database
- Admin needs to create account first
- Check spelling of email address

### Reset email not arriving
- Check spam/junk folder
- Wait 2-3 minutes
- Verify email is correct in database
- Check Supabase email configuration

### Reset link not working
- Link expires after 1 hour - request new one
- Link can only be used once
- Check redirect URL in Supabase settings

### Can't change password
- Verify current password is correct
- New password must be 8+ characters
- Passwords must match

## Files Created

### Frontend
- `client/pages/ForgotPassword.tsx` - Forgot password page
- `client/pages/ResetPassword.tsx` - Reset password page
- `client/components/AccountSettings.tsx` - Account settings component
- `client/pages/Login.tsx` - Updated with forgot password link
- `client/App.tsx` - Added new routes

### Documentation
- `ACCOUNT_MANAGEMENT_GUIDE.md` - Complete feature documentation
- `SUPABASE_EMAIL_CONFIGURATION.md` - Detailed email setup guide
- `VERIFY_ACCOUNT_MANAGEMENT_SETUP.sql` - Database verification script
- `ACCOUNT_MANAGEMENT_QUICK_START.md` - This file

## Next Steps

1. ✅ Configure Supabase email redirect URL (5 minutes)
2. ✅ Test forgot password flow
3. ✅ Test change password
4. ✅ Test change email
5. ⏭️ (Optional) Set up custom SMTP for production
6. ⏭️ (Optional) Customize email templates with branding
7. ⏭️ Push changes to GitHub

## Support

If you encounter issues:

1. **Check Supabase Logs:**
   - Go to Logs → Auth Logs
   - Look for email send events
   - Check for errors

2. **Verify Configuration:**
   - Run `VERIFY_ACCOUNT_MANAGEMENT_SETUP.sql`
   - Check all users have email addresses
   - Verify redirect URLs are correct

3. **Test with Different Email:**
   - Try Gmail, Outlook, etc.
   - Some providers block automated emails

4. **Check Documentation:**
   - `ACCOUNT_MANAGEMENT_GUIDE.md` - Full feature guide
   - `SUPABASE_EMAIL_CONFIGURATION.md` - Email setup details

---

**Status**: ✅ Ready to Configure
**Time to Setup**: 5 minutes
**Time to Test**: 10 minutes
**Priority**: HIGH (Required for password recovery)
