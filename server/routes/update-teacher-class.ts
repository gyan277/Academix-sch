import { RequestHandler } from "express";
import { createClient } from '@supabase/supabase-js';

// Initialize Supabase admin client
const supabaseAdmin = createClient(
  process.env.VITE_SUPABASE_URL!,
  process.env.SUPABASE_SERVICE_ROLE_KEY!,
  {
    auth: {
      autoRefreshToken: false,
      persistSession: false
    }
  }
);

interface UpdateTeacherClassRequest {
  staff_id: string;
  new_class: string | null;
  school_id: string;
}

export const handleUpdateTeacherClass: RequestHandler = async (req, res) => {
  try {
    const { staff_id, new_class, school_id }: UpdateTeacherClassRequest = req.body;

    // Validate required fields
    if (!staff_id || !school_id) {
      return res.status(400).json({
        error: 'Missing required fields: staff_id, school_id'
      });
    }

    // SECURITY: Validate that the staff member exists and belongs to the correct school
    const { data: staffData, error: staffValidationError } = await supabaseAdmin
      .from('staff')
      .select('id, full_name, position, school_id')
      .eq('id', staff_id)
      .eq('school_id', school_id)
      .single();

    if (staffValidationError || !staffData) {
      console.error('Staff validation failed:', staffValidationError);
      return res.status(400).json({
        error: 'Staff member not found or does not belong to the specified school'
      });
    }

    // Get the teacher's user ID from the users table
    const { data: userData, error: userError } = await supabaseAdmin
      .from('users')
      .select('id')
      .eq('school_id', school_id)
      .ilike('full_name', staffData.full_name)
      .eq('role', 'teacher')
      .single();

    if (userError || !userData) {
      console.log('No user account found for this staff member - that\'s okay');
    }

    // If removing class assignment (new_class is null or empty)
    if (!new_class) {
      if (userData) {
        // Remove existing teacher_classes record
        const { error: deleteError } = await supabaseAdmin
          .from('teacher_classes')
          .delete()
          .eq('teacher_id', userData.id)
          .eq('school_id', school_id);

        if (deleteError) {
          console.warn('Failed to remove teacher class assignment:', deleteError);
        }
      }

      return res.json({
        success: true,
        message: `Removed class assignment for ${staffData.full_name}`,
        assigned_class: null
      });
    }

    // If assigning a new class
    if (userData) {
      // First, remove any existing assignment
      await supabaseAdmin
        .from('teacher_classes')
        .delete()
        .eq('teacher_id', userData.id)
        .eq('school_id', school_id);

      // Then create new assignment
      const { error: insertError } = await supabaseAdmin
        .from('teacher_classes')
        .insert([{
          teacher_id: userData.id,
          class: new_class,
          academic_year: '2024/2025',
          school_id: school_id
        }]);

      if (insertError) {
        console.error('Failed to create teacher class assignment:', insertError);
        return res.status(500).json({
          error: `Failed to assign class: ${insertError.message}`
        });
      }
    }

    // Success response
    res.json({
      success: true,
      message: `Successfully assigned ${staffData.full_name} to ${new_class}`,
      assigned_class: new_class
    });

  } catch (error) {
    console.error('Server error updating teacher class:', error);
    res.status(500).json({
      error: 'Internal server error'
    });
  }
};