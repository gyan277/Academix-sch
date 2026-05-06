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

interface CreateStaffUserRequest {
  email: string;
  password: string;
  full_name: string;
  position: string;
  school_id: string;
  staff_id: string;
  assigned_class?: string;
}

export const handler = async (event: any) => {
  // Handle CORS preflight
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

  // Only allow POST
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

  try {
    const body: CreateStaffUserRequest = JSON.parse(event.body || '{}');
    const { email, password, full_name, position, school_id, staff_id, assigned_class } = body;

    // Validate required fields
    if (!email || !password || !full_name || !position || !school_id || !staff_id) {
      return {
        statusCode: 400,
        headers: {
          'Access-Control-Allow-Origin': '*',
          'Content-Type': 'application/json'
        },
        body: JSON.stringify({
          error: 'Missing required fields: email, password, full_name, position, school_id, staff_id'
        })
      };
    }

    // Validate school exists
    const { data: schoolData, error: schoolError } = await supabaseAdmin
      .from('school_settings')
      .select('id, school_name')
      .eq('id', school_id)
      .single();

    if (schoolError || !schoolData) {
      return {
        statusCode: 400,
        headers: {
          'Access-Control-Allow-Origin': '*',
          'Content-Type': 'application/json'
        },
        body: JSON.stringify({ error: 'Invalid school ID provided' })
      };
    }

    // Validate staff record exists
    const { data: staffData, error: staffValidationError } = await supabaseAdmin
      .from('staff')
      .select('id, full_name, school_id')
      .eq('id', staff_id)
      .eq('school_id', school_id)
      .single();

    if (staffValidationError || !staffData) {
      return {
        statusCode: 400,
        headers: {
          'Access-Control-Allow-Origin': '*',
          'Content-Type': 'application/json'
        },
        body: JSON.stringify({
          error: 'Staff record not found or does not belong to the specified school'
        })
      };
    }

    // Create user in Supabase Auth
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
      if (authError.message.includes('already registered') || authError.message.includes('duplicate')) {
        return {
          statusCode: 400,
          headers: {
            'Access-Control-Allow-Origin': '*',
            'Content-Type': 'application/json'
          },
          body: JSON.stringify({
            error: `Email ${email} is already registered. Please use a different email address.`
          })
        };
      }
      return {
        statusCode: 400,
        headers: {
          'Access-Control-Allow-Origin': '*',
          'Content-Type': 'application/json'
        },
        body: JSON.stringify({
          error: `Failed to create user account: ${authError.message}`
        })
      };
    }

    const userId = authData.user?.id;
    if (!userId) {
      return {
        statusCode: 500,
        headers: {
          'Access-Control-Allow-Origin': '*',
          'Content-Type': 'application/json'
        },
        body: JSON.stringify({ error: 'User created but no ID returned' })
      };
    }

    // Check if user already exists in users table
    const { data: existingUser } = await supabaseAdmin
      .from('users')
      .select('id')
      .eq('id', userId)
      .single();

    // Only insert if user doesn't exist
    if (!existingUser) {
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
        // Clean up the auth user if users table creation fails
        await supabaseAdmin.auth.admin.deleteUser(userId);
        return {
          statusCode: 500,
          headers: {
            'Access-Control-Allow-Origin': '*',
            'Content-Type': 'application/json'
          },
          body: JSON.stringify({
            error: `Failed to create user record: ${usersError.message}`
          })
        };
      }
    }

    // If this is a teacher with an assigned class, create the teacher_classes record
    if (position.toLowerCase().includes('teacher') && assigned_class) {
      // Remove any existing assignment
      await supabaseAdmin
        .from('teacher_classes')
        .delete()
        .eq('teacher_id', userId)
        .eq('school_id', school_id);

      // Create new assignment
      await supabaseAdmin
        .from('teacher_classes')
        .insert([{
          teacher_id: userId,
          class: assigned_class,
          academic_year: '2024/2025',
          school_id: school_id
        }]);
    }

    // Success response
    return {
      statusCode: 200,
      headers: {
        'Access-Control-Allow-Origin': '*',
        'Content-Type': 'application/json'
      },
      body: JSON.stringify({
        success: true,
        user_id: userId,
        school_name: schoolData.school_name,
        assigned_class: assigned_class || null,
        message: `${position} account created successfully for ${full_name} at ${schoolData.school_name}${assigned_class ? ` (assigned to ${assigned_class})` : ''}`
      })
    };

  } catch (error: any) {
    console.error('Server error creating staff user:', error);
    return {
      statusCode: 500,
      headers: {
        'Access-Control-Allow-Origin': '*',
        'Content-Type': 'application/json'
      },
      body: JSON.stringify({ error: 'Internal server error' })
    };
  }
};
