# School Branding Implementation (Logo & Signature)

## Overview
Implemented proper image upload to Supabase Storage and integrated school logo and headmaster signature into PDF report cards.

## What Was Implemented

### 1. Supabase Storage Bucket
Created a public storage bucket called `school-assets` for storing:
- School logos
- Headmaster signatures
- Other school documents

**Features:**
- 5MB file size limit
- Supports: PNG, JPG, JPEG, GIF, WEBP
- Public read access (needed for PDFs)
- Multi-tenancy: Each school has its own folder (by school_id)
- RLS policies enforce school isolation

### 2. Settings Page Upload
**Before:**
- Images converted to base64 and stored in database (bloated)
- No actual file upload
- Not used in PDFs

**After:**
- Images uploaded to Supabase Storage
- Get permanent public URLs
- URLs saved to database (lightweight)
- Automatic upload on file selection
- Preview shown immediately
- Old files automatically replaced

**Upload Flow:**
1. User selects image file
2. Validates file size (max 5MB) and type (images only)
3. Shows preview immediately
4. Uploads to Supabase Storage at `school-assets/{school_id}/logo.png` or `signature.png`
5. Gets public URL
6. Saves URL to `school_settings` table
7. Shows success toast

### 3. PDF Report Card Integration
**Logo:**
- Displayed at top-left of report card (30x30px)
- Positioned above school name
- Graceful fallback if logo not available

**Signature:**
- Displayed in signature section at bottom (40x15px)
- Replaces text placeholder
- Graceful fallback to line if signature not available

**Footer:**
- Now shows school name instead of generic "School Management System"

### 4. Academic Page Enhancement
- Loads school logo and signature on page load
- Passes them to PDF generation function
- Cached for all report card downloads in the session

## Database Setup

### Step 1: Create Storage Bucket
Run `database-migrations/add-storage-buckets.sql` in Supabase SQL Editor:
```sql
-- Creates school-assets bucket with RLS policies
```

### Step 2: Verify Bucket Creation
In Supabase Dashboard:
1. Go to Storage
2. You should see `school-assets` bucket
3. Click on it - it should be empty initially

## How to Use

### Upload Logo and Signature
1. Go to **Settings** page
2. Scroll to **Assets** section
3. Click "Click to upload" under School Logo
4. Select your school logo (PNG/JPG, max 5MB)
5. Preview appears immediately
6. Image is automatically uploaded and saved
7. Repeat for Headmaster's Signature

### Generate Report Cards with Branding
1. Go to **Academic** page
2. Click **Reports** tab
3. Select class, term, and grading period
4. Click "Generate Reports"
5. Click "Download Report Card" for any student
6. PDF will include:
   - School logo at top
   - School name
   - All academic data
   - Headmaster's signature at bottom

### Replace Logo or Signature
1. Go to **Settings** page
2. Find the existing logo/signature preview
3. Click "Change" button
4. Select new image
5. Old image is automatically replaced in storage
6. New URL saved to database

### Remove Logo or Signature
1. Go to **Settings** page
2. Find the existing logo/signature preview
3. Click "Remove" button
4. Image removed from preview
5. URL cleared from database
6. File remains in storage (can be manually deleted)

## File Structure

### Storage Organization
```
school-assets/
├── {school_id_1}/
│   ├── logo.png
│   └── signature.png
├── {school_id_2}/
│   ├── logo.jpg
│   └── signature.jpg
└── ...
```

### Database Schema
```sql
school_settings:
- school_logo_url: TEXT (public URL from storage)
- headmaster_signature_url: TEXT (public URL from storage)
```

## Technical Details

### Image Loading in PDFs
jsPDF requires images to be:
1. Loaded from a URL (public access required)
2. Base64 encoded, OR
3. Data URL format

We use public URLs from Supabase Storage, which jsPDF loads directly.

### Error Handling
- File size validation (max 5MB)
- File type validation (images only)
- Upload errors show toast notification
- PDF generation continues even if images fail to load
- Graceful fallbacks for missing images

### Performance
- Images cached in component state
- Only loaded once per page visit
- Public URLs are CDN-backed by Supabase
- No database bloat (only URLs stored)

## Security

### RLS Policies
- Users can only upload to their school's folder
- Users can only view/update/delete their school's assets
- Public read access for PDF generation
- School isolation enforced by folder structure

### File Validation
- Size limit: 5MB
- Type limit: Images only (PNG, JPG, JPEG, GIF, WEBP)
- Automatic file replacement (no duplicates)

## Troubleshooting

### Logo/Signature Not Showing in PDF
1. Check if URL is saved in database:
   ```sql
   SELECT school_logo_url, headmaster_signature_url 
   FROM school_settings 
   WHERE school_id = 'your-school-id';
   ```
2. Check if file exists in storage (Supabase Dashboard > Storage > school-assets)
3. Check browser console for errors
4. Verify URL is publicly accessible (open in new tab)

### Upload Fails
1. Check file size (must be < 5MB)
2. Check file type (must be image)
3. Check browser console for errors
4. Verify storage bucket exists
5. Verify RLS policies are set up

### Images Not Loading
1. Check if storage bucket is public
2. Check if RLS policies allow public read
3. Verify URLs are correct format
4. Check network tab for failed requests

## Files Modified
- `database-migrations/add-storage-buckets.sql` - Storage bucket setup
- `client/pages/Settings.tsx` - Upload functions updated
- `client/lib/export-utils.ts` - PDF generation updated
- `client/pages/Academic.tsx` - Load and pass logo/signature

## Files Created
- `SCHOOL_BRANDING_IMPLEMENTATION.md` - This documentation

## Future Enhancements
- Add logo to other reports (attendance, enrollment, finance)
- Add school motto/tagline to reports
- Support multiple signatures (headmaster, class teacher)
- Add watermark option
- Support school seal/stamp
- Add branding to login page
- Customize report card layout/colors per school

## Notes
- Logo appears on all report cards generated after upload
- Signature appears on all report cards generated after upload
- Old report cards (already downloaded) won't have the branding
- Images are publicly accessible (needed for PDFs)
- Each school's images are isolated by folder
- File names are standardized (logo.ext, signature.ext)
- File extension preserved from original upload
