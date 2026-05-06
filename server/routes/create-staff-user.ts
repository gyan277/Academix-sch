import { RequestHandler } from "express";
import { createClient } from '@supabase/supabase-js';

// Initialize Supabase admin client
const supabaseAdmin = createClient(
  process.env.VITE_SUPABASE_URL!,
  process.env.SUPABASE_SERVICE_ROLE_KEY!, // Service role key for admin operations
  {
    auth: {
      autoRefreshToken: false,
      persistSession: false
    }
  }
);

interface CreateStaffUserRequest {
  email: string;
  password: string;
  full_name: string;
  position: string;
  school_id: string;
  staff_id: string;
  assigned_class?: string; // Optional class assignment for teachers
}

export const handleCreateStaffUser: RequestHandler = async (req, res) => {
  try {
    const { email, password, full_name, position, school_id, staff_id, assigned_class }: CreateStaffUserRequest = req.body;

    // Validate required fields
    if (!email || !password || !full_name || !position || !school_id || !staff_id) {
      return res.status(400).json({
        error: 'Missing required fields: email, password, full_name, position, school_id, staff_id'
      });
    }

    // SECURITY: Validate that the school_id exists and is valid
    const { data: schoolData, error: schoolError } = await supabaseAdmin
      .from('school_settings')
      .select('id, school_name')
      .eq('id', school_id)
      .single();

    if (schoolError || !schoolData) {
      console.error('Invalid school_id:', school_id, schoolError);
      return res.status(400).json({
        error: 'Invalid school ID provided'
      });
    }

    // SECURITY: Validate that the staff record exists and belongs to the correct school
    const { data: staffData, error: staffValidationError } = await supabaseAdmin
      .from('staff')
      .select('id, full_name, school_id')
      .eq('id', staff_id)
      .eq('school_id', school_id)
      .single();

    if (staffValidationError || !staffData) {
      console.error('Staff validation failed:', staffValidationError);
      return res.status(400).json({
        error: 'Staff record not found or does not belong to the specified school'
      });
    }

    // If class is assigned, validate and fix school_id mismatches
    if (assigned_class) {
      // First, check if there are students in the class
      const { data: classStudents, error: classError } = await supabaseAdmin
        .from('students')
        .select('id, school_id')
        .eq('class', assigned_class)
        .eq('status', 'active');

      if (classError) {
        console.error('Class validation error:', classError);
        return res.status(400).json({
          error: 'Failed to validate class assignment'
        });
      }

      // If there are students with different school_ids, update them to match
      if (classStudents && classStudents.length > 0) {
        const studentsToUpdate = classStudents.filter(student => 
          student.school_id !== school_id
        );

        if (studentsToUpdate.length > 0) {
          console.log(`Auto-fixing ${studentsToUpdate.length} students in ${assigned_class} to match school_id`);
          
          // Update students to have the correct school_id
          const { error: updateError } = await supabaseAdmin
            .from('students')
            .update({ school_id: school_id })
            .in('id', studentsToUpdate.map(s => s.id));

          if (updateError) {
            console.warn('Failed to auto-fix student school_ids:', updateError);
            // Don't fail the entire operation, just log the warning
          }
        }
      }
    }

    // Create user in Supabase Auth with proper metadata
    const { data: authData, error: authError } = await supabaseAdmin.auth.admin.createUser({
      email,
      password,
      email_confirm: true,
      user_metadata: {
        role: position.toLowerCase().includes('teacher') ? 'teacher' : 'staff',
        full_name,
        position,
        school_id,
        staff_id,
        assigned_class: assigned_class || null
      }
    });

    if (authError) {
      // Check if it's a duplicate email error
      if (authError.message.includes('already registered') || authError.message.includes('duplicate')) {
        return res.status(400).json({
          error: `Email ${email} is already registered. Please use a different email address.`
        });
      }
      console.error('Auth creation error:', authError);
      return res.status(400).json({
        error: `Failed to create user account: ${authError.message}`
      });
    }

    const userId = authData.user?.id;
    if (!userId) {
      return res.status(500).json({
        error: 'User created but no ID returned'
      });
    }

    // Check if user already exists in users table
    const { data: existingUser, error: checkError } = await supabaseAdmin
      .from('users')
      .select('id')
      .eq('id', userId)
      .single();

    if (checkError && checkError.code !== 'PGRST116') { // PGRST116 = no rows returned
      console.error('Error checking existing user:', checkError);
    }

    // Only insert if user doesn't exist
    if (!existingUser) {
      // Create users table record with proper multi-tenancy
      const { error: usersError } = await supabaseAdmin
        .from('users')
        .insert([{
          id: userId,
          email,
          role: position.toLowerCase().includes('teacher') ? 'teacher' : 'staff',
          full_name,
          school_id
        }]);

      if (usersError) {
        console.error('Users table error:', usersError);
        // Clean up the auth user if users table creation fails
        await supabaseAdmin.auth.admin.deleteUser(userId);
        return res.status(500).json({
          error: `Failed to create user record: ${usersError.message}`
        });
      }
    } else {
      console.log('User already exists in users table, skipping insert');
    }

    // If this is a teacher with an assigned class, create the teacher_classes record
    if (position.toLowerCase().includes('teacher') && assigned_class) {
      // First, remove any existing assignment for this teacher
      await supabaseAdmin
        .from('teacher_classes')
        .delete()
        .eq('teacher_id', userId)
        .eq('school_id', school_id);

      // Then create new assignment
      const { error: teacherClassError } = await supabaseAdmin
        .from('teacher_classes')
        .insert([{
          teacher_id: userId,
          class: assigned_class,
          academic_year: '2024/2025',
          school_id: school_id
        }]);

      if (teacherClassError) {
        console.error('Teacher class assignment error:', teacherClassError);
        // Don't fail the entire operation, but log the error
        console.warn(`Teacher account created but class assignment failed: ${teacherClassError.message}`);
      }
    }

    // Success response
    res.json({
      success: true,
      user_id: userId,
      school_name: schoolData.school_name,
      assigned_class: assigned_class || null,
      message: `${position} account created successfully for ${full_name} at ${schoolData.school_name}${assigned_class ? ` (assigned to ${assigned_class})` : ''}`
    });

  } catch (error) {
    console.error('Server error creating staff user:', error);
    res.status(500).json({
      error: 'Internal server error'
    });
  }
};