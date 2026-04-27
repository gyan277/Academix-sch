# How to Force PostgREST Schema Refresh in Supabase

The "Could not find table in schema cache" error means PostgREST hasn't reloaded the schema yet.

## Method 1: Restart PostgREST via Supabase Dashboard (RECOMMENDED)

1. Go to your Supabase Dashboard: https://supabase.com/dashboard
2. Select your project
3. Go to **Settings** (gear icon in left sidebar)
4. Click **API** in the settings menu
5. Scroll down to find **"Restart API"** or **"Restart PostgREST"** button
6. Click it and wait 10-15 seconds
7. Refresh your Academix app (F5)

## Method 2: Wait for Automatic Refresh

PostgREST automatically refreshes its schema cache every few minutes. You can:
1. Wait 2-3 minutes
2. Refresh your app (F5)
3. Try again

## Method 3: Use SQL NOTIFY (Already Tried)

We already ran `NOTIFY pgrst, 'reload schema';` but it didn't work immediately.
This might take a few minutes to process.

## Method 4: Restart Your Supabase Project (NUCLEAR OPTION)

If nothing else works:
1. Go to Supabase Dashboard
2. Settings → General
3. Look for "Pause project" or "Restart project"
4. Pause and then unpause (or restart)
5. Wait 30 seconds
6. Try again

## After PostgREST Restarts

Once the schema is refreshed:
1. The "Could not find table" error will disappear
2. You'll see "No Class Assigned" message
3. Then follow the instructions to assign a class to the teacher

## Quick Check

Run this in Supabase SQL Editor to verify tables exist:

```sql
SELECT table_name 
FROM information_schema.tables 
WHERE table_schema = 'public' 
AND table_name IN ('teachers', 'teacher_fee_collections')
ORDER BY table_name;
```

If you see both tables, the issue is just the schema cache, not the tables themselves.
