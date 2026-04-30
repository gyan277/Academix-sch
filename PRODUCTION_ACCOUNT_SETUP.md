# Account Management - Production Setup Guide

## Quick Setup for Netlify Production (5 Minutes)

### Step 1: Configure Supabase Email Templates

1. **Go to Supabase Dashboard**
   - Open https://supabase.com
   - Sign in and select your project

2. **Navigate to Email Templates**
   - Click **Authentication** in left sidebar
   - Click **Email Templates**

3. **Configure Reset Password Template**
   - Click **"Reset Password"**
   - Scroll to **"Redirect URL"** field at the bottom
   - Type exactly: `https://academix-man.netlify.app/reset-password`
   - Click **"Save"**

4. **Configure Email Change Template**
   - Go back to Email Templates list
   - Click **"Change Email Address"**
   - Scroll to **"Redirect URL"** field
   - Type exactly: `https://academix-man.netlify.app/login`
   - Click **"Save"**

### Step 2: Configure URL Settings

1. **Go to URL Configuration**
   - In Authentication section, click **"URL Configuration"**

2. **Set Site URL**
   - Site URL: `https://academix-man.netlify.app`

3. **Add Redirect URLs** (one per line)
   ```
   https://academix-man.netlify.app/reset-password
   https://academix-man.netlify.app/login
   ```

4. **Click "Save"**

### Step 3: Customize Email Template (Optional)

Replace the default email template with this beautiful one:

**In Reset Password → Message Body, paste:**

```html
<div style="font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, 'Helvetica Neue', Arial, sans-serif; max-width: 600px; margin: 0 auto; background-color: #ffffff;">
  
  <!-- Header -->
  <div style="background: linear-gradient(135deg, #667eea 0%, #764ba2 100%); padding: 40px 20px; text-align: center;">
    <h1 style="color: #ffffff; margin: 0; font-size: 28px; font-weight: 600;">Reset Your Password</h1>
    <p style="color: #f0f0f0; margin: 10px 0 0 0; font-size: 16px;">Academix School Management System</p>
  </div>
  
  <!-- Content -->
  <div style="padding: 40px 30px; background-color: #ffffff;">
    <p style="color: #374151; font-size: 16px; line-height: 1.6; margin: 0 0 20px 0;">
      Hello,
    </p>
    
    <p style="color: #374151; font-size: 16px; line-height: 1.6; margin: 0 0 20px 0;">
      We received a request to reset your password for your Academix account. Click the button below to create a new password:
    </p>
    
    <!-- Reset Button (Ash Color) -->
    <div style="text-align: center; margin: 35px 0;">
      <a href="{{ .ConfirmationURL }}" 
         style="display: inline-block;
                background-color: #6B7280;
                color: #ffffff;
                text-decoration: none;
                padding: 16px 40px;
                border-radius: 8px;
                font-size: 16px;
                font-weight: 600;
                box-shadow: 0 4px 6px rgba(107, 114, 128, 0.3);">
        Reset Password
      </a>
    </div>
    
    <p style="color: #6B7280; font-size: 14px; line-height: 1.6; margin: 30px 0 20px 0;">
      Or copy and paste this link into your browser:
    </p>
    
    <div style="background-color: #F3F4F6; padding: 12px; border-radius: 6px; word-break: break-all; font-size: 13px; color: #4B5563;">
      {{ .ConfirmationURL }}
    </div>
    
    <!-- Important Info Box -->
    <div style="background-color: #FEF3C7; border-left: 4px solid #F59E0B; padding: 16px; margin: 30px 0; border-radius: 4px;">
      <p style="color: #92400E; font-size: 14px; margin: 0; line-height: 1.5;">
        <strong>⚠️ Important:</strong> This link will expire in 1 hour for security reasons.
      </p>
    </div>
    
    <p style="color: #6B7280; font-size: 14px; line-height: 1.6; margin: 20px 0 0 0;">
      If you didn't request a password reset, you can safely ignore this email. Your password will remain unchanged.
    </p>
  </div>
  
  <!-- Footer -->
  <div style="background-color: #F9FAFB; padding: 30px; text-align: center; border-top: 1px solid #E5E7EB;">
    <p style="color: #9CA3AF; font-size: 13px; margin: 0 0 10px 0;">
      This email was sent by Academix School Management System
    </p>
    <p style="color: #9CA3AF; font-size: 13px; margin: 0 0 10px 0;">
      Mount Olivet Methodist Academy
    </p>
    <p style="color: #D1D5DB; font-size: 12px; margin: 10px 0 0 0;">
      © 2026 Glinax Tech Innovations. All rights reserved.
    </p>
  </div>
  
</div>
```

**Click "Save"**

## That's It! ✅

Your production account management is now configured.

## Test It

1. Go to https://academix-man.netlify.app/login
2. Click "Forgot password?"
3. Enter your email
4. Check your email inbox
5. Click the reset link
6. You should land on the reset password page
7. Create new password
8. Log in with new password

## Features Now Available

✅ **Forgot Password** - Users can reset via email
✅ **Change Password** - In Settings → Account
✅ **Change Email** - In Settings → Account with verification
✅ **Controlled Access** - Only admin-registered users can access

## User Instructions

### For Teachers/Staff

**Forgot Password:**
1. Go to login page
2. Click "Forgot password?"
3. Enter your email
4. Check email and click reset link
5. Create new password

**Change Password:**
1. Log in
2. Go to Settings → Account
3. Fill in Change Password form
4. Click "Update Password"

**Change Email:**
1. Log in
2. Go to Settings → Account
3. Fill in Change Email form
4. Click "Update Email"
5. Check new email and click verification link

### For Administrators

**Register New Users:**
- Go to Settings → Teachers
- Or use Registrar page
- Create user with email and password
- User can now log in and manage their account

## Troubleshooting

### Emails Not Arriving
- Check spam/junk folder
- Wait 2-3 minutes
- Verify email is correct in database
- Check Supabase auth logs

### Reset Link Not Working
- Link expires after 1 hour - request new one
- Link can only be used once
- Verify redirect URL is correct in Supabase

### Can't Change Password
- Verify current password is correct
- New password must be 8+ characters
- Passwords must match

## Support

If issues persist:
1. Check Supabase Dashboard → Logs → Auth Logs
2. Verify all users have email addresses
3. Test with different email provider
4. Contact support if needed

---

**Status**: ✅ Production Ready
**Time to Setup**: 5 minutes
**Your Production URL**: https://academix-man.netlify.app
