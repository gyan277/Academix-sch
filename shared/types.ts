/**
 * Shared types between client and server
 */

export type UserRole = "admin" | "teacher" | "registrar";

export interface User {
  id: string;
  email: string;
  name: string;
  role: UserRole;
  assignedClasses?: string[]; // For teachers
}

export interface AuthResponse {
  success: boolean;
  user?: User;
  message?: string;
}

// Teacher Management Types

export interface TeacherProfile {
  id: string;
  email: string;
  full_name: string;
  role: 'teacher';
  phone: string | null;
  status: 'active' | 'inactive';
  created_at: string;
  updated_at: string;
  assigned_classes: string[]; // Populated from teacher_classes join
}

export interface CreateTeacherRequest {
  email: string;
  full_name: string;
  phone: string;
  password: string;
  classes?: string[];
}

export interface CreateTeacherResponse {
  success: boolean;
  teacher?: TeacherProfile;
  credentials?: {
    email: string;
    password: string;
  };
  error?: string;
}

export interface UpdateTeacherRequest {
  full_name: string;
  phone: string;
  classes: string[];
}

export interface UpdateTeacherResponse {
  success: boolean;
  teacher?: TeacherProfile;
  error?: string;
}

export interface ResetPasswordResponse {
  success: boolean;
  credentials?: {
    email: string;
    password: string;
  };
  error?: string;
}

// Finance System Types

export type PaymentType = "tuition" | "bus" | "canteen" | "other";

export interface ClassFee {
  id: string;
  school_id: string;
  class: string;
  academic_year: string;
  term: string;
  fee_amount: number;
  bus_fee?: number;
  canteen_fee?: number;
  created_at: string;
  updated_at: string;
}

export interface StudentFeeOverride {
  id: string;
  school_id: string;
  student_id: string;
  academic_year: string;
  term: string;
  bus_fee_override?: number;
  canteen_fee_override?: number;
  uses_bus: boolean;
  uses_canteen: boolean;
  created_at: string;
  updated_at: string;
}

export interface Payment {
  id: string;
  school_id: string;
  student_id: string;
  amount: number;
  payment_date: string;
  payment_method?: string;
  payment_type: PaymentType;
  reference_number?: string;
  notes?: string;
  recorded_by?: string;
  created_at: string;
}

export interface StaffSalary {
  id: string;
  school_id: string;
  staff_id: string;
  monthly_salary: number;
  currency: string;
  effective_date: string;
  is_active: boolean;
  created_at: string;
  updated_at: string;
  staff?: {
    full_name: string;
    email: string;
    role: string;
  };
}

export interface SalaryPayment {
  id: string;
  school_id: string;
  staff_id: string;
  amount: number;
  payment_month: string;
  payment_date: string;
  payment_method?: string;
  reference_number?: string;
  notes?: string;
  paid_by?: string;
  created_at: string;
  staff?: {
    full_name: string;
    email: string;
  };
}

export interface CustomExpense {
  id: string;
  school_id: string;
  expense_category: string;
  description: string;
  amount: number;
  expense_date: string;
  class?: string;
  payment_method?: string;
  reference_number?: string;
  recorded_by?: string;
  created_at: string;
  updated_at: string;
}

export interface StudentTotalFees {
  tuition_fee: number;
  bus_fee: number;
  canteen_fee: number;
  total_fee: number;
}

export interface FinancialSummary {
  total_income: number;
  total_expenses: number;
  net_balance: number;
  tuition_collected: number;
  bus_collected: number;
  canteen_collected: number;
  outstanding_balance: number;
}
