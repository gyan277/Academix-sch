// Enhanced Staff Management for Registrar
// This replaces the current staff management with full teacher functionality

// Add these interfaces to the existing ones in Registrar.tsx
interface EnhancedStaff {
  id: string;
  staff_id: string;
  staff_number: string;
  full_name: string;
  email: string;
  phone: string;
  position: string;
  specialization: string;
  employment_date: string;
  status: string;
  // New fields for teachers
  can_login: boolean;
  assigned_classes: string[];
  subjects: string[];
}

interface TeacherClassAssignment {
  id: string;
  teacher_id: string;
  class_name: string;
  subject: string;
  school_id: string;
}

// Enhanced state for staff management
const [enhancedStaff, setEnhancedStaff] = useState<EnhancedStaff[]>([]);
const [teacherAssignments, setTeacherAssignments] = useState<TeacherClassAssignment[]>([]);
const [isAssignClassDialogOpen, setIsAssignClassDialogOpen] = useState(false);
const [selectedTeacherForAssignment, setSelectedTeacherForAssignment] = useState<string>("");
const [newAssignment, setNewAssignment] = useState({
  class_name: "",
  subject: "",
});

// Enhanced staff form state
const [newStaff, setNewStaff] = useState({
  name: "",
  email: "",
  phone: "",
  position: "",
  specialization: "",
  createLogin: false, // New field
  password: "", // New field
});

// Available positions
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

// Available subjects
const subjects = [
  "Mathematics",
  "English Language", 
  "Science",
  "Social Studies",
  "Physical Education",
  "Creative Arts",
  "Computing",
  "Religious & Moral Education",
  "French",
  "Music"
];

// Enhanced load data function
const loadEnhancedData = async () => {
  try {
    setLoading(true);
    
    if (!profile?.school_id) {
      console.log("⚠️ Profile school_id not loaded yet, waiting...");
      setLoading(false);
      return;
    }

    console.log("🔍 Loading enhanced registrar data for school_id:", profile.school_id);
    
    // Load enhanced staff data with login info
    const { data: staffData, error: staffError } = await supabase
      .from("staff")
      .select(`
        *,
        users!inner(email, role)
      `)
      .eq("status", "active")
      .eq("school_id", profile.school_id)
      .order("full_name");

    if (staffError) {
      console.error("❌ Error loading staff:", staffError);
      throw staffError;
    }
    
    // Load teacher class assignments
    const { data: assignmentsData, error: assignmentsError } = await supabase
      .from("teacher_class_assignments")
      .select("*")
      .eq("school_id", profile.school_id);

    if (assignmentsError && assignmentsError.code !== 'PGRST116') { // Ignore table not found
      console.error("❌ Error loading assignments:", assignmentsError);
    }
    
    // Process staff data
    const processedStaff = staffData?.map(staff => ({
      ...staff,
      can_login: !!staff.users?.email,
      email: staff.users?.email || "",
      assigned_classes: assignmentsData?.filter(a => a.teacher_id === staff.id).map(a => a.class_name) || [],
      subjects: assignmentsData?.filter(a => a.teacher_id === staff.id).map(a => a.subject) || []
    })) || [];
    
    console.log("✅ Loaded enhanced staff:", processedStaff.length);
    setEnhancedStaff(processedStaff);
    setTeacherAssignments(assignmentsData || []);
    
  } catch (error) {
    console.error("Error loading enhanced data:", error);
    toast({
      title: "Error",
      description: "Failed to load staff data from database",
      variant: "destructive",
    });
  } finally {
    setLoading(false);
  }
};

// Enhanced add staff function with login creation
const handleAddEnhancedStaff = async () => {
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
    let userId = null;
    
    // Step 1: Create authentication user if requested
    if (newStaff.createLogin) {
      const { data: authData, error: authError } = await supabase.auth.admin.createUser({
        email: newStaff.email,
        password: newStaff.password,
        email_confirm: true,
        user_metadata: {
          role: newStaff.position.toLowerCase().includes('teacher') ? 'teacher' : 'staff',
          full_name: newStaff.name,
          position: newStaff.position
        }
      });

      if (authError) {
        console.error("❌ Auth creation error:", authError);
        throw new Error(`Failed to create login: ${authError.message}`);
      }
      
      userId = authData.user?.id;
      console.log("✅ Created auth user:", userId);
    }

    // Step 2: Create staff record
    const staffData = {
      id: userId, // Use auth user ID if login created
      full_name: newStaff.name,
      email: newStaff.email || null,
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

    // Step 3: Create users table record if login created
    if (newStaff.createLogin && userId) {
      const { error: usersError } = await supabase
        .from("users")
        .insert([{
          id: userId,
          email: newStaff.email,
          role: newStaff.position.toLowerCase().includes('teacher') ? 'teacher' : 'staff',
          full_name: newStaff.name,
          school_id: profile.school_id,
        }]);

      if (usersError) {
        console.error("❌ Users table error:", usersError);
        // Don't throw here, staff record is already created
      }
    }

    // Step 4: Update local state
    const newStaffMember = {
      ...staffResult,
      can_login: newStaff.createLogin,
      assigned_classes: [],
      subjects: []
    };
    
    setEnhancedStaff([...enhancedStaff, newStaffMember]);
    
    // Reset form
    setNewStaff({
      name: "",
      email: "",
      phone: "",
      position: "",
      specialization: "",
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

// Function to assign classes to teachers
const handleAssignClass = async () => {
  if (!selectedTeacherForAssignment || !newAssignment.class_name || !newAssignment.subject) {
    toast({
      title: "Validation Error",
      description: "Please select teacher, class, and subject",
      variant: "destructive",
    });
    return;
  }

  try {
    // Create teacher_class_assignments table if it doesn't exist
    const { error: createTableError } = await supabase.rpc('create_teacher_assignments_table');
    
    const { data, error } = await supabase
      .from("teacher_class_assignments")
      .insert([{
        teacher_id: selectedTeacherForAssignment,
        class_name: newAssignment.class_name,
        subject: newAssignment.subject,
        school_id: profile.school_id,
      }])
      .select()
      .single();

    if (error) throw error;

    // Update local state
    setTeacherAssignments([...teacherAssignments, data]);
    
    // Update staff member's assignments
    setEnhancedStaff(enhancedStaff.map(staff => 
      staff.id === selectedTeacherForAssignment
        ? {
            ...staff,
            assigned_classes: [...staff.assigned_classes, newAssignment.class_name],
            subjects: [...staff.subjects, newAssignment.subject]
          }
        : staff
    ));

    // Reset form
    setNewAssignment({ class_name: "", subject: "" });
    setIsAssignClassDialogOpen(false);
    
    toast({
      title: "Success",
      description: "Class assignment added successfully",
    });

  } catch (error: any) {
    console.error("Error assigning class:", error);
    toast({
      title: "Error",
      description: error.message || "Failed to assign class",
      variant: "destructive",
    });
  }
};

// Enhanced Staff Dialog JSX
const EnhancedStaffDialog = () => (
  <Dialog open={isStaffDialogOpen} onOpenChange={setIsStaffDialogOpen}>
    <DialogTrigger asChild>
      <Button className="gap-2 w-full sm:w-auto">
        <UserPlus className="w-4 h-4" />
        Add Staff Member
      </Button>
    </DialogTrigger>
    <DialogContent className="max-w-md">
      <DialogHeader>
        <DialogTitle>Add New Staff Member</DialogTitle>
        <DialogDescription>
          Fill in the staff member's information below
        </DialogDescription>
      </DialogHeader>
      <div className="space-y-4">
        <div>
          <Label htmlFor="staff-name">Full Name *</Label>
          <Input
            id="staff-name"
            value={newStaff.name}
            onChange={(e) => setNewStaff({ ...newStaff, name: e.target.value })}
            placeholder="John Doe"
          />
        </div>
        
        <div>
          <Label htmlFor="staff-position">Position *</Label>
          <select
            id="staff-position"
            value={newStaff.position}
            onChange={(e) => setNewStaff({ ...newStaff, position: e.target.value })}
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
          <Label htmlFor="staff-phone">Phone Number *</Label>
          <Input
            id="staff-phone"
            value={newStaff.phone}
            onChange={(e) => setNewStaff({ ...newStaff, phone: e.target.value })}
            placeholder="+233503413080"
          />
        </div>

        <div>
          <Label htmlFor="staff-specialization">Specialization</Label>
          <Input
            id="staff-specialization"
            value={newStaff.specialization}
            onChange={(e) => setNewStaff({ ...newStaff, specialization: e.target.value })}
            placeholder="Mathematics, Science, etc."
          />
        </div>

        {/* Login Account Section */}
        <div className="border-t pt-4">
          <div className="flex items-center space-x-2">
            <input
              type="checkbox"
              id="create-login"
              checked={newStaff.createLogin}
              onChange={(e) => setNewStaff({ ...newStaff, createLogin: e.target.checked })}
              className="rounded"
            />
            <Label htmlFor="create-login">Create login account</Label>
          </div>
          <p className="text-sm text-muted-foreground mt-1">
            Allow this staff member to login to the system
          </p>
        </div>

        {newStaff.createLogin && (
          <>
            <div>
              <Label htmlFor="staff-email">Email Address *</Label>
              <Input
                id="staff-email"
                type="email"
                value={newStaff.email}
                onChange={(e) => setNewStaff({ ...newStaff, email: e.target.value })}
                placeholder="john.doe@school.edu"
              />
            </div>

            <div>
              <Label htmlFor="staff-password">Password *</Label>
              <Input
                id="staff-password"
                type="password"
                value={newStaff.password}
                onChange={(e) => setNewStaff({ ...newStaff, password: e.target.value })}
                placeholder="Minimum 6 characters"
              />
            </div>
          </>
        )}

        <Button onClick={handleAddEnhancedStaff} className="w-full">
          Add Staff Member
        </Button>
      </div>
    </DialogContent>
  </Dialog>
);

// Class Assignment Dialog JSX
const ClassAssignmentDialog = () => (
  <Dialog open={isAssignClassDialogOpen} onOpenChange={setIsAssignClassDialogOpen}>
    <DialogContent>
      <DialogHeader>
        <DialogTitle>Assign Class to Teacher</DialogTitle>
        <DialogDescription>
          Assign a class and subject to a teacher
        </DialogDescription>
      </DialogHeader>
      <div className="space-y-4">
        <div>
          <Label htmlFor="teacher-select">Teacher</Label>
          <select
            id="teacher-select"
            value={selectedTeacherForAssignment}
            onChange={(e) => setSelectedTeacherForAssignment(e.target.value)}
            className="w-full px-3 py-2 border border-input rounded-md bg-background"
          >
            <option value="">Select Teacher</option>
            {enhancedStaff
              .filter(staff => staff.position.toLowerCase().includes('teacher'))
              .map((teacher) => (
                <option key={teacher.id} value={teacher.id}>
                  {teacher.full_name} ({teacher.position})
                </option>
              ))}
          </select>
        </div>

        <div>
          <Label htmlFor="class-select">Class</Label>
          <select
            id="class-select"
            value={newAssignment.class_name}
            onChange={(e) => setNewAssignment({ ...newAssignment, class_name: e.target.value })}
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
          <Label htmlFor="subject-select">Subject</Label>
          <select
            id="subject-select"
            value={newAssignment.subject}
            onChange={(e) => setNewAssignment({ ...newAssignment, subject: e.target.value })}
            className="w-full px-3 py-2 border border-input rounded-md bg-background"
          >
            <option value="">Select Subject</option>
            {subjects.map((subject) => (
              <option key={subject} value={subject}>
                {subject}
              </option>
            ))}
          </select>
        </div>

        <Button onClick={handleAssignClass} className="w-full">
          Assign Class
        </Button>
      </div>
    </DialogContent>
  </Dialog>
);

// Enhanced Staff List JSX
const EnhancedStaffList = () => (
  <div className="space-y-4">
    {enhancedStaff.map((member) => (
      <Card key={member.id} className="border-border/50">
        <CardContent className="p-4">
          <div className="flex items-center justify-between">
            <div className="flex-1">
              <div className="flex items-center gap-3">
                <div>
                  <h3 className="font-medium">{member.full_name}</h3>
                  <p className="text-sm text-muted-foreground">
                    {member.position} • {member.staff_number || member.staff_id}
                  </p>
                  {member.email && (
                    <p className="text-sm text-muted-foreground">{member.email}</p>
                  )}
                  <p className="text-sm text-muted-foreground">{member.phone}</p>
                  {member.specialization && (
                    <p className="text-sm text-muted-foreground">
                      Specialization: {member.specialization}
                    </p>
                  )}
                </div>
              </div>
              
              {/* Show class assignments for teachers */}
              {member.position.toLowerCase().includes('teacher') && (
                <div className="mt-3">
                  <div className="flex items-center gap-2 mb-2">
                    <Badge variant={member.can_login ? "default" : "secondary"}>
                      {member.can_login ? "Can Login" : "No Login"}
                    </Badge>
                    {member.assigned_classes.length > 0 && (
                      <Badge variant="outline">
                        {member.assigned_classes.length} Class{member.assigned_classes.length !== 1 ? 'es' : ''}
                      </Badge>
                    )}
                  </div>
                  
                  {member.assigned_classes.length > 0 ? (
                    <div className="space-y-1">
                      {member.assigned_classes.map((className, index) => (
                        <div key={index} className="text-sm">
                          <span className="font-medium">{className}</span>
                          {member.subjects[index] && (
                            <span className="text-muted-foreground"> - {member.subjects[index]}</span>
                          )}
                        </div>
                      ))}
                    </div>
                  ) : (
                    <p className="text-sm text-muted-foreground">No classes assigned</p>
                  )}
                </div>
              )}
            </div>
            
            <div className="flex items-center gap-2">
              {member.position.toLowerCase().includes('teacher') && (
                <Button
                  variant="outline"
                  size="sm"
                  onClick={() => {
                    setSelectedTeacherForAssignment(member.id);
                    setIsAssignClassDialogOpen(true);
                  }}
                >
                  Assign Class
                </Button>
              )}
              <Button
                variant="outline"
                size="sm"
                onClick={() => setEditingStaff(member)}
              >
                <Edit2 className="w-4 h-4" />
              </Button>
              <Button
                variant="outline"
                size="sm"
                onClick={() => handleDeleteStaff(member.id)}
              >
                <Trash2 className="w-4 h-4" />
              </Button>
            </div>
          </div>
        </CardContent>
      </Card>
    ))}
  </div>
);

export {
  EnhancedStaffDialog,
  ClassAssignmentDialog, 
  EnhancedStaffList,
  loadEnhancedData,
  handleAddEnhancedStaff,
  handleAssignClass
};