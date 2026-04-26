import { createClient } from '@supabase/supabase-js';

const supabaseUrl = import.meta.env.VITE_SUPABASE_URL;
const supabaseAnonKey = import.meta.env.VITE_SUPABASE_ANON_KEY;

if (!supabaseUrl || !supabaseAnonKey) {
  throw new Error('Missing Supabase environment variables. Please check your .env file.');
}

export const supabase = createClient(supabaseUrl, supabaseAnonKey);

// Database types
export type Database = {
  public: {
    Tables: {
      users: {
        Row: {
          id: string;
          email: string;
          full_name: string;
          role: 'admin' | 'teacher' | 'registrar';
          phone: string | null;
          created_at: string;
          updated_at: string;
        };
        Insert: Omit<Database['public']['Tables']['users']['Row'], 'created_at' | 'updated_at'>;
        Update: Partial<Database['public']['Tables']['users']['Insert']>;
      };
      students: {
        Row: {
          id: string;
          student_id: string;
          full_name: string;
          date_of_birth: string;
          gender: 'Male' | 'Female';
          class: string;
          home_address: string | null;
          admission_date: string;
          parent_name: string;
          parent_phone: string;
          parent_email: string | null;
          photo_url: string | null;
          status: 'active' | 'inactive' | 'graduated';
          created_at: string;
          updated_at: string;
        };
        Insert: Omit<Database['public']['Tables']['students']['Row'], 'id' | 'created_at' | 'updated_at'>;
        Update: Partial<Database['public']['Tables']['students']['Insert']>;
      };
      staff: {
        Row: {
          id: string;
          staff_id: string;
          full_name: string;
          phone: string;
          email: string | null;
          position: string;
          specialization: string | null;
          employment_date: string;
          photo_url: string | null;
          status: 'active' | 'inactive';
          created_at: string;
          updated_at: string;
        };
        Insert: Omit<Database['public']['Tables']['staff']['Row'], 'id' | 'created_at' | 'updated_at'>;
        Update: Partial<Database['public']['Tables']['staff']['Insert']>;
      };
      grades: {
        Row: {
          id: string;
          student_id: string;
          subject_id: string;
          class: string;
          term: string;
          academic_year: string;
          class_score: number;
          exam_score: number;
          total_score: number;
          grade: string | null;
          teacher_id: string | null;
          remarks: string | null;
          created_at: string;
          updated_at: string;
        };
        Insert: Omit<Database['public']['Tables']['grades']['Row'], 'id' | 'total_score' | 'created_at' | 'updated_at'>;
        Update: Partial<Database['public']['Tables']['grades']['Insert']>;
      };
      attendance: {
        Row: {
          id: string;
          student_id: string;
          class: string;
          date: string;
          status: 'present' | 'absent' | 'late';
          marked_by: string | null;
          notes: string | null;
          created_at: string;
          updated_at: string;
        };
        Insert: Omit<Database['public']['Tables']['attendance']['Row'], 'id' | 'created_at' | 'updated_at'>;
        Update: Partial<Database['public']['Tables']['attendance']['Insert']>;
      };
      school_settings: {
        Row: {
          id: string;
          school_name: string;
          school_address: string | null;
          school_phone: string | null;
          school_email: string | null;
          school_logo_url: string | null;
          headmaster_signature_url: string | null;
          current_academic_year: string | null;
          created_at: string;
          updated_at: string;
        };
        Insert: Omit<Database['public']['Tables']['school_settings']['Row'], 'id' | 'created_at' | 'updated_at'>;
        Update: Partial<Database['public']['Tables']['school_settings']['Insert']>;
      };
    };
  };
};
