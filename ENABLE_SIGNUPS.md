# Enable Sign Ups in Supabase

## The Issue

If you're getting "An error occurred during authentication" when creating teachers, it's most likely because **sign ups are disabled** in Supabase.

## How to Fix

### Step 1: Go to Supabase Authentication Settings

1. Open your Supabase Dashboard: https://supabase.com/dashboard
2. Select your project
3. Click **Authentication** in the left sidebar
4. Click **Settings** (or **Providers**)

### Step 2: Enable Sign Ups

Look for one of these settings:
- **"Enable sign ups"**
- **"Allow new users to sign up"**
- **"Disable sign ups"** (toggle this OFF)

Make sure sign ups are **ENABLED** (turned ON).

### Step 3: Verify Email Settings

While you're there, also verify:
- ✅ **Enable email confirmations**: Should be **OFF** (disabled)
- ✅ **Enable sign ups**: Should be **ON** (enabled)

### Step 4: Save Changes

Click **Save** at the bottom of the page.

### Step 5: Test Again

1. Go back to your app
2. Try creating a teacher again
3. It should work now!

## Alternative: Check via SQL

You can also check if sign ups are enabled by looking at your project settings, but the dashboard is the easiest way.

## What This Does

When sign ups are disabled:
- `supabase.auth.signUp()` will fail with an authentication error
- Only existing users can login
- No new users can be created

When sign ups are enabled:
- Admins can create new teacher accounts
- The `signUp()` function works properly
- New users are created in `auth.users` table

## After Enabling

Once you enable sign ups:
1. New teachers will be created successfully
2. They'll be able to login immediately (since email confirmation is disabled)
3. The credentials dialog will show their email and password

Try it now! 🚀
