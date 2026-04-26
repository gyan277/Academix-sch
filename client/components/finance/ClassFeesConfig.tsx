import { useState, useEffect } from "react";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
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
import { Plus, Edit, Save, X } from "lucide-react";
import { supabase } from "@/lib/supabase";
import { useToast } from "@/hooks/use-toast";
import type { ClassFee } from "@shared/types";

interface ClassFeesConfigProps {
  schoolId: string;
  academicYear: string;
  term: string;
}

const CLASSES = ["Creche", "Nursery 1", "Nursery 2", "KG1", "KG2", "Primary 1", "Primary 2", "Primary 3", "Primary 4", "Primary 5", "Primary 6", "JHS 1", "JHS 2", "JHS 3"];

export default function ClassFeesConfig({ schoolId, academicYear, term }: ClassFeesConfigProps) {
  const { toast } = useToast();
  const [loading, setLoading] = useState(true);
  const [classFees, setClassFees] = useState<ClassFee[]>([]);
  const [isDialogOpen, setIsDialogOpen] = useState(false);
  const [editingFee, setEditingFee] = useState<ClassFee | null>(null);
  
  const [formData, setFormData] = useState({
    class: "",
    amount: "",
    bus_fee: "",
    canteen_fee: "",
  });

  useEffect(() => {
    loadClassFees();
  }, [schoolId, academicYear, term]);

  const loadClassFees = async () => {
    try {
      setLoading(true);
      const { data, error } = await supabase
        .from("class_fees")
        .select("*")
        .eq("school_id", schoolId)
        .eq("academic_year", academicYear)
        .eq("term", term)
        .order("class");

      if (error) throw error;
      setClassFees(data || []);
    } catch (error: any) {
      console.error("Error loading class fees:", error);
      toast({
        title: "Error",
        description: "Failed to load class fees",
        variant: "destructive",
      });
    } finally {
      setLoading(false);
    }
  };

  const handleOpenDialog = (fee?: ClassFee) => {
    if (fee) {
      setEditingFee(fee);
      setFormData({
        class: fee.class,
        amount: fee.fee_amount.toString(),
        bus_fee: fee.bus_fee?.toString() || "0",
        canteen_fee: fee.canteen_fee?.toString() || "0",
      });
    } else {
      setEditingFee(null);
      setFormData({
        class: "",
        amount: "",
        bus_fee: "0",
        canteen_fee: "0",
      });
    }
    setIsDialogOpen(true);
  };

  const handleCloseDialog = () => {
    setIsDialogOpen(false);
    setEditingFee(null);
    setFormData({
      class: "",
      amount: "",
      bus_fee: "0",
      canteen_fee: "0",
    });
  };

  const handleSave = async () => {
    if (!formData.class || !formData.amount) {
      toast({
        title: "Validation Error",
        description: "Please fill in class and tuition amount",
        variant: "destructive",
      });
      return;
    }

    try {
      const feeData = {
        school_id: schoolId,
        class: formData.class,
        academic_year: academicYear,
        term: term,
        fee_amount: parseFloat(formData.amount),
        bus_fee: parseFloat(formData.bus_fee) || 0,
        canteen_fee: parseFloat(formData.canteen_fee) || 0,
      };

      if (editingFee) {
        // Update existing fee
        const { error } = await supabase
          .from("class_fees")
          .update(feeData)
          .eq("id", editingFee.id);

        if (error) throw error;

        toast({
          title: "Fee Updated",
          description: `Fees for ${formData.class} have been updated`,
        });
      } else {
        // Insert new fee
        const { error } = await supabase
          .from("class_fees")
          .insert(feeData);

        if (error) throw error;

        toast({
          title: "Fee Created",
          description: `Fees for ${formData.class} have been set`,
        });
      }

      handleCloseDialog();
      loadClassFees();
    } catch (error: any) {
      console.error("Error saving class fee:", error);
      toast({
        title: "Error",
        description: error.message || "Failed to save class fee",
        variant: "destructive",
      });
    }
  };

  const getClassFee = (className: string) => {
    return classFees.find((f) => f.class === className);
  };

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
      {/* Header */}
      <Card>
        <CardHeader>
          <div className="flex items-center justify-between">
            <div>
              <CardTitle className="text-base sm:text-lg">Class Fees Configuration</CardTitle>
              <p className="text-xs sm:text-sm text-muted-foreground mt-1">
                Set tuition, bus, and canteen fees for each class
              </p>
            </div>
            <Dialog open={isDialogOpen} onOpenChange={setIsDialogOpen}>
              <DialogTrigger asChild>
                <Button onClick={() => handleOpenDialog()} className="text-xs sm:text-sm">
                  <Plus className="w-3 h-3 sm:w-4 sm:h-4 mr-1 sm:mr-2" />
                  <span className="hidden sm:inline">Add Class Fee</span>
                  <span className="sm:hidden">Add</span>
                </Button>
              </DialogTrigger>
              <DialogContent>
                <DialogHeader>
                  <DialogTitle>
                    {editingFee ? "Edit Class Fee" : "Add Class Fee"}
                  </DialogTitle>
                  <DialogDescription>
                    Set the fees for a class. All students in this class will be billed accordingly.
                  </DialogDescription>
                </DialogHeader>
                <div className="space-y-4">
                  <div>
                    <Label htmlFor="class">Class *</Label>
                    <select
                      id="class"
                      value={formData.class}
                      onChange={(e) => setFormData({ ...formData, class: e.target.value })}
                      className="w-full px-3 py-2 border border-input rounded-md bg-background mt-2"
                      disabled={!!editingFee}
                    >
                      <option value="">Select a class</option>
                      {CLASSES.map((cls) => (
                        <option key={cls} value={cls}>
                          {cls}
                        </option>
                      ))}
                    </select>
                  </div>

                  <div>
                    <Label htmlFor="amount">Tuition Fee (GHS) *</Label>
                    <Input
                      id="amount"
                      type="number"
                      step="0.01"
                      placeholder="e.g., 500.00"
                      value={formData.amount}
                      onChange={(e) => setFormData({ ...formData, amount: e.target.value })}
                      className="mt-2"
                    />
                  </div>

                  <div>
                    <Label htmlFor="bus_fee">Bus Fee (GHS)</Label>
                    <Input
                      id="bus_fee"
                      type="number"
                      step="0.01"
                      placeholder="e.g., 50.00"
                      value={formData.bus_fee}
                      onChange={(e) => setFormData({ ...formData, bus_fee: e.target.value })}
                      className="mt-2"
                    />
                    <p className="text-xs text-muted-foreground mt-1">
                      Default bus fee for students who use the bus
                    </p>
                  </div>

                  <div>
                    <Label htmlFor="canteen_fee">Canteen Fee (GHS)</Label>
                    <Input
                      id="canteen_fee"
                      type="number"
                      step="0.01"
                      placeholder="e.g., 30.00"
                      value={formData.canteen_fee}
                      onChange={(e) => setFormData({ ...formData, canteen_fee: e.target.value })}
                      className="mt-2"
                    />
                    <p className="text-xs text-muted-foreground mt-1">
                      Default canteen fee for students who use the canteen
                    </p>
                  </div>

                  <div className="flex justify-end gap-2 pt-4">
                    <Button variant="outline" onClick={handleCloseDialog}>
                      <X className="w-4 h-4 mr-2" />
                      Cancel
                    </Button>
                    <Button onClick={handleSave}>
                      <Save className="w-4 h-4 mr-2" />
                      Save
                    </Button>
                  </div>
                </div>
              </DialogContent>
            </Dialog>
          </div>
        </CardHeader>
      </Card>

      {/* Fees Table */}
      <Card>
        <CardContent className="pt-6">
          <div className="overflow-x-auto -mx-6 px-6">
          <Table>
            <TableHeader>
              <TableRow>
                <TableHead className="text-xs sm:text-sm whitespace-nowrap">Class</TableHead>
                <TableHead className="text-right text-xs sm:text-sm whitespace-nowrap">Tuition Fee</TableHead>
                <TableHead className="text-right text-xs sm:text-sm whitespace-nowrap">Bus Fee</TableHead>
                <TableHead className="text-right text-xs sm:text-sm whitespace-nowrap">Canteen Fee</TableHead>
                <TableHead className="text-right text-xs sm:text-sm whitespace-nowrap">Total (Max)</TableHead>
                <TableHead className="text-right text-xs sm:text-sm whitespace-nowrap">Action</TableHead>
              </TableRow>
            </TableHeader>
            <TableBody>
              {CLASSES.map((className) => {
                const fee = getClassFee(className);
                const totalMax = fee
                  ? fee.fee_amount + (fee.bus_fee || 0) + (fee.canteen_fee || 0)
                  : 0;

                return (
                  <TableRow key={className}>
                    <TableCell className="font-medium text-xs sm:text-sm whitespace-nowrap">{className}</TableCell>
                    <TableCell className="text-right text-xs sm:text-sm whitespace-nowrap">
                      {fee ? `GHS ${fee.fee_amount.toFixed(2)}` : "-"}
                    </TableCell>
                    <TableCell className="text-right text-xs sm:text-sm whitespace-nowrap">
                      {fee ? `GHS ${(fee.bus_fee || 0).toFixed(2)}` : "-"}
                    </TableCell>
                    <TableCell className="text-right text-xs sm:text-sm whitespace-nowrap">
                      {fee ? `GHS ${(fee.canteen_fee || 0).toFixed(2)}` : "-"}
                    </TableCell>
                    <TableCell className="text-right font-semibold text-xs sm:text-sm whitespace-nowrap">
                      {fee ? `GHS ${totalMax.toFixed(2)}` : "-"}
                    </TableCell>
                    <TableCell className="text-right whitespace-nowrap">
                      {fee ? (
                        <Button
                          size="sm"
                          variant="outline"
                          className="text-xs px-2 py-1"
                          onClick={() => handleOpenDialog(fee)}
                        >
                          <Edit className="w-3 h-3 sm:w-4 sm:h-4 mr-0 sm:mr-1" />
                          <span className="hidden sm:inline">Edit</span>
                        </Button>
                      ) : (
                        <Button
                          size="sm"
                          className="text-xs px-2 py-1"
                          onClick={() => {
                            setFormData({ ...formData, class: className });
                            setIsDialogOpen(true);
                          }}
                        >
                          <Plus className="w-3 h-3 sm:w-4 sm:h-4 mr-0 sm:mr-1" />
                          <span className="hidden sm:inline">Set Fee</span>
                        </Button>
                      )}
                    </TableCell>
                  </TableRow>
                );
              })}
            </TableBody>
          </Table>
          </div>

          {classFees.length === 0 && (
            <div className="text-center py-12 text-muted-foreground">
              <p className="text-xs sm:text-sm">No class fees configured yet.</p>
              <p className="text-xs sm:text-sm mt-2">Click "Add Class Fee" to get started.</p>
            </div>
          )}
        </CardContent>
      </Card>

      {/* Info Card */}
      <Card className="bg-muted/50">
        <CardContent className="pt-6">
          <h4 className="font-semibold mb-2 text-sm sm:text-base">How it works:</h4>
          <ul className="text-xs sm:text-sm text-muted-foreground space-y-1 list-disc list-inside">
            <li>Set default fees for each class (tuition, bus, canteen)</li>
            <li>Students are automatically billed based on their class</li>
            <li>Bus and canteen fees are optional - only charged if student uses them</li>
            <li>You can override fees for individual students in the Income tab</li>
            <li>Changes apply to the selected academic year and term</li>
          </ul>
        </CardContent>
      </Card>
    </div>
  );
}
