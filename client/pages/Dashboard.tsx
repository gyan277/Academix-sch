import { useState, useEffect } from "react";
import { Button } from "@/components/ui/button";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { Alert, AlertDescription } from "@/components/ui/alert";
import Layout from "@/components/Layout";
import { useNavigate } from "react-router-dom";
import {
  Users,
  UserPlus,
  Clock,
  TrendingUp,
  AlertTriangle,
  Calendar,
  DollarSign,
  Activity,
} from "lucide-react";
import { supabase } from "@/lib/supabase";
import { useToast } from "@/hooks/use-toast";

export default function Dashboard() {
  const navigate = useNavigate();
  const { toast } = useToast();
  const [loading, setLoading] = useState(true);

  // Stats state
  const [stats, setStats] = useState({
    totalEnrollment: 0,
    boysCount: 0,
    girlsCount: 0,
    attendanceToday: 0,
    staffPresent: 0,
    staffTotal: 0,
  });

  // Load dashboard data
  useEffect(() => {
    loadDashboardData();
  }, []);

  const loadDashboardData = async () => {
    try {
      setLoading(true);

      // Get current user's school_id
      const { data: { user } } = await supabase.auth.getUser();
      if (!user) throw new Error("Not authenticated");

      const { data: userData } = await supabase
        .from("users")
        .select("school_id")
        .eq("id", user.id)
        .single();

      const schoolId = userData?.school_id;

      // Load total students for this school
      const { data: students, error: studentsError } = await supabase
        .from("students")
        .select("gender")
        .eq("status", "active")
        .eq("school_id", schoolId);

      if (studentsError) throw studentsError;

      const totalEnrollment = students?.length || 0;
      const boysCount = students?.filter(s => s.gender === "Male").length || 0;
      const girlsCount = students?.filter(s => s.gender === "Female").length || 0;

      // Load staff count for this school
      const { data: staff, error: staffError } = await supabase
        .from("staff")
        .select("id")
        .eq("status", "active")
        .eq("school_id", schoolId);

      if (staffError) throw staffError;

      const staffTotal = staff?.length || 0;

      // Load today's student attendance for this school
      const today = new Date().toISOString().split("T")[0];
      const { data: studentAttendance } = await supabase
        .from("attendance")
        .select("status, student_id")
        .eq("date", today)
        .eq("school_id", schoolId)
        .not("student_id", "is", null);

      let attendanceToday = 0;
      if (studentAttendance && studentAttendance.length > 0) {
        const present = studentAttendance.filter(a => a.status === "present").length;
        attendanceToday = (present / studentAttendance.length) * 100;
      }

      // Load today's staff attendance for this school
      const { data: staffAttendance } = await supabase
        .from("attendance")
        .select("status, staff_id")
        .eq("date", today)
        .eq("school_id", schoolId)
        .not("staff_id", "is", null);

      let staffPresent = 0;
      if (staffAttendance && staffAttendance.length > 0) {
        staffPresent = staffAttendance.filter(a => a.status === "present").length;
      }

      setStats({
        totalEnrollment,
        boysCount,
        girlsCount,
        attendanceToday,
        staffPresent,
        staffTotal,
      });
    } catch (error) {
      console.error("Error loading dashboard data:", error);
      toast({
        title: "Error",
        description: "Failed to load dashboard data",
        variant: "destructive",
      });
    } finally {
      setLoading(false);
    }
  };

  // Alerts will be loaded from database
  const alerts: Array<{
    id: number;
    type: string;
    message: string;
    time: string;
  }> = [];

  return (
    <Layout title="Dashboard" subtitle="Welcome back to Academix">
      {loading ? (
        <div className="flex flex-col items-center justify-center py-20">
          <div className="animate-spin rounded-full h-12 w-12 border-b-2 border-primary mb-4"></div>
          <p className="text-muted-foreground">Loading dashboard...</p>
        </div>
      ) : (
      <div className="space-y-8">
        {/* Stats Grid */}
        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
          {/* Total Enrollment Card */}
          <Card className="border-border/50 shadow-sm hover:shadow-md transition-shadow">
            <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-3">
              <CardTitle className="text-sm font-medium text-muted-foreground">
                Total Enrollment
              </CardTitle>
              <Users className="h-4 w-4 text-muted-foreground" />
            </CardHeader>
            <CardContent className="space-y-3">
              <div>
                <p className="text-3xl font-bold text-foreground">{stats.totalEnrollment}</p>
                <p className="text-xs text-muted-foreground mt-1">Students Enrolled</p>
              </div>
              <div className="grid grid-cols-2 gap-4 pt-2 border-t border-border">
                <div>
                  <p className="text-2xl font-semibold text-foreground">{stats.boysCount}</p>
                  <p className="text-xs text-muted-foreground">Boys</p>
                </div>
                <div>
                  <p className="text-2xl font-semibold text-foreground">{stats.girlsCount}</p>
                  <p className="text-xs text-muted-foreground">Girls</p>
                </div>
              </div>
            </CardContent>
          </Card>

          {/* Attendance Tracker Card */}
          <Card className="border-border/50 shadow-sm hover:shadow-md transition-shadow">
            <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-3">
              <CardTitle className="text-sm font-medium text-muted-foreground">
                Today's Attendance
              </CardTitle>
              <Activity className="h-4 w-4 text-muted-foreground" />
            </CardHeader>
            <CardContent className="space-y-3">
              <div>
                <p className="text-3xl font-bold text-foreground">
                  {stats.attendanceToday.toFixed(1)}%
                </p>
                <p className="text-xs text-muted-foreground mt-1">Attendance Rate</p>
              </div>
              <div className="space-y-2">
                <div className="flex items-center justify-between text-sm">
                  <span className="text-muted-foreground">Overall Status</span>
                  <span className="inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium bg-muted text-foreground border border-border">
                    Good
                  </span>
                </div>
              </div>
            </CardContent>
          </Card>

          {/* Staff Present Card */}
          <Card className="border-border/50 shadow-sm hover:shadow-md transition-shadow">
            <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-3">
              <CardTitle className="text-sm font-medium text-muted-foreground">
                Staff Present
              </CardTitle>
              <Clock className="h-4 w-4 text-muted-foreground" />
            </CardHeader>
            <CardContent className="space-y-3">
              <div>
                <p className="text-3xl font-bold text-foreground">
                  {stats.staffPresent}/{stats.staffTotal}
                </p>
                <p className="text-xs text-muted-foreground mt-1">Staff Clocked In</p>
              </div>
              <div className="pt-2 border-t border-border">
                <div className="flex items-center justify-between text-sm">
                  <span className="text-muted-foreground">Present</span>
                  <span className="font-semibold">
                    {stats.staffTotal > 0 
                      ? ((stats.staffPresent / stats.staffTotal) * 100).toFixed(0)
                      : 0}%
                  </span>
                </div>
              </div>
            </CardContent>
          </Card>
        </div>

        {/* Alerts Section */}
        {alerts.length > 0 && (
          <div className="space-y-4">
            <h2 className="text-xl font-bold text-foreground">Alerts & Notifications</h2>
            <div className="space-y-3">
              {alerts.map((alert) => (
                <Alert
                  key={alert.id}
                  className="border-border/50 bg-background hover:bg-muted/50 transition-colors"
                >
                  <AlertTriangle className="h-4 w-4 text-muted-foreground" />
                  <AlertDescription className="flex items-center justify-between">
                    <span>{alert.message}</span>
                    <span className="text-xs text-muted-foreground ml-4 flex-shrink-0">
                      {alert.time}
                    </span>
                  </AlertDescription>
                </Alert>
              ))}
            </div>
          </div>
        )}

        {/* Quick Actions Section */}
        <div className="space-y-4">
          <h2 className="text-xl font-bold text-foreground">Quick Actions</h2>
          <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 gap-4">
            <Button
              onClick={() => navigate("/registrar")}
              className="h-16 text-base font-semibold gap-3"
            >
              <UserPlus className="w-5 h-5" />
              <span>Add New Student</span>
            </Button>
            <Button
              onClick={() => navigate("/attendance")}
              variant="outline"
              className="h-16 text-base font-semibold gap-3 border-border/50 hover:bg-secondary/10"
            >
              <Calendar className="w-5 h-5" />
              <span>Mark Attendance</span>
            </Button>
            <Button
              onClick={() => navigate("/finance")}
              variant="outline"
              className="h-16 text-base font-semibold gap-3 border-border/50 hover:bg-accent/10"
            >
              <DollarSign className="w-5 h-5" />
              <span>Finance</span>
            </Button>
          </div>
        </div>

        {/* Recent Activity */}
        <Card className="border-border/50 shadow-sm">
          <CardHeader>
            <CardTitle className="flex items-center gap-2">
              <TrendingUp className="w-5 h-5 text-muted-foreground" />
              Recent Activity
            </CardTitle>
          </CardHeader>
          <CardContent>
            <div className="text-center py-8 text-muted-foreground">
              <p>No recent activity yet</p>
              <p className="text-sm mt-2">Activity will appear here as you use the system</p>
            </div>
          </CardContent>
        </Card>
      </div>
      )}
    </Layout>
  );
}
