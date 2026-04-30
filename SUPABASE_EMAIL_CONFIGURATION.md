# Supabase Email Configuration for Account Management

## Overview

For the account management features (forgot password, email verification) to work, you need to configure email settings in your Supabase project.

## Step-by-Step Configuration

### 1. Access Supabase Dashboard

1. Go to https://supabase.com
2. Sign in to your account
3. Select your project (School Management System)

### 2. Enable Email Authentication

1. In the left sidebar, click **Authentication**
2. Click **Providers**
3. Find **Email** provider
4. Make sure it's **enabled** (toggle should be ON)
5. Click **Save**

### 3. Configure Email Templates

1. In Authentication section, click **Email Templates**
2. You'll see several templates:
   - Confirm signup
   - Invite user
   - Magic Link
   - **Reset Password** ← This is what we need
   - Email Change

#### Configure Reset Password Template

1. Click on **Reset Password**
2. You'll see the email template editor
3. Update the **Subject** (optional):
   ```
   Reset Your Academix Password
   ```

4. Update the **Message Body** (optional - customize with your branding):
   ```html
   <h2>Reset Your Password</h2>
   <p>Hi there,</p>
   <p>Someone requested a password reset for your Academix account.</p>
   <p>Click the button below to reset your password:</p>
   <p><a href="{{ .ConfirmationURL }}" style="background-color: #4F46E5; color: white; padding: 12px 24px; text-decoration: none; border-radius: 6px; display: inline-block;">Reset Password</a></p>
   <p>If you didn't request this, you can safely ignore this email.</p>
   <p>This link will expire in 1 hour.</p>
   <p>Thanks,<br>The Academix Team</p>
   ```

5. **IMPORTANT**: Set the **Redirect URL**:
   ```
   https://yourdomain.com/reset-password
   ```
   
   For local development:
   ```
   http://localhost:8080/reset-password
   ```

6. Click **Save**

#### Configure Email Change Template

1. Click on **Change Email Address**
2. Update the **Redirect URL**:
   ```
   https://yourdomain.com/login
   ```
   
   For local development:
   ```
   http://localhost:8080/login
   ```

3. Click **Save**

### 4. Configure SMTP Settings (Production)

For production, you should use a custom SMTP server for better deliverability.

#### Option A: Use Supabase's Default SMTP (Development Only)
- Supabase provides a default SMTP for testing
- Limited to 3 emails per hour per user
- Not recommended for production
- No configuration needed - works out of the box

#### Option B: Configure Custom SMTP (Recommended for Production)

1. In Authentication section, click **Settings**
2. Scroll to **SMTP Settings**
3. Click **Enable Custom SMTP**

**Popular SMTP Providers:**

##### Using Gmail
```
SMTP Host: smtp.gmail.com
SMTP Port: 587
SMTP User: your-email@gmail.com
SMTP Password: your-app-password (not your regular password!)
Sender Email: your-email@gmail.com
Sender Name: Academix School System
```

**Note**: For Gmail, you need to create an "App Password":
1. Go to Google Account settings
2. Security → 2-Step Verification
3. App passwords → Generate new app password
4. Use that password in SMTP settings

##### Using SendGrid
```
SMTP Host: smtp.sendgrid.net
SMTP Port: 587
SMTP User: apikey
SMTP Password: your-sendgrid-api-key
Sender Email: noreply@yourdomain.com
Sender Name: Academix School System
```

##### Using Mailgun
```
SMTP Host: smtp.mailgun.org
SMTP Port: 587
SMTP User: postmaster@yourdomain.com
SMTP Password: your-mailgun-password
Sender Email: noreply@yourdomain.com
Sender Name: Academix School System
```

##### Using AWS SES
```
SMTP Host: email-smtp.us-east-1.amazonaws.com
SMTP Port: 587
SMTP User: your-ses-smtp-username
SMTP Password: your-ses-smtp-password
Sender Email: noreply@yourdomain.com
Sender Name: Academix School System
```

4. Click **Save**
5. Click **Send Test Email** to verify configuration

### 5. Configure Site URL

1. In Authentication section, click **URL Configuration**
2. Set **Site URL** to your production domain:
   ```
   https://yourdomain.com
   ```
   
   For local development:
   ```
   http://localhost:8080
   ```

3. Add **Redirect URLs** (one per line):
   ```
   https://yourdomain.com/reset-password
   https://yourdomain.com/login
   http://localhost:8080/reset-password
   http://localhost:8080/login
   ```

4. Click **Save**

### 6. Test Email Configuration

#### Test Forgot Password Flow

1. Go to your login page
2. Click "Forgot password?"
3. Enter a registered email address
4. Click "Send Reset Instructions"
5. Check email inbox (and spam folder)
6. Verify email arrives within 1-2 minutes
7. Click the reset link
8. Verify it redirects to `/reset-password` page
9. Create new password
10. Verify you can log in with new password

#### Test Email Change Flow

1. Log in to your account
2. Go to Settings → Account
3. Enter new email address
4. Enter your password
5. Click "Update Email"
6. Check new email inbox
7. Click verification link
8. Verify email is updated
9. Log out and log in with new email

## Troubleshooting

### Emails Not Arriving

**Check 1: Spam Folder**
- Check spam/junk folder
- Mark as "Not Spam" if found there

**Check 2: SMTP Configuration**
1. Go to Authentication → Settings → SMTP
2. Click "Send Test Email"
3. If test fails, check SMTP credentials
4. Verify SMTP port (usually 587 or 465)

**Check 3: Rate Limits**
- Default Supabase SMTP: 3 emails/hour per user
- Custom SMTP: Check your provider's limits
- Wait and try again if rate limited

**Check 4: Email Provider Blocking**
- Some email providers block automated emails
- Try different email address
- Use custom SMTP with verified domain

**Check 5: Supabase Logs**
1. Go to Logs → Auth Logs
2. Look for email send events
3. Check for errors

### Reset Link Not Working

**Check 1: Link Expired**
- Reset links expire after 1 hour
- Request new reset link

**Check 2: Redirect URL Mismatch**
1. Go to Authentication → Email Templates
2. Verify Redirect URL matches your domain
3. Should be: `https://yourdomain.com/reset-password`

**Check 3: Site URL Configuration**
1. Go to Authentication → URL Configuration
2. Verify Site URL is correct
3. Verify Redirect URLs include reset-password page

**Check 4: Already Used**
- Reset links can only be used once
- Request new reset link if needed

### Email Change Not Working

**Check 1: Verification Email**
- Check new email inbox (and spam)
- Verification link must be clicked

**Check 2: Password Incorrect**
- Verify you're entering correct current password
- Try resetting password if forgotten

**Check 3: Email Already Exists**
- Email must be unique in system
- Try different email address

## Security Best Practices

### Email Security
- ✅ Use custom SMTP with verified domain
- ✅ Enable SPF, DKIM, DMARC records
- ✅ Use strong SMTP password
- ✅ Rotate SMTP credentials regularly
- ✅ Monitor email delivery rates

### Password Reset Security
- ✅ Links expire after 1 hour
- ✅ Links can only be used once
- ✅ Only registered users can request reset
- ✅ No password hints or recovery questions
- ✅ Secure token generation by Supabase

### Rate Limiting
- ✅ Supabase enforces rate limits
- ✅ Prevents email spam/abuse
- ✅ 3 emails/hour with default SMTP
- ✅ Custom SMTP has higher limits

## Production Checklist

Before going live, verify:

- [ ] Custom SMTP configured (not using default)
- [ ] SMTP credentials tested and working
- [ ] Site URL set to production domain
- [ ] Redirect URLs include production domain
- [ ] Email templates customized with branding
- [ ] Test emails arriving in inbox (not spam)
- [ ] Reset password flow tested end-to-end
- [ ] Email change flow tested end-to-end
- [ ] SPF/DKIM/DMARC records configured
- [ ] Email delivery monitoring set up

## Email Template Customization

### Branding Your Emails

You can customize email templates with your school's branding:

```html
<div style="font-family: Arial, sans-serif; max-width: 600px; margin: 0 auto;">
  <!-- Header with Logo -->
  <div style="background-color: #4F46E5; padding: 20px; text-align: center;">
    <img src="https://yourdomain.com/logo.png" alt="School Logo" style="height: 60px;">
    <h1 style="color: white; margin: 10px 0 0 0;">Mount Olivet Methodist Academy</h1>
  </div>
  
  <!-- Content -->
  <div style="padding: 30px; background-color: #f9fafb;">
    <h2 style="color: #1f2937;">Reset Your Password</h2>
    <p style="color: #4b5563; line-height: 1.6;">
      Someone requested a password reset for your Academix account.
    </p>
    <p style="margin: 30px 0;">
      <a href="{{ .ConfirmationURL }}" 
         style="background-color: #4F46E5; 
                color: white; 
                padding: 14px 28px; 
                text-decoration: none; 
                border-radius: 6px; 
                display: inline-block;
                font-weight: 600;">
        Reset Password
      </a>
    </p>
    <p style="color: #6b7280; font-size: 14px;">
      If you didn't request this, you can safely ignore this email.
    </p>
    <p style="color: #6b7280; font-size: 14px;">
      This link will expire in 1 hour.
    </p>
  </div>
  
  <!-- Footer -->
  <div style="padding: 20px; text-align: center; background-color: #e5e7eb;">
    <p style="color: #6b7280; font-size: 12px; margin: 0;">
      © 2026 Mount Olivet Methodist Academy. All rights reserved.
    </p>
    <p style="color: #6b7280; font-size: 12px; margin: 5px 0 0 0;">
      Powered by Academix School Management System
    </p>
  </div>
</div>
```

## Monitoring & Maintenance

### Monitor Email Delivery

1. **Supabase Dashboard**
   - Go to Logs → Auth Logs
   - Filter by email events
   - Check success/failure rates

2. **SMTP Provider Dashboard**
   - Check delivery rates
   - Monitor bounce rates
   - Review spam complaints

3. **User Feedback**
   - Ask users if they received emails
   - Check spam folder reports
   - Monitor support tickets

### Regular Maintenance

- **Weekly**: Check email delivery logs
- **Monthly**: Review bounce rates
- **Quarterly**: Rotate SMTP credentials
- **Yearly**: Review and update email templates

## Cost Considerations

### Supabase Default SMTP
- **Free**: Included with Supabase
- **Limit**: 3 emails/hour per user
- **Best for**: Development and testing

### Custom SMTP Providers

**SendGrid**
- Free: 100 emails/day
- Paid: Starting at $15/month for 40,000 emails

**Mailgun**
- Free: 5,000 emails/month
- Paid: Pay as you go, $0.80 per 1,000 emails

**AWS SES**
- Free: 62,000 emails/month (if hosted on AWS)
- Paid: $0.10 per 1,000 emails

**Gmail**
- Free: 500 emails/day
- Paid (Google Workspace): 2,000 emails/day

## Support Resources

- **Supabase Docs**: https://supabase.com/docs/guides/auth
- **Email Templates**: https://supabase.com/docs/guides/auth/auth-email-templates
- **SMTP Setup**: https://supabase.com/docs/guides/auth/auth-smtp

---

**Status**: Configuration Required
**Priority**: High (Required for password reset)
**Estimated Setup Time**: 15-30 minutes
