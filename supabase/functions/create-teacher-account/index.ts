// Supabase Edge Function for creating teacher accounts
// Deploy this to Supabase: supabase functions deploy create-teacher-account

import { serve } from 'https://deno.land/std@0.168.0/http/server.ts'
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

serve(async (req) => {
  // Handle CORS preflight
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders })
  }

  try {
    // Create Supabase admin client
    const supabaseAdmin = createClient(
      Deno.env.get('SUPABASE_URL') ?? '',
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? '',
      {
        auth: {
          autoRefreshToken: false,
          persistSession: false
        }
      }
    )

    // Parse request body
    const { email, password, full_name, position, school_id, staff_id, assigned_class } = await req.json()

    // Log for debugging
    console.log('Received request:', { email, full_name, position, assigned_class });

    // Validate required fields
    if (!email || !password || !full_name || !position || !school_id || !staff_id) {
      return new Response(
        JSON.stringify({ error: 'Missing required fields' }),
        { status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      )
    }

    // Validate school exists
    const { data: schoolData, error: schoolError } = await supabaseAdmin
      .from('school_settings')
      .select('id, school_name')
      .eq('id', school_id)
      .single()

    if (schoolError || !schoolData) {
      return new Response(
        JSON.stringify({ error: 'Invalid school ID' }),
        { status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      )
    }

    // Validate staff record exists
    const { data: staffData, error: staffError } = await supabaseAdmin
      .from('staff')
      .select('id, full_name, school_id')
      .eq('id', staff_id)
      .eq('school_id', school_id)
      .single()

    if (staffError || !staffData) {
      return new Response(
        JSON.stringify({ error: 'Staff record not found' }),
        { status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      )
    }

    // Create user in Supabase Auth
    const { data: authData, error: authError } = await supabaseAdmin.auth.admin.createUser({
      email,
      password,
      email_confirm: true,
      user_metadata: {
        role: position.toLowerCase().includes('teacher') ? 'teacher' : 'admin',
        full_name,
        position,
        school_id,
        staff_id,
        assigned_class: assigned_class || null
      }
    })

    if (authError) {
      return new Response(
        JSON.stringify({ error: `Failed to create user: ${authError.message}` }),
        { status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      )
    }

    const userId = authData.user?.id
    if (!userId) {
      return new Response(
        JSON.stringify({ error: 'User created but no ID returned' }),
        { status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      )
    }

    // Check if user already exists in users table
    const { data: existingUser } = await supabaseAdmin
      .from('users')
      .select('id')
      .eq('id', userId)
      .single()

    // Only insert if user doesn't exist
    if (!existingUser) {
      const { error: usersError } = await supabaseAdmin
        .from('users')
        .insert([{
          id: userId,
          email,
          role: position.toLowerCase().includes('teacher') ? 'teacher' : 'admin',
          full_name,
          school_id
        }])

      if (usersError) {
        // Clean up auth user if users table creation fails
        await supabaseAdmin.auth.admin.deleteUser(userId)
        return new Response(
          JSON.stringify({ error: `Failed to create user record: ${usersError.message}` }),
          { status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
        )
      }
    }

    // If teacher with assigned class, create teacher_classes record
    if (position.toLowerCase().includes('teacher') && assigned_class) {
      console.log('Creating teacher_classes record with class:', assigned_class);
      
      // Remove any existing assignment
      await supabaseAdmin
        .from('teacher_classes')
        .delete()
        .eq('teacher_id', userId)
        .eq('school_id', school_id)

      // Create new assignment using the school's current academic year
      const { error: classError } = await supabaseAdmin
        .from('teacher_classes')
        .insert([{
          teacher_id: userId,
          class: assigned_class,
          academic_year: schoolData.current_academic_year,
          school_id: school_id
        }])
      
      if (classError) {
        console.error('Error creating teacher_classes:', classError);
      } else {
        console.log('Successfully created teacher_classes record');
      }
    }

    // Success response
    return new Response(
      JSON.stringify({
        success: true,
        user_id: userId,
        school_name: schoolData.school_name,
        assigned_class: assigned_class || null,
        message: `${position} account created successfully for ${full_name} at ${schoolData.school_name}${assigned_class ? ` (assigned to ${assigned_class})` : ''}`
      }),
      { status: 200, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    )

  } catch (error) {
    return new Response(
      JSON.stringify({ error: error.message || 'Internal server error' }),
      { status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    )
  }
})
