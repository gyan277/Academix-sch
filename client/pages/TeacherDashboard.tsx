import { useState, useEffect } from "react";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import { Tabs, TabsContent, TabsList, TabsTrigger } from "@/components/ui/tabs";
import {
  Table,
  TableBody,
  TableCell,
  TableHead,
  TableHeader,
  TableRow,
} from "@/components/ui/table";
import {
  Dialog,
  DialogContent,
  DialogDescription,
  DialogHeader,
  DialogTitle,
  DialogTrigger,
} from "@/components/ui/dialog";
import { DollarSign, Users, CheckCircle, Clock, AlertCircle } from "lucide-react";
import { supabase } from "@/lib/supabase";
import { useToast } from "@/hooks/use-toast";
import { useAuth } from "@/hooks/use-auth";
import { useAcademicYear } from "@/hooks/use-academic-year";
import Layout from "@/components/Layout";

interface Student {
  id: string;
  student_number: string;
  full_name: string;
  bus_fee: number;
  canteen_fee: number;
  uses_bus: boolean;
  uses_canteen: boolean;
}

interface Collection {
  id: string;
  student_id: string;
  student_name: string;
  collection_type: string;
  amount: number;
  collection_date: string;
  status: string;
  notes?: string;
}

export default function TeacherDashboard() {
  const { toast } = useToast();
  const { profile } = useAuth();
  const { academicYear, term } = useAcademicYear();
  
  const [loading, setLoading] = useState(true);
  const [featureEnabled, setFeatureEnabled] = useState(false);
  const [students, setStudents] = useState<Student[]>([]);
  const [collections, setCollections] = useState<Collection[]>([]);
  const [selectedStudent, setSelectedStudent] = useState<Student | null>(null);
  const [isCollectionDialogOpen, setIsCollectionDialogOpen] = useState(false);
  const [teacherClass, setTeacherClass] = useState<string>("");
  
  const [collectionForm, setCollectionForm] = useState({
    collection_type: "bus",
    amount: "",
    collection_date: new Date().toISOString().split("T")[0],
    notes: "",
  });

  useEffect(() => {
    if (profile?.school_id) {
      checkFeatureEnabled();
      loadTeacherClass();
      loadCollections();
    }
  }, [profile?.school_id]);

  useEffect(() => {
    if (teacherClass && featureEnabled) {
      loadStudents();
    }
  }, [teacherClass, featureEnabled]);

  const checkFeatureEnabled = async () => {
    try {
      // Use RPC function to bypass schema cache
      const { data, error } = await supabase
        .rpc('is_teacher_fee_collection_enabled', { p_school_id: profile?.school_id });

      if (error) throw error;
      setFeatureEnabled(data || false);
    } catch (error) {
      console.error("Error checking feature:", error);
    }
  };

  const loadTeacherClass = async () => {
    try {
      console.log("=== Loading Teacher Class (via RPC) ===");
      console.log("User ID:", profile?.id);
      
      // Use RPC function to bypass schema cache
      const { data, error } = await supabase
        .rpc('get_teacher_class', { p_user_id: profile?.id });

      if (error) {
        console.error("❌ Error loading teacher record:", error);
        toast({
          title: "Error Loading Teacher Information",
          description: error.message || "Failed to load teacher information",
          variant: "destructive",
        });
        throw error;
      }

      if (!data || data.length === 0) {
        console.error("❌ No teacher record found");
        toast({
          title: "Teacher Record Not Found",
          description: "Your teacher account is not set up. Please contact your administrator.",
          variant: "destructive",
        });
        return;
      }

      const teacherInfo = data[0];
      console.log("✅ Teacher record found:", teacherInfo);
      console.log("Class assigned:", teacherInfo?.class_assigned);
      
      const assignedClass = teacherInfo?.class_assigned?.trim() || "";
      setTeacherClass(assignedClass);
      
      if (!assignedClass) {
        console.warn("⚠️ Teacher has no class assigned");
      } else {
        console.log("✅ Class loaded successfully:", assignedClass);
      }
    } catch (error: any) {
      console.error("❌ Exception in loadTeacherClass:", error);
    }
  };

  const loadStudents = async () => {
    try {
      setLoading(true);

      // Use RPC function to bypass schema cache and get all data in one call
      const { data, error } = await supabase
        .rpc('get_teacher_students_with_fees', {
          p_school_id: profile?.school_id,
          p_class: teacherClass,
          p_academic_year: academicYear,
          p_term: term
        });

      if (error) throw error;

      const studentsWithFees: Student[] = (data || []).map((row: any) => ({
        id: row.student_id,
        student_number: row.student_number,
        full_name: row.full_name,
        bus_fee: parseFloat(row.bus_fee) || 0,
        canteen_fee: parseFloat(row.canteen_fee) || 0,
        uses_bus: row.uses_bus || false,
        uses_canteen: row.uses_canteen || false,
      }));

      setStudents(studentsWithFees);
    } catch (error: any) {
      console.error("Error loading students:", error);
      toast({
        title: "Error",
        description: "Failed to load students",
        variant: "destructive",
      });
    } finally {
      setLoading(false);
    }
  };

  const loadCollections = async () => {
    try {
      // First get teacher ID
      const { data: teacherData } = await supabase
        .rpc('get_teacher_class', { p_user_id: profile?.id });

      if (!teacherData || teacherData.length === 0) return;

      const teacherId = teacherData[0].teacher_id;

      // Use RPC function to get collections
      const { data, error } = await supabase
        .rpc('get_teacher_collections', {
          p_school_id: profile?.school_id,
          p_teacher_id: teacherId,
          p_academic_year: academicYear,
          p_term: term
        });

      if (error) throw error;

      const formattedCollections: Collection[] = (data || []).map((c: any) => ({
        id: c.collection_id,
        student_id: c.student_id,
        student_name: c.student_name || "Unknown",
        collection_type: c.collection_type,
        amount: parseFloat(c.amount),
        collection_date: c.collection_date,
        status: c.status,
        notes: c.notes,
      }));

      setCollections(formattedCollections);
    } catch (error) {
      console.error("Error loading collections:", error);
    }
  };

  const handleCollectFee = async () => {
    if (!selectedStudent) return;

    try {
      // Get teacher ID
      const { data: teacherData } = await supabase
        .rpc('get_teacher_class', { p_user_id: profile?.id });

      if (!teacherData || teacherData.length === 0) {
        toast({
          title: "Error",
          description: "Teacher record not found",
          variant: "destructive",
        });
        return;
      }

      const teacherId = teacherData[0].teacher_id;

      const amount = parseFloat(collectionForm.amount);
      if (isNaN(amount) || amount <= 0) {
        toast({
          title: "Invalid Amount",
          description: "Please enter a valid amount",
          variant: "destructive",
        });
        return;
      }

      // Use RPC function to record collection
      const { data, error } = await supabase
        .rpc('record_teacher_fee_collection', {
          p_school_id: profile?.school_id,
          p_teacher_id: teacherId,
          p_student_id: selectedStudent.id,
          p_collection_type: collectionForm.collection_type,
          p_amount: amount,
          p_collection_date: collectionForm.collection_date,
          p_notes: collectionForm.notes || '',
          p_academic_year: academicYear,
          p_term: term
        });

      if (error) throw error;

      toast({
        title: "Fee Collected",
        description: `${collectionForm.collection_type === "bus" ? "Bus" : "Canteen"} fee collected from ${selectedStudent.full_name}`,
      });

      setIsCollectionDialogOpen(false);
      setSelectedStudent(null);
      setCollectionForm({
        collection_type: "bus",
        amount: "",
        collection_date: new Date().toISOString().split("T")[0],
        notes: "",
      });
      loadCollections();
    } catch (error: any) {
      console.error("Error collecting fee:", error);
      toast({
        title: "Error",
        description: error.message || "Failed to record collection",
        variant: "destructive",
      });
    }
  };

  const pendingCollections = collections.filter(c => c.status === "pending");
  const confirmedCollections = collections.filter(c => c.status === "confirmed");
  const totalPending = pendingCollections.reduce((sum, c) => sum + c.amount, 0);
  const totalConfirmed = confirmedCollections.reduce((sum, c) => sum + c.amount, 0);

  if (!featureEnabled) {
    return (
      <Layout>
        <div className="p-6">
          <Card>
            <CardContent className="py-12">
              <div className="text-center">
                <AlertCircle className="w-16 h-16 mx-auto mb-4 text-muted-foreground" />
                <h3 className="text-lg font-semibold mb-2">Feature Not Enabled</h3>
                <p className="text-muted-foreground">
                  Teacher fee collection is not enabled for your school.
                  <br />
                  Please contact your administrator to enable this feature.
                </p>
              </div>
            </CardContent>
          </Card>
        </div>
      </Layout>
    );
  }

  if (!teacherClass) {
    return (
      <Layout>
        <div className="p-6">
          <Card>
            <CardContent className="py-12">
              <div className="text-center">
                <AlertCircle className="w-16 h-16 mx-auto mb-4 text-muted-foreground" />
                <h3 className="text-lg font-semibold mb-2">No Class Assigned</h3>
                <p className="text-muted-foreground mb-4">
                  You don't have a class assigned yet.
                  <br />
                  Please contact your administrator to assign you to a class.
                </p>
                <div className="mt-6 p-4 bg-muted rounded-lg text-left max-w-md mx-auto">
                  <p className="text-sm font-semibold mb-2">How to fix this:</p>
                  <ol className="text-sm text-muted-foreground space-y-1 list-decimal list-inside">
                    <li>Ask your admin to go to Settings → Teachers</li>
                    <li>Find your name in the teacher list</li>
                    <li>Click Edit on your row</li>
                    <li>Set the "Class Assigned" field (e.g., Primary 1, KG1, etc.)</li>
                    <li>Click Save</li>
                    <li>Refresh this page</li>
                  </ol>
                </div>
              </div>
            </CardContent>
          </Card>
        </div>
      </Layout>
    );
  }

  return (
    <Layout>
      <div className="p-6 space-y-6">
      <div>
        <h1 className="text-2xl sm:text-3xl font-bold">Fee Collection</h1>
        <p className="text-sm sm:text-base text-muted-foreground">Collect bus and canteen fees from your class: {teacherClass}</p>
      </div>

      {/* Summary Cards */}
      <div className="grid grid-cols-2 md:grid-cols-4 gap-3 sm:gap-4">
        <Card>
          <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
            <CardTitle className="text-xs sm:text-sm font-medium">Total Students</CardTitle>
            <Users className="h-3 w-3 sm:h-4 sm:w-4 text-muted-foreground" />
          </CardHeader>
          <CardContent>
            <div className="text-xl sm:text-2xl font-bold">{students.length}</div>
          </CardContent>
        </Card>

        <Card>
          <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
            <CardTitle className="text-xs sm:text-sm font-medium">Pending</CardTitle>
            <Clock className="h-3 w-3 sm:h-4 sm:w-4 text-orange-600" />
          </CardHeader>
          <CardContent>
            <div className="text-lg sm:text-2xl font-bold text-orange-600">GHS {totalPending.toFixed(2)}</div>
            <p className="text-xs text-muted-foreground">{pendingCollections.length}</p>
          </CardContent>
        </Card>

        <Card>
          <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
            <CardTitle className="text-xs sm:text-sm font-medium">Confirmed</CardTitle>
            <CheckCircle className="h-3 w-3 sm:h-4 sm:w-4 text-green-600" />
          </CardHeader>
          <CardContent>
            <div className="text-lg sm:text-2xl font-bold text-green-600">GHS {totalConfirmed.toFixed(2)}</div>
            <p className="text-xs text-muted-foreground">{confirmedCollections.length}</p>
          </CardContent>
        </Card>

        <Card>
          <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
            <CardTitle className="text-xs sm:text-sm font-medium">Total</CardTitle>
            <DollarSign className="h-3 w-3 sm:h-4 sm:w-4 text-primary" />
          </CardHeader>
          <CardContent>
            <div className="text-lg sm:text-2xl font-bold">GHS {(totalPending + totalConfirmed).toFixed(2)}</div>
          </CardContent>
        </Card>
      </div>

      {/* Tabs */}
      <Tabs defaultValue="students">
        <TabsList className="grid w-full grid-cols-2">
          <TabsTrigger value="students">Collect Fees</TabsTrigger>
          <TabsTrigger value="collections">My Collections</TabsTrigger>
        </TabsList>

        {/* Students Tab */}
        <TabsContent value="students">
          <Card>
            <CardHeader>
              <CardTitle>Students in {teacherClass}</CardTitle>
            </CardHeader>
            <CardContent>
              {/* Desktop Table */}
              <div className="hidden md:block overflow-x-auto">
                <Table>
                  <TableHeader>
                    <TableRow>
                      <TableHead>Student Number</TableHead>
                      <TableHead>Name</TableHead>
                      <TableHead className="text-right">Bus Fee</TableHead>
                      <TableHead className="text-right">Canteen Fee</TableHead>
                      <TableHead className="text-right">Actions</TableHead>
                    </TableRow>
                  </TableHeader>
                  <TableBody>
                    {students.length === 0 ? (
                      <TableRow>
                        <TableCell colSpan={5} className="text-center text-muted-foreground">
                          No students found in your class
                        </TableCell>
                      </TableRow>
                    ) : (
                      students.map((student) => (
                        <TableRow key={student.id}>
                          <TableCell className="font-medium">{student.student_number}</TableCell>
                          <TableCell>{student.full_name}</TableCell>
                          <TableCell className="text-right">
                            {student.uses_bus ? `GHS ${student.bus_fee.toFixed(2)}` : "-"}
                          </TableCell>
                          <TableCell className="text-right">
                            {student.uses_canteen ? `GHS ${student.canteen_fee.toFixed(2)}` : "-"}
                          </TableCell>
                          <TableCell className="text-right">
                            <Button
                              size="sm"
                              onClick={() => {
                                setSelectedStudent(student);
                                setCollectionForm({
                                  ...collectionForm,
                                  collection_type: student.uses_bus ? "bus" : "canteen",
                                  amount: student.uses_bus ? student.bus_fee.toString() : student.canteen_fee.toString(),
                                });
                                setIsCollectionDialogOpen(true);
                              }}
                              disabled={!student.uses_bus && !student.uses_canteen}
                            >
                              Collect Fee
                            </Button>
                          </TableCell>
                        </TableRow>
                      ))
                    )}
                  </TableBody>
                </Table>
              </div>

              {/* Mobile Cards */}
              <div className="md:hidden space-y-4">
                {students.length === 0 ? (
                  <p className="text-center text-muted-foreground py-8">
                    No students found in your class
                  </p>
                ) : (
                  students.map((student) => (
                    <Card key={student.id} className="p-4">
                      <div className="space-y-3">
                        <div className="flex justify-between items-start">
                          <div>
                            <p className="font-semibold">{student.full_name}</p>
                            <p className="text-sm text-muted-foreground">{student.student_number}</p>
                          </div>
                        </div>
                        <div className="grid grid-cols-2 gap-2 text-sm">
                          <div>
                            <span className="text-muted-foreground">Bus Fee:</span>
                            <p className="font-medium">
                              {student.uses_bus ? `GHS ${student.bus_fee.toFixed(2)}` : "-"}
                            </p>
                          </div>
                          <div>
                            <span className="text-muted-foreground">Canteen Fee:</span>
                            <p className="font-medium">
                              {student.uses_canteen ? `GHS ${student.canteen_fee.toFixed(2)}` : "-"}
                            </p>
                          </div>
                        </div>
                        <Button
                          size="sm"
                          className="w-full"
                          onClick={() => {
                            setSelectedStudent(student);
                            setCollectionForm({
                              ...collectionForm,
                              collection_type: student.uses_bus ? "bus" : "canteen",
                              amount: student.uses_bus ? student.bus_fee.toString() : student.canteen_fee.toString(),
                            });
                            setIsCollectionDialogOpen(true);
                          }}
                          disabled={!student.uses_bus && !student.uses_canteen}
                        >
                          Collect Fee
                        </Button>
                      </div>
                    </Card>
                  ))
                )}
              </div>
            </CardContent>
          </Card>
        </TabsContent>

        {/* Collections Tab */}
        <TabsContent value="collections">
          <Card>
            <CardHeader>
              <CardTitle>My Fee Collections</CardTitle>
            </CardHeader>
            <CardContent>
              {/* Desktop Table */}
              <div className="hidden md:block overflow-x-auto">
                <Table>
                  <TableHeader>
                    <TableRow>
                      <TableHead>Date</TableHead>
                      <TableHead>Student</TableHead>
                      <TableHead>Type</TableHead>
                      <TableHead className="text-right">Amount</TableHead>
                      <TableHead>Status</TableHead>
                      <TableHead>Notes</TableHead>
                    </TableRow>
                  </TableHeader>
                  <TableBody>
                    {collections.length === 0 ? (
                      <TableRow>
                        <TableCell colSpan={6} className="text-center text-muted-foreground">
                          No collections yet
                        </TableCell>
                      </TableRow>
                    ) : (
                      collections.map((collection) => (
                        <TableRow key={collection.id}>
                          <TableCell>{new Date(collection.collection_date).toLocaleDateString()}</TableCell>
                          <TableCell>{collection.student_name}</TableCell>
                          <TableCell className="capitalize">{collection.collection_type}</TableCell>
                          <TableCell className="text-right">GHS {collection.amount.toFixed(2)}</TableCell>
                          <TableCell>
                            <span className={`px-2 py-1 rounded-full text-xs font-medium ${
                              collection.status === "confirmed" 
                                ? "bg-green-100 text-green-700"
                                : collection.status === "pending"
                                ? "bg-orange-100 text-orange-700"
                                : "bg-red-100 text-red-700"
                            }`}>
                              {collection.status}
                            </span>
                          </TableCell>
                          <TableCell className="text-sm text-muted-foreground">{collection.notes || "-"}</TableCell>
                        </TableRow>
                      ))
                    )}
                  </TableBody>
                </Table>
              </div>

              {/* Mobile Cards */}
              <div className="md:hidden space-y-4">
                {collections.length === 0 ? (
                  <p className="text-center text-muted-foreground py-8">
                    No collections yet
                  </p>
                ) : (
                  collections.map((collection) => (
                    <Card key={collection.id} className="p-4">
                      <div className="space-y-3">
                        <div className="flex justify-between items-start">
                          <div>
                            <p className="font-semibold">{collection.student_name}</p>
                            <p className="text-sm text-muted-foreground">
                              {new Date(collection.collection_date).toLocaleDateString()}
                            </p>
                          </div>
                          <span className={`px-2 py-1 rounded-full text-xs font-medium ${
                            collection.status === "confirmed" 
                              ? "bg-green-100 text-green-700"
                              : collection.status === "pending"
                              ? "bg-orange-100 text-orange-700"
                              : "bg-red-100 text-red-700"
                          }`}>
                            {collection.status}
                          </span>
                        </div>
                        <div className="grid grid-cols-2 gap-2 text-sm">
                          <div>
                            <span className="text-muted-foreground">Type:</span>
                            <p className="font-medium capitalize">{collection.collection_type}</p>
                          </div>
                          <div>
                            <span className="text-muted-foreground">Amount:</span>
                            <p className="font-medium">GHS {collection.amount.toFixed(2)}</p>
                          </div>
                        </div>
                        {collection.notes && (
                          <div className="text-sm">
                            <span className="text-muted-foreground">Notes:</span>
                            <p className="mt-1">{collection.notes}</p>
                          </div>
                        )}
                      </div>
                    </Card>
                  ))
                )}
              </div>
            </CardContent>
          </Card>
        </TabsContent>
      </Tabs>

      {/* Collection Dialog */}
      <Dialog open={isCollectionDialogOpen} onOpenChange={setIsCollectionDialogOpen}>
        <DialogContent>
          <DialogHeader>
            <DialogTitle>Collect Fee</DialogTitle>
            <DialogDescription>
              Record fee collection from {selectedStudent?.full_name}
            </DialogDescription>
          </DialogHeader>
          <div className="space-y-4">
            <div>
              <Label>Fee Type</Label>
              <select
                className="w-full px-3 py-2 border rounded-md"
                value={collectionForm.collection_type}
                onChange={(e) => {
                  const type = e.target.value as "bus" | "canteen";
                  setCollectionForm({
                    ...collectionForm,
                    collection_type: type,
                    amount: type === "bus" 
                      ? selectedStudent?.bus_fee.toString() || ""
                      : selectedStudent?.canteen_fee.toString() || "",
                  });
                }}
              >
                {selectedStudent?.uses_bus && <option value="bus">Bus Fee</option>}
                {selectedStudent?.uses_canteen && <option value="canteen">Canteen Fee</option>}
              </select>
            </div>

            <div>
              <Label>Amount (GHS)</Label>
              <Input
                type="number"
                step="0.01"
                value={collectionForm.amount}
                onChange={(e) => setCollectionForm({ ...collectionForm, amount: e.target.value })}
              />
            </div>

            <div>
              <Label>Collection Date</Label>
              <Input
                type="date"
                value={collectionForm.collection_date}
                onChange={(e) => setCollectionForm({ ...collectionForm, collection_date: e.target.value })}
              />
            </div>

            <div>
              <Label>Notes (Optional)</Label>
              <Input
                value={collectionForm.notes}
                onChange={(e) => setCollectionForm({ ...collectionForm, notes: e.target.value })}
                placeholder="Any additional notes..."
              />
            </div>

            <div className="flex gap-2">
              <Button onClick={handleCollectFee} className="flex-1">
                Record Collection
              </Button>
              <Button variant="outline" onClick={() => setIsCollectionDialogOpen(false)}>
                Cancel
              </Button>
            </div>
          </div>
        </DialogContent>
      </Dialog>
    </div>
    </Layout>
  );
}
