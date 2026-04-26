/**
 * Utility functions for teacher management
 * Provides validation, password generation, and error mapping
 */

/**
 * Validates email format
 * @param email - Email address to validate
 * @returns true if email is valid, false otherwise
 */
export function validateEmail(email: string): boolean {
  if (!email || email.trim().length === 0) {
    return false;
  }
  
  const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
  return emailRegex.test(email.trim());
}

/**
 * Validates name length
 * @param name - Name to validate
 * @returns true if name is at least 2 characters, false otherwise
 */
export function validateName(name: string): boolean {
  if (!name || name.trim().length < 2) {
    return false;
  }
  return true;
}

/**
 * Validates phone number format
 * Allows digits, spaces, parentheses, hyphens, and plus signs
 * @param phone - Phone number to validate
 * @returns true if phone is valid or empty, false otherwise
 */
export function validatePhone(phone: string): boolean {
  if (!phone || phone.trim().length === 0) {
    return true; // Phone is optional
  }
  
  const phoneRegex = /^[\d\s()\-+]+$/;
  return phoneRegex.test(phone.trim());
}

/**
 * Validates password strength
 * @param password - Password to validate
 * @returns true if password is at least 8 characters, false otherwise
 */
export function validatePassword(password: string): boolean {
  if (!password || password.length < 8) {
    return false;
  }
  return true;
}

/**
 * Generates a secure random password
 * Password contains uppercase, lowercase, numbers, and special characters
 * @returns A secure password string
 */
export function generateSecurePassword(): string {
  const uppercase = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ';
  const lowercase = 'abcdefghijklmnopqrstuvwxyz';
  const numbers = '0123456789';
  const special = '!@#$%^&*';
  const allChars = uppercase + lowercase + numbers + special;
  
  // Ensure at least one character from each category
  let password = '';
  password += uppercase[Math.floor(Math.random() * uppercase.length)];
  password += lowercase[Math.floor(Math.random() * lowercase.length)];
  password += numbers[Math.floor(Math.random() * numbers.length)];
  password += special[Math.floor(Math.random() * special.length)];
  
  // Fill remaining characters (total length 12)
  for (let i = 4; i < 12; i++) {
    password += allChars[Math.floor(Math.random() * allChars.length)];
  }
  
  // Shuffle the password
  return password.split('').sort(() => Math.random() - 0.5).join('');
}

/**
 * Maps Supabase auth errors to user-friendly messages
 * @param errorMessage - Error message from Supabase
 * @returns User-friendly error message
 */
export function mapAuthError(errorMessage: string): string {
  const lowerMessage = errorMessage.toLowerCase();
  
  if (lowerMessage.includes('already registered') || lowerMessage.includes('already exists') || lowerMessage.includes('duplicate')) {
    return 'This email address is already registered in the system.';
  }
  
  if (lowerMessage.includes('invalid email')) {
    return 'Please provide a valid email address.';
  }
  
  if (lowerMessage.includes('password')) {
    return 'Password must be at least 8 characters long.';
  }
  
  if (lowerMessage.includes('rate limit')) {
    return 'Too many requests. Please wait a moment and try again.';
  }
  
  if (lowerMessage.includes('network') || lowerMessage.includes('connection')) {
    return 'Unable to connect to authentication service. Please check your connection.';
  }
  
  return 'An error occurred during authentication. Please try again.';
}

/**
 * Maps database errors to user-friendly messages
 * @param error - Error object from Supabase
 * @returns User-friendly error message
 */
export function mapDatabaseError(error: any): string {
  if (!error) {
    return 'An unknown error occurred.';
  }
  
  const errorCode = error.code;
  const errorMessage = error.message?.toLowerCase() || '';
  
  // PostgreSQL error codes
  if (errorCode === '23505') {
    return 'This information already exists in the system.';
  }
  
  if (errorCode === '23503') {
    return 'Unable to complete operation due to data dependencies.';
  }
  
  if (errorCode === '23502') {
    return 'Required information is missing.';
  }
  
  if (errorMessage.includes('permission') || errorMessage.includes('policy')) {
    return 'You do not have permission to perform this action.';
  }
  
  if (errorMessage.includes('timeout') || errorMessage.includes('connection')) {
    return 'Unable to connect to database. Please check your connection.';
  }
  
  return 'Unable to save changes. Please try again.';
}
