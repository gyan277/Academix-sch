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
import { Plus, DollarSign, TrendingUp, AlertCircle, Edit } from "lucide-react";
import { supabase } from "@/lib/supabase";
import { useToast } from "@/hooks/use-toast";
import type { Payment, StudentFeeOverride } from "@shared/types";

interface IncomeDashboardProps {
  schoolId: string;
  academicYear: string;
  term: string;
}

interface StudentWithFees {
  id: string;
  student_number: string;
  full_name: string;
  class: string;
  tuition_fee: number;
  bus_fee: number;
  canteen_fee: number;
  total_fee: number;
  tuition_paid: number;
  bus_paid: number;
  canteen_paid: number;
  total_paid: number;
  tuition_balance: number;
  bus_balance: number;
  canteen_balance: number;
  total_balance: number;
  uses_bus: boolean;
  uses_canteen: boolean;
}

export default function IncomeDashboard({ schoolId, academicYear, term }: IncomeDashboardProps) {
  const { toast } = useToast();
  const [loading, setLoading] = useState(true);
  const [activeTab, setActiveTab] = useState("overview");
  const [selectedClass, setSelectedClass] = useState<string>("all");
  
  const [students, setStudents] = useState<StudentWithFees[]>([]);
  const [selectedStudent, setSelectedStudent] = useState<StudentWithFees | null>(null);
  const [isPaymentDialogOpen, setIsPaymentDialogOpen] = useState(false);
  const [isOverrideDialogOpen, setIsOverrideDialogOpen] = useState(false);
  
  const [paymentForm, setPaymentForm] = useState({
    tuition_amount: "",
    bus_amount: "",
    canteen_amount: "",
    payment_date: new Date().toISOString().split("T")[0],
    payment_method: "cash",
    reference_number: "",
    notes: "",
  });

  const [overrideForm, setOverrideForm] = useState({
    uses_bus: false,
    uses_canteen: false,
    bus_fee_override: "",
    canteen_fee_override: "",
  });

  useEffect(() => {
    loadStudentsWithFees();
  }, [schoolId, academicYear, term]);

  const loadStudentsWithFees = async () => {
    try {
      setLoading(true);
      console.log("Loading students with fees...", { schoolId, academicYear, term });

      // Load students
      const { data: studentsData, error: studentsError } = await supabase
        .from("students")
        .select("id, student_number, full_name, class")
        .eq("school_id", schoolId)
        .eq("status", "active")
        .order("class")
        .order("full_name");

      if (studentsError) throw studentsError;

      // Load class fees
      const { data: classFeesData, error: classFeesError } = await supabase
        .from("class_fees")
        .select("*")
        .eq("school_id", schoolId)
        .eq("academic_year", academicYear)
        .eq("term", term);

      if (classFeesError) throw classFeesError;

      // Load student fee overrides
      const { data: overridesData, error: overridesError } = await supabase
        .from("student_fee_overrides")
        .select("*")
        .eq("school_id", schoolId)
        .eq("academic_year", academicYear)
        .eq("term", term);

      if (overridesError) throw overridesError;

      // Load payments
      const { data: paymentsData, error: paymentsError } = await supabase
        .from("payments")
        .select("student_id, amount, payment_type")
        .eq("school_id", schoolId);

      if (paymentsError) throw paymentsError;

      // Build student fees map
      const classFeeMap = new Map(classFeesData?.map(cf => [cf.class, cf]) || []);
      const overrideMap = new Map(overridesData?.map(o => [o.student_id, o]) || []);
      const paymentMap = new Map<string, { tuition: number; bus: number; canteen: number }>();

      // Calculate payments per student
      paymentsData?.forEach(payment => {
        if (!paymentMap.has(payment.student_id)) {
          paymentMap.set(payment.student_id, { tuition: 0, bus: 0, canteen: 0 });
        }
        const studentPayments = paymentMap.get(payment.student_id)!;
        if (payment.payment_type === "tuition") {
          studentPayments.tuition += Number(payment.amount);
        } else if (payment.payment_type === "bus") {
          studentPayments.bus += Number(payment.amount);
        } else if (payment.payment_type === "canteen") {
          studentPayments.canteen += Number(payment.amount);
        }
      });

      // Calculate fees for each student with separate payment tracking
      const studentsWithFees: StudentWithFees[] = (studentsData || []).map(student => {
        const classFee = classFeeMap.get(student.class);
        const override = overrideMap.get(student.id);
        const payments = paymentMap.get(student.id) || { tuition: 0, bus: 0, canteen: 0 };

        const tuition_fee = classFee?.fee_amount || 0;
        
        let bus_fee = 0;
        if (override?.uses_bus) {
          bus_fee = override.bus_fee_override ?? classFee?.bus_fee ?? 0;
        }

        let canteen_fee = 0;
        if (override?.uses_canteen) {
          canteen_fee = override.canteen_fee_override ?? classFee?.canteen_fee ?? 0;
        }

        const total_fee = tuition_fee + bus_fee + canteen_fee;
        
        // Separate payment tracking
        const tuition_paid = payments.tuition;
        const bus_paid = payments.bus;
        const canteen_paid = payments.canteen;
        const total_paid = tuition_paid + bus_paid + canteen_paid;
        
        // Separate balance tracking
        const tuition_balance = tuition_fee - tuition_paid;
        const bus_balance = bus_fee - bus_paid;
        const canteen_balance = canteen_fee - canteen_paid;
        const total_balance = total_fee - total_paid;

        return {
          id: student.id,
          student_number: student.student_number,
          full_name: student.full_name,
          class: student.class,
          tuition_fee,
          bus_fee,
          canteen_fee,
          total_fee,
          tuition_paid,
          bus_paid,
          canteen_paid,
          total_paid,
          tuition_balance,
          bus_balance,
          canteen_balance,
          total_balance,
          uses_bus: override?.uses_bus || false,
          uses_canteen: override?.uses_canteen || false,
        };
      });

      setStudents(studentsWithFees);
      console.log("Loaded students with fees:", studentsWithFees.length);
    } catch (error: any) {
      console.error("Error loading students with fees:", error);
      toast({
        title: "Error",
        description: "Failed to load student fees",
        variant: "destructive",
      });
    } finally {
      setLoading(false);
    }
  };

  const handleRecordPayment = async () => {
    if (!selectedStudent) {
      toast({
        title: "Validation Error",
        description: "No student selected",
        variant: "destructive",
      });
      return;
    }

    // Check if at least one payment amount is entered
    const tuitionAmt = parseFloat(paymentForm.tuition_amount) || 0;
    const busAmt = parseFloat(paymentForm.bus_amount) || 0;
    const canteenAmt = parseFloat(paymentForm.canteen_amount) || 0;

    if (tuitionAmt === 0 && busAmt === 0 && canteenAmt === 0) {
      toast({
        title: "Validation Error",
        description: "Please enter at least one payment amount",
        variant: "destructive",
      });
      return;
    }

    try {
      const { data: { user } } = await supabase.auth.getUser();
      const payments = [];

      // Prepare tuition payment
      if (tuitionAmt > 0) {
        payments.push({
          school_id: schoolId,
          student_id: selectedStudent.id,
          student_fee_id: null,
          amount: tuitionAmt,
          payment_type: "tuition",
          payment_date: paymentForm.payment_date,
          payment_method: paymentForm.payment_method,
          reference_number: paymentForm.reference_number || null,
          notes: paymentForm.notes ? `Tuition: ${paymentForm.notes}` : "Tuition payment",
          recorded_by: user?.id,
        });
      }

      // Prepare bus payment
      if (busAmt > 0) {
        payments.push({
          school_id: schoolId,
          student_id: selectedStudent.id,
          student_fee_id: null,
          amount: busAmt,
          payment_type: "bus",
          payment_date: paymentForm.payment_date,
          payment_method: paymentForm.payment_method,
          reference_number: paymentForm.reference_number || null,
          notes: paymentForm.notes ? `Bus: ${paymentForm.notes}` : "Bus fee payment",
          recorded_by: user?.id,
        });
      }

      // Prepare canteen payment
      if (canteenAmt > 0) {
        payments.push({
          school_id: schoolId,
          student_id: selectedStudent.id,
          student_fee_id: null,
          amount: canteenAmt,
          payment_type: "canteen",
          payment_date: paymentForm.payment_date,
          payment_method: paymentForm.payment_method,
          reference_number: paymentForm.reference_number || null,
          notes: paymentForm.notes ? `Canteen: ${paymentForm.notes}` : "Canteen fee payment",
          recorded_by: user?.id,
        });
      }

      // Insert all payments at once
      const { error } = await supabase.from("payments").insert(payments);

      if (error) throw error;

      const totalPaid = tuitionAmt + busAmt + canteenAmt;
      toast({
        title: "Payments Recorded",
        description: `Total of GHS ${totalPaid.toFixed(2)} recorded successfully (${payments.length} payment${payments.length > 1 ? 's' : ''})`,
      });

      setIsPaymentDialogOpen(false);
      setSelectedStudent(null);
      setPaymentForm({
        tuition_amount: "",
        bus_amount: "",
        canteen_amount: "",
        payment_date: new Date().toISOString().split("T")[0],
        payment_method: "cash",
        reference_number: "",
        notes: "",
      });
      loadStudentsWithFees();
    } catch (error: any) {
      console.error("Error recording payment:", error);
      toast({
        title: "Error",
        description: error.message || "Failed to record payment",
        variant: "destructive",
      });
    }
  };

  const handleSaveOverride = async () => {
    if (!selectedStudent) return;

    try {
      const overrideData = {
        school_id: schoolId,
        student_id: selectedStudent.id,
        academic_year: academicYear,
        term: term,
        uses_bus: overrideForm.uses_bus,
        uses_canteen: overrideForm.uses_canteen,
        bus_fee_override: overrideForm.bus_fee_override ? parseFloat(overrideForm.bus_fee_override) : null,
        canteen_fee_override: overrideForm.canteen_fee_override ? parseFloat(overrideForm.canteen_fee_override) : null,
      };

      const { error } = await supabase
        .from("student_fee_overrides")
        .upsert(overrideData, {
          onConflict: "student_id,academic_year,term",
        });

      if (error) throw error;

      toast({
        title: "Fee Override Saved",
        description: "Student fee settings have been updated",
      });

      setIsOverrideDialogOpen(false);
      setSelectedStudent(null);
      setOverrideForm({
        uses_bus: false,
        uses_canteen: false,
        bus_fee_override: "",
        canteen_fee_override: "",
      });
      loadStudentsWithFees();
    } catch (error: any) {
      console.error("Error saving override:", error);
      toast({
        title: "Error",
        description: error.message || "Failed to save fee override",
        variant: "destructive",
      });
    }
  };

  // Filter students by selected class
  const filteredStudents = selectedClass === "all" 
    ? students 
    : students.filter(s => s.class === selectedClass);

  // Get unique classes for filter dropdown
  const availableClasses = Array.from(new Set(students.map(s => s.class))).sort();

  // Calculate summary statistics (based on filtered students) - SEPARATE TRACKING
  const totalTuitionExpected = filteredStudents.reduce((sum, s) => sum + s.tuition_fee, 0);
  const totalBusExpected = filteredStudents.reduce((sum, s) => sum + s.bus_fee, 0);
  const totalCanteenExpected = filteredStudents.reduce((sum, s) => sum + s.canteen_fee, 0);
  const totalExpectedIncome = filteredStudents.reduce((sum, s) => sum + s.total_fee, 0);
  
  const totalTuitionCollected = filteredStudents.reduce((sum, s) => sum + s.tuition_paid, 0);
  const totalBusCollected = filteredStudents.reduce((sum, s) => sum + s.bus_paid, 0);
  const totalCanteenCollected = filteredStudents.reduce((sum, s) => sum + s.canteen_paid, 0);
  const totalCollected = filteredStudents.reduce((sum, s) => sum + s.total_paid, 0);
  
  const totalTuitionOutstanding = filteredStudents.reduce((sum, s) => sum + s.tuition_balance, 0);
  const totalBusOutstanding = filteredStudents.reduce((sum, s) => sum + s.bus_balance, 0);
  const totalCanteenOutstanding = filteredStudents.reduce((sum, s) => sum + s.canteen_balance, 0);
  const totalOutstanding = filteredStudents.reduce((sum, s) => sum + s.total_balance, 0);
  
  const collectionRate = totalExpectedIncome > 0 ? (totalCollected / totalExpectedIncome) * 100 : 0;

  if (loading) {
    return (
      <Card>
        <CardContent className="py-12">
          <div className="flex items-center justify-center">
            <div className="animate-spin rounded-full h-8 w-8 border-b-2 border-primary"></div>
          </div>
        </CardContent>
      </Card>
    );
  }

  return (
    <div className="space-y-6">
      {/* Revenue Overview - Total Summary */}
      <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-3 sm:gap-4">
        <Card className="border-l-4 border-l-primary">
          <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
            <CardTitle className="text-xs sm:text-sm font-medium">Total Expected Revenue</CardTitle>
            <DollarSign className="h-4 w-4 sm:h-5 sm:w-5 text-primary" />
          </CardHeader>
          <CardContent className="pb-3">
            <div className="text-xl sm:text-3xl font-bold text-primary">GHS {totalExpectedIncome.toFixed(2)}</div>
            <p className="text-xs text-muted-foreground mt-1">
              All services combined
            </p>
          </CardContent>
        </Card>

        <Card className="border-l-4 border-l-green-600">
          <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
            <CardTitle className="text-xs sm:text-sm font-medium">Total Collected</CardTitle>
            <TrendingUp className="h-4 w-4 sm:h-5 sm:w-5 text-green-600" />
          </CardHeader>
          <CardContent className="pb-3">
            <div className="text-xl sm:text-3xl font-bold text-green-600">GHS {totalCollected.toFixed(2)}</div>
            <p className="text-xs text-muted-foreground mt-1">
              {collectionRate.toFixed(1)}% collection rate
            </p>
          </CardContent>
        </Card>

        <Card className="border-l-4 border-l-orange-600">
          <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
            <CardTitle className="text-xs sm:text-sm font-medium">Total Outstanding</CardTitle>
            <AlertCircle className="h-4 w-4 sm:h-5 sm:w-5 text-orange-600" />
          </CardHeader>
          <CardContent className="pb-3">
            <div className="text-xl sm:text-3xl font-bold text-orange-600">GHS {totalOutstanding.toFixed(2)}</div>
            <p className="text-xs text-muted-foreground mt-1">
              Pending collection
            </p>
          </CardContent>
        </Card>

        <Card className="border-l-4 border-l-accent">
          <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
            <CardTitle className="text-xs sm:text-sm font-medium">Students Status</CardTitle>
            <TrendingUp className="h-4 w-4 sm:h-5 sm:w-5 text-accent" />
          </CardHeader>
          <CardContent className="pb-3">
            <div className="text-xl sm:text-3xl font-bold text-accent">
              {filteredStudents.filter(s => s.total_balance <= 0).length}/{filteredStudents.length}
            </div>
            <p className="text-xs text-muted-foreground mt-1">
              Fully paid students
            </p>
          </CardContent>
        </Card>
      </div>

      {/* Revenue Breakdown by Service Type */}
      <div>
        <h3 className="text-base sm:text-lg font-semibold mb-3">Revenue Breakdown by Service</h3>
        <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
          {/* Tuition Revenue Card */}
          <Card className="border-t-4 border-t-primary">
            <CardHeader className="pb-3">
              <CardTitle className="text-sm font-medium flex items-center gap-2">
                <div className="h-8 w-8 rounded-full bg-primary/10 flex items-center justify-center">
                  <DollarSign className="h-4 w-4 text-primary" />
                </div>
                Tuition Fees
              </CardTitle>
            </CardHeader>
            <CardContent className="space-y-3">
              <div className="space-y-2">
                <div className="flex justify-between items-center">
                  <span className="text-xs text-muted-foreground">Expected</span>
                  <span className="text-sm font-semibold">GHS {totalTuitionExpected.toFixed(2)}</span>
                </div>
                <div className="flex justify-between items-center">
                  <span className="text-xs text-muted-foreground">Collected</span>
                  <span className="text-sm font-bold text-green-600">GHS {totalTuitionCollected.toFixed(2)}</span>
                </div>
                <div className="flex justify-between items-center">
                  <span className="text-xs text-muted-foreground">Outstanding</span>
                  <span className="text-sm font-bold text-orange-600">GHS {totalTuitionOutstanding.toFixed(2)}</span>
                </div>
              </div>
              <div className="pt-2 border-t">
                <div className="flex justify-between items-center">
                  <span className="text-xs font-medium">Collection Rate</span>
                  <span className="text-sm font-bold text-primary">
                    {totalTuitionExpected > 0 ? ((totalTuitionCollected / totalTuitionExpected) * 100).toFixed(1) : 0}%
                  </span>
                </div>
                <div className="w-full bg-muted rounded-full h-2 mt-2">
                  <div 
                    className="bg-primary h-2 rounded-full transition-all"
                    style={{ width: `${totalTuitionExpected > 0 ? (totalTuitionCollected / totalTuitionExpected) * 100 : 0}%` }}
                  ></div>
                </div>
              </div>
            </CardContent>
          </Card>

          {/* Bus Revenue Card */}
          <Card className="border-t-4 border-t-secondary">
            <CardHeader className="pb-3">
              <CardTitle className="text-sm font-medium flex items-center gap-2">
                <div className="h-8 w-8 rounded-full bg-secondary/10 flex items-center justify-center">
                  <DollarSign className="h-4 w-4 text-secondary" />
                </div>
                Bus Fees
              </CardTitle>
            </CardHeader>
            <CardContent className="space-y-3">
              <div className="space-y-2">
                <div className="flex justify-between items-center">
                  <span className="text-xs text-muted-foreground">Expected</span>
                  <span className="text-sm font-semibold">GHS {totalBusExpected.toFixed(2)}</span>
                </div>
                <div className="flex justify-between items-center">
                  <span className="text-xs text-muted-foreground">Collected</span>
                  <span className="text-sm font-bold text-green-600">GHS {totalBusCollected.toFixed(2)}</span>
                </div>
                <div className="flex justify-between items-center">
                  <span className="text-xs text-muted-foreground">Outstanding</span>
                  <span className="text-sm font-bold text-orange-600">GHS {totalBusOutstanding.toFixed(2)}</span>
                </div>
              </div>
              <div className="pt-2 border-t">
                <div className="flex justify-between items-center">
                  <span className="text-xs font-medium">Collection Rate</span>
                  <span className="text-sm font-bold text-secondary">
                    {totalBusExpected > 0 ? ((totalBusCollected / totalBusExpected) * 100).toFixed(1) : 0}%
                  </span>
                </div>
                <div className="w-full bg-muted rounded-full h-2 mt-2">
                  <div 
                    className="bg-secondary h-2 rounded-full transition-all"
                    style={{ width: `${totalBusExpected > 0 ? (totalBusCollected / totalBusExpected) * 100 : 0}%` }}
                  ></div>
                </div>
              </div>
            </CardContent>
          </Card>

          {/* Canteen Revenue Card */}
          <Card className="border-t-4 border-t-accent">
            <CardHeader className="pb-3">
              <CardTitle className="text-sm font-medium flex items-center gap-2">
                <div className="h-8 w-8 rounded-full bg-accent/10 flex items-center justify-center">
                  <DollarSign className="h-4 w-4 text-accent" />
                </div>
                Canteen Fees
              </CardTitle>
            </CardHeader>
            <CardContent className="space-y-3">
              <div className="space-y-2">
                <div className="flex justify-between items-center">
                  <span className="text-xs text-muted-foreground">Expected</span>
                  <span className="text-sm font-semibold">GHS {totalCanteenExpected.toFixed(2)}</span>
                </div>
                <div className="flex justify-between items-center">
                  <span className="text-xs text-muted-foreground">Collected</span>
                  <span className="text-sm font-bold text-green-600">GHS {totalCanteenCollected.toFixed(2)}</span>
                </div>
                <div className="flex justify-between items-center">
                  <span className="text-xs text-muted-foreground">Outstanding</span>
                  <span className="text-sm font-bold text-orange-600">GHS {totalCanteenOutstanding.toFixed(2)}</span>
                </div>
              </div>
              <div className="pt-2 border-t">
                <div className="flex justify-between items-center">
                  <span className="text-xs font-medium">Collection Rate</span>
                  <span className="text-sm font-bold text-accent">
                    {totalCanteenExpected > 0 ? ((totalCanteenCollected / totalCanteenExpected) * 100).toFixed(1) : 0}%
                  </span>
                </div>
                <div className="w-full bg-muted rounded-full h-2 mt-2">
                  <div 
                    className="bg-accent h-2 rounded-full transition-all"
                    style={{ width: `${totalCanteenExpected > 0 ? (totalCanteenCollected / totalCanteenExpected) * 100 : 0}%` }}
                  ></div>
                </div>
              </div>
            </CardContent>
          </Card>
        </div>
      </div>

      {/* Tabs */}
      <Tabs value={activeTab} onValueChange={setActiveTab}>
        <TabsList className="grid w-full max-w-md grid-cols-2">
          <TabsTrigger value="overview" className="text-xs sm:text-sm">Student Balances</TabsTrigger>
          <TabsTrigger value="outstanding" className="text-xs sm:text-sm">Outstanding Only</TabsTrigger>
        </TabsList>

        {/* All Students Tab */}
        <TabsContent value="overview" className="mt-6">
          <Card>
            <CardHeader>
              <div className="flex flex-col sm:flex-row sm:items-center sm:justify-between gap-3">
                <div>
                  <CardTitle className="text-base sm:text-lg">Student Payment Status</CardTitle>
                  <p className="text-xs sm:text-sm text-muted-foreground">
                    View and manage student fees and payments
                  </p>
                </div>
                <div className="flex items-center gap-2">
                  <Label htmlFor="class-filter" className="text-xs sm:text-sm whitespace-nowrap">Filter by Class:</Label>
                  <select
                    id="class-filter"
                    value={selectedClass}
                    onChange={(e) => setSelectedClass(e.target.value)}
                    className="px-2 sm:px-3 py-1 sm:py-2 border rounded-md text-xs sm:text-sm bg-background min-w-[100px]"
                  >
                    <option value="all">All Classes</option>
                    {availableClasses.map((cls) => (
                      <option key={cls} value={cls}>
                        {cls}
                      </option>
                    ))}
                  </select>
                </div>
              </div>
            </CardHeader>
            <CardContent>
              <div className="overflow-x-auto -mx-6 px-6">
              <Table>
                <TableHeader>
                  <TableRow>
                    <TableHead>Student Number</TableHead>
                    <TableHead>Name</TableHead>
                    <TableHead>Class</TableHead>
                    <TableHead className="text-right">Total Fee</TableHead>
                    <TableHead className="text-right">Paid</TableHead>
                    <TableHead className="text-right">Balance</TableHead>
                    <TableHead className="text-right">Actions</TableHead>
                  </TableRow>
                </TableHeader>
                <TableBody>
                  {filteredStudents.length === 0 ? (
                    <TableRow>
                      <TableCell colSpan={7} className="text-center text-muted-foreground text-xs sm:text-sm">
                        {students.length === 0 
                          ? "No students found. Configure class fees first."
                          : "No students in this class."}
                      </TableCell>
                    </TableRow>
                  ) : (
                    filteredStudents.map((student) => (
                      <TableRow key={student.id}>
                        <TableCell className="font-medium text-xs sm:text-sm whitespace-nowrap">{student.student_number}</TableCell>
                        <TableCell className="text-xs sm:text-sm whitespace-nowrap">{student.full_name}</TableCell>
                        <TableCell className="text-xs sm:text-sm whitespace-nowrap">{student.class}</TableCell>
                        <TableCell className="text-right text-xs sm:text-sm whitespace-nowrap">
                          GHS {student.total_fee.toFixed(2)}
                        </TableCell>
                        <TableCell className="text-right text-green-600 text-xs sm:text-sm whitespace-nowrap">
                          GHS {student.total_paid.toFixed(2)}
                        </TableCell>
                        <TableCell className={`text-right font-semibold text-xs sm:text-sm whitespace-nowrap ${
                          student.total_balance > 0 ? "text-orange-600" : "text-green-600"
                        }`}>
                          GHS {student.total_balance.toFixed(2)}
                        </TableCell>
                        <TableCell className="text-right whitespace-nowrap">
                          <div className="flex justify-end gap-1 sm:gap-2">
                            <Button
                              size="sm"
                              className="text-xs px-2 py-1"
                              onClick={() => {
                                setSelectedStudent(student);
                                setPaymentForm({
                                  tuition_amount: "",
                                  bus_amount: "",
                                  canteen_amount: "",
                                  payment_date: new Date().toISOString().split("T")[0],
                                  payment_method: "cash",
                                  reference_number: "",
                                  notes: "",
                                });
                                setIsPaymentDialogOpen(true);
                              }}
                            >
                              <span className="hidden sm:inline">Record Payment</span>
                              <span className="sm:hidden">Pay</span>
                            </Button>
                            <Button
                              size="sm"
                              variant="outline"
                              className="px-2 py-1"
                              onClick={() => {
                                setSelectedStudent(student);
                                setOverrideForm({
                                  uses_bus: student.uses_bus,
                                  uses_canteen: student.uses_canteen,
                                  bus_fee_override: student.bus_fee > 0 ? student.bus_fee.toString() : "",
                                  canteen_fee_override: student.canteen_fee > 0 ? student.canteen_fee.toString() : "",
                                });
                                setIsOverrideDialogOpen(true);
                              }}
                            >
                              <Edit className="w-3 h-3 sm:w-4 sm:h-4" />
                            </Button>
                          </div>
                        </TableCell>
                      </TableRow>
                    ))
                  )}
                </TableBody>
              </Table>
              </div>
            </CardContent>
          </Card>
        </TabsContent>

        {/* Outstanding Only Tab */}
        <TabsContent value="outstanding" className="mt-6">
          <Card>
            <CardHeader>
              <div className="flex flex-col sm:flex-row sm:items-center sm:justify-between gap-3">
                <div>
                  <CardTitle className="text-base sm:text-lg">Students with Outstanding Balance</CardTitle>
                  <p className="text-xs sm:text-sm text-muted-foreground">
                    Students who still owe fees
                  </p>
                </div>
                <div className="flex items-center gap-2">
                  <Label htmlFor="class-filter-outstanding" className="text-xs sm:text-sm whitespace-nowrap">Filter by Class:</Label>
                  <select
                    id="class-filter-outstanding"
                    value={selectedClass}
                    onChange={(e) => setSelectedClass(e.target.value)}
                    className="px-2 sm:px-3 py-1 sm:py-2 border rounded-md text-xs sm:text-sm bg-background min-w-[100px]"
                  >
                    <option value="all">All Classes</option>
                    {availableClasses.map((cls) => (
                      <option key={cls} value={cls}>
                        {cls}
                      </option>
                    ))}
                  </select>
                </div>
              </div>
            </CardHeader>
            <CardContent>
              <div className="overflow-x-auto -mx-6 px-6">
              <Table>
                <TableHeader>
                  <TableRow>
                    <TableHead className="text-xs sm:text-sm whitespace-nowrap">Student Number</TableHead>
                    <TableHead className="text-xs sm:text-sm whitespace-nowrap">Name</TableHead>
                    <TableHead className="text-xs sm:text-sm whitespace-nowrap">Class</TableHead>
                    <TableHead className="text-right text-xs sm:text-sm whitespace-nowrap">Total Fee</TableHead>
                    <TableHead className="text-right text-xs sm:text-sm whitespace-nowrap">Paid</TableHead>
                    <TableHead className="text-right text-xs sm:text-sm whitespace-nowrap">Balance</TableHead>
                    <TableHead className="text-right text-xs sm:text-sm whitespace-nowrap">Actions</TableHead>
                  </TableRow>
                </TableHeader>
                <TableBody>
                  {filteredStudents.filter(s => s.total_balance > 0).length === 0 ? (
                    <TableRow>
                      <TableCell colSpan={7} className="text-center text-muted-foreground text-xs sm:text-sm">
                        {students.filter(s => s.total_balance > 0).length === 0
                          ? "All students have paid their fees!"
                          : "No outstanding balances in this class!"}
                      </TableCell>
                    </TableRow>
                  ) : (
                    filteredStudents
                      .filter(s => s.total_balance > 0)
                      .map((student) => (
                        <TableRow key={student.id}>
                          <TableCell className="font-medium text-xs sm:text-sm whitespace-nowrap">{student.student_number}</TableCell>
                          <TableCell className="text-xs sm:text-sm whitespace-nowrap">{student.full_name}</TableCell>
                          <TableCell className="text-xs sm:text-sm whitespace-nowrap">{student.class}</TableCell>
                          <TableCell className="text-right text-xs sm:text-sm whitespace-nowrap">
                            GHS {student.total_fee.toFixed(2)}
                          </TableCell>
                          <TableCell className="text-right text-green-600 text-xs sm:text-sm whitespace-nowrap">
                            GHS {student.total_paid.toFixed(2)}
                          </TableCell>
                          <TableCell className="text-right font-semibold text-orange-600 text-xs sm:text-sm whitespace-nowrap">
                            GHS {student.total_balance.toFixed(2)}
                          </TableCell>
                          <TableCell className="text-right whitespace-nowrap">
                            <Button
                              size="sm"
                              className="text-xs px-2 py-1"
                              onClick={() => {
                                setSelectedStudent(student);
                                setPaymentForm({
                                  tuition_amount: "",
                                  bus_amount: "",
                                  canteen_amount: "",
                                  payment_date: new Date().toISOString().split("T")[0],
                                  payment_method: "cash",
                                  reference_number: "",
                                  notes: "",
                                });
                                setIsPaymentDialogOpen(true);
                              }}
                            >
                              <span className="hidden sm:inline">Record Payment</span>
                              <span className="sm:hidden">Pay</span>
                            </Button>
                          </TableCell>
                        </TableRow>
                      ))
                  )}
                </TableBody>
              </Table>
              </div>
            </CardContent>
          </Card>
        </TabsContent>
      </Tabs>

      {/* Record Payment Dialog - Multi-Step Cart Style */}
      <Dialog open={isPaymentDialogOpen} onOpenChange={setIsPaymentDialogOpen}>
        <DialogContent className="max-w-2xl max-h-[90vh] overflow-y-auto">
          <DialogHeader>
            <DialogTitle>Record Payment</DialogTitle>
            <DialogDescription>
              Enter payment amounts for {selectedStudent?.full_name} ({selectedStudent?.student_number})
            </DialogDescription>
          </DialogHeader>
          <div className="space-y-6">
            {/* Current Balance Summary */}
            <div className="p-4 bg-muted rounded-lg">
              <h4 className="font-semibold mb-3 text-sm">Current Outstanding Balance</h4>
              <div className="grid grid-cols-2 gap-3 text-sm">
                <div className="flex justify-between">
                  <span className="text-muted-foreground">Tuition:</span>
                  <span className="font-medium text-orange-600">
                    GHS {selectedStudent?.tuition_balance.toFixed(2)}
                  </span>
                </div>
                <div className="flex justify-between">
                  <span className="text-muted-foreground">Paid:</span>
                  <span className="font-medium text-green-600">
                    GHS {selectedStudent?.tuition_paid.toFixed(2)}
                  </span>
                </div>
                {selectedStudent?.uses_bus && (
                  <>
                    <div className="flex justify-between">
                      <span className="text-muted-foreground">Bus:</span>
                      <span className="font-medium text-orange-600">
                        GHS {selectedStudent?.bus_balance.toFixed(2)}
                      </span>
                    </div>
                    <div className="flex justify-between">
                      <span className="text-muted-foreground">Paid:</span>
                      <span className="font-medium text-green-600">
                        GHS {selectedStudent?.bus_paid.toFixed(2)}
                      </span>
                    </div>
                  </>
                )}
                {selectedStudent?.uses_canteen && (
                  <>
                    <div className="flex justify-between">
                      <span className="text-muted-foreground">Canteen:</span>
                      <span className="font-medium text-orange-600">
                        GHS {selectedStudent?.canteen_balance.toFixed(2)}
                      </span>
                    </div>
                    <div className="flex justify-between">
                      <span className="text-muted-foreground">Paid:</span>
                      <span className="font-medium text-green-600">
                        GHS {selectedStudent?.canteen_paid.toFixed(2)}
                      </span>
                    </div>
                  </>
                )}
                <div className="col-span-2 pt-2 border-t flex justify-between">
                  <span className="text-muted-foreground font-semibold">Total Outstanding:</span>
                  <span className="font-bold text-orange-600">
                    GHS {selectedStudent?.total_balance.toFixed(2)}
                  </span>
                </div>
              </div>
            </div>

            {/* Payment Entry Section */}
            <div className="space-y-4">
              <h4 className="font-semibold text-sm">Enter Payment Amounts</h4>
              
              {/* Tuition Payment */}
              <div className="p-4 border rounded-lg">
                <div className="flex items-center justify-between mb-2">
                  <Label htmlFor="tuition_amount" className="font-medium">Tuition Payment</Label>
                  <span className="text-xs text-muted-foreground">
                    Balance: GHS {selectedStudent?.tuition_balance.toFixed(2)}
                  </span>
                </div>
                <Input
                  id="tuition_amount"
                  type="number"
                  step="0.01"
                  placeholder="0.00"
                  value={paymentForm.tuition_amount}
                  onChange={(e) => setPaymentForm({ ...paymentForm, tuition_amount: e.target.value })}
                  className="text-lg font-semibold"
                />
                <div className="flex gap-2 mt-2">
                  <Button
                    type="button"
                    size="sm"
                    variant="outline"
                    onClick={() => setPaymentForm({ ...paymentForm, tuition_amount: selectedStudent?.tuition_balance.toFixed(2) || "" })}
                  >
                    Pay Full Balance
                  </Button>
                  <Button
                    type="button"
                    size="sm"
                    variant="ghost"
                    onClick={() => setPaymentForm({ ...paymentForm, tuition_amount: "" })}
                  >
                    Clear
                  </Button>
                </div>
              </div>

              {/* Bus Payment */}
              {selectedStudent?.uses_bus && (
                <div className="p-4 border rounded-lg">
                  <div className="flex items-center justify-between mb-2">
                    <Label htmlFor="bus_amount" className="font-medium">Bus Fee Payment</Label>
                    <span className="text-xs text-muted-foreground">
                      Balance: GHS {selectedStudent?.bus_balance.toFixed(2)}
                    </span>
                  </div>
                  <Input
                    id="bus_amount"
                    type="number"
                    step="0.01"
                    placeholder="0.00"
                    value={paymentForm.bus_amount}
                    onChange={(e) => setPaymentForm({ ...paymentForm, bus_amount: e.target.value })}
                    className="text-lg font-semibold"
                  />
                  <div className="flex gap-2 mt-2">
                    <Button
                      type="button"
                      size="sm"
                      variant="outline"
                      onClick={() => setPaymentForm({ ...paymentForm, bus_amount: selectedStudent?.bus_balance.toFixed(2) || "" })}
                    >
                      Pay Full Balance
                    </Button>
                    <Button
                      type="button"
                      size="sm"
                      variant="ghost"
                      onClick={() => setPaymentForm({ ...paymentForm, bus_amount: "" })}
                    >
                      Clear
                    </Button>
                  </div>
                </div>
              )}

              {/* Canteen Payment */}
              {selectedStudent?.uses_canteen && (
                <div className="p-4 border rounded-lg">
                  <div className="flex items-center justify-between mb-2">
                    <Label htmlFor="canteen_amount" className="font-medium">Canteen Fee Payment</Label>
                    <span className="text-xs text-muted-foreground">
                      Balance: GHS {selectedStudent?.canteen_balance.toFixed(2)}
                    </span>
                  </div>
                  <Input
                    id="canteen_amount"
                    type="number"
                    step="0.01"
                    placeholder="0.00"
                    value={paymentForm.canteen_amount}
                    onChange={(e) => setPaymentForm({ ...paymentForm, canteen_amount: e.target.value })}
                    className="text-lg font-semibold"
                  />
                  <div className="flex gap-2 mt-2">
                    <Button
                      type="button"
                      size="sm"
                      variant="outline"
                      onClick={() => setPaymentForm({ ...paymentForm, canteen_amount: selectedStudent?.canteen_balance.toFixed(2) || "" })}
                    >
                      Pay Full Balance
                    </Button>
                    <Button
                      type="button"
                      size="sm"
                      variant="ghost"
                      onClick={() => setPaymentForm({ ...paymentForm, canteen_amount: "" })}
                    >
                      Clear
                    </Button>
                  </div>
                </div>
              )}

              {/* Total Payment Summary */}
              <div className="p-4 bg-green-50 dark:bg-green-950 rounded-lg border-2 border-green-200 dark:border-green-800">
                <div className="flex justify-between items-center">
                  <span className="font-semibold">Total Payment Amount:</span>
                  <span className="text-2xl font-bold text-green-600">
                    GHS {(
                      (parseFloat(paymentForm.tuition_amount) || 0) +
                      (parseFloat(paymentForm.bus_amount) || 0) +
                      (parseFloat(paymentForm.canteen_amount) || 0)
                    ).toFixed(2)}
                  </span>
                </div>
              </div>
            </div>

            {/* Payment Details */}
            <div className="space-y-4 pt-4 border-t">
              <h4 className="font-semibold text-sm">Payment Details</h4>
              
              <div>
                <Label>Payment Date *</Label>
                <Input
                  type="date"
                  value={paymentForm.payment_date}
                  onChange={(e) => setPaymentForm({ ...paymentForm, payment_date: e.target.value })}
                  className="mt-2"
                />
              </div>

              <div>
                <Label>Payment Method *</Label>
                <select
                  value={paymentForm.payment_method}
                  onChange={(e) => setPaymentForm({ ...paymentForm, payment_method: e.target.value })}
                  className="w-full px-3 py-2 border rounded-md mt-2"
                >
                  <option value="cash">Cash</option>
                  <option value="bank_transfer">Bank Transfer</option>
                  <option value="cheque">Cheque</option>
                  <option value="mobile_money">Mobile Money</option>
                </select>
              </div>

              <div>
                <Label>Reference Number</Label>
                <Input
                  placeholder="Optional reference number"
                  value={paymentForm.reference_number}
                  onChange={(e) => setPaymentForm({ ...paymentForm, reference_number: e.target.value })}
                  className="mt-2"
                />
              </div>

              <div>
                <Label>Notes</Label>
                <Input
                  placeholder="Optional notes"
                  value={paymentForm.notes}
                  onChange={(e) => setPaymentForm({ ...paymentForm, notes: e.target.value })}
                  className="mt-2"
                />
              </div>
            </div>

            {/* Action Buttons */}
            <div className="flex justify-end gap-2 pt-4 border-t">
              <Button variant="outline" onClick={() => setIsPaymentDialogOpen(false)}>
                Cancel
              </Button>
              <Button onClick={handleRecordPayment} className="bg-green-600 hover:bg-green-700">
                <DollarSign className="w-4 h-4 mr-2" />
                Make Payment
              </Button>
            </div>
          </div>
        </DialogContent>
      </Dialog>

      {/* Fee Override Dialog */}
      <Dialog open={isOverrideDialogOpen} onOpenChange={setIsOverrideDialogOpen}>
        <DialogContent>
          <DialogHeader>
            <DialogTitle>Configure Student Fees</DialogTitle>
            <DialogDescription>
              Set individual fee settings for {selectedStudent?.full_name}
            </DialogDescription>
          </DialogHeader>
          <div className="space-y-4">
            <div className="flex items-center space-x-2">
              <input
                type="checkbox"
                id="uses_bus"
                checked={overrideForm.uses_bus}
                onChange={(e) => setOverrideForm({ ...overrideForm, uses_bus: e.target.checked })}
                className="w-4 h-4"
              />
              <Label htmlFor="uses_bus">Student uses bus service</Label>
            </div>

            {overrideForm.uses_bus && (
              <div>
                <Label>Bus Fee Override (GHS)</Label>
                <Input
                  type="number"
                  step="0.01"
                  placeholder="Leave empty to use class default"
                  value={overrideForm.bus_fee_override}
                  onChange={(e) => setOverrideForm({ ...overrideForm, bus_fee_override: e.target.value })}
                  className="mt-2"
                />
                <p className="text-xs text-muted-foreground mt-1">
                  Leave empty to use the default bus fee for this class
                </p>
              </div>
            )}

            <div className="flex items-center space-x-2">
              <input
                type="checkbox"
                id="uses_canteen"
                checked={overrideForm.uses_canteen}
                onChange={(e) => setOverrideForm({ ...overrideForm, uses_canteen: e.target.checked })}
                className="w-4 h-4"
              />
              <Label htmlFor="uses_canteen">Student uses canteen service</Label>
            </div>

            {overrideForm.uses_canteen && (
              <div>
                <Label>Canteen Fee Override (GHS)</Label>
                <Input
                  type="number"
                  step="0.01"
                  placeholder="Leave empty to use class default"
                  value={overrideForm.canteen_fee_override}
                  onChange={(e) => setOverrideForm({ ...overrideForm, canteen_fee_override: e.target.value })}
                  className="mt-2"
                />
                <p className="text-xs text-muted-foreground mt-1">
                  Leave empty to use the default canteen fee for this class
                </p>
              </div>
            )}

            <div className="flex justify-end gap-2 pt-4">
              <Button variant="outline" onClick={() => setIsOverrideDialogOpen(false)}>
                Cancel
              </Button>
              <Button onClick={handleSaveOverride}>Save Settings</Button>
            </div>
          </div>
        </DialogContent>
      </Dialog>
    </div>
  );
}
