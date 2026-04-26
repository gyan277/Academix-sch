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
import { Plus, Edit, Trash2, DollarSign, Users, Receipt } from "lucide-react";
import { supabase } from "@/lib/supabase";
import { useToast } from "@/hooks/use-toast";
import type { StaffSalary, SalaryPayment, CustomExpense } from "@shared/types";

interface ExpensesDashboardProps {
  schoolId: string;
  academicYear: string;
  term: string;
}

export default function ExpensesDashboard({ schoolId, academicYear, term }: ExpensesDashboardProps) {
  const { toast } = useToast();
  const [loading, setLoading] = useState(true);
  const [activeTab, setActiveTab] = useState("salaries");

  // Salaries state
  const [staffSalaries, setStaffSalaries] = useState<StaffSalary[]>([]);
  const [salaryPayments, setSalaryPayments] = useState<SalaryPayment[]>([]);
  const [isSalaryDialogOpen, setIsSalaryDialogOpen] = useState(false);
  const [isPaymentDialogOpen, setIsPaymentDialogOpen] = useState(false);
  const [selectedStaff, setSelectedStaff] = useState<StaffSalary | null>(null);
  const [staffList, setStaffList] = useState<any[]>([]);

  // Custom expenses state
  const [customExpenses, setCustomExpenses] = useState<CustomExpense[]>([]);
  const [isExpenseDialogOpen, setIsExpenseDialogOpen] = useState(false);
  const [editingExpense, setEditingExpense] = useState<CustomExpense | null>(null);

  // Form states
  const [salaryForm, setSalaryForm] = useState({
    staff_id: "",
    monthly_salary: "",
    effective_date: new Date().toISOString().split("T")[0],
  });

  const [paymentForm, setPaymentForm] = useState({
    amount: "",
    payment_month: new Date().toISOString().slice(0, 7), // YYYY-MM
    payment_date: new Date().toISOString().split("T")[0],
    payment_method: "bank_transfer",
    reference_number: "",
    notes: "",
  });

  const [expenseForm, setExpenseForm] = useState({
    expense_category: "",
    description: "",
    amount: "",
    expense_date: new Date().toISOString().split("T")[0],
    payment_method: "cash",
    reference_number: "",
  });

  useEffect(() => {
    loadData();
  }, [schoolId]);

  const loadData = async () => {
    setLoading(true);
    await Promise.all([
      loadStaffList(),
      loadStaffSalaries(),
      loadSalaryPayments(),
      loadCustomExpenses(),
    ]);
    setLoading(false);
  };

  const loadStaffList = async () => {
    try {
      // Load staff with login accounts (from users table)
      const { data: usersData, error: usersError } = await supabase
        .from("users")
        .select("id, full_name, email, role")
        .eq("school_id", schoolId)
        .in("role", ["teacher", "admin", "registrar"])
        .eq("status", "active")
        .order("full_name");

      if (usersError) throw usersError;

      // Load staff without login accounts (from staff table)
      const { data: staffData, error: staffError } = await supabase
        .from("staff")
        .select("id, full_name, staff_number, position")
        .eq("school_id", schoolId)
        .eq("status", "active")
        .order("full_name");

      if (staffError) throw staffError;

      // Combine both lists
      const combinedStaff = [
        ...(usersData || []).map(u => ({
          id: u.id,
          full_name: u.full_name,
          email: u.email,
          role: u.role,
          source: "users" as const,
        })),
        ...(staffData || []).map(s => ({
          id: s.id,
          full_name: s.full_name,
          email: null,
          role: s.position || "staff",
          source: "staff" as const,
        })),
      ];

      setStaffList(combinedStaff);
    } catch (error: any) {
      console.error("Error loading staff:", error);
    }
  };

  const loadStaffSalaries = async () => {
    try {
      const { data, error } = await supabase
        .from("staff_salaries")
        .select("*")
        .eq("school_id", schoolId)
        .eq("is_active", true)
        .order("created_at", { ascending: false });

      if (error) throw error;

      // Manually fetch staff details for each salary
      const salariesWithStaff = await Promise.all(
        (data || []).map(async (salary) => {
          // Try to find in users table first
          const { data: userData } = await supabase
            .from("users")
            .select("full_name, email, role")
            .eq("id", salary.staff_id)
            .single();

          if (userData) {
            return {
              ...salary,
              staff: userData,
            };
          }

          // If not found in users, try staff table
          const { data: staffData } = await supabase
            .from("staff")
            .select("full_name, staff_number, position")
            .eq("id", salary.staff_id)
            .single();

          if (staffData) {
            return {
              ...salary,
              staff: {
                full_name: staffData.full_name,
                email: null,
                role: staffData.position || "staff",
              },
            };
          }

          // If not found in either table
          return {
            ...salary,
            staff: {
              full_name: "Unknown",
              email: null,
              role: "unknown",
            },
          };
        })
      );

      setStaffSalaries(salariesWithStaff);
    } catch (error: any) {
      console.error("Error loading salaries:", error);
    }
  };

  const loadSalaryPayments = async () => {
    try {
      const { data, error } = await supabase
        .from("salary_payments")
        .select("*")
        .eq("school_id", schoolId)
        .order("payment_date", { ascending: false })
        .limit(50);

      if (error) throw error;

      // Manually fetch staff details for each payment
      const paymentsWithStaff = await Promise.all(
        (data || []).map(async (payment) => {
          // Try to find in users table first
          const { data: userData } = await supabase
            .from("users")
            .select("full_name, email")
            .eq("id", payment.staff_id)
            .single();

          if (userData) {
            return {
              ...payment,
              staff: userData,
            };
          }

          // If not found in users, try staff table
          const { data: staffData } = await supabase
            .from("staff")
            .select("full_name")
            .eq("id", payment.staff_id)
            .single();

          if (staffData) {
            return {
              ...payment,
              staff: {
                full_name: staffData.full_name,
                email: null,
              },
            };
          }

          // If not found in either table
          return {
            ...payment,
            staff: {
              full_name: "Unknown",
              email: null,
            },
          };
        })
      );

      setSalaryPayments(paymentsWithStaff);
    } catch (error: any) {
      console.error("Error loading salary payments:", error);
    }
  };

  const loadCustomExpenses = async () => {
    try {
      const { data, error } = await supabase
        .from("custom_expenses")
        .select("*")
        .eq("school_id", schoolId)
        .order("expense_date", { ascending: false });

      if (error) throw error;
      setCustomExpenses(data || []);
    } catch (error: any) {
      console.error("Error loading custom expenses:", error);
    }
  };

  const handleSaveSalary = async () => {
    if (!salaryForm.staff_id || !salaryForm.monthly_salary) {
      toast({
        title: "Validation Error",
        description: "Please fill in all required fields",
        variant: "destructive",
      });
      return;
    }

    try {
      const { error } = await supabase.from("staff_salaries").insert({
        school_id: schoolId,
        staff_id: salaryForm.staff_id,
        monthly_salary: parseFloat(salaryForm.monthly_salary),
        effective_date: salaryForm.effective_date,
        is_active: true,
      });

      if (error) throw error;

      toast({
        title: "Salary Added",
        description: "Staff salary has been set successfully",
      });

      setIsSalaryDialogOpen(false);
      setSalaryForm({
        staff_id: "",
        monthly_salary: "",
        effective_date: new Date().toISOString().split("T")[0],
      });
      loadStaffSalaries();
    } catch (error: any) {
      console.error("Error saving salary:", error);
      toast({
        title: "Error",
        description: error.message || "Failed to save salary",
        variant: "destructive",
      });
    }
  };

  const handleRecordPayment = async () => {
    if (!selectedStaff || !paymentForm.amount) {
      toast({
        title: "Validation Error",
        description: "Please fill in all required fields",
        variant: "destructive",
      });
      return;
    }

    try {
      const { data: { user } } = await supabase.auth.getUser();

      const { error } = await supabase.from("salary_payments").insert({
        school_id: schoolId,
        staff_id: selectedStaff.staff_id,
        amount: parseFloat(paymentForm.amount),
        payment_month: paymentForm.payment_month,
        payment_date: paymentForm.payment_date,
        payment_method: paymentForm.payment_method,
        reference_number: paymentForm.reference_number || null,
        notes: paymentForm.notes || null,
        paid_by: user?.id,
      });

      if (error) throw error;

      toast({
        title: "Payment Recorded",
        description: `Salary payment of GHS ${paymentForm.amount} recorded successfully`,
      });

      setIsPaymentDialogOpen(false);
      setSelectedStaff(null);
      setPaymentForm({
        amount: "",
        payment_month: new Date().toISOString().slice(0, 7),
        payment_date: new Date().toISOString().split("T")[0],
        payment_method: "bank_transfer",
        reference_number: "",
        notes: "",
      });
      loadSalaryPayments();
    } catch (error: any) {
      console.error("Error recording payment:", error);
      toast({
        title: "Error",
        description: error.message || "Failed to record payment",
        variant: "destructive",
      });
    }
  };

  const handleSaveExpense = async () => {
    if (!expenseForm.expense_category || !expenseForm.description || !expenseForm.amount) {
      toast({
        title: "Validation Error",
        description: "Please fill in all required fields",
        variant: "destructive",
      });
      return;
    }

    try {
      const { data: { user } } = await supabase.auth.getUser();

      if (editingExpense) {
        const { error } = await supabase
          .from("custom_expenses")
          .update({
            expense_category: expenseForm.expense_category,
            description: expenseForm.description,
            amount: parseFloat(expenseForm.amount),
            expense_date: expenseForm.expense_date,
            payment_method: expenseForm.payment_method,
            reference_number: expenseForm.reference_number || null,
          })
          .eq("id", editingExpense.id);

        if (error) throw error;

        toast({
          title: "Expense Updated",
          description: "Expense has been updated successfully",
        });
      } else {
        const { error } = await supabase.from("custom_expenses").insert({
          school_id: schoolId,
          expense_category: expenseForm.expense_category,
          description: expenseForm.description,
          amount: parseFloat(expenseForm.amount),
          expense_date: expenseForm.expense_date,
          payment_method: expenseForm.payment_method,
          reference_number: expenseForm.reference_number || null,
          recorded_by: user?.id,
        });

        if (error) throw error;

        toast({
          title: "Expense Added",
          description: "Expense has been recorded successfully",
        });
      }

      setIsExpenseDialogOpen(false);
      setEditingExpense(null);
      setExpenseForm({
        expense_category: "",
        description: "",
        amount: "",
        expense_date: new Date().toISOString().split("T")[0],
        payment_method: "cash",
        reference_number: "",
      });
      loadCustomExpenses();
    } catch (error: any) {
      console.error("Error saving expense:", error);
      toast({
        title: "Error",
        description: error.message || "Failed to save expense",
        variant: "destructive",
      });
    }
  };

  const handleDeleteExpense = async (id: string) => {
    if (!confirm("Are you sure you want to delete this expense?")) return;

    try {
      const { error } = await supabase
        .from("custom_expenses")
        .delete()
        .eq("id", id);

      if (error) throw error;

      toast({
        title: "Expense Deleted",
        description: "Expense has been deleted successfully",
      });

      loadCustomExpenses();
    } catch (error: any) {
      console.error("Error deleting expense:", error);
      toast({
        title: "Error",
        description: error.message || "Failed to delete expense",
        variant: "destructive",
      });
    }
  };

  // Calculate totals
  const totalSalaryExpenses = salaryPayments.reduce((sum, p) => sum + Number(p.amount), 0);
  const totalCustomExpenses = customExpenses.reduce((sum, e) => sum + Number(e.amount), 0);
  const totalExpenses = totalSalaryExpenses + totalCustomExpenses;

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
      {/* Summary Cards */}
      <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 gap-3 sm:gap-4">
        <Card>
          <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
            <CardTitle className="text-xs sm:text-sm font-medium">Total Expenses</CardTitle>
            <DollarSign className="h-3 w-3 sm:h-4 sm:w-4 text-muted-foreground" />
          </CardHeader>
          <CardContent className="pb-3">
            <div className="text-lg sm:text-2xl font-bold">GHS {totalExpenses.toFixed(2)}</div>
            <p className="text-xs text-muted-foreground">All expenses</p>
          </CardContent>
        </Card>

        <Card>
          <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
            <CardTitle className="text-xs sm:text-sm font-medium">Salary Expenses</CardTitle>
            <Users className="h-3 w-3 sm:h-4 sm:w-4 text-muted-foreground" />
          </CardHeader>
          <CardContent className="pb-3">
            <div className="text-lg sm:text-2xl font-bold">GHS {totalSalaryExpenses.toFixed(2)}</div>
            <p className="text-xs text-muted-foreground">{salaryPayments.length} payments</p>
          </CardContent>
        </Card>

        <Card>
          <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
            <CardTitle className="text-xs sm:text-sm font-medium">Other Expenses</CardTitle>
            <Receipt className="h-3 w-3 sm:h-4 sm:w-4 text-muted-foreground" />
          </CardHeader>
          <CardContent className="pb-3">
            <div className="text-lg sm:text-2xl font-bold">GHS {totalCustomExpenses.toFixed(2)}</div>
            <p className="text-xs text-muted-foreground">{customExpenses.length} expenses</p>
          </CardContent>
        </Card>
      </div>

      {/* Tabs */}
      <Tabs value={activeTab} onValueChange={setActiveTab}>
        <TabsList className="grid w-full max-w-md grid-cols-2">
          <TabsTrigger value="salaries" className="text-xs sm:text-sm">Staff Salaries</TabsTrigger>
          <TabsTrigger value="expenses" className="text-xs sm:text-sm">Custom Expenses</TabsTrigger>
        </TabsList>

        {/* Staff Salaries Tab */}
        <TabsContent value="salaries" className="space-y-4 mt-6">
          <Card>
            <CardHeader>
              <div className="flex items-center justify-between">
                <CardTitle className="text-base sm:text-lg">Staff Salaries</CardTitle>
                <Dialog open={isSalaryDialogOpen} onOpenChange={setIsSalaryDialogOpen}>
                  <DialogTrigger asChild>
                    <Button className="text-xs sm:text-sm">
                      <Plus className="w-3 h-3 sm:w-4 sm:h-4 mr-1 sm:mr-2" />
                      <span className="hidden sm:inline">Add Salary</span>
                      <span className="sm:hidden">Add</span>
                    </Button>
                  </DialogTrigger>
                  <DialogContent>
                    <DialogHeader>
                      <DialogTitle>Add Staff Salary</DialogTitle>
                      <DialogDescription>
                        Set monthly salary for a staff member
                      </DialogDescription>
                    </DialogHeader>
                    <div className="space-y-4">
                      <div>
                        <Label>Staff Member *</Label>
                        <select
                          value={salaryForm.staff_id}
                          onChange={(e) => setSalaryForm({ ...salaryForm, staff_id: e.target.value })}
                          className="w-full px-3 py-2 border rounded-md mt-2"
                        >
                          <option value="">Select staff</option>
                          {staffList.map((staff) => (
                            <option key={staff.id} value={staff.id}>
                              {staff.full_name} ({staff.role})
                            </option>
                          ))}
                        </select>
                      </div>
                      <div>
                        <Label>Monthly Salary (GHS) *</Label>
                        <Input
                          type="number"
                          step="0.01"
                          value={salaryForm.monthly_salary}
                          onChange={(e) => setSalaryForm({ ...salaryForm, monthly_salary: e.target.value })}
                          className="mt-2"
                        />
                      </div>
                      <div>
                        <Label>Effective Date *</Label>
                        <Input
                          type="date"
                          value={salaryForm.effective_date}
                          onChange={(e) => setSalaryForm({ ...salaryForm, effective_date: e.target.value })}
                          className="mt-2"
                        />
                      </div>
                      <div className="flex justify-end gap-2 pt-4">
                        <Button variant="outline" onClick={() => setIsSalaryDialogOpen(false)}>
                          Cancel
                        </Button>
                        <Button onClick={handleSaveSalary}>Save</Button>
                      </div>
                    </div>
                  </DialogContent>
                </Dialog>
              </div>
            </CardHeader>
            <CardContent>
              <div className="overflow-x-auto -mx-6 px-6">
              <Table>
                <TableHeader>
                  <TableRow>
                    <TableHead className="text-xs sm:text-sm whitespace-nowrap">Staff Name</TableHead>
                    <TableHead className="text-xs sm:text-sm whitespace-nowrap">Role</TableHead>
                    <TableHead className="text-right text-xs sm:text-sm whitespace-nowrap">Monthly Salary</TableHead>
                    <TableHead className="text-right text-xs sm:text-sm whitespace-nowrap">Action</TableHead>
                  </TableRow>
                </TableHeader>
                <TableBody>
                  {staffSalaries.length === 0 ? (
                    <TableRow>
                      <TableCell colSpan={4} className="text-center text-muted-foreground text-xs sm:text-sm">
                        No salaries configured yet
                      </TableCell>
                    </TableRow>
                  ) : (
                    staffSalaries.map((salary) => (
                      <TableRow key={salary.id}>
                        <TableCell className="font-medium text-xs sm:text-sm whitespace-nowrap">
                          {salary.staff?.full_name || "Unknown"}
                        </TableCell>
                        <TableCell className="text-xs sm:text-sm whitespace-nowrap">{salary.staff?.role || "-"}</TableCell>
                        <TableCell className="text-right text-xs sm:text-sm whitespace-nowrap">
                          GHS {Number(salary.monthly_salary).toFixed(2)}
                        </TableCell>
                        <TableCell className="text-right whitespace-nowrap">
                          <Button
                            size="sm"
                            className="text-xs px-2 py-1"
                            onClick={() => {
                              setSelectedStaff(salary);
                              setPaymentForm({
                                ...paymentForm,
                                amount: salary.monthly_salary.toString(),
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

          {/* Recent Salary Payments */}
          <Card>
            <CardHeader>
              <CardTitle className="text-base sm:text-lg">Recent Salary Payments</CardTitle>
            </CardHeader>
            <CardContent>
              <div className="overflow-x-auto -mx-6 px-6">
              <Table>
                <TableHeader>
                  <TableRow>
                    <TableHead className="text-xs sm:text-sm whitespace-nowrap">Staff Name</TableHead>
                    <TableHead className="text-xs sm:text-sm whitespace-nowrap">Month</TableHead>
                    <TableHead className="text-right text-xs sm:text-sm whitespace-nowrap">Amount</TableHead>
                    <TableHead className="text-xs sm:text-sm whitespace-nowrap">Payment Date</TableHead>
                    <TableHead className="text-xs sm:text-sm whitespace-nowrap">Method</TableHead>
                  </TableRow>
                </TableHeader>
                <TableBody>
                  {salaryPayments.length === 0 ? (
                    <TableRow>
                      <TableCell colSpan={5} className="text-center text-muted-foreground text-xs sm:text-sm">
                        No salary payments recorded yet
                      </TableCell>
                    </TableRow>
                  ) : (
                    salaryPayments.map((payment) => (
                      <TableRow key={payment.id}>
                        <TableCell className="font-medium text-xs sm:text-sm whitespace-nowrap">
                          {payment.staff?.full_name || "Unknown"}
                        </TableCell>
                        <TableCell className="text-xs sm:text-sm whitespace-nowrap">{payment.payment_month}</TableCell>
                        <TableCell className="text-right text-xs sm:text-sm whitespace-nowrap">
                          GHS {Number(payment.amount).toFixed(2)}
                        </TableCell>
                        <TableCell className="text-xs sm:text-sm whitespace-nowrap">
                          {new Date(payment.payment_date).toLocaleDateString()}
                        </TableCell>
                        <TableCell className="text-xs sm:text-sm whitespace-nowrap">{payment.payment_method || "-"}</TableCell>
                      </TableRow>
                    ))
                  )}
                </TableBody>
              </Table>
              </div>
            </CardContent>
          </Card>
        </TabsContent>

        {/* Custom Expenses Tab */}
        <TabsContent value="expenses" className="space-y-4 mt-6">
          <Card>
            <CardHeader>
              <div className="flex items-center justify-between">
                <CardTitle className="text-base sm:text-lg">Custom Expenses</CardTitle>
                <Dialog open={isExpenseDialogOpen} onOpenChange={setIsExpenseDialogOpen}>
                  <DialogTrigger asChild>
                    <Button onClick={() => setEditingExpense(null)} className="text-xs sm:text-sm">
                      <Plus className="w-3 h-3 sm:w-4 sm:h-4 mr-1 sm:mr-2" />
                      <span className="hidden sm:inline">Add Expense</span>
                      <span className="sm:hidden">Add</span>
                    </Button>
                  </DialogTrigger>
                  <DialogContent>
                    <DialogHeader>
                      <DialogTitle>
                        {editingExpense ? "Edit Expense" : "Add Expense"}
                      </DialogTitle>
                      <DialogDescription>
                        Record a custom expense (utilities, maintenance, supplies, etc.)
                      </DialogDescription>
                    </DialogHeader>
                    <div className="space-y-4">
                      <div>
                        <Label>Category *</Label>
                        <Input
                          placeholder="e.g., Utilities, Maintenance, Supplies"
                          value={expenseForm.expense_category}
                          onChange={(e) => setExpenseForm({ ...expenseForm, expense_category: e.target.value })}
                          className="mt-2"
                        />
                      </div>
                      <div>
                        <Label>Description *</Label>
                        <Input
                          placeholder="Brief description of the expense"
                          value={expenseForm.description}
                          onChange={(e) => setExpenseForm({ ...expenseForm, description: e.target.value })}
                          className="mt-2"
                        />
                      </div>
                      <div>
                        <Label>Amount (GHS) *</Label>
                        <Input
                          type="number"
                          step="0.01"
                          value={expenseForm.amount}
                          onChange={(e) => setExpenseForm({ ...expenseForm, amount: e.target.value })}
                          className="mt-2"
                        />
                      </div>
                      <div>
                        <Label>Expense Date *</Label>
                        <Input
                          type="date"
                          value={expenseForm.expense_date}
                          onChange={(e) => setExpenseForm({ ...expenseForm, expense_date: e.target.value })}
                          className="mt-2"
                        />
                      </div>
                      <div>
                        <Label>Payment Method</Label>
                        <select
                          value={expenseForm.payment_method}
                          onChange={(e) => setExpenseForm({ ...expenseForm, payment_method: e.target.value })}
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
                          value={expenseForm.reference_number}
                          onChange={(e) => setExpenseForm({ ...expenseForm, reference_number: e.target.value })}
                          className="mt-2"
                        />
                      </div>
                      <div className="flex justify-end gap-2 pt-4">
                        <Button variant="outline" onClick={() => {
                          setIsExpenseDialogOpen(false);
                          setEditingExpense(null);
                        }}>
                          Cancel
                        </Button>
                        <Button onClick={handleSaveExpense}>Save</Button>
                      </div>
                    </div>
                  </DialogContent>
                </Dialog>
              </div>
            </CardHeader>
            <CardContent>
              <div className="overflow-x-auto -mx-6 px-6">
              <Table>
                <TableHeader>
                  <TableRow>
                    <TableHead className="text-xs sm:text-sm whitespace-nowrap">Category</TableHead>
                    <TableHead className="text-xs sm:text-sm whitespace-nowrap">Description</TableHead>
                    <TableHead className="text-right text-xs sm:text-sm whitespace-nowrap">Amount</TableHead>
                    <TableHead className="text-xs sm:text-sm whitespace-nowrap">Date</TableHead>
                    <TableHead className="text-right text-xs sm:text-sm whitespace-nowrap">Actions</TableHead>
                  </TableRow>
                </TableHeader>
                <TableBody>
                  {customExpenses.length === 0 ? (
                    <TableRow>
                      <TableCell colSpan={5} className="text-center text-muted-foreground text-xs sm:text-sm">
                        No custom expenses recorded yet
                      </TableCell>
                    </TableRow>
                  ) : (
                    customExpenses.map((expense) => (
                      <TableRow key={expense.id}>
                        <TableCell className="font-medium text-xs sm:text-sm whitespace-nowrap">
                          {expense.expense_category}
                        </TableCell>
                        <TableCell className="text-xs sm:text-sm whitespace-nowrap">{expense.description}</TableCell>
                        <TableCell className="text-right text-xs sm:text-sm whitespace-nowrap">
                          GHS {Number(expense.amount).toFixed(2)}
                        </TableCell>
                        <TableCell className="text-xs sm:text-sm whitespace-nowrap">
                          {new Date(expense.expense_date).toLocaleDateString()}
                        </TableCell>
                        <TableCell className="text-right whitespace-nowrap">
                          <div className="flex justify-end gap-1 sm:gap-2">
                            <Button
                              size="sm"
                              variant="outline"
                              className="px-2 py-1"
                              onClick={() => {
                                setEditingExpense(expense);
                                setExpenseForm({
                                  expense_category: expense.expense_category,
                                  description: expense.description,
                                  amount: expense.amount.toString(),
                                  expense_date: expense.expense_date,
                                  payment_method: expense.payment_method || "cash",
                                  reference_number: expense.reference_number || "",
                                });
                                setIsExpenseDialogOpen(true);
                              }}
                            >
                              <Edit className="w-3 h-3 sm:w-4 sm:h-4" />
                            </Button>
                            <Button
                              size="sm"
                              variant="destructive"
                              className="px-2 py-1"
                              onClick={() => handleDeleteExpense(expense.id)}
                            >
                              <Trash2 className="w-3 h-3 sm:w-4 sm:h-4" />
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
      </Tabs>

      {/* Payment Dialog */}
      <Dialog open={isPaymentDialogOpen} onOpenChange={setIsPaymentDialogOpen}>
        <DialogContent>
          <DialogHeader>
            <DialogTitle>Record Salary Payment</DialogTitle>
            <DialogDescription>
              Record salary payment for {selectedStaff?.staff?.full_name}
            </DialogDescription>
          </DialogHeader>
          <div className="space-y-4">
            <div>
              <Label>Amount (GHS) *</Label>
              <Input
                type="number"
                step="0.01"
                value={paymentForm.amount}
                onChange={(e) => setPaymentForm({ ...paymentForm, amount: e.target.value })}
                className="mt-2"
              />
            </div>
            <div>
              <Label>Payment Month *</Label>
              <Input
                type="month"
                value={paymentForm.payment_month}
                onChange={(e) => setPaymentForm({ ...paymentForm, payment_month: e.target.value })}
                className="mt-2"
              />
            </div>
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
              <Label>Payment Method</Label>
              <select
                value={paymentForm.payment_method}
                onChange={(e) => setPaymentForm({ ...paymentForm, payment_method: e.target.value })}
                className="w-full px-3 py-2 border rounded-md mt-2"
              >
                <option value="bank_transfer">Bank Transfer</option>
                <option value="cash">Cash</option>
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
            <div className="flex justify-end gap-2 pt-4">
              <Button variant="outline" onClick={() => setIsPaymentDialogOpen(false)}>
                Cancel
              </Button>
              <Button onClick={handleRecordPayment}>Record Payment</Button>
            </div>
          </div>
        </DialogContent>
      </Dialog>
    </div>
  );
}
