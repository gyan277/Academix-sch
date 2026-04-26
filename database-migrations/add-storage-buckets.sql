-- Create Storage Buckets for School Assets
-- This allows schools to upload logos, signatures, and other documents

-- Create school-assets bucket for logos and signatures
INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES (
  'school-assets',
  'school-assets',
  true, -- Public bucket so images can be accessed in PDFs
  5242880, -- 5MB limit
  ARRAY['image/png', 'image/jpeg', 'image/jpg', 'image/gif', 'image/webp']
)
ON CONFLICT (id) DO NOTHING;

-- RLS Policies for school-assets bucket

-- Allow authenticated users to upload files to their school folder
CREATE POLICY "Users can upload to their school folder"
ON storage.objects FOR INSERT
TO authenticated
WITH CHECK (
  bucket_id = 'school-assets' AND
  (storage.foldername(name))[1] IN (
    SELECT school_id::text FROM users WHERE id = auth.uid()
  )
);

-- Allow authenticated users to view files from their school folder
CREATE POLICY "Users can view their school assets"
ON storage.objects FOR SELECT
TO authenticated
USING (
  bucket_id = 'school-assets' AND
  (storage.foldername(name))[1] IN (
    SELECT school_id::text FROM users WHERE id = auth.uid()
  )
);

-- Allow authenticated users to update files in their school folder
CREATE POLICY "Users can update their school assets"
ON storage.objects FOR UPDATE
TO authenticated
USING (
  bucket_id = 'school-assets' AND
  (storage.foldername(name))[1] IN (
    SELECT school_id::text FROM users WHERE id = auth.uid()
  )
);

-- Allow authenticated users to delete files from their school folder
CREATE POLICY "Users can delete their school assets"
ON storage.objects FOR DELETE
TO authenticated
USING (
  bucket_id = 'school-assets' AND
  (storage.foldername(name))[1] IN (
    SELECT school_id::text FROM users WHERE id = auth.uid()
  )
);

-- Allow public read access (needed for PDFs to load images)
CREATE POLICY "Public can view school assets"
ON storage.objects FOR SELECT
TO public
USING (bucket_id = 'school-assets');

COMMENT ON POLICY "Users can upload to their school folder" ON storage.objects IS 
  'Allows users to upload logos and signatures to their school folder';
COMMENT ON POLICY "Public can view school assets" ON storage.objects IS 
  'Allows public access to school logos and signatures for use in PDFs and documents';
