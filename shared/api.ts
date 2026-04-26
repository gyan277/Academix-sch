/**
 * Shared code between client and server
 * Useful to share types between client and server
 * and/or small pure JS functions that can be used on both client and server
 */

/**
 * Example response type for /api/demo
 */
export interface DemoResponse {
  message: string;
}

/**
 * User roles and permissions
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
