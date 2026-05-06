# Netlify Serverless API Restructure - Complete Fix

## Problem Summary
The Express-based API wrapped with `serverless-http` was not working properly on Netlify. The `/api/create-staff-user` endpoint was returning HTML instead of JSON, causing teacher login creation to fail in production.

## Root Cause
Netlify serverless functions have a different architecture than traditional Express servers. Each API endpoint needs to be a standalone serverless function, not routed through Express.

## Solution Implemented

### 1. Created Individual Serverless Functions

**`netlify/functions/create-staff-user.ts`**
- Standalone serverless function for creating staff user accounts
- Handles authentication with Supabase service role key
- Creates user in Supabase Auth and users table
- Assigns teacher to class if applicable
- Returns proper JSON responses with CORS headers

**`netlify/functions/update-teacher-class.ts`**
- Standalone serverless function for updating teacher class assignments
- Validates staff member and school relationship
- Updates teacher_classes table
- Returns proper JSON responses with CORS headers

### 2. Updated Netlify Configuration

**`netlify.toml`** changes:
```toml
[functions]
node_bundler = "esbuild"

# Direct function mappings (no Express routing)
[[redirects]]
from = "/api/create-staff-user"
to = "/.netlify/functions/create-staff-user"
status = 200
force = true

[[redirects]]
from = "/api/update-teacher-class"
to = "/.netlify/functions/update-teacher-class"
status = 200
force = true
```

### 3. Key Differences from Express Approach

| Express (Old) | Serverless Functions (New) |
|--------------|---------------------------|
| Single `api.ts` file with routing | Individual function files |
| `serverless-http` wrapper | Native Netlify handler |
| Express middleware (cors, json) | Manual CORS headers |
| `req.body` parsing | `JSON.parse(event.body)` |
| `res.json()` responses | Return objects with statusCode, headers, body |

### 4. Function Structure

Each serverless function follows this pattern:

```typescript
export const handler = async (event: any) => {
  // 1. Handle CORS preflight
  if (event.httpMethod === 'OPTIONS') {
    return {
      statusCode: 200,
      headers: {
        'Access-Control-Allow-Origin': '*',
        'Access-Control-Allow-Headers': 'Content-Type',
        'Access-Control-Allow-Methods': 'POST, OPTIONS'
      },
      body: ''
    };
  }

  // 2. Validate HTTP method
  if (event.httpMethod !== 'POST') {
    return {
      statusCode: 405,
      headers: {
        'Access-Control-Allow-Origin': '*',
        'Content-Type': 'application/json'
      },
      body: JSON.stringify({ error: 'Method not allowed' })
    };
  }

  // 3. Parse request body
  const body = JSON.parse(event.body || '{}');

  // 4. Business logic here...

  // 5. Return response
  return {
    statusCode: 200,
    headers: {
      'Access-Control-Allow-Origin': '*',
      'Content-Type': 'application/json'
    },
    body: JSON.stringify({ success: true, data: result })
  };
};
```

## Environment Variables Required

Ensure these are set in Netlify dashboard:

1. `VITE_SUPABASE_URL` - Your Supabase project URL
2. `SUPABASE_SERVICE_ROLE_KEY` - Service role key (admin privileges)
3. `VITE_SUPABASE_ANON_KEY` - Anonymous key (for client-side)

## Deployment Steps

1. **Commit all changes:**
   ```bash
   git add .
   git commit -m "Restructure API to use Netlify serverless functions"
   git push origin main
   ```

2. **Netlify will auto-deploy** (if connected to GitHub)

3. **Verify environment variables** in Netlify dashboard:
   - Go to Site settings → Environment variables
   - Confirm all three variables are set

4. **Test the endpoints:**
   - Try creating a teacher account from the Registrar page
   - Check browser console for any errors
   - Verify the response is JSON (not HTML)

## Testing Locally

The serverless functions work differently in local vs production:

**Local development:**
- Uses Express server (`server/index.ts`)
- Routes defined in `server/routes/`
- Run with: `pnpm dev`

**Production (Netlify):**
- Uses serverless functions (`netlify/functions/`)
- Each endpoint is a separate function
- Deployed automatically on push

## Frontend Compatibility

No changes needed in the frontend! The API calls remain the same:

```typescript
// This works with both local Express and Netlify serverless
const response = await fetch('/api/create-staff-user', {
  method: 'POST',
  headers: { 'Content-Type': 'application/json' },
  body: JSON.stringify({ email, password, ... })
});
```

## Files Modified

✅ **Created:**
- `netlify/functions/create-staff-user.ts` - Staff user creation function
- `netlify/functions/update-teacher-class.ts` - Teacher class update function
- `NETLIFY_SERVERLESS_API_RESTRUCTURE.md` - This documentation

✅ **Modified:**
- `netlify.toml` - Updated redirects to point to individual functions

⚠️ **Deprecated (but kept for local dev):**
- `netlify/functions/api.ts` - Old Express wrapper (can be removed)
- `server/routes/create-staff-user.ts` - Still used for local dev
- `server/routes/update-teacher-class.ts` - Still used for local dev

## Troubleshooting

### Issue: Still getting HTML responses
**Solution:** Clear Netlify cache and redeploy
```bash
# In Netlify dashboard: Deploys → Trigger deploy → Clear cache and deploy site
```

### Issue: Environment variables not working
**Solution:** Check variable names match exactly (case-sensitive)
- `VITE_SUPABASE_URL` (not `SUPABASE_URL`)
- `SUPABASE_SERVICE_ROLE_KEY` (not `SUPABASE_KEY`)

### Issue: CORS errors
**Solution:** Ensure all responses include CORS headers:
```typescript
headers: {
  'Access-Control-Allow-Origin': '*',
  'Content-Type': 'application/json'
}
```

### Issue: Function timeout
**Solution:** Netlify free tier has 10s timeout. Optimize database queries or upgrade plan.

## Success Indicators

✅ Teacher login creation works on production
✅ API returns JSON (not HTML)
✅ No CORS errors in browser console
✅ Teacher class assignments work
✅ Multi-tenancy is preserved (school_id filtering)

## Next Steps

1. Deploy and test on Netlify production
2. Verify teacher account creation works
3. Test class assignment updates
4. Monitor Netlify function logs for any errors
5. Consider removing old `netlify/functions/api.ts` if everything works

## Production URL
https://academix-man.netlify.app

Test by creating a teacher account from the Registrar page!
