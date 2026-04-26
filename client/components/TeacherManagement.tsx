import { useState, useEffect } from 'react';
import { useAuth } from '@/hooks/use-auth';
import { supabase } from '@/lib/supabase';
import { TeacherProfile } from '@shared/types';
import { useAcademicYear } from '@/hooks/use-academic-year';
import {
  validateEmail,
  validateName,
  validatePhone,
  validatePassword,
  generateSecurePassword,
  mapAuthError,
  mapDatabaseError,
} from '@/lib/teacher-utils';
import { Button } from '@/components/ui/button';
import { Input } from '@/components/ui/input';
import { Label } from '@/components/ui/label';
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '@/components/ui/card';
import { Badge } from '@/components/ui/badge';
import { Dialog, DialogContent, DialogDescription, DialogFooter, DialogHeader, DialogTitle } from '@/components/ui/dialog';
import { useToast } from '@/hooks/use-toast';
import { Loader2, Plus, Edit, Key, Power, Copy, Check } from 'lucide-react';
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from '@/components/ui/select';

interface CreateTeacherData {
  email: string;
  full_name: string;
  phone: string;
  password: string;
  classes: string[];
}

interface EditTeacherData {
  full_name: string;
  phone: string;
  classes: string[];
}

interface Credentials {
  email: string;
  password: string;
}

/**
 * Main Teacher Management Interface Component
 * Provides admin interface for creating, editing, and managing teacher accounts
 */
export function TeacherManagementInterface() {
  const { profile } = useAuth();
  const { toast } = useToast();
  const { academicYear } = useAcademicYear();
  
  const [teachers, setTeachers] = useState<TeacherProfile[]>([]);
  const [loading, setLoading] = useState(true);
  const [isCreateDialogOpen, setIsCreateDialogOpen] = useState(false);
  const [editingTeacher, setEditingTeacher] = useState<TeacherProfile | null>(null);
  const [credentialsToShow, setCredentialsToShow] = useState<Credentials | null>(null);
  const [availableClasses, setAvailableClasses] = useState<string[]>([]);

  // Load teachers on mount - wait for profile to load
  useEffect(() => {
    if (profile?.school_id) {
      loadTeachers();
      loadAvailableClasses();
    }
  }, [profile?.school_id]);

  /**
   * Fetch all teachers from database with their class assignments
   * CRITICAL: Filter by school_id for multi-tenancy
   */
  async function loadTeachers() {
    try {
      setLoading(true);
      
      // CRITICAL: Must have school_id to load teachers
      if (!profile?.school_id) {
        console.log("⚠️ Profile school_id not loaded yet, waiting...");
        setLoading(false);
        return;
      }

      console.log("🔍 Loading teachers for school_id:", profile.school_id);
      
      const { data: teachersData, error } = await supabase
        .from('users')
        .select(`
          *,
          teacher_classes (
            class
          )
        `)
        .eq('role', 'teacher')
        .eq('school_id', profile.school_id) // EXPLICIT school_id filter
        .order('full_name', { ascending: true });

      if (error) {
        console.error('❌ Error loading teachers:', error);
        toast({
          title: 'Error Loading Teachers',
          description: mapDatabaseError(error),
          variant: 'destructive',
        });
        return;
      }

      console.log("✅ Loaded teachers:", teachersData?.length || 0, "teachers");

      // Transform data to include assigned_classes array
      const transformedTeachers: TeacherProfile[] = (teachersData || []).map((teacher: any) => ({
        id: teacher.id,
        email: teacher.email,
        full_name: teacher.full_name,
        role: 'teacher' as const,
        phone: teacher.phone,
        status: teacher.status || 'active',
        created_at: teacher.created_at,
        updated_at: teacher.updated_at,
        assigned_classes: teacher.teacher_classes?.map((tc: any) => tc.class) || [],
      }));

      setTeachers(transformedTeachers);
    } catch (err) {
      console.error('Unexpected error loading teachers:', err);
      toast({
        title: 'Connection Error',
        description: 'Unable to load teachers. Please check your connection.',
        variant: 'destructive',
      });
    } finally {
      setLoading(false);
    }
  }

  /**
   * Fetch available classes from students table
   * CRITICAL: Filter by school_id for multi-tenancy
   */
  async function loadAvailableClasses() {
    try {
      if (!profile?.school_id) {
        console.log("⚠️ Profile school_id not loaded yet for classes");
        return;
      }

      const { data: classData, error } = await supabase
        .from('students')
        .select('class')
        .eq('status', 'active')
        .eq('school_id', profile.school_id); // EXPLICIT school_id filter

      if (error) {
        console.error('Error loading classes:', error);
        return;
      }

      const uniqueClasses = [...new Set(classData?.map((s: any) => s.class) || [])].sort();
      setAvailableClasses(uniqueClasses);
    } catch (err) {
      console.error('Error loading classes:', err);
    }
  }

  /**
   * Create a new teacher account
   */
  async function handleCreateTeacher(data: CreateTeacherData) {
    try {
      // CRITICAL: Check if admin has school_id
      if (!profile?.school_id) {
        console.error("❌ Cannot create teacher: Admin school_id is NULL");
        console.error("Admin profile:", profile);
        toast({
          title: 'School ID Missing',
          description: 'Your account is missing a school_id. Please run FIX_NEW_ADMIN_SCHOOL_ID.sql in Supabase, then logout and login again.',
          variant: 'destructive',
        });
        return;
      }

      console.log("✅ Creating teacher with admin school_id:", profile.school_id);

      // Step 1: Create auth user using signUp
      // IMPORTANT: We need to prevent auto-login so admin stays logged in
      // We'll use a workaround by storing current session and restoring it
      const { data: { session: currentSession } } = await supabase.auth.getSession();
      
      console.log("📝 Creating auth user for:", data.email);
      
      const { data: authData, error: authError } = await supabase.auth.signUp({
        email: data.email,
        password: data.password,
        options: {
          data: {
            full_name: data.full_name,
            role: 'teacher',
            phone: data.phone,
            school_id: profile.school_id, // Pass school_id in metadata
          },
          emailRedirectTo: undefined, // Prevent email confirmation redirect
        },
      });

      // Step 1.5: Restore admin session immediately
      if (currentSession) {
        await supabase.auth.setSession({
          access_token: currentSession.access_token,
          refresh_token: currentSession.refresh_token,
        });
      }

      if (authError) {
        console.error('❌ Auth error:', authError);
        console.error('Error code:', authError.code);
        console.error('Error message:', authError.message);
        console.error('Error status:', authError.status);
        toast({
          title: 'Failed to Create Teacher',
          description: mapAuthError(authError.message) + ` (${authError.code || 'unknown'})`,
          variant: 'destructive',
        });
        return;
      }

      if (!authData.user) {
        console.error('❌ No user data returned from auth');
        toast({
          title: 'Failed to Create Teacher',
          description: 'No user data returned from authentication service.',
          variant: 'destructive',
        });
        return;
      }

      console.log("✅ Auth user created:", authData.user.id);

      // Step 2: Update user profile (trigger should have created it)
      // Wait a moment for the trigger to complete
      await new Promise(resolve => setTimeout(resolve, 1000));

      const { error: updateError } = await supabase
        .from('users')
        .update({ 
          full_name: data.full_name,
          phone: data.phone,
          role: 'teacher',
          status: 'active',
          school_id: profile?.school_id, // CRITICAL: Set school_id
        })
        .eq('id', authData.user.id);

      if (updateError) {
        console.error('Profile update error:', updateError);
        // If profile doesn't exist, create it
        const { error: insertError } = await supabase
          .from('users')
          .insert({
            id: authData.user.id,
            email: data.email,
            full_name: data.full_name,
            role: 'teacher',
            phone: data.phone,
            status: 'active',
            school_id: profile?.school_id, // CRITICAL: Set school_id
          });

        if (insertError) {
          console.error('Profile insert error:', insertError);
        }
      }

      // Step 3: Create class assignments with validation
      if (data.classes && data.classes.length > 0) {
        
        // Validate school_id matches for each class
        for (const className of data.classes) {
          const { data: studentsInClass, error: checkError } = await supabase
            .from('students')
            .select('school_id')
            .eq('class', className)
            .eq('status', 'active')
            .limit(1);

          if (checkError) {
            console.error('Error checking class students:', checkError);
            continue;
          }

          // If there are students in the class, verify school_id match
          if (studentsInClass && studentsInClass.length > 0) {
            const studentSchoolId = studentsInClass[0].school_id;
            if (studentSchoolId && studentSchoolId !== profile?.school_id) {
              toast({
                title: 'School ID Mismatch',
                description: `Cannot assign teacher to ${className}. Students in this class belong to a different school.`,
                variant: 'destructive',
              });
              continue; // Skip this class assignment
            }
          }
        }
        
        const classRecords = data.classes.map((className) => ({
          teacher_id: authData.user.id,
          class: className,
          academic_year: academicYear,
        }));

        const { error: classError } = await supabase
          .from('teacher_classes')
          .insert(classRecords);

        if (classError) {
          console.error('Class assignment error:', classError);
          // Check if it's a school_id mismatch error from the database trigger
          if (classError.message?.includes('school_id')) {
            toast({
              title: 'Class Assignment Failed',
              description: 'Teacher and students must belong to the same school. Please check school_id settings.',
              variant: 'destructive',
            });
          }
        }
      }

      // Success!
      toast({
        title: 'Teacher Created',
        description: `${data.full_name} has been added successfully. ${authData.user.email_confirmed_at ? '' : 'Note: Email confirmation may be required.'}`,
      });

      // Show credentials dialog
      setCredentialsToShow({
        email: data.email,
        password: data.password,
      });

      // Close create dialog and refresh list
      setIsCreateDialogOpen(false);
      loadTeachers();
    } catch (err) {
      console.error('Unexpected error creating teacher:', err);
      toast({
        title: 'Connection Error',
        description: 'Unable to create teacher. Please try again.',
        variant: 'destructive',
      });
    }
  }

  /**
   * Update teacher information
   */
  async function handleEditTeacher(id: string, data: EditTeacherData) {
    try {
      // Step 1: Update user profile
      const { error: updateError } = await supabase
        .from('users')
        .update({
          full_name: data.full_name,
          phone: data.phone,
        })
        .eq('id', id);

      if (updateError) {
        console.error('Update error:', updateError);
        toast({
          title: 'Failed to Update Teacher',
          description: mapDatabaseError(updateError),
          variant: 'destructive',
        });
        return;
      }

      // Step 2: Update class assignments (delete old, insert new)
      const { error: deleteError } = await supabase
        .from('teacher_classes')
        .delete()
        .eq('teacher_id', id);

      if (deleteError) {
        console.error('Delete classes error:', deleteError);
      }

      if (data.classes && data.classes.length > 0) {
        
        // Validate school_id matches for each class
        const teacherData = await supabase
          .from('users')
          .select('school_id')
          .eq('id', id)
          .single();

        if (teacherData.data?.school_id) {
          for (const className of data.classes) {
            const { data: studentsInClass, error: checkError } = await supabase
              .from('students')
              .select('school_id')
              .eq('class', className)
              .eq('status', 'active')
              .limit(1);

            if (checkError) {
              console.error('Error checking class students:', checkError);
              continue;
            }

            // If there are students in the class, verify school_id match
            if (studentsInClass && studentsInClass.length > 0) {
              const studentSchoolId = studentsInClass[0].school_id;
              if (studentSchoolId && studentSchoolId !== teacherData.data.school_id) {
                toast({
                  title: 'School ID Mismatch',
                  description: `Cannot assign teacher to ${className}. Students in this class belong to a different school.`,
                  variant: 'destructive',
                });
                continue; // Skip this class assignment
              }
            }
          }
        }
        
        const classRecords = data.classes.map((className) => ({
          teacher_id: id,
          class: className,
          academic_year: academicYear,
        }));

        const { error: insertError } = await supabase
          .from('teacher_classes')
          .insert(classRecords);

        if (insertError) {
          console.error('Insert classes error:', insertError);
          // Check if it's a school_id mismatch error from the database trigger
          if (insertError.message?.includes('school_id')) {
            toast({
              title: 'Class Assignment Failed',
              description: 'Teacher and students must belong to the same school. Please check school_id settings.',
              variant: 'destructive',
            });
          }
        }
      }

      // Success!
      toast({
        title: 'Teacher Updated',
        description: 'Teacher information has been updated successfully.',
      });

      // Close dialog and refresh list
      setEditingTeacher(null);
      loadTeachers();
    } catch (err) {
      console.error('Unexpected error updating teacher:', err);
      toast({
        title: 'Connection Error',
        description: 'Unable to update teacher. Please try again.',
        variant: 'destructive',
      });
    }
  }

  /**
   * Toggle teacher account status (active/inactive)
   */
  async function handleToggleStatus(id: string, currentStatus: string) {
    try {
      const newStatus = currentStatus === 'active' ? 'inactive' : 'active';

      const { error } = await supabase
        .from('users')
        .update({ status: newStatus })
        .eq('id', id);

      if (error) {
        console.error('Status toggle error:', error);
        toast({
          title: 'Failed to Update Status',
          description: mapDatabaseError(error),
          variant: 'destructive',
        });
        return;
      }

      toast({
        title: 'Status Updated',
        description: `Teacher account is now ${newStatus}.`,
      });

      loadTeachers();
    } catch (err) {
      console.error('Unexpected error toggling status:', err);
      toast({
        title: 'Connection Error',
        description: 'Unable to update status. Please try again.',
        variant: 'destructive',
      });
    }
  }

  /**
   * Reset teacher password
   * Note: This creates a password reset request that the teacher must complete
   */
  async function handleResetPassword(id: string, email: string) {
    try {
      // Send password reset email
      const { error } = await supabase.auth.resetPasswordForEmail(email, {
        redirectTo: `${window.location.origin}/reset-password`,
      });

      if (error) {
        console.error('Password reset error:', error);
        toast({
          title: 'Failed to Reset Password',
          description: mapAuthError(error.message),
          variant: 'destructive',
        });
        return;
      }

      toast({
        title: 'Password Reset Email Sent',
        description: `A password reset link has been sent to ${email}.`,
      });
    } catch (err) {
      console.error('Unexpected error resetting password:', err);
      toast({
        title: 'Connection Error',
        description: 'Unable to reset password. Please try again.',
        variant: 'destructive',
      });
    }
  }

  // Check admin access
  if (!profile || profile.role !== 'admin') {
    return (
      <div className="p-6 text-center">
        <p className="text-muted-foreground">You do not have permission to access this feature.</p>
      </div>
    );
  }

  return (
    <div className="space-y-6">
      <div className="flex items-center justify-between">
        <div>
          <h2 className="text-2xl font-bold tracking-tight">Teacher Management</h2>
          <p className="text-muted-foreground">Create and manage teacher accounts</p>
        </div>
        <Button onClick={() => setIsCreateDialogOpen(true)}>
          <Plus className="mr-2 h-4 w-4" />
          Add New Teacher
        </Button>
      </div>

      {loading ? (
        <div className="flex items-center justify-center py-12">
          <Loader2 className="h-8 w-8 animate-spin text-muted-foreground" />
        </div>
      ) : (
        <TeacherList
          teachers={teachers}
          onEdit={setEditingTeacher}
          onToggleStatus={handleToggleStatus}
          onResetPassword={handleResetPassword}
        />
      )}

      <CreateTeacherDialog
        isOpen={isCreateDialogOpen}
        onClose={() => setIsCreateDialogOpen(false)}
        onSubmit={handleCreateTeacher}
        availableClasses={availableClasses}
      />

      <EditTeacherDialog
        teacher={editingTeacher}
        isOpen={!!editingTeacher}
        onClose={() => setEditingTeacher(null)}
        onSave={handleEditTeacher}
        availableClasses={availableClasses}
      />

      <CredentialsDialog
        credentials={credentialsToShow}
        isOpen={!!credentialsToShow}
        onClose={() => setCredentialsToShow(null)}
      />
    </div>
  );
}

/**
 * Teacher List Component
 * Displays all teachers in a grid layout
 */
interface TeacherListProps {
  teachers: TeacherProfile[];
  onEdit: (teacher: TeacherProfile) => void;
  onToggleStatus: (id: string, currentStatus: string) => void;
  onResetPassword: (id: string, email: string) => void;
}

function TeacherList({ teachers, onEdit, onToggleStatus, onResetPassword }: TeacherListProps) {
  if (teachers.length === 0) {
    return (
      <Card>
        <CardContent className="py-12 text-center">
          <p className="text-muted-foreground">No teachers registered yet.</p>
          <p className="text-sm text-muted-foreground mt-2">Click "Add New Teacher" to create your first teacher account.</p>
        </CardContent>
      </Card>
    );
  }

  return (
    <div className="grid gap-4 md:grid-cols-2 lg:grid-cols-3">
      {teachers.map((teacher) => (
        <TeacherCard
          key={teacher.id}
          teacher={teacher}
          onEdit={() => onEdit(teacher)}
          onToggleStatus={() => onToggleStatus(teacher.id, teacher.status)}
          onResetPassword={() => onResetPassword(teacher.id, teacher.email)}
        />
      ))}
    </div>
  );
}

/**
 * Teacher Card Component
 * Displays individual teacher information
 */
interface TeacherCardProps {
  teacher: TeacherProfile;
  onEdit: () => void;
  onToggleStatus: () => void;
  onResetPassword: () => void;
}

function TeacherCard({ teacher, onEdit, onToggleStatus, onResetPassword }: TeacherCardProps) {
  return (
    <Card>
      <CardHeader>
        <div className="flex items-start justify-between">
          <div className="space-y-1">
            <CardTitle className="text-lg">{teacher.full_name}</CardTitle>
            <CardDescription>{teacher.email}</CardDescription>
          </div>
          <Badge variant={teacher.status === 'active' ? 'default' : 'secondary'}>
            {teacher.status}
          </Badge>
        </div>
      </CardHeader>
      <CardContent className="space-y-4">
        <div>
          <p className="text-sm text-muted-foreground">Phone</p>
          <p className="text-sm">{teacher.phone || 'Not provided'}</p>
        </div>

        {teacher.assigned_classes.length > 0 && (
          <div>
            <p className="text-sm text-muted-foreground mb-2">Assigned Classes</p>
            <div className="flex flex-wrap gap-1">
              {teacher.assigned_classes.map((className) => (
                <Badge key={className} variant="outline">
                  {className}
                </Badge>
              ))}
            </div>
          </div>
        )}

        <div className="flex gap-2 pt-2">
          <Button variant="outline" size="sm" onClick={onEdit}>
            <Edit className="h-4 w-4" />
          </Button>
          <Button variant="outline" size="sm" onClick={onToggleStatus}>
            <Power className="h-4 w-4" />
          </Button>
          <Button variant="outline" size="sm" onClick={onResetPassword}>
            <Key className="h-4 w-4" />
          </Button>
        </div>
      </CardContent>
    </Card>
  );
}

/**
 * Create Teacher Dialog Component
 */
interface CreateTeacherDialogProps {
  isOpen: boolean;
  onClose: () => void;
  onSubmit: (data: CreateTeacherData) => Promise<void>;
  availableClasses: string[];
}

function CreateTeacherDialog({ isOpen, onClose, onSubmit, availableClasses }: CreateTeacherDialogProps) {
  const [formData, setFormData] = useState<CreateTeacherData>({
    email: '',
    full_name: '',
    phone: '',
    password: '',
    classes: [],
  });
  const [errors, setErrors] = useState<Partial<Record<keyof CreateTeacherData, string>>>({});
  const [submitting, setSubmitting] = useState(false);

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();

    // Validate form
    const newErrors: Partial<Record<keyof CreateTeacherData, string>> = {};

    if (!validateEmail(formData.email)) {
      newErrors.email = 'Please enter a valid email address';
    }

    if (!validateName(formData.full_name)) {
      newErrors.full_name = 'Name must be at least 2 characters';
    }

    if (!validatePhone(formData.phone)) {
      newErrors.phone = 'Please enter a valid phone number';
    }

    if (!validatePassword(formData.password)) {
      newErrors.password = 'Password must be at least 8 characters';
    }

    if (Object.keys(newErrors).length > 0) {
      setErrors(newErrors);
      return;
    }

    setSubmitting(true);
    await onSubmit(formData);
    setSubmitting(false);

    // Reset form
    setFormData({
      email: '',
      full_name: '',
      phone: '',
      password: '',
      classes: [],
    });
    setErrors({});
  };

  const handleGeneratePassword = () => {
    const password = generateSecurePassword();
    setFormData({ ...formData, password });
    setErrors({ ...errors, password: undefined });
  };

  const toggleClass = (className: string) => {
    const newClasses = formData.classes.includes(className)
      ? formData.classes.filter((c) => c !== className)
      : [...formData.classes, className];
    setFormData({ ...formData, classes: newClasses });
  };

  return (
    <Dialog open={isOpen} onOpenChange={onClose}>
      <DialogContent className="max-w-md max-h-[90vh] overflow-y-auto">
        <DialogHeader>
          <DialogTitle>Create New Teacher</DialogTitle>
          <DialogDescription>Add a new teacher account to the system</DialogDescription>
        </DialogHeader>

        <form onSubmit={handleSubmit} className="space-y-4">
          <div className="space-y-2">
            <Label htmlFor="email">Email *</Label>
            <Input
              id="email"
              type="email"
              value={formData.email}
              onChange={(e) => {
                setFormData({ ...formData, email: e.target.value });
                setErrors({ ...errors, email: undefined });
              }}
              placeholder="teacher@school.com"
            />
            {errors.email && <p className="text-sm text-destructive">{errors.email}</p>}
          </div>

          <div className="space-y-2">
            <Label htmlFor="full_name">Full Name *</Label>
            <Input
              id="full_name"
              value={formData.full_name}
              onChange={(e) => {
                setFormData({ ...formData, full_name: e.target.value });
                setErrors({ ...errors, full_name: undefined });
              }}
              placeholder="Daniel Gyan"
            />
            {errors.full_name && <p className="text-sm text-destructive">{errors.full_name}</p>}
          </div>

          <div className="space-y-2">
            <Label htmlFor="phone">Phone</Label>
            <Input
              id="phone"
              value={formData.phone}
              onChange={(e) => {
                setFormData({ ...formData, phone: e.target.value });
                setErrors({ ...errors, phone: undefined });
              }}
              placeholder="+233 501 234 567"
            />
            {errors.phone && <p className="text-sm text-destructive">{errors.phone}</p>}
          </div>

          <div className="space-y-2">
            <Label htmlFor="password">Password *</Label>
            <div className="flex gap-2">
              <Input
                id="password"
                type="text"
                value={formData.password}
                onChange={(e) => {
                  setFormData({ ...formData, password: e.target.value });
                  setErrors({ ...errors, password: undefined });
                }}
                placeholder="Minimum 8 characters"
              />
              <Button type="button" variant="outline" onClick={handleGeneratePassword}>
                Generate
              </Button>
            </div>
            {errors.password && <p className="text-sm text-destructive">{errors.password}</p>}
          </div>

          {availableClasses.length > 0 && (
            <div className="space-y-2">
              <Label>Assign Classes (Optional)</Label>
              <div className="flex flex-wrap gap-2 p-3 border rounded-md">
                {availableClasses.map((className) => (
                  <Badge
                    key={className}
                    variant={formData.classes.includes(className) ? 'default' : 'outline'}
                    className="cursor-pointer"
                    onClick={() => toggleClass(className)}
                  >
                    {className}
                  </Badge>
                ))}
              </div>
            </div>
          )}

          <DialogFooter>
            <Button type="button" variant="outline" onClick={onClose} disabled={submitting}>
              Cancel
            </Button>
            <Button type="submit" disabled={submitting}>
              {submitting && <Loader2 className="mr-2 h-4 w-4 animate-spin" />}
              Create Teacher
            </Button>
          </DialogFooter>
        </form>
      </DialogContent>
    </Dialog>
  );
}

/**
 * Edit Teacher Dialog Component
 */
interface EditTeacherDialogProps {
  teacher: TeacherProfile | null;
  isOpen: boolean;
  onClose: () => void;
  onSave: (id: string, data: EditTeacherData) => Promise<void>;
  availableClasses: string[];
}

function EditTeacherDialog({ teacher, isOpen, onClose, onSave, availableClasses }: EditTeacherDialogProps) {
  const [formData, setFormData] = useState<EditTeacherData>({
    full_name: '',
    phone: '',
    classes: [],
  });
  const [errors, setErrors] = useState<Partial<Record<keyof EditTeacherData, string>>>({});
  const [submitting, setSubmitting] = useState(false);

  // Update form data when teacher changes
  useEffect(() => {
    if (teacher) {
      setFormData({
        full_name: teacher.full_name,
        phone: teacher.phone || '',
        classes: teacher.assigned_classes,
      });
      setErrors({});
    }
  }, [teacher]);

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();

    if (!teacher) return;

    // Validate form
    const newErrors: Partial<Record<keyof EditTeacherData, string>> = {};

    if (!validateName(formData.full_name)) {
      newErrors.full_name = 'Name must be at least 2 characters';
    }

    if (!validatePhone(formData.phone)) {
      newErrors.phone = 'Please enter a valid phone number';
    }

    if (Object.keys(newErrors).length > 0) {
      setErrors(newErrors);
      return;
    }

    setSubmitting(true);
    await onSave(teacher.id, formData);
    setSubmitting(false);
  };

  const toggleClass = (className: string) => {
    const newClasses = formData.classes.includes(className)
      ? formData.classes.filter((c) => c !== className)
      : [...formData.classes, className];
    setFormData({ ...formData, classes: newClasses });
  };

  if (!teacher) return null;

  return (
    <Dialog open={isOpen} onOpenChange={onClose}>
      <DialogContent className="max-w-md max-h-[90vh] overflow-y-auto">
        <DialogHeader>
          <DialogTitle>Edit Teacher</DialogTitle>
          <DialogDescription>Update teacher information</DialogDescription>
        </DialogHeader>

        <form onSubmit={handleSubmit} className="space-y-4">
          <div className="space-y-2">
            <Label>Email</Label>
            <Input value={teacher.email} disabled className="bg-muted" />
            <p className="text-xs text-muted-foreground">Email cannot be changed</p>
          </div>

          <div className="space-y-2">
            <Label htmlFor="edit_full_name">Full Name *</Label>
            <Input
              id="edit_full_name"
              value={formData.full_name}
              onChange={(e) => {
                setFormData({ ...formData, full_name: e.target.value });
                setErrors({ ...errors, full_name: undefined });
              }}
            />
            {errors.full_name && <p className="text-sm text-destructive">{errors.full_name}</p>}
          </div>

          <div className="space-y-2">
            <Label htmlFor="edit_phone">Phone</Label>
            <Input
              id="edit_phone"
              value={formData.phone}
              onChange={(e) => {
                setFormData({ ...formData, phone: e.target.value });
                setErrors({ ...errors, phone: undefined });
              }}
            />
            {errors.phone && <p className="text-sm text-destructive">{errors.phone}</p>}
          </div>

          {availableClasses.length > 0 && (
            <div className="space-y-2">
              <Label>Assigned Classes</Label>
              <div className="flex flex-wrap gap-2 p-3 border rounded-md">
                {availableClasses.map((className) => (
                  <Badge
                    key={className}
                    variant={formData.classes.includes(className) ? 'default' : 'outline'}
                    className="cursor-pointer"
                    onClick={() => toggleClass(className)}
                  >
                    {className}
                  </Badge>
                ))}
              </div>
            </div>
          )}

          <DialogFooter>
            <Button type="button" variant="outline" onClick={onClose} disabled={submitting}>
              Cancel
            </Button>
            <Button type="submit" disabled={submitting}>
              {submitting && <Loader2 className="mr-2 h-4 w-4 animate-spin" />}
              Save Changes
            </Button>
          </DialogFooter>
        </form>
      </DialogContent>
    </Dialog>
  );
}

/**
 * Credentials Dialog Component
 * Shows teacher credentials after creation or password reset
 */
interface CredentialsDialogProps {
  credentials: Credentials | null;
  isOpen: boolean;
  onClose: () => void;
}

function CredentialsDialog({ credentials, isOpen, onClose }: CredentialsDialogProps) {
  const [copied, setCopied] = useState(false);

  const handleCopy = () => {
    if (credentials) {
      const text = `Email: ${credentials.email}\nPassword: ${credentials.password}`;
      navigator.clipboard.writeText(text);
      setCopied(true);
      setTimeout(() => setCopied(false), 2000);
    }
  };

  if (!credentials) return null;

  return (
    <Dialog open={isOpen} onOpenChange={onClose}>
      <DialogContent className="max-w-md">
        <DialogHeader>
          <DialogTitle>Teacher Credentials</DialogTitle>
          <DialogDescription>
            Save these credentials securely. They will not be shown again.
          </DialogDescription>
        </DialogHeader>

        <div className="space-y-4">
          <div className="space-y-2">
            <Label>Email</Label>
            <Input value={credentials.email} readOnly className="bg-muted" />
          </div>

          <div className="space-y-2">
            <Label>Password</Label>
            <Input value={credentials.password} readOnly className="bg-muted font-mono" />
          </div>

          <div className="rounded-md bg-yellow-50 dark:bg-yellow-950 p-4">
            <p className="text-sm text-yellow-800 dark:text-yellow-200">
              <strong>Important:</strong> Please share these credentials securely with the teacher. 
              They should change their password after first login.
            </p>
          </div>
        </div>

        <DialogFooter>
          <Button variant="outline" onClick={handleCopy}>
            {copied ? (
              <>
                <Check className="mr-2 h-4 w-4" />
                Copied!
              </>
            ) : (
              <>
                <Copy className="mr-2 h-4 w-4" />
                Copy Credentials
              </>
            )}
          </Button>
          <Button onClick={onClose}>Close</Button>
        </DialogFooter>
      </DialogContent>
    </Dialog>
  );
}
