-- Add status column to users table for teacher account management
-- This migration adds the status field to track active/inactive teacher accounts

ALTER TABLE public.users 
ADD COLUMN IF NOT EXISTS status TEXT NOT NULL DEFAULT 'active' 
CHECK (status IN ('active', 'inactive'));

-- Create index for performance when filtering by status
CREATE INDEX IF NOT EXISTS idx_users_status ON public.users(status);

-- Update existing users to have active status (if column was just added)
UPDATE public.users 
SET status = 'active' 
WHERE status IS NULL;
