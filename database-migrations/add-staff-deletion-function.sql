-- Function to safely delete staff members and their associated user accounts
-- This ensures all related records are properly cleaned up

CREATE OR REPLACE FUNCTION delete_staff_member(staff_id_param UUID)
RETURNS JSON AS $$
DECLARE
  user_id_var UUID;
  staff_email TEXT;
  result JSON;
BEGIN
  -- Get staff email
  SELECT email INTO staff_email
  FROM staff
  WHERE id = staff_id_param;

  -- If staff has an email, check for associated user account
  IF staff_email IS NOT NULL THEN
    SELECT id INTO user_id_var
    FROM users
    WHERE email = staff_email;

    -- If user account exists, delete it (cascades to teacher_classes, etc.)
    IF user_id_var IS NOT NULL THEN
      -- Delete from teacher_classes
      DELETE FROM teacher_classes WHERE teacher_id = user_id_var;
      
      -- Delete from users table
      DELETE FROM users WHERE id = user_id_var;
      
      -- Note: Deleting from auth.users requires admin privileges
      -- This should be handled by the application layer or a separate admin function
    END IF;
  END IF;

  -- Delete the staff record
  DELETE FROM staff WHERE id = staff_id_param;

  -- Return success result
  result := json_build_object(
    'success', true,
    'message', 'Staff member deleted successfully',
    'staff_id', staff_id_param,
    'user_deleted', user_id_var IS NOT NULL
  );

  RETURN result;

EXCEPTION WHEN OTHERS THEN
  -- Return error result
  result := json_build_object(
    'success', false,
    'message', SQLERRM,
    'staff_id', staff_id_param
  );
  RETURN result;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Grant execute permission to authenticated users
GRANT EXECUTE ON FUNCTION delete_staff_member(UUID) TO authenticated;

-- Add comment
COMMENT ON FUNCTION delete_staff_member IS 'Safely deletes a staff member and their associated user account with all related records';
