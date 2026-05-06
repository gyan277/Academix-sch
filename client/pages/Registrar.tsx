import { useState, useEffect } from "react";
import Layout from "@/components/Layout";
import { Button } from "@/components/ui/button";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { Tabs, TabsContent, TabsList, TabsTrigger } from "@/components/ui/tabs";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import {
  Dialog,
  DialogContent,
  DialogDescription,
  DialogHeader,
  DialogTitle,
  DialogTrigger,
} from "@/components/ui/dialog";
import { Badge } from "@/components/ui/badge";
import { Plus, Search, Edit2, Trash2, Users, UserPlus } from "lucide-react";
import { supabase } from "@/lib/supabase";
import { useToast } from "@/hooks/use-toast";
import { useAuth } from "@/hooks/use-auth";

interface Student {
  id: string;
  student_id: string;
  student_number: string;
  full_name: string;
  date_of_birth: string;
  gender: string;
  class: string;
  admission_date: string;
  parent_name: string;
  parent_phone: string;
  status: string;
}

interface Staff {
  id: string;
  staff_id: string;
  full_name: string;
  phone: string;
  position: string;
  specialization: string;
  employment_date: string;
  status: string;
  assigned_class?: string; // Add assigned class field
}

const classes = ["Creche", "Nursery 1", "Nursery 2", "KG1", "KG2", "Primary 1", "Primary 2", "Primary 3", "Primary 4", "Primary 5", "Primary 6", "JHS 1", "JHS 2", "JHS 3"];

const staffPositions = [
  "Teacher",
  "Head Teacher", 
  "Assistant Head Teacher",
  "Librarian",
  "Secretary",
  "Accountant",
  "Security Guard",
  "Cleaner",
  "Driver",
  "Cook",
  "IT Support",
  "Nurse"
];

export default function Registrar() {
  const { toast } = useToast();
  const { profile } = useAuth();
  const [students, setStudents] = useState<Student[]>([]);
  const [staff, setStaff] = useState<Staff[]>([]);
  const [loading, setLoading] = useState(true);
  const [searchTerm, setSearchTerm] = useState("");
  const [selectedClass, setSelectedClass] = useState<string>("");
  const [isStudentDialogOpen, setIsStudentDialogOpen] = useState(false);
  const [isStaffDialogOpen, setIsStaffDialogOpen] = useState(false);
  const [studentSortBy, setStudentSortBy] = useState<"lastName" | "firstName" | "studentNumber" | "admissionDate">("lastName");
  const [staffSortBy, setStaffSortBy] = useState<"lastName" | "firstName" | "staffNumber" | "employmentDate">("lastName");
  const [selectedStudentsForPromotion, setSelectedStudentsForPromotion] = useState<Set<string>>(new Set());
  const [editingStudent, setEditingStudent] = useState<Student | null>(null);
  const [editingStaff, setEditingStaff] = useState<Staff | null>(null);
  const [newStudent, setNewStudent] = useState({
    name: "",
    dob: "",
    gender: "",
    class: "",
    parentName: "",
    parentPhone: "",
  });
  const [newStaff, setNewStaff] = useState({
    name: "",
    email: "",
    phone: "",
    position: "",
    specialization: "",
    assignedClass: "", // New field for class assignment
    createLogin: false,
    password: "",
  });

  // Load students and staff from database - wait for profile
  useEffect(() => {
    if (profile?.school_id) {
      loadData();
    }
  }, [profile?.school_id]);

  const loadData = async () => {
    try {
      setLoading(true);
      
      // CRITICAL: Wait for profile to load before querying
      if (!profile?.school_id) {
        console.log("⚠️ Profile school_id not loaded yet, waiting...");
        setLoading(false);
        return;
      }

      console.log("🔍 Loading registrar data for school_id:", profile.school_id);
      
      // Load students
      const { data: studentsData, error: studentsError } = await supabase
        .from("students")
        .select("*")
        .eq("status", "active")
        .eq("school_id", profile.school_id) // EXPLICIT school_id filter
        .order("full_name");

      if (studentsError) {
        console.error("❌ Error loading students:", studentsError);
        throw studentsError;
      }
      
      console.log("✅ Loaded students:", studentsData?.length || 0);
      setStudents(studentsData || []);

      // Load staff - use a simpler approach to avoid join issues
      const { data: staffData, error: staffError } = await supabase
        .from("staff")
        .select("*")
        .eq("status", "active")
        .eq("school_id", profile.school_id) // EXPLICIT school_id filter
        .order("full_name");

      if (staffError) {
        console.error("❌ Error loading staff:", staffError);
        throw staffError;
      }
      
      // Load teacher class assignments separately
      let staffWithClasses = staffData || [];
      
      if (staffData && staffData.length > 0) {
        try {
          // Get teacher IDs from users table for staff members
          const { data: teacherUsers, error: teacherError } = await supabase
            .from("users")
            .select("id, full_name")
            .eq("school_id", profile.school_id)
            .eq("role", "teacher");

          if (!teacherError && teacherUsers) {
            // Get class assignments for these teachers
            const { data: classAssignments, error: classError } = await supabase
              .from("teacher_classes")
              .select("teacher_id, class")
              .eq("school_id", profile.school_id);

            if (!classError && classAssignments) {
              // Match staff with their class assignments
              staffWithClasses = staffData.map(staff => {
                // Find matching user account
                const matchingUser = teacherUsers.find(user => 
                  user.full_name.toLowerCase() === staff.full_name.toLowerCase()
                );
                
                // Find class assignment for this user
                const classAssignment = matchingUser ? 
                  classAssignments.find(ca => ca.teacher_id === matchingUser.id) : null;
                
                return {
                  ...staff,
                  assigned_class: classAssignment?.class || null
                };
              });
            }
          }
        } catch (classLoadError) {
          console.warn("Could not load class assignments:", classLoadError);
          // Continue without class assignments
        }
      }
      
      console.log("✅ Loaded staff:", staffWithClasses?.length || 0);
      setStaff(staffWithClasses);
    } catch (error) {
      console.error("Error loading data:", error);
      toast({
        title: "Error",
        description: "Failed to load data from database",
        variant: "destructive",
      });
    } finally {
      setLoading(false);
    }
  };

  // Helper function to extract last name and first name
  const getNameParts = (fullName: string) => {
    const parts = fullName.trim().split(" ");
    if (parts.length === 1) {
      return { firstName: parts[0], lastName: parts[0] };
    }
    const lastName = parts[parts.length - 1];
    const firstName = parts.slice(0, -1).join(" ");
    return { firstName, lastName };
  };

  // Sort students
  const sortStudents = (studentList: Student[]) => {
    return [...studentList].sort((a, b) => {
      switch (studentSortBy) {
        case "lastName": {
          const aName = getNameParts(a.full_name);
          const bName = getNameParts(b.full_name);
          return aName.lastName.localeCompare(bName.lastName) || aName.firstName.localeCompare(bName.firstName);
        }
        case "firstName": {
          const aName = getNameParts(a.full_name);
          const bName = getNameParts(b.full_name);
          return aName.firstName.localeCompare(bName.firstName) || aName.lastName.localeCompare(bName.lastName);
        }
        case "studentNumber":
          return (a.student_number || a.student_id || "").localeCompare(b.student_number || b.student_id || "");
        case "admissionDate":
          return new Date(a.admission_date).getTime() - new Date(b.admission_date).getTime();
        default:
          return 0;
      }
    });
  };

  // Sort staff
  const sortStaff = (staffList: Staff[]) => {
    return [...staffList].sort((a, b) => {
      switch (staffSortBy) {
        case "lastName": {
          const aName = getNameParts(a.full_name);
          const bName = getNameParts(b.full_name);
          return aName.lastName.localeCompare(bName.lastName) || aName.firstName.localeCompare(bName.firstName);
        }
        case "firstName": {
          const aName = getNameParts(a.full_name);
          const bName = getNameParts(b.full_name);
          return aName.firstName.localeCompare(bName.firstName) || aName.lastName.localeCompare(bName.lastName);
        }
        case "staffNumber":
          return (a.staff_id || "").localeCompare(b.staff_id || "");
        case "employmentDate":
          return new Date(a.employment_date).getTime() - new Date(b.employment_date).getTime();
        default:
          return 0;
      }
    });
  };

  // Filter students
  const filteredStudents = sortStudents(students.filter((student) => {
    const matchesSearch =
      student.full_name.toLowerCase().includes(searchTerm.toLowerCase()) ||
      (student.student_number && student.student_number.toLowerCase().includes(searchTerm.toLowerCase())) ||
      (student.student_id && student.student_id.includes(searchTerm));
    const matchesClass = !selectedClass || student.class === selectedClass;
    return matchesSearch && matchesClass;
  }));

  // Filter staff
  const filteredStaff = sortStaff(staff.filter((member) =>
    member.full_name.toLowerCase().includes(searchTerm.toLowerCase()) ||
    member.staff_id.includes(searchTerm)
  ));

  const handleAddStudent = async () => {
    // Only name and class are required
    if (!newStudent.name || !newStudent.class) {
      toast({
        title: "Validation Error",
        description: "Please fill in student name and class",
        variant: "destructive",
      });
      return;
    }

    if (!profile?.school_id) {
      toast({
        title: "School ID Missing",
        description: "Your account is missing a school_id. Please contact support or run the FIX_NEW_ADMIN_SCHOOL_ID.sql script in Supabase.",
        variant: "destructive",
      });
      console.error("❌ Cannot add student: Admin school_id is NULL");
      console.error("Admin profile:", profile);
      console.error("Run FIX_NEW_ADMIN_SCHOOL_ID.sql to fix this issue");
      return;
    }

    console.log("✅ Adding student with school_id:", profile.school_id);

    try {
      const { data, error } = await supabase
        .from("students")
        .insert([
          {
            full_name: newStudent.name,
            date_of_birth: newStudent.dob || null, // Convert empty string to null
            gender: newStudent.gender,
            class: newStudent.class,
            parent_name: newStudent.parentName || null, // Convert empty string to null
            parent_phone: newStudent.parentPhone || null, // Convert empty string to null
            admission_date: new Date().toISOString().split("T")[0],
            status: "active",
            school_id: profile.school_id,
          },
        ])
        .select()
        .single();

      if (error) {
        console.error("❌ Database error:", error);
        throw error;
      }

      console.log("✅ Student added successfully:", data);
      setStudents([...students, data]);
      setNewStudent({
        name: "",
        dob: "",
        gender: "",
        class: "",
        parentName: "",
        parentPhone: "",
      });
      setIsStudentDialogOpen(false);
      
      toast({
        title: "Success",
        description: `Student ${newStudent.name} added successfully`,
      });
    } catch (error: any) {
      console.error("Error adding student:", error);
      toast({
        title: "Error",
        description: error.message || "Failed to add student to database",
        variant: "destructive",
      });
    }
  };

  const handleDeleteStudent = async (id: string) => {
    if (!confirm("Are you sure you want to delete this student?")) return;

    try {
      const { error } = await supabase
        .from("students")
        .delete()
        .eq("id", id);

      if (error) throw error;

      setStudents(students.filter((s) => s.id !== id));
      
      toast({
        title: "Success",
        description: "Student deleted successfully",
      });
    } catch (error) {
      console.error("Error deleting student:", error);
      toast({
        title: "Error",
        description: "Failed to delete student",
        variant: "destructive",
      });
    }
  };

  const handleEditStudent = async (student: Student) => {
    // Only name and class are required
    if (!student.full_name || !student.class) {
      toast({
        title: "Validation Error",
        description: "Please fill in student name and class",
        variant: "destructive",
      });
      return;
    }

    try {
      const { error } = await supabase
        .from("students")
        .update({
          full_name: student.full_name,
          date_of_birth: student.date_of_birth || null, // Convert empty string to null
          gender: student.gender || null,
          class: student.class,
          parent_name: student.parent_name || null, // Convert empty string to null
          parent_phone: student.parent_phone || null, // Convert empty string to null
        })
        .eq("id", student.id);

      if (error) throw error;

      // Update local state
      setStudents(students.map(s => s.id === student.id ? student : s));
      setEditingStudent(null);
      
      toast({
        title: "Success",
        description: `Student ${student.full_name} updated successfully`,
      });
    } catch (error) {
      console.error("Error updating student:", error);
      toast({
        title: "Error",
        description: "Failed to update student in database",
        variant: "destructive",
      });
    }
  };

  const handleAddStaff = async () => {
    if (!newStaff.name || !newStaff.position || !newStaff.phone) {
      toast({
        title: "Validation Error",
        description: "Please fill in name, position, and phone number",
        variant: "destructive",
      });
      return;
    }

    if (newStaff.createLogin && (!newStaff.email || !newStaff.password)) {
      toast({
        title: "Validation Error", 
        description: "Email and password are required for login accounts",
        variant: "destructive",
      });
      return;
    }

    if (!profile?.school_id) {
      toast({
        title: "Error",
        description: "School information not found. Please contact support.",
        variant: "destructive",
      });
      return;
    }

    try {
      // Step 1: Create staff record first
      const staffData = {
        full_name: newStaff.name,
        email: newStaff.createLogin ? newStaff.email : null,
        phone: newStaff.phone,
        position: newStaff.position,
        specialization: newStaff.specialization || null,
        employment_date: new Date().toISOString().split("T")[0],
        status: "active",
        school_id: profile.school_id,
      };

      const { data: staffResult, error: staffError } = await supabase
        .from("staff")
        .insert([staffData])
        .select()
        .single();

      if (staffError) {
        console.error("❌ Staff creation error:", staffError);
        throw staffError;
      }

      // Step 2: Create login account if requested
      if (newStaff.createLogin) {
        try {
          // Call Supabase Edge Function
          const supabaseUrl = import.meta.env.VITE_SUPABASE_URL;
          const response = await fetch(`${supabaseUrl}/functions/v1/create-teacher-account`, {
            method: 'POST',
            headers: {
              'Content-Type': 'application/json',
              'Authorization': `Bearer ${import.meta.env.VITE_SUPABASE_ANON_KEY}`
            },
            body: JSON.stringify({
              email: newStaff.email,
              password: newStaff.password,
              full_name: newStaff.name,
              position: newStaff.position,
              school_id: profile.school_id,
              staff_id: staffResult.id,
              assigned_class: newStaff.assignedClass || null,
            }),
          });

          const result = await response.json();
          
          if (!response.ok) {
            throw new Error(result.error || 'Failed to create login account');
          }

          console.log("✅ Login account created:", result);
        } catch (loginError: any) {
          console.error("❌ Login creation failed:", loginError);
          // Staff record is already created, just show a warning
          toast({
            title: "Staff Added with Warning",
            description: `${newStaff.position} ${newStaff.name} added, but login account creation failed: ${loginError.message}`,
            variant: "destructive",
          });
          
          // Update local state and return early
          setStaff([...staff, staffResult]);
          setNewStaff({
            name: "",
            email: "",
            phone: "",
            position: "",
            specialization: "",
            assignedClass: "",
            createLogin: false,
            password: "",
          });
          setIsStaffDialogOpen(false);
          return;
        }
      }

      // Step 3: Update local state
      setStaff([...staff, staffResult]);
      
      // Reset form
      setNewStaff({
        name: "",
        email: "",
        phone: "",
        position: "",
        specialization: "",
        assignedClass: "",
        createLogin: false,
        password: "",
      });
      setIsStaffDialogOpen(false);
      
      toast({
        title: "Success",
        description: `${newStaff.position} ${newStaff.name} added successfully${newStaff.createLogin ? ' with login account' : ''}`,
      });

    } catch (error: any) {
      console.error("Error adding staff:", error);
      toast({
        title: "Error",
        description: error.message || "Failed to add staff member",
        variant: "destructive",
      });
    }
  };

  const handleDeleteStaff = async (id: string) => {
    if (!confirm("Are you sure you want to delete this staff member?")) return;

    try {
      const { error } = await supabase
        .from("staff")
        .delete()
        .eq("id", id);

      if (error) throw error;

      setStaff(staff.filter((s) => s.id !== id));
      
      toast({
        title: "Success",
        description: "Staff member deleted successfully",
      });
    } catch (error) {
      console.error("Error deleting staff:", error);
      toast({
        title: "Error",
        description: "Failed to delete staff member",
        variant: "destructive",
      });
    }
  };

  const handleEditStaff = async (staffMember: Staff) => {
    if (!staffMember.full_name || !staffMember.position || !staffMember.phone) {
      toast({
        title: "Validation Error",
        description: "Please fill in all required fields",
        variant: "destructive",
      });
      return;
    }

    try {
      // Update staff record
      const { error } = await supabase
        .from("staff")
        .update({
          full_name: staffMember.full_name,
          phone: staffMember.phone,
          position: staffMember.position,
          specialization: staffMember.specialization,
        })
        .eq("id", staffMember.id);

      if (error) throw error;

      // If this is a teacher and class assignment changed, update it
      if (staffMember.position.toLowerCase().includes('teacher')) {
        try {
          const response = await fetch('/api/update-teacher-class', {
            method: 'POST',
            headers: {
              'Content-Type': 'application/json',
            },
            body: JSON.stringify({
              staff_id: staffMember.id,
              new_class: staffMember.assigned_class || null,
              school_id: profile?.school_id,
            }),
          });

          const result = await response.json();
          
          if (!response.ok) {
            console.warn('Class assignment update failed:', result.error);
            // Don't fail the entire operation, just show a warning
            toast({
              title: "Partial Success",
              description: `Staff updated, but class assignment failed: ${result.error}`,
              variant: "destructive",
            });
          }
        } catch (classError: any) {
          console.warn('Class assignment update failed:', classError);
          // Don't fail the entire operation
        }
      }

      // Update local state
      setStaff(staff.map(s => s.id === staffMember.id ? staffMember : s));
      setEditingStaff(null);
      
      toast({
        title: "Success",
        description: `Staff member ${staffMember.full_name} updated successfully`,
      });
    } catch (error) {
      console.error("Error updating staff:", error);
      toast({
        title: "Error",
        description: "Failed to update staff member in database",
        variant: "destructive",
      });
    }
  };

  const handlePromoteClass = async (fromClass: string) => {
    const currentIndex = classes.indexOf(fromClass);
    const nextClass = classes[currentIndex + 1];

    const studentsToPromote = students.filter(s => s.class === fromClass && s.status === "active");

    if (studentsToPromote.length === 0) {
      toast({
        title: "No Students",
        description: `No students found in ${fromClass} to promote`,
        variant: "destructive",
      });
      return;
    }

    // Special handling for JHS3 - Graduate instead of promote
    if (fromClass === "JHS3") {
      if (!confirm(`Are you sure you want to graduate ${studentsToPromote.length} students from JHS3? They will be marked as graduated and removed from the active student list.`)) {
        return;
      }

      try {
        // Mark students as graduated (inactive)
        const { error } = await supabase
          .from("students")
          .update({ 
            status: "graduated",
            graduation_date: new Date().toISOString().split("T")[0]
          })
          .in("id", studentsToPromote.map(s => s.id));

        if (error) throw error;

        // Remove from local state (they're no longer active)
        setStudents(students.filter(student => 
          !studentsToPromote.find(s => s.id === student.id)
        ));

        toast({
          title: "Congratulations!",
          description: `Successfully graduated ${studentsToPromote.length} students from JHS3`,
        });
      } catch (error) {
        console.error("Error graduating students:", error);
        toast({
          title: "Error",
          description: "Failed to graduate students",
          variant: "destructive",
        });
      }
      return;
    }

    // Regular promotion for other classes
    if (!nextClass) {
      toast({
        title: "Cannot Promote",
        description: `${fromClass} is the highest class`,
        variant: "destructive",
      });
      return;
    }

    try {
      // Update all students in the class
      const { error } = await supabase
        .from("students")
        .update({ class: nextClass })
        .in("id", studentsToPromote.map(s => s.id));

      if (error) throw error;

      // Update local state
      setStudents(students.map(student => 
        studentsToPromote.find(s => s.id === student.id)
          ? { ...student, class: nextClass }
          : student
      ));

      toast({
        title: "Success",
        description: `Promoted ${studentsToPromote.length} students from ${fromClass} to ${nextClass}`,
      });
    } catch (error) {
      console.error("Error promoting students:", error);
      toast({
        title: "Error",
        description: "Failed to promote students",
        variant: "destructive",
      });
    }
  };

  const handleSelectivePromotion = async (fromClass: string) => {
    const currentIndex = classes.indexOf(fromClass);
    const nextClass = classes[currentIndex + 1];
    
    const classStudents = students.filter(s => s.class === fromClass && s.status === "active");
    const selectedIds = Array.from(selectedStudentsForPromotion);
    const studentsToPromote = classStudents.filter(s => selectedIds.includes(s.id));
    const studentsToRepeat = classStudents.filter(s => !selectedIds.includes(s.id));

    if (studentsToPromote.length === 0) {
      toast({
        title: "No Students Selected",
        description: "Please select at least one student to promote",
        variant: "destructive",
      });
      return;
    }

    // Special handling for JHS3 - Graduate instead of promote
    if (fromClass === "JHS3") {
      const message = studentsToRepeat.length > 0
        ? `Graduate ${studentsToPromote.length} students and keep ${studentsToRepeat.length} students in JHS3?`
        : `Graduate all ${studentsToPromote.length} selected students from JHS3?`;
      
      if (!confirm(message)) return;

      try {
        // Mark selected students as graduated
        const { error } = await supabase
          .from("students")
          .update({ 
            status: "graduated",
            graduation_date: new Date().toISOString().split("T")[0]
          })
          .in("id", studentsToPromote.map(s => s.id));

        if (error) throw error;

        // Remove graduated students from local state
        setStudents(students.filter(student => 
          !studentsToPromote.find(s => s.id === student.id)
        ));

        // Clear selection
        setSelectedStudentsForPromotion(new Set());

        toast({
          title: "Success!",
          description: `Graduated ${studentsToPromote.length} students. ${studentsToRepeat.length} students will repeat JHS3.`,
        });
      } catch (error) {
        console.error("Error graduating students:", error);
        toast({
          title: "Error",
          description: "Failed to graduate students",
          variant: "destructive",
        });
      }
      return;
    }

    // Regular promotion for other classes
    if (!nextClass) {
      toast({
        title: "Cannot Promote",
        description: `${fromClass} is the highest class`,
        variant: "destructive",
      });
      return;
    }

    const message = studentsToRepeat.length > 0
      ? `Promote ${studentsToPromote.length} students to ${nextClass} and keep ${studentsToRepeat.length} students in ${fromClass}?`
      : `Promote all ${studentsToPromote.length} selected students to ${nextClass}?`;
    
    if (!confirm(message)) return;

    try {
      // Update selected students to next class
      const { error } = await supabase
        .from("students")
        .update({ class: nextClass })
        .in("id", studentsToPromote.map(s => s.id));

      if (error) throw error;

      // Update local state
      setStudents(students.map(student => 
        studentsToPromote.find(s => s.id === student.id)
          ? { ...student, class: nextClass }
          : student
      ));

      // Clear selection
      setSelectedStudentsForPromotion(new Set());

      toast({
        title: "Success",
        description: `Promoted ${studentsToPromote.length} students to ${nextClass}. ${studentsToRepeat.length} students will repeat ${fromClass}.`,
      });
    } catch (error) {
      console.error("Error promoting students:", error);
      toast({
        title: "Error",
        description: "Failed to promote students",
        variant: "destructive",
      });
    }
  };

  const toggleStudentSelection = (studentId: string) => {
    const newSelection = new Set(selectedStudentsForPromotion);
    if (newSelection.has(studentId)) {
      newSelection.delete(studentId);
    } else {
      newSelection.add(studentId);
    }
    setSelectedStudentsForPromotion(newSelection);
  };

  const toggleSelectAll = (classLevel: string) => {
    const classStudents = students.filter(s => s.class === classLevel && s.status === "active");
    const allSelected = classStudents.every(s => selectedStudentsForPromotion.has(s.id));
    
    const newSelection = new Set(selectedStudentsForPromotion);
    if (allSelected) {
      // Deselect all from this class
      classStudents.forEach(s => newSelection.delete(s.id));
    } else {
      // Select all from this class
      classStudents.forEach(s => newSelection.add(s.id));
    }
    setSelectedStudentsForPromotion(newSelection);
  };

  // Count students per class
  const classStudentCount = (classLevel: string) => {
    return students.filter((s) => s.class === classLevel).length;
  };

  return (
    <Layout title="Registrar" subtitle="Student & Staff Management System">
      {loading ? (
        <div className="flex flex-col items-center justify-center py-20">
          <div className="animate-spin rounded-full h-12 w-12 border-b-2 border-primary mb-4"></div>
          <p className="text-muted-foreground">Loading data...</p>
        </div>
      ) : (
      <Tabs defaultValue="students" className="w-full">
        <TabsList className="grid w-full max-w-md grid-cols-3">
          <TabsTrigger value="students">Students</TabsTrigger>
          <TabsTrigger value="classes">Classes</TabsTrigger>
          <TabsTrigger value="staff">Staff</TabsTrigger>
        </TabsList>

        {/* STUDENTS TAB */}
        <TabsContent value="students" className="space-y-6 mt-6">
          <div className="flex flex-col sm:flex-row gap-4 items-start sm:items-center justify-between">
            <div className="flex flex-col sm:flex-row gap-3 flex-1 w-full">
              {/* Class Filter Dropdown */}
              <div className="w-full sm:w-48">
                <select
                  value={selectedClass}
                  onChange={(e) => setSelectedClass(e.target.value)}
                  className="w-full px-3 py-2 border border-input rounded-md bg-background text-sm h-10"
                >
                  <option value="">All Classes</option>
                  {classes.map((cls) => (
                    <option key={cls} value={cls}>
                      {cls}
                    </option>
                  ))}
                </select>
              </div>
              {/* Sort By Dropdown */}
              <div className="w-full sm:w-48">
                <select
                  value={studentSortBy}
                  onChange={(e) => setStudentSortBy(e.target.value as any)}
                  className="w-full px-3 py-2 border border-input rounded-md bg-background text-sm h-10"
                >
                  <option value="lastName">Sort by Last Name</option>
                  <option value="firstName">Sort by First Name</option>
                  <option value="studentNumber">Sort by Student Number</option>
                  <option value="admissionDate">Sort by Admission Date</option>
                </select>
              </div>
              {/* Search Input */}
              <div className="relative flex-1 sm:max-w-xs">
                <Search className="absolute left-3 top-3 w-4 h-4 text-muted-foreground" />
                <Input
                  placeholder="Search by name or ID..."
                  value={searchTerm}
                  onChange={(e) => setSearchTerm(e.target.value)}
                  className="pl-10"
                />
              </div>
            </div>
            <Dialog open={isStudentDialogOpen} onOpenChange={setIsStudentDialogOpen}>
              <DialogTrigger asChild>
                <Button className="gap-2 w-full sm:w-auto">
                  <UserPlus className="w-4 h-4" />
                  Add Student
                </Button>
              </DialogTrigger>
              <DialogContent>
                <DialogHeader>
                  <DialogTitle>Add New Student</DialogTitle>
                  <DialogDescription>
                    Fill in the student's information below
                  </DialogDescription>
                </DialogHeader>
                <div className="space-y-4">
                  <div>
                    <Label htmlFor="name">Full Name</Label>
                    <Input
                      id="name"
                      value={newStudent.name}
                      onChange={(e) =>
                        setNewStudent({ ...newStudent, name: e.target.value })
                      }
                      placeholder="Daniel Gyan"
                    />
                  </div>
                  <div>
                    <Label htmlFor="dob">Date of Birth <span className="text-muted-foreground">(Optional)</span></Label>
                    <Input
                      id="dob"
                      type="date"
                      value={newStudent.dob}
                      onChange={(e) =>
                        setNewStudent({ ...newStudent, dob: e.target.value })
                      }
                    />
                  </div>
                  <div>
                    <Label htmlFor="gender">Gender</Label>
                    <select
                      id="gender"
                      value={newStudent.gender}
                      onChange={(e) =>
                        setNewStudent({ ...newStudent, gender: e.target.value })
                      }
                      className="w-full px-3 py-2 border border-input rounded-md bg-background"
                    >
                      <option value="">Select Gender</option>
                      <option value="Male">Male</option>
                      <option value="Female">Female</option>
                    </select>
                  </div>
                  <div>
                    <Label htmlFor="class">Class</Label>
                    <select
                      id="class"
                      value={newStudent.class}
                      onChange={(e) =>
                        setNewStudent({ ...newStudent, class: e.target.value })
                      }
                      className="w-full px-3 py-2 border border-input rounded-md bg-background"
                    >
                      <option value="">Select Class</option>
                      {classes.map((cls) => (
                        <option key={cls} value={cls}>
                          {cls}
                        </option>
                      ))}
                    </select>
                  </div>
                  <div>
                    <Label htmlFor="parentName">Parent/Guardian Name <span className="text-muted-foreground">(Optional)</span></Label>
                    <Input
                      id="parentName"
                      value={newStudent.parentName}
                      onChange={(e) =>
                        setNewStudent({ ...newStudent, parentName: e.target.value })
                      }
                      placeholder="Parent's name"
                    />
                  </div>
                  <div>
                    <Label htmlFor="parentPhone">Parent Phone Number <span className="text-muted-foreground">(Optional)</span></Label>
                    <Input
                      id="parentPhone"
                      value={newStudent.parentPhone}
                      onChange={(e) =>
                        setNewStudent({ ...newStudent, parentPhone: e.target.value })
                      }
                      placeholder="+233503413080"
                    />
                  </div>
                  <Button onClick={handleAddStudent} className="w-full">
                    Add Student
                  </Button>
                </div>
              </DialogContent>
            </Dialog>
          </div>

          {/* Results Counter */}
          <div className="text-sm text-muted-foreground">
            Showing {filteredStudents.length} of {students.length} students
            {selectedClass && ` in ${selectedClass}`}
          </div>

          {/* Students List */}
          <div className="grid gap-4">
            {filteredStudents.length === 0 ? (
              <Card className="border-border/50">
                <CardContent className="text-center py-8 text-muted-foreground">
                  No students found
                </CardContent>
              </Card>
            ) : (
              filteredStudents.map((student) => (
                <Card key={student.id} className="border-border/50 hover:shadow-md transition-shadow">
                  <CardContent className="pt-6">
                    <div className="flex flex-col sm:flex-row sm:items-center sm:justify-between gap-4">
                      <div className="flex-1">
                        <div className="flex items-center gap-3 mb-2">
                          <h4 className="font-semibold text-foreground">{student.full_name}</h4>
                          <Badge variant="outline" className="text-xs">
                            {student.student_number || student.student_id || 'No ID'}
                          </Badge>
                        </div>
                        <div className="grid grid-cols-2 sm:grid-cols-4 gap-4 text-sm text-muted-foreground">
                          <div>
                            <p className="text-xs font-semibold">Class</p>
                            <p>{student.class}</p>
                          </div>
                          <div>
                            <p className="text-xs font-semibold">Gender</p>
                            <p>{student.gender}</p>
                          </div>
                          <div>
                            <p className="text-xs font-semibold">Parent</p>
                            <p>{student.parent_name}</p>
                          </div>
                          <div>
                            <p className="text-xs font-semibold">Phone</p>
                            <p>{student.parent_phone}</p>
                          </div>
                        </div>
                      </div>
                      <div className="flex gap-2">
                        <Button 
                          variant="ghost" 
                          size="icon"
                          onClick={() => setEditingStudent(student)}
                        >
                          <Edit2 className="w-4 h-4" />
                        </Button>
                        <Button
                          variant="ghost"
                          size="icon"
                          onClick={() => handleDeleteStudent(student.id)}
                        >
                          <Trash2 className="w-4 h-4 text-destructive" />
                        </Button>
                      </div>
                    </div>
                  </CardContent>
                </Card>
              ))
            )}
          </div>
        </TabsContent>

        {/* CLASSES TAB */}
        <TabsContent value="classes" className="space-y-6 mt-6">
          <Card className="border-border/50">
            <CardHeader>
              <CardTitle className="flex items-center gap-2">
                <Users className="w-5 h-5" />
                Class List
              </CardTitle>
            </CardHeader>
            <CardContent>
              <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4">
                {classes.map((cls) => (
                  <Card
                    key={cls}
                    className="border-border/50 cursor-pointer hover:border-primary/50 transition-colors"
                    onClick={() => setSelectedClass(cls)}
                  >
                    <CardContent className="pt-6 text-center">
                      <h4 className="text-lg font-bold text-foreground mb-2">Class {cls}</h4>
                      <p className="text-3xl font-bold text-primary">
                        {classStudentCount(cls)}
                      </p>
                      <p className="text-sm text-muted-foreground mt-2">Students Enrolled</p>
                    </CardContent>
                  </Card>
                ))}
              </div>
            </CardContent>
          </Card>

          {selectedClass && (
            <Card className="border-border/50">
              <CardHeader>
                <CardTitle className="flex items-center justify-between">
                  <span>Class {selectedClass} - Students</span>
                  <div className="flex gap-2">
                    <Button
                      variant="outline"
                      size="sm"
                      onClick={() => toggleSelectAll(selectedClass)}
                    >
                      {students.filter(s => s.class === selectedClass && s.status === "active").every(s => selectedStudentsForPromotion.has(s.id))
                        ? "Deselect All"
                        : "Select All"}
                    </Button>
                  </div>
                </CardTitle>
              </CardHeader>
              <CardContent>
                <div className="space-y-3">
                  {students
                    .filter((s) => s.class === selectedClass && s.status === "active")
                    .map((student) => (
                      <div
                        key={student.id}
                        className="p-3 border border-border/50 rounded-lg flex justify-between items-center hover:bg-muted/50 transition-colors"
                      >
                        <div className="flex items-center gap-3">
                          <input
                            type="checkbox"
                            checked={selectedStudentsForPromotion.has(student.id)}
                            onChange={() => toggleStudentSelection(student.id)}
                            className="w-4 h-4 rounded border-gray-300 text-primary focus:ring-primary cursor-pointer"
                          />
                          <div>
                            <p className="font-medium text-foreground">{student.full_name}</p>
                            <p className="text-sm text-muted-foreground">{student.student_number || student.student_id || 'No ID'}</p>
                          </div>
                        </div>
                        <Badge>{student.gender}</Badge>
                      </div>
                    ))}
                </div>
                
                {students.filter(s => s.class === selectedClass && s.status === "active").length === 0 && (
                  <p className="text-center text-muted-foreground py-8">No students in this class</p>
                )}
                
                <div className="mt-6 space-y-3">
                  <div className="flex items-center justify-between p-3 bg-muted rounded-lg">
                    <span className="text-sm font-medium">
                      {selectedStudentsForPromotion.size > 0 
                        ? `${selectedStudentsForPromotion.size} student(s) selected for promotion`
                        : "No students selected"}
                    </span>
                    {selectedStudentsForPromotion.size > 0 && (
                      <Button
                        variant="ghost"
                        size="sm"
                        onClick={() => setSelectedStudentsForPromotion(new Set())}
                      >
                        Clear Selection
                      </Button>
                    )}
                  </div>
                  
                  <div className="grid grid-cols-1 sm:grid-cols-2 gap-3">
                    <Button 
                      className="w-full"
                      onClick={() => handlePromoteClass(selectedClass)}
                      variant={selectedClass === "JHS3" ? "destructive" : "default"}
                    >
                      {selectedClass === "JHS3" 
                        ? `Graduate All (${students.filter(s => s.class === "JHS3" && s.status === "active").length})`
                        : `Promote All to ${classes[classes.indexOf(selectedClass) + 1] || 'Next Class'}`
                      }
                    </Button>
                    
                    <Button 
                      className="w-full"
                      onClick={() => handleSelectivePromotion(selectedClass)}
                      variant="outline"
                      disabled={selectedStudentsForPromotion.size === 0}
                    >
                      {selectedClass === "JHS3" 
                        ? `Graduate Selected (${selectedStudentsForPromotion.size})`
                        : `Promote Selected (${selectedStudentsForPromotion.size})`
                      }
                    </Button>
                  </div>
                  
                  {selectedStudentsForPromotion.size > 0 && selectedStudentsForPromotion.size < students.filter(s => s.class === selectedClass && s.status === "active").length && (
                    <p className="text-xs text-muted-foreground text-center">
                      {students.filter(s => s.class === selectedClass && s.status === "active").length - selectedStudentsForPromotion.size} student(s) will repeat {selectedClass}
                    </p>
                  )}
                </div>
              </CardContent>
            </Card>
          )}
        </TabsContent>

        {/* STAFF TAB */}
        <TabsContent value="staff" className="space-y-6 mt-6">
          <div className="flex flex-col sm:flex-row gap-4 items-start sm:items-center justify-between">
            <div className="flex flex-col sm:flex-row gap-3 flex-1 w-full">
              {/* Sort By Dropdown */}
              <div className="w-full sm:w-48">
                <select
                  value={staffSortBy}
                  onChange={(e) => setStaffSortBy(e.target.value as any)}
                  className="w-full px-3 py-2 border border-input rounded-md bg-background text-sm h-10"
                >
                  <option value="lastName">Sort by Last Name</option>
                  <option value="firstName">Sort by First Name</option>
                  <option value="staffNumber">Sort by Staff Number</option>
                  <option value="employmentDate">Sort by Employment Date</option>
                </select>
              </div>
              {/* Search Input */}
              <div className="relative flex-1 sm:max-w-xs">
                <Search className="absolute left-3 top-3 w-4 h-4 text-muted-foreground" />
                <Input
                  placeholder="Search staff..."
                  value={searchTerm}
                  onChange={(e) => setSearchTerm(e.target.value)}
                  className="pl-10"
                />
              </div>
            </div>
            <Dialog open={isStaffDialogOpen} onOpenChange={setIsStaffDialogOpen}>
              <DialogTrigger asChild>
                <Button className="gap-2">
                  <Plus className="w-4 h-4" />
                  Add Staff
                </Button>
              </DialogTrigger>
              <DialogContent className="max-w-md max-h-[90vh] overflow-y-auto">
                <DialogHeader>
                  <DialogTitle>Add New Staff Member</DialogTitle>
                  <DialogDescription>
                    Fill in the staff member's information below
                  </DialogDescription>
                </DialogHeader>
                <div className="space-y-4 pb-4">
                  <div>
                    <Label htmlFor="staffName">Full Name *</Label>
                    <Input
                      id="staffName"
                      value={newStaff.name}
                      onChange={(e) =>
                        setNewStaff({ ...newStaff, name: e.target.value })
                      }
                      placeholder="John Doe"
                    />
                  </div>
                  
                  <div>
                    <Label htmlFor="staffPosition">Position *</Label>
                    <select
                      id="staffPosition"
                      value={newStaff.position}
                      onChange={(e) =>
                        setNewStaff({ ...newStaff, position: e.target.value })
                      }
                      className="w-full px-3 py-2 border border-input rounded-md bg-background"
                    >
                      <option value="">Select Position</option>
                      {staffPositions.map((position) => (
                        <option key={position} value={position}>
                          {position}
                        </option>
                      ))}
                    </select>
                  </div>

                  <div>
                    <Label htmlFor="staffPhone">Phone Number *</Label>
                    <Input
                      id="staffPhone"
                      value={newStaff.phone}
                      onChange={(e) =>
                        setNewStaff({ ...newStaff, phone: e.target.value })
                      }
                      placeholder="+233503413080"
                    />
                  </div>

                  <div>
                    <Label htmlFor="staffSpecialization">Specialization</Label>
                    <Input
                      id="staffSpecialization"
                      value={newStaff.specialization}
                      onChange={(e) =>
                        setNewStaff({ ...newStaff, specialization: e.target.value })
                      }
                      placeholder="Mathematics, Science, etc."
                    />
                  </div>

                  {/* Class Assignment for Teachers */}
                  {newStaff.position.toLowerCase().includes('teacher') && (
                    <div>
                      <Label htmlFor="assignedClass">Assigned Class</Label>
                      <select
                        id="assignedClass"
                        value={newStaff.assignedClass}
                        onChange={(e) =>
                          setNewStaff({ ...newStaff, assignedClass: e.target.value })
                        }
                        className="w-full px-3 py-2 border border-input rounded-md bg-background"
                      >
                        <option value="">Select Class (Optional)</option>
                        {classes.map((cls) => (
                          <option key={cls} value={cls}>
                            {cls}
                          </option>
                        ))}
                      </select>
                      <p className="text-sm text-muted-foreground mt-1">
                        Teachers can only see students from their assigned class
                      </p>
                    </div>
                  )}

                  {/* Login Account Section */}
                  <div className="border-t pt-4">
                    <div className="flex items-center space-x-2">
                      <input
                        type="checkbox"
                        id="createLogin"
                        checked={newStaff.createLogin}
                        onChange={(e) => setNewStaff({ ...newStaff, createLogin: e.target.checked })}
                        className="rounded"
                      />
                      <Label htmlFor="createLogin">Create login account</Label>
                    </div>
                    <p className="text-sm text-muted-foreground mt-1">
                      Allow this staff member to login to the system
                    </p>
                  </div>

                  {newStaff.createLogin && (
                    <>
                      <div>
                        <Label htmlFor="staffEmail">Email Address *</Label>
                        <Input
                          id="staffEmail"
                          type="email"
                          value={newStaff.email}
                          onChange={(e) => setNewStaff({ ...newStaff, email: e.target.value })}
                          placeholder="john.doe@school.edu"
                        />
                      </div>

                      <div>
                        <Label htmlFor="staffPassword">Password *</Label>
                        <Input
                          id="staffPassword"
                          type="password"
                          value={newStaff.password}
                          onChange={(e) => setNewStaff({ ...newStaff, password: e.target.value })}
                          placeholder="Minimum 6 characters"
                        />
                      </div>
                    </>
                  )}

                  <div className="pt-4 border-t">
                    <Button onClick={handleAddStaff} className="w-full">
                      Add Staff Member
                    </Button>
                  </div>
                </div>
              </DialogContent>
            </Dialog>
          </div>

          {/* Staff List */}
          <div className="grid gap-4">
            {filteredStaff.length === 0 ? (
              <Card className="border-border/50">
                <CardContent className="text-center py-8 text-muted-foreground">
                  No staff members found
                </CardContent>
              </Card>
            ) : (
              filteredStaff.map((member) => (
                <Card key={member.id} className="border-border/50 hover:shadow-md transition-shadow">
                  <CardContent className="pt-6">
                    <div className="flex flex-col sm:flex-row sm:items-center sm:justify-between gap-4">
                      <div className="flex-1">
                        <div className="flex items-center gap-3 mb-2">
                          <h4 className="font-semibold text-foreground">{member.full_name}</h4>
                          <Badge variant="outline" className="text-xs">
                            {member.staff_id}
                          </Badge>
                        </div>
                        <div className="grid grid-cols-2 sm:grid-cols-4 gap-4 text-sm text-muted-foreground">
                          <div>
                            <p className="text-xs font-semibold">Position</p>
                            <p>{member.position}</p>
                          </div>
                          <div>
                            <p className="text-xs font-semibold">Specialization</p>
                            <p>{member.specialization}</p>
                          </div>
                          <div>
                            <p className="text-xs font-semibold">Phone</p>
                            <p>{member.phone}</p>
                          </div>
                          {member.position.toLowerCase().includes('teacher') && (
                            <div>
                              <p className="text-xs font-semibold">Assigned Class</p>
                              <p className={member.assigned_class ? "text-primary font-medium" : "text-muted-foreground italic"}>
                                {member.assigned_class || "No class assigned"}
                              </p>
                            </div>
                          )}
                        </div>
                      </div>
                      <div className="flex gap-2">
                        <Button 
                          variant="ghost" 
                          size="icon"
                          onClick={() => setEditingStaff(member)}
                        >
                          <Edit2 className="w-4 h-4" />
                        </Button>
                        <Button
                          variant="ghost"
                          size="icon"
                          onClick={() => handleDeleteStaff(member.id)}
                        >
                          <Trash2 className="w-4 h-4 text-destructive" />
                        </Button>
                      </div>
                    </div>
                  </CardContent>
                </Card>
              ))
            )}
          </div>
        </TabsContent>
      </Tabs>
      )}

      {/* Edit Student Dialog */}
      <Dialog open={!!editingStudent} onOpenChange={() => setEditingStudent(null)}>
        <DialogContent>
          <DialogHeader>
            <DialogTitle>Edit Student</DialogTitle>
            <DialogDescription>
              Update the student's information below
            </DialogDescription>
          </DialogHeader>
          {editingStudent && (
            <div className="space-y-4">
              <div>
                <Label htmlFor="edit-name">Full Name</Label>
                <Input
                  id="edit-name"
                  value={editingStudent.full_name}
                  onChange={(e) =>
                    setEditingStudent({ ...editingStudent, full_name: e.target.value })
                  }
                  placeholder="Daniel Gyan"
                />
              </div>
              <div>
                <Label htmlFor="edit-dob">Date of Birth <span className="text-muted-foreground">(Optional)</span></Label>
                <Input
                  id="edit-dob"
                  type="date"
                  value={editingStudent.date_of_birth}
                  onChange={(e) =>
                    setEditingStudent({ ...editingStudent, date_of_birth: e.target.value })
                  }
                />
              </div>
              <div>
                <Label htmlFor="edit-gender">Gender</Label>
                <select
                  id="edit-gender"
                  value={editingStudent.gender}
                  onChange={(e) =>
                    setEditingStudent({ ...editingStudent, gender: e.target.value })
                  }
                  className="w-full px-3 py-2 border border-input rounded-md bg-background"
                >
                  <option value="">Select Gender</option>
                  <option value="Male">Male</option>
                  <option value="Female">Female</option>
                </select>
              </div>
              <div>
                <Label htmlFor="edit-class">Class</Label>
                <select
                  id="edit-class"
                  value={editingStudent.class}
                  onChange={(e) =>
                    setEditingStudent({ ...editingStudent, class: e.target.value })
                  }
                  className="w-full px-3 py-2 border border-input rounded-md bg-background"
                >
                  <option value="">Select Class</option>
                  {classes.map((cls) => (
                    <option key={cls} value={cls}>
                      {cls}
                    </option>
                  ))}
                </select>
              </div>
              <div>
                <Label htmlFor="edit-parentName">Parent/Guardian Name <span className="text-muted-foreground">(Optional)</span></Label>
                <Input
                  id="edit-parentName"
                  value={editingStudent.parent_name}
                  onChange={(e) =>
                    setEditingStudent({ ...editingStudent, parent_name: e.target.value })
                  }
                  placeholder="Parent's name"
                />
              </div>
              <div>
                <Label htmlFor="edit-parentPhone">Parent Phone Number <span className="text-muted-foreground">(Optional)</span></Label>
                <Input
                  id="edit-parentPhone"
                  value={editingStudent.parent_phone}
                  onChange={(e) =>
                    setEditingStudent({ ...editingStudent, parent_phone: e.target.value })
                  }
                  placeholder="+233503413080"
                />
              </div>
              <div className="flex gap-2">
                <Button 
                  variant="outline" 
                  onClick={() => setEditingStudent(null)}
                  className="flex-1"
                >
                  Cancel
                </Button>
                <Button 
                  onClick={() => handleEditStudent(editingStudent)} 
                  className="flex-1"
                >
                  Save Changes
                </Button>
              </div>
            </div>
          )}
        </DialogContent>
      </Dialog>

      {/* Edit Staff Dialog */}
      <Dialog open={!!editingStaff} onOpenChange={() => setEditingStaff(null)}>
        <DialogContent>
          <DialogHeader>
            <DialogTitle>Edit Staff Member</DialogTitle>
            <DialogDescription>
              Update the staff member's information below
            </DialogDescription>
          </DialogHeader>
          {editingStaff && (
            <div className="space-y-4">
              <div>
                <Label htmlFor="edit-staffName">Full Name</Label>
                <Input
                  id="edit-staffName"
                  value={editingStaff.full_name}
                  onChange={(e) =>
                    setEditingStaff({ ...editingStaff, full_name: e.target.value })
                  }
                  placeholder="Mr./Mrs. Name"
                />
              </div>
              <div>
                <Label htmlFor="edit-staffPhone">Phone Number</Label>
                <Input
                  id="edit-staffPhone"
                  value={editingStaff.phone}
                  onChange={(e) =>
                    setEditingStaff({ ...editingStaff, phone: e.target.value })
                  }
                  placeholder="+233503413080"
                />
              </div>
              <div>
                <Label htmlFor="edit-position">Position/Role</Label>
                <Input
                  id="edit-position"
                  value={editingStaff.position}
                  onChange={(e) =>
                    setEditingStaff({ ...editingStaff, position: e.target.value })
                  }
                  placeholder="Headmaster, Teacher, etc."
                />
              </div>
              <div>
                <Label htmlFor="edit-specialization">Specialization</Label>
                <Input
                  id="edit-specialization"
                  value={editingStaff.specialization}
                  onChange={(e) =>
                    setEditingStaff({ ...editingStaff, specialization: e.target.value })
                  }
                  placeholder="Mathematics, English, etc."
                />
              </div>

              {/* Class Assignment for Teachers */}
              {editingStaff.position.toLowerCase().includes('teacher') && (
                <div>
                  <Label htmlFor="edit-assignedClass">Assigned Class</Label>
                  <select
                    id="edit-assignedClass"
                    value={editingStaff.assigned_class || ""}
                    onChange={(e) =>
                      setEditingStaff({ ...editingStaff, assigned_class: e.target.value })
                    }
                    className="w-full px-3 py-2 border border-input rounded-md bg-background"
                  >
                    <option value="">No Class Assigned</option>
                    {classes.map((cls) => (
                      <option key={cls} value={cls}>
                        {cls}
                      </option>
                    ))}
                  </select>
                  <p className="text-sm text-muted-foreground mt-1">
                    Teachers can only see students from their assigned class
                  </p>
                </div>
              )}
              <div className="flex gap-2">
                <Button 
                  variant="outline" 
                  onClick={() => setEditingStaff(null)}
                  className="flex-1"
                >
                  Cancel
                </Button>
                <Button 
                  onClick={() => handleEditStaff(editingStaff)} 
                  className="flex-1"
                >
                  Save Changes
                </Button>
              </div>
            </div>
          )}
        </DialogContent>
      </Dialog>
    </Layout>
  );
}
