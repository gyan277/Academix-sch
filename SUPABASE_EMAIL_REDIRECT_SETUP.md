# Supabase Email Confirmation Redirect Setup

## Overview
Configure Supabase to redirect users to a custom confirmation page after they click the email verification link.

---

## Steps to Configure in Supabase

### 1. Go to Supabase Dashboard

1. Open your Supabase project
2. Click on **Authentication** in the left sidebar
3. Click on **URL Configuration**

### 2. Set Redirect URLs

Find the **Redirect URLs** section and add:

**Site URL** (if not set):
```
http://localhost:8082
```
or your production URL:
```
https://your-domain.com
```

**Redirect URLs** (add these):
```
http://localhost:8082/email-confirmed
http://localhost:8082/login
https://your-domain.com/email-confirmed
https://your-domain.com/login
```

### 3. Configure Email Templates

1. Still in **Authentication** settings
2. Click on **Email Templates**
3. Select **Confirm signup**

**Update the template** to use your redirect URL:

```html
<h2>Confirm your signup</h2>

<p>Follow this link to confirm your email:</p>
<p><a href="{{ .ConfirmationURL }}">Confirm your email</a></p>

<p>Or copy and paste this URL into your browser:</p>
<p>{{ .ConfirmationURL }}</p>
```

The `{{ .ConfirmationURL }}` will automatically include your redirect URL.

### 4. Set the Confirmation URL in Project Settings

1. Go to **Project Settings** (gear icon)
2. Click on **Authentication**
3. Scroll to **Email Auth**
4. Find **Confirm Email Redirect URL**
5. Set it to:
```
http://localhost:8082/email-confirmed
```

---

## Alternative: Disable Email Confirmation

If you don't want email confirmation at all (for testing):

1. Go to **Authentication** → **Providers**
2. Click on **Email**
3. **Disable** "Confirm email"
4. Click **Save**

This allows users to login immediately without email verification.

---

## How It Works

### With Email Confirmation Enabled:

1. **Admin creates teacher account**
2. **Teacher receives email** with confirmation link
3. **Teacher clicks link** → Redirected to `/email-confirmed` page
4. **Page shows**: "Email Confirmed! Redirecting to login..."
5. **Auto-redirects** to login page after 5 seconds
6. **Teacher can login** with their credentials

### With Email Confirmation Disabled:

1. **Admin creates teacher account**
2. **Teacher can login immediately** (no email needed)

---

## Recommended Setup for Production

### For Mount Olivet Methodist Academy:

**Option 1: No Email Confirmation** (Simpler)
- Disable email confirmation in Supabase
- Admin creates accounts, teachers login immediately
- ✅ Easier for users
- ✅ No email server needed

**Option 2: With Email Confirmation** (More Secure)
- Keep email confirmation enabled
- Set redirect URL to your domain
- Teachers must verify email before login
- ✅ More secure
- ✅ Verifies email addresses are real

---

## Current Setup (Recommended)

Based on your earlier setup, **email confirmation is already disabled**:

```sql
-- From your setup
UPDATE auth.config 
SET enable_signup = false,
    enable_email_confirmations = false;
```

This means:
- ✅ Teachers can login immediately after account creation
- ✅ No email verification needed
- ✅ Simpler workflow

---

## If You Want to Enable Email Confirmation

Run this in Supabase SQL Editor:

```sql
-- Enable email confirmations
UPDATE auth.config 
SET enable_email_confirmations = true;
```

Then configure the redirect URLs as described above.

---

## Testing

### Test Email Confirmation Flow:

1. **Create a test teacher account**
2. **Check the email** (use a real email address)
3. **Click the confirmation link**
4. **Should redirect** to `/email-confirmed` page
5. **Should auto-redirect** to login after 5 seconds
6. **Login** with the credentials

---

## Troubleshooting

### Issue: Email not received
- Check spam folder
- Verify email provider settings in Supabase
- Check Supabase logs for email sending errors

### Issue: Redirect not working
- Verify redirect URL is added to allowed URLs
- Check browser console for errors
- Ensure `/email-confirmed` route exists in your app

### Issue: "Invalid redirect URL" error
- Add your URL to the Redirect URLs list in Supabase
- Include both http://localhost and https://domain.com

---

## Summary

**Current Status**: Email confirmation is **disabled** ✅

**To Enable**:
1. Enable in Supabase settings
2. Add redirect URLs
3. Configure email template
4. Test the flow

**Recommended**: Keep it **disabled** for simplicity, since admin creates all accounts manually.

---

## Files Created

- ✅ `client/pages/EmailConfirmed.tsx` - Confirmation page (ready to use)
- ✅ Route added to `client/App.tsx`

Everything is ready! Just configure Supabase settings if you want to enable email confirmation.
