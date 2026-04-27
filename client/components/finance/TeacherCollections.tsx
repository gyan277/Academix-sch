import { useState, useEffect } from "react";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { Button } from "@/components/ui/button";
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
} from "@/components/ui/dialog";
import { Clock, CheckCircle, XCircle, DollarSign } from "lucide-react";
import { supabase } from "@/lib/supabase";
import { useToast } from "@/hooks/use-toast";
import { Textarea } from "@/components/ui/textarea";
import { Label } from "@/components/ui/label";

interface TeacherCollectionsProps {
  schoolId: string;
  academicYear: string;
  term: string;
}

interface Collection {
  id: string;
  teacher_id: string;
  teacher_name: string;
  student_id: string;
  student_name: string;
  collection_type: string;
  amount: number;
  collection_date: string;
  status: string;
  notes?: string;
  rejection_reason?: string;
}

export default function TeacherCollections({ schoolId, academicYear, term }: TeacherCollectionsProps) {
  const { toast } = useToast();
  const [loading, setLoading] = useState(true);
  const [collections, setCollections] = useState<Collection[]>([]);
  const [selectedCollection, setSelectedCollection] = useState<Collection | null>(null);
  const [isConfirmDialogOpen, setIsConfirmDialogOpen] = useState(false);
  const [isRejectDialogOpen, setIsRejectDialogOpen] = useState(false);
  const [rejectionReason, setRejectionReason] = useState("");

  useEffect(() => {
    loadCollections();
  }, [schoolId, academicYear, term]);

  const loadCollections = async () => {
    try {
      setLoading(true);

      console.log("🔍 Loading collections with params:", {
        schoolId,
        academicYear,
        term
      });

      // Use RPC function to bypass schema cache
      const { data, error } = await supabase
        .rpc('get_all_teacher_collections', {
          p_school_id: schoolId,
          p_academic_year: academicYear,
          p_term: term
        });

      console.log("📊 RPC Response:", { data, error });

      if (error) throw error;

      const formattedCollections: Collection[] = (data || []).map((c: any) => ({
        id: c.collection_id,
        teacher_id: c.teacher_id,
        teacher_name: c.teacher_name || "Unknown",
        student_id: c.student_id,
        student_name: c.student_name || "Unknown",
        collection_type: c.collection_type,
        amount: parseFloat(c.amount),
        collection_date: c.collection_date,
        status: c.status,
        notes: c.notes,
        rejection_reason: c.rejection_reason,
      }));

      console.log("✅ Formatted collections:", formattedCollections);
      console.log("📈 Total collections:", formattedCollections.length);

      setCollections(formattedCollections);
    } catch (error: any) {
      console.error("❌ Error loading collections:", error);
      toast({
        title: "Error",
        description: "Failed to load teacher collections",
        variant: "destructive",
      });
    } finally {
      setLoading(false);
    }
  };

  const handleConfirmCollection = async () => {
    if (!selectedCollection) return;

    try {
      const { data: { user } } = await supabase.auth.getUser();

      const { error } = await supabase
        .from("teacher_fee_collections")
        .update({
          status: "confirmed",
          confirmed_by: user?.id,
          confirmed_at: new Date().toISOString(),
        })
        .eq("id", selectedCollection.id);

      if (error) throw error;

      toast({
        title: "Collection Confirmed",
        description: `GHS ${selectedCollection.amount.toFixed(2)} from ${selectedCollection.teacher_name} has been confirmed`,
      });

      setIsConfirmDialogOpen(false);
      setSelectedCollection(null);
      loadCollections();
    } catch (error: any) {
      console.error("Error confirming collection:", error);
      toast({
        title: "Error",
        description: error.message || "Failed to confirm collection",
        variant: "destructive",
      });
    }
  };

  const handleRejectCollection = async () => {
    if (!selectedCollection || !rejectionReason.trim()) {
      toast({
        title: "Validation Error",
        description: "Please provide a reason for rejection",
        variant: "destructive",
      });
      return;
    }

    try {
      const { error } = await supabase
        .from("teacher_fee_collections")
        .update({
          status: "rejected",
          rejection_reason: rejectionReason,
        })
        .eq("id", selectedCollection.id);

      if (error) throw error;

      toast({
        title: "Collection Rejected",
        description: `Collection from ${selectedCollection.teacher_name} has been rejected`,
      });

      setIsRejectDialogOpen(false);
      setSelectedCollection(null);
      setRejectionReason("");
      loadCollections();
    } catch (error: any) {
      console.error("Error rejecting collection:", error);
      toast({
        title: "Error",
        description: error.message || "Failed to reject collection",
        variant: "destructive",
      });
    }
  };

  const pendingCollections = collections.filter(c => c.status === "pending");
  const confirmedCollections = collections.filter(c => c.status === "confirmed");
  const rejectedCollections = collections.filter(c => c.status === "rejected");

  const totalPending = pendingCollections.reduce((sum, c) => sum + c.amount, 0);
  const totalConfirmed = confirmedCollections.reduce((sum, c) => sum + c.amount, 0);

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
      <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
        <Card>
          <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
            <CardTitle className="text-sm font-medium">Pending Confirmation</CardTitle>
            <Clock className="h-4 w-4 text-orange-600" />
          </CardHeader>
          <CardContent>
            <div className="text-2xl font-bold text-orange-600">GHS {totalPending.toFixed(2)}</div>
            <p className="text-xs text-muted-foreground">{pendingCollections.length} collections</p>
          </CardContent>
        </Card>

        <Card>
          <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
            <CardTitle className="text-sm font-medium">Confirmed</CardTitle>
            <CheckCircle className="h-4 w-4 text-green-600" />
          </CardHeader>
          <CardContent>
            <div className="text-2xl font-bold text-green-600">GHS {totalConfirmed.toFixed(2)}</div>
            <p className="text-xs text-muted-foreground">{confirmedCollections.length} collections</p>
          </CardContent>
        </Card>

        <Card>
          <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
            <CardTitle className="text-sm font-medium">Total Collected by Teachers</CardTitle>
            <DollarSign className="h-4 w-4 text-primary" />
          </CardHeader>
          <CardContent>
            <div className="text-2xl font-bold">GHS {(totalPending + totalConfirmed).toFixed(2)}</div>
          </CardContent>
        </Card>
      </div>

      {/* Tabs */}
      <Tabs defaultValue="pending">
        <TabsList>
          <TabsTrigger value="pending">
            Pending ({pendingCollections.length})
          </TabsTrigger>
          <TabsTrigger value="confirmed">
            Confirmed ({confirmedCollections.length})
          </TabsTrigger>
          <TabsTrigger value="rejected">
            Rejected ({rejectedCollections.length})
          </TabsTrigger>
        </TabsList>

        {/* Pending Tab */}
        <TabsContent value="pending">
          <Card>
            <CardHeader>
              <CardTitle>Pending Confirmations</CardTitle>
              <p className="text-sm text-muted-foreground">
                Collections waiting for your confirmation
              </p>
            </CardHeader>
            <CardContent>
              <Table>
                <TableHeader>
                  <TableRow>
                    <TableHead>Date</TableHead>
                    <TableHead>Teacher</TableHead>
                    <TableHead>Student</TableHead>
                    <TableHead>Type</TableHead>
                    <TableHead className="text-right">Amount</TableHead>
                    <TableHead>Notes</TableHead>
                    <TableHead className="text-right">Actions</TableHead>
                  </TableRow>
                </TableHeader>
                <TableBody>
                  {pendingCollections.length === 0 ? (
                    <TableRow>
                      <TableCell colSpan={7} className="text-center text-muted-foreground">
                        No pending collections
                      </TableCell>
                    </TableRow>
                  ) : (
                    pendingCollections.map((collection) => (
                      <TableRow key={collection.id}>
                        <TableCell>{new Date(collection.collection_date).toLocaleDateString()}</TableCell>
                        <TableCell>{collection.teacher_name}</TableCell>
                        <TableCell>{collection.student_name}</TableCell>
                        <TableCell className="capitalize">{collection.collection_type}</TableCell>
                        <TableCell className="text-right font-semibold">GHS {collection.amount.toFixed(2)}</TableCell>
                        <TableCell className="text-sm text-muted-foreground">{collection.notes || "-"}</TableCell>
                        <TableCell className="text-right">
                          <div className="flex gap-2 justify-end">
                            <Button
                              size="sm"
                              onClick={() => {
                                setSelectedCollection(collection);
                                setIsConfirmDialogOpen(true);
                              }}
                            >
                              Confirm
                            </Button>
                            <Button
                              size="sm"
                              variant="destructive"
                              onClick={() => {
                                setSelectedCollection(collection);
                                setIsRejectDialogOpen(true);
                              }}
                            >
                              Reject
                            </Button>
                          </div>
                        </TableCell>
                      </TableRow>
                    ))
                  )}
                </TableBody>
              </Table>
            </CardContent>
          </Card>
        </TabsContent>

        {/* Confirmed Tab */}
        <TabsContent value="confirmed">
          <Card>
            <CardHeader>
              <CardTitle>Confirmed Collections</CardTitle>
            </CardHeader>
            <CardContent>
              <Table>
                <TableHeader>
                  <TableRow>
                    <TableHead>Date</TableHead>
                    <TableHead>Teacher</TableHead>
                    <TableHead>Student</TableHead>
                    <TableHead>Type</TableHead>
                    <TableHead className="text-right">Amount</TableHead>
                    <TableHead>Notes</TableHead>
                  </TableRow>
                </TableHeader>
                <TableBody>
                  {confirmedCollections.length === 0 ? (
                    <TableRow>
                      <TableCell colSpan={6} className="text-center text-muted-foreground">
                        No confirmed collections yet
                      </TableCell>
                    </TableRow>
                  ) : (
                    confirmedCollections.map((collection) => (
                      <TableRow key={collection.id}>
                        <TableCell>{new Date(collection.collection_date).toLocaleDateString()}</TableCell>
                        <TableCell>{collection.teacher_name}</TableCell>
                        <TableCell>{collection.student_name}</TableCell>
                        <TableCell className="capitalize">{collection.collection_type}</TableCell>
                        <TableCell className="text-right font-semibold text-green-600">
                          GHS {collection.amount.toFixed(2)}
                        </TableCell>
                        <TableCell className="text-sm text-muted-foreground">{collection.notes || "-"}</TableCell>
                      </TableRow>
                    ))
                  )}
                </TableBody>
              </Table>
            </CardContent>
          </Card>
        </TabsContent>

        {/* Rejected Tab */}
        <TabsContent value="rejected">
          <Card>
            <CardHeader>
              <CardTitle>Rejected Collections</CardTitle>
            </CardHeader>
            <CardContent>
              <Table>
                <TableHeader>
                  <TableRow>
                    <TableHead>Date</TableHead>
                    <TableHead>Teacher</TableHead>
                    <TableHead>Student</TableHead>
                    <TableHead>Type</TableHead>
                    <TableHead className="text-right">Amount</TableHead>
                    <TableHead>Reason</TableHead>
                  </TableRow>
                </TableHeader>
                <TableBody>
                  {rejectedCollections.length === 0 ? (
                    <TableRow>
                      <TableCell colSpan={6} className="text-center text-muted-foreground">
                        No rejected collections
                      </TableCell>
                    </TableRow>
                  ) : (
                    rejectedCollections.map((collection) => (
                      <TableRow key={collection.id}>
                        <TableCell>{new Date(collection.collection_date).toLocaleDateString()}</TableCell>
                        <TableCell>{collection.teacher_name}</TableCell>
                        <TableCell>{collection.student_name}</TableCell>
                        <TableCell className="capitalize">{collection.collection_type}</TableCell>
                        <TableCell className="text-right font-semibold text-red-600">
                          GHS {collection.amount.toFixed(2)}
                        </TableCell>
                        <TableCell className="text-sm text-muted-foreground">
                          {collection.rejection_reason || "-"}
                        </TableCell>
                      </TableRow>
                    ))
                  )}
                </TableBody>
              </Table>
            </CardContent>
          </Card>
        </TabsContent>
      </Tabs>

      {/* Confirm Dialog */}
      <Dialog open={isConfirmDialogOpen} onOpenChange={setIsConfirmDialogOpen}>
        <DialogContent>
          <DialogHeader>
            <DialogTitle>Confirm Collection</DialogTitle>
            <DialogDescription>
              Confirm that you have received the money from the teacher
            </DialogDescription>
          </DialogHeader>
          {selectedCollection && (
            <div className="space-y-4">
              <div className="p-4 bg-muted rounded-lg space-y-2">
                <div className="flex justify-between">
                  <span className="text-sm text-muted-foreground">Teacher:</span>
                  <span className="font-medium">{selectedCollection.teacher_name}</span>
                </div>
                <div className="flex justify-between">
                  <span className="text-sm text-muted-foreground">Student:</span>
                  <span className="font-medium">{selectedCollection.student_name}</span>
                </div>
                <div className="flex justify-between">
                  <span className="text-sm text-muted-foreground">Type:</span>
                  <span className="font-medium capitalize">{selectedCollection.collection_type}</span>
                </div>
                <div className="flex justify-between">
                  <span className="text-sm text-muted-foreground">Amount:</span>
                  <span className="font-bold text-lg">GHS {selectedCollection.amount.toFixed(2)}</span>
                </div>
              </div>
              <div className="flex gap-2">
                <Button onClick={handleConfirmCollection} className="flex-1">
                  Confirm Receipt
                </Button>
                <Button variant="outline" onClick={() => setIsConfirmDialogOpen(false)}>
                  Cancel
                </Button>
              </div>
            </div>
          )}
        </DialogContent>
      </Dialog>

      {/* Reject Dialog */}
      <Dialog open={isRejectDialogOpen} onOpenChange={setIsRejectDialogOpen}>
        <DialogContent>
          <DialogHeader>
            <DialogTitle>Reject Collection</DialogTitle>
            <DialogDescription>
              Provide a reason for rejecting this collection
            </DialogDescription>
          </DialogHeader>
          {selectedCollection && (
            <div className="space-y-4">
              <div className="p-4 bg-muted rounded-lg space-y-2">
                <div className="flex justify-between">
                  <span className="text-sm text-muted-foreground">Teacher:</span>
                  <span className="font-medium">{selectedCollection.teacher_name}</span>
                </div>
                <div className="flex justify-between">
                  <span className="text-sm text-muted-foreground">Amount:</span>
                  <span className="font-bold">GHS {selectedCollection.amount.toFixed(2)}</span>
                </div>
              </div>
              <div>
                <Label>Reason for Rejection</Label>
                <Textarea
                  value={rejectionReason}
                  onChange={(e) => setRejectionReason(e.target.value)}
                  placeholder="Enter reason..."
                  rows={3}
                />
              </div>
              <div className="flex gap-2">
                <Button variant="destructive" onClick={handleRejectCollection} className="flex-1">
                  Reject Collection
                </Button>
                <Button variant="outline" onClick={() => {
                  setIsRejectDialogOpen(false);
                  setRejectionReason("");
                }}>
                  Cancel
                </Button>
              </div>
            </div>
          )}
        </DialogContent>
      </Dialog>
    </div>
  );
}
