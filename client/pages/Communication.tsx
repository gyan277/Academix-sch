import { useState } from "react";
import Layout from "@/components/Layout";
import { Button } from "@/components/ui/button";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { Textarea } from "@/components/ui/textarea";
import { Badge } from "@/components/ui/badge";
import { Tabs, TabsContent, TabsList, TabsTrigger } from "@/components/ui/tabs";
import { AlertCircle, Send, Clock, CheckCircle, AlertTriangle } from "lucide-react";
import { Alert, AlertDescription } from "@/components/ui/alert";

interface Recipient {
  id: string;
  name: string;
  phone: string;
  class: string;
  type: "student" | "staff";
}

interface SMSMessage {
  id: string;
  recipient: string;
  phone: string;
  message: string;
  status: "pending" | "sent" | "failed";
  timestamp: string;
  deliveryTime?: string;
}

// Mock data removed - will be loaded from Supabase
const mockRecipients: Recipient[] = [];

export default function Communication() {
  const [selectedRecipients, setSelectedRecipients] = useState<Recipient[]>([]);
  const [message, setMessage] = useState("");
  const [selectMode, setSelectMode] = useState<"all" | "class" | "staff" | "custom">("custom");
  const [selectedClass, setSelectedClass] = useState<string>("");
  const [smsHistory, setSmsHistory] = useState<SMSMessage[]>([]);
  const [creditBalance] = useState(0);
  const [loading, setLoading] = useState(false);

  const classes = ["Creche", "Nursery 1", "Nursery 2", "KG1", "KG2", "Primary 1", "Primary 2", "Primary 3", "Primary 4", "Primary 5", "Primary 6", "JHS 1", "JHS 2", "JHS 3"];

  // Handle recipient selection
  const handleSelectAll = () => {
    setSelectedRecipients(mockRecipients);
    setSelectMode("all");
  };

  const handleSelectByClass = (classLevel: string) => {
    const classRecipients = mockRecipients.filter(
      (r) => r.type === "student" && r.class === classLevel
    );
    setSelectedRecipients(classRecipients);
    setSelectedClass(classLevel);
    setSelectMode("class");
  };

  const handleSelectStaff = () => {
    const staffRecipients = mockRecipients.filter((r) => r.type === "staff");
    setSelectedRecipients(staffRecipients);
    setSelectMode("staff");
  };

  const handleRemoveRecipient = (id: string) => {
    setSelectedRecipients(selectedRecipients.filter((r) => r.id !== id));
  };

  const handleSendSMS = async () => {
    if (!message.trim()) {
      alert("Please enter a message");
      return;
    }
    if (selectedRecipients.length === 0) {
      alert("Please select at least one recipient");
      return;
    }

    setLoading(true);
    // Simulate API call
    await new Promise((resolve) => setTimeout(resolve, 1500));

    // Add to history
    const newMessages: SMSMessage[] = selectedRecipients.map((recipient) => ({
      id: `msg_${Date.now()}_${recipient.id}`,
      recipient: recipient.name,
      phone: recipient.phone,
      message,
      status: Math.random() > 0.1 ? "sent" : "failed",
      timestamp: new Date().toLocaleString(),
      deliveryTime: Math.random() > 0.1 ? new Date().toLocaleString() : undefined,
    }));

    setSmsHistory((prev) => [...newMessages, ...prev]);
    setMessage("");
    setSelectedRecipients([]);
    setSelectMode("custom");
    setLoading(false);

    // Show success notification
    alert(`SMS sent to ${selectedRecipients.length} recipients!`);
  };

  const estimatedCost = selectedRecipients.length;

  return (
    <Layout title="Communication" subtitle="Bulk SMS and Messaging System">
      <div className="space-y-6">
        {/* SMS Composer */}
        <Card className="border-border/50 shadow-sm">
          <CardHeader>
            <CardTitle className="flex items-center gap-2">
              <Send className="w-5 h-5 text-primary" />
              SMS Composer
            </CardTitle>
          </CardHeader>
          <CardContent className="space-y-6">
            {/* Credit Balance Alert */}
            <Alert className="border-border/50 bg-muted">
              <AlertCircle className="h-4 w-4 text-muted-foreground" />
              <AlertDescription>
                SMS Credit Balance: <span className="font-bold text-foreground">{creditBalance}</span> credits
                {estimatedCost > 0 && (
                  <span className="ml-4">
                    • Estimated cost for this send: <span className="font-bold">{estimatedCost}</span> credits
                  </span>
                )}
              </AlertDescription>
            </Alert>

            {/* Recipient Selection Tabs */}
            <div className="space-y-4">
              <div>
                <h3 className="font-semibold text-foreground mb-3">Select Recipients</h3>
                <div className="grid grid-cols-2 sm:grid-cols-4 gap-2 mb-4">
                  <Button
                    variant={selectMode === "all" ? "default" : "outline"}
                    onClick={handleSelectAll}
                    className="text-sm"
                  >
                    Select All
                  </Button>
                  <Button
                    variant={selectMode === "staff" ? "default" : "outline"}
                    onClick={handleSelectStaff}
                    className="text-sm"
                  >
                    Staff Only
                  </Button>
                  {classes.slice(0, 2).map((cls) => (
                    <Button
                      key={cls}
                      variant={selectMode === "class" && selectedClass === cls ? "default" : "outline"}
                      onClick={() => handleSelectByClass(cls)}
                      className="text-sm"
                    >
                      Class {cls}
                    </Button>
                  ))}
                </div>

                {/* More classes in dropdown */}
                <div className="flex flex-wrap gap-2">
                  {classes.slice(2).map((cls) => (
                    <Button
                      key={cls}
                      variant={selectMode === "class" && selectedClass === cls ? "default" : "outline"}
                      onClick={() => handleSelectByClass(cls)}
                      size="sm"
                    >
                      {cls}
                    </Button>
                  ))}
                </div>
              </div>

              {/* Selected Recipients Preview */}
              {selectedRecipients.length > 0 && (
                <div className="space-y-3">
                  <div className="flex items-center justify-between">
                    <h4 className="font-semibold text-foreground">
                      Selected Recipients ({selectedRecipients.length})
                    </h4>
                    <Button
                      variant="ghost"
                      size="sm"
                      onClick={() => setSelectedRecipients([])}
                      className="text-destructive hover:bg-destructive/10"
                    >
                      Clear All
                    </Button>
                  </div>
                  <div className="flex flex-wrap gap-2">
                    {selectedRecipients.slice(0, 5).map((recipient) => (
                      <Badge
                        key={recipient.id}
                        variant="secondary"
                        className="cursor-pointer hover:bg-secondary/80"
                        onClick={() => handleRemoveRecipient(recipient.id)}
                      >
                        {recipient.name} ✕
                      </Badge>
                    ))}
                    {selectedRecipients.length > 5 && (
                      <Badge variant="outline">+{selectedRecipients.length - 5} more</Badge>
                    )}
                  </div>
                </div>
              )}
            </div>

            {/* Message Composition */}
            <div className="space-y-3">
              <label className="text-sm font-semibold text-foreground">Message</label>
              <Textarea
                placeholder="Type your message here... (Max 160 characters per SMS)"
                value={message}
                onChange={(e) => setMessage(e.target.value.slice(0, 160))}
                className="min-h-24 resize-none"
              />
              <div className="flex justify-between items-center">
                <span className="text-xs text-muted-foreground">
                  {message.length}/160 characters
                </span>
                {message.length > 140 && (
                  <span className="text-xs text-muted-foreground">
                    Will require {Math.ceil(message.length / 160)} SMS
                  </span>
                )}
              </div>
            </div>

            {/* Send Button */}
            <div className="flex gap-3 pt-4">
              <Button
                onClick={handleSendSMS}
                disabled={loading || selectedRecipients.length === 0}
                className="gap-2 px-6"
              >
                <Send className="w-4 h-4" />
                {loading ? "Sending..." : "Send SMS"}
              </Button>
              <Button
                variant="outline"
                onClick={() => {
                  setMessage("");
                  setSelectedRecipients([]);
                }}
              >
                Clear
              </Button>
            </div>
          </CardContent>
        </Card>

        {/* SMS History */}
        <Card className="border-border/50 shadow-sm">
          <CardHeader>
            <CardTitle className="flex items-center gap-2">
              <Clock className="w-5 h-5 text-secondary" />
              SMS History
            </CardTitle>
          </CardHeader>
          <CardContent>
            {smsHistory.length === 0 ? (
              <div className="text-center py-8 text-muted-foreground">
                No SMS history yet
              </div>
            ) : (
              <div className="space-y-4">
                {smsHistory.map((sms) => (
                  <div
                    key={sms.id}
                    className="p-4 border border-border/50 rounded-lg hover:bg-muted/50 transition-colors"
                  >
                    <div className="flex items-start justify-between gap-4">
                      <div className="flex-1 min-w-0">
                        <div className="flex items-center gap-2 mb-1">
                          <h4 className="font-semibold text-foreground">{sms.recipient}</h4>
                          <Badge variant="outline" className="text-xs">
                            {sms.phone}
                          </Badge>
                        </div>
                        <p className="text-sm text-muted-foreground mb-2">{sms.message}</p>
                        <div className="flex items-center gap-2 text-xs text-muted-foreground">
                          <span>Sent: {sms.timestamp}</span>
                          {sms.deliveryTime && (
                            <span>• Delivered: {sms.deliveryTime}</span>
                          )}
                        </div>
                      </div>
                      <div className="flex-shrink-0">
                        {sms.status === "sent" ? (
                          <div className="flex items-center gap-1 text-foreground">
                            <CheckCircle className="w-5 h-5" />
                            <span className="text-xs font-semibold">Sent</span>
                          </div>
                        ) : sms.status === "pending" ? (
                          <div className="flex items-center gap-1 text-muted-foreground">
                            <Clock className="w-5 h-5" />
                            <span className="text-xs font-semibold">Pending</span>
                          </div>
                        ) : (
                          <div className="flex items-center gap-1 text-foreground">
                            <AlertTriangle className="w-5 h-5" />
                            <span className="text-xs font-semibold">Failed</span>
                          </div>
                        )}
                      </div>
                    </div>
                  </div>
                ))}
              </div>
            )}
          </CardContent>
        </Card>
      </div>
    </Layout>
  );
}
