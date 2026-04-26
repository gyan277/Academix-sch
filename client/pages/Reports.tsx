import { useState, useEffect } from "react";
import Layout from "@/components/Layout";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { Tabs, TabsContent, TabsList, TabsTrigger } from "@/components/ui/tabs";
import { Button } from "@/components/ui/button";
import { BarChart3, TrendingUp, Users, PieChart, Download } from "lucide-react";
import { Badge } from "@/components/ui/badge";
import { useToast } from "@/hooks/use-toast";
import { supabase } from "@/lib/supabase";
import {
  generateAcademicReportPDF,
  generateAttendanceReportPDF,
  generateEnrollmentReportPDF,
  generateCSV,
} from "@/lib/export-utils";

const classes = ["Creche", "Nursery 1", "Nursery 2", "KG1", "KG2", "Primary 1", "Primary 2", "Primary 3", "Primary 4", "Primary 5", "Primary 6", "JHS 1", "JHS 2", "JHS 3"];

interface AcademicData {
  class: string;
  avgScore: number;
  topStudent: string;
  topScore: number;
}

interface AttendanceData {
  class: string;
  rate: number;
  students: number;
  absent: number;
}

interface EnrollmentData {
  class: string;
  boys: number;
  girls: number;
  total: number;
}

export default function Reports() {
  const { toast } = useToast();
  const [selectedClass, setSelectedClass] = useState("P1");
  const [dateRange, setDateRange] = useState("month");
  const [loading, setLoading] = useState(true);
  const [schoolId, setSchoolId] = useState<string | null>(null);

  // Data state
  const [academicData, setAcademicData] = useState<AcademicData[]>([]);
  const [attendanceData, setAttendanceData] = useState<AttendanceData[]>([]);
  const [enrollmentData, setEnrollmentData] = useState<EnrollmentData[]>([]);

  const schoolName = localStorage.getItem("schoolName") || "Mount Olivet Methodist Academy";

  // Load school_id on mount
  useEffect(() => {
    loadSchoolId();
  }, []);

  // Load all reports data when school_id is available
  useEffect(() => {
    if (schoolId) {
      loadAllReports();
    }
  }, [schoolId]);

  const loadSchoolId = async () => {
    try {
      const { data: { user } } = await supabase.auth.getUser();
      if (!user) return;

      const { data: userData } = await supabase
        .from("users")
        .select("school_id")
        .eq("id", user.id)
        .single();

      setSchoolId(userData?.school_id || null);
    } catch (error) {
      console.error("Error loading school ID:", error);
    }
  };

  const loadAllReports = async () => {
    setLoading(true);
    await Promise.all([
      loadEnrollmentData(),
      loadAttendanceData(),
      loadAcademicData(),
    ]);
    setLoading(false);
  };

  const loadEnrollmentData = async () => {
    try {
      const { data: students, error } = await supabase
        .from("students")
        .select("class, gender")
        .eq("status", "active")
        .eq("school_id", schoolId);

      if (error) throw error;

      // Group by class
      const grouped = classes.map(className => {
        const classStudents = students?.filter(s => s.class === className) || [];
        const boys = classStudents.filter(s => s.gender === "Male").length;
        const girls = classStudents.filter(s => s.gender === "Female").length;
        
        return {
          class: className,
          boys,
          girls,
          total: boys + girls,
        };
      }).filter(item => item.total > 0); // Only show classes with students

      setEnrollmentData(grouped);
    } catch (error) {
      console.error("Error loading enrollment data:", error);
    }
  };

  const loadAttendanceData = async () => {
    try {
      // Get attendance for last 30 days
      const thirtyDaysAgo = new Date();
      thirtyDaysAgo.setDate(thirtyDaysAgo.getDate() - 30);

      const { data: attendance, error } = await supabase
        .from("attendance")
        .select("class, status, student_id")
        .eq("school_id", schoolId)
        .not("student_id", "is", null)
        .gte("date", thirtyDaysAgo.toISOString().split("T")[0]);

      if (error) throw error;

      // Group by class and calculate rates
      const grouped = classes.map(className => {
        const classAttendance = attendance?.filter(a => a.class === className) || [];
        const total = classAttendance.length;
        const present = classAttendance.filter(a => a.status === "present").length;
        const absent = classAttendance.filter(a => a.status === "absent").length;
        const rate = total > 0 ? (present / total) * 100 : 0;

        return {
          class: className,
          rate: parseFloat(rate.toFixed(1)),
          students: total,
          absent,
        };
      }).filter(item => item.students > 0); // Only show classes with attendance records

      setAttendanceData(grouped);
    } catch (error) {
      console.error("Error loading attendance data:", error);
    }
  };

  const loadAcademicData = async () => {
    try {
      console.log("Loading academic data for school:", schoolId);

      // Get current academic year from school settings
      const { data: settings } = await supabase
        .from("school_settings")
        .select("current_academic_year, current_term")
        .eq("school_id", schoolId)
        .single();

      const academicYear = settings?.current_academic_year || "2024/2025";
      const term = settings?.current_term || "Term 1";

      console.log("Using academic year:", academicYear, "term:", term);

      // Build query - start with base filters
      let query = supabase
        .from("academic_scores")
        .select(`
          total_score,
          student_id,
          class,
          students!inner(full_name, school_id)
        `)
        .eq("school_id", schoolId)
        .eq("academic_year", academicYear);

      // Only filter by term if it's set (not null)
      if (term && term !== "NULL") {
        query = query.eq("term", term);
      }

      const { data: scores, error } = await query;

      if (error) {
        console.error("Error fetching academic scores:", error);
        throw error;
      }

      console.log("Fetched academic scores:", scores?.length || 0, "records");

      if (!scores || scores.length === 0) {
        console.log("No academic scores found");
        setAcademicData([]);
        return;
      }

      // Calculate average score per student (average of all their subjects)
      const studentAverages = new Map<string, { studentId: string; fullName: string; class: string; avgScore: number }>();
      
      scores.forEach((score: any) => {
        const key = score.student_id;
        if (!studentAverages.has(key)) {
          studentAverages.set(key, {
            studentId: score.student_id,
            fullName: score.students.full_name,
            class: score.class,
            avgScore: 0,
          });
        }
      });

      // Calculate average for each student
      studentAverages.forEach((student, studentId) => {
        const studentScores = scores.filter((s: any) => s.student_id === studentId);
        const totalScore = studentScores.reduce((sum: number, s: any) => sum + s.total_score, 0);
        student.avgScore = totalScore / studentScores.length;
      });

      console.log("Calculated averages for", studentAverages.size, "students");

      // Group by class and calculate class averages
      const grouped = classes.map(className => {
        const classStudents = Array.from(studentAverages.values()).filter(s => s.class === className);
        
        if (classStudents.length === 0) return null;

        const classAvg = classStudents.reduce((sum, s) => sum + s.avgScore, 0) / classStudents.length;
        const topStudent = classStudents.reduce((prev, current) => 
          (current.avgScore > prev.avgScore) ? current : prev
        );

        return {
          class: className,
          avgScore: parseFloat(classAvg.toFixed(1)),
          topStudent: topStudent.fullName,
          topScore: parseFloat(topStudent.avgScore.toFixed(1)),
        };
      }).filter(item => item !== null) as AcademicData[];

      console.log("Grouped data by class:", grouped);
      setAcademicData(grouped);
    } catch (error) {
      console.error("Error loading academic data:", error);
    }
  };

  const totalEnrollment = enrollmentData.reduce((sum, item) => sum + item.total, 0);
  const totalBoys = enrollmentData.reduce((sum, item) => sum + item.boys, 0);
  const totalGirls = enrollmentData.reduce((sum, item) => sum + item.girls, 0);
  const avgAttendance = academicData.length > 0
    ? (attendanceData.reduce((sum, item) => sum + item.rate, 0) / attendanceData.length).toFixed(1)
    : "0.0";
  const avgAcademic = academicData.length > 0
    ? (academicData.reduce((sum, item) => sum + item.avgScore, 0) / academicData.length).toFixed(1)
    : "0.0";

  // Download handlers
  const handleDownloadAcademicReport = () => {
    generateAcademicReportPDF(academicData, schoolName);
    toast({
      title: "Download Started",
      description: "Academic report is being downloaded.",
    });
  };

  const handleDownloadAttendanceReport = () => {
    generateAttendanceReportPDF(attendanceData, schoolName);
    toast({
      title: "Download Started",
      description: "Attendance report is being downloaded.",
    });
  };

  const handleDownloadEnrollmentReport = () => {
    generateEnrollmentReportPDF(enrollmentData, schoolName);
    toast({
      title: "Download Started",
      description: "Enrollment report is being downloaded.",
    });
  };

  const handleDownloadCSV = (data: any[], filename: string) => {
    generateCSV(data, filename);
    toast({
      title: "Download Started",
      description: `${filename}.csv is being downloaded.`,
    });
  };

  return (
    <Layout title="Reports & Analytics" subtitle="View comprehensive school analytics and reports">
      {loading ? (
        <div className="flex flex-col items-center justify-center py-20">
          <div className="animate-spin rounded-full h-12 w-12 border-b-2 border-primary mb-4"></div>
          <p className="text-muted-foreground">Loading reports...</p>
        </div>
      ) : (
      <Tabs defaultValue="academic" className="w-full">
        <TabsList className="grid w-full max-w-md grid-cols-3">
          <TabsTrigger value="academic">Academic</TabsTrigger>
          <TabsTrigger value="attendance">Attendance</TabsTrigger>
          <TabsTrigger value="enrollment">Enrollment</TabsTrigger>
        </TabsList>

        {/* ACADEMIC REPORTS */}
        <TabsContent value="academic" className="space-y-6 mt-6">
          {/* Summary Stats */}
          <div className="grid grid-cols-1 md:grid-cols-3 gap-6">
            <Card className="border-border/50 shadow-sm">
              <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-3">
                <CardTitle className="text-sm font-medium text-muted-foreground">
                  School Average
                </CardTitle>
                <TrendingUp className="h-4 w-4 text-muted-foreground" />
              </CardHeader>
              <CardContent>
                <p className="text-3xl font-bold text-foreground">{avgAcademic}%</p>
                <p className="text-xs text-muted-foreground mt-1">Across all classes</p>
              </CardContent>
            </Card>

            <Card className="border-border/50 shadow-sm">
              <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-3">
                <CardTitle className="text-sm font-medium text-muted-foreground">
                  Top Performer
                </CardTitle>
                <PieChart className="h-4 w-4 text-muted-foreground" />
              </CardHeader>
              <CardContent>
                {academicData.length > 0 ? (
                  <>
                    <p className="text-3xl font-bold text-foreground">
                      {Math.max(...academicData.map(d => d.topScore))}
                    </p>
                    <p className="text-xs text-muted-foreground mt-1">
                      {academicData.reduce((prev, current) => 
                        (prev.topScore > current.topScore) ? prev : current
                      ).topStudent} - {academicData.reduce((prev, current) => 
                        (prev.topScore > current.topScore) ? prev : current
                      ).class}
                    </p>
                  </>
                ) : (
                  <>
                    <p className="text-3xl font-bold text-foreground">-</p>
                    <p className="text-xs text-muted-foreground mt-1">No data yet</p>
                  </>
                )}
              </CardContent>
            </Card>

            <Card className="border-border/50 shadow-sm">
              <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-3">
                <CardTitle className="text-sm font-medium text-muted-foreground">
                  Classes Assessed
                </CardTitle>
                <BarChart3 className="h-4 w-4 text-muted-foreground" />
              </CardHeader>
              <CardContent>
                <p className="text-3xl font-bold text-foreground">{academicData.length}</p>
                <p className="text-xs text-muted-foreground mt-1">Out of {classes.length}</p>
              </CardContent>
            </Card>
          </div>

          {/* Performance Table */}
          <Card className="border-border/50">
            <CardHeader>
              <CardTitle>Class Performance Comparison</CardTitle>
            </CardHeader>
            <CardContent>
              {academicData.length === 0 ? (
                <div className="text-center py-12 text-muted-foreground">
                  <p>No academic data available yet</p>
                  <p className="text-sm mt-2">Enter exam scores in the Academic page to see performance reports</p>
                </div>
              ) : (
                <div className="overflow-x-auto border border-border/50 rounded-lg">
                  <table className="w-full text-sm">
                    <thead className="bg-muted border-b border-border">
                      <tr>
                        <th className="px-4 py-3 text-left font-semibold">Class</th>
                        <th className="px-4 py-3 text-center font-semibold">Average Score</th>
                        <th className="px-4 py-3 text-center font-semibold">Performance</th>
                        <th className="px-4 py-3 text-left font-semibold">Top Student</th>
                        <th className="px-4 py-3 text-center font-semibold">Top Score</th>
                      </tr>
                    </thead>
                    <tbody>
                      {academicData.map((item) => (
                        <tr key={item.class} className="border-b border-border/50 hover:bg-muted/50">
                          <td className="px-4 py-3 font-medium">{item.class}</td>
                          <td className="px-4 py-3 text-center font-semibold text-foreground">
                            {item.avgScore}%
                          </td>
                          <td className="px-4 py-3 text-center">
                            <div className="flex items-center justify-center gap-2 w-24 mx-auto">
                              <div className="flex-1 h-2 bg-border rounded-full overflow-hidden">
                                <div
                                  className="h-full bg-foreground transition-all"
                                  style={{ width: `${item.avgScore}%` }}
                                />
                              </div>
                            </div>
                          </td>
                          <td className="px-4 py-3">{item.topStudent}</td>
                          <td className="px-4 py-3 text-center">
                            <Badge variant="outline">
                              {item.topScore}
                            </Badge>
                          </td>
                        </tr>
                      ))}
                    </tbody>
                  </table>
                </div>
              )}
            </CardContent>
          </Card>

          <div className="flex gap-2">
            <Button onClick={handleDownloadAcademicReport} className="gap-2">
              <Download className="w-4 h-4" />
              Download PDF
            </Button>
            <Button 
              onClick={() => handleDownloadCSV(academicData, 'Academic_Performance')} 
              variant="outline" 
              className="gap-2"
            >
              <Download className="w-4 h-4" />
              Download CSV
            </Button>
          </div>
        </TabsContent>

        {/* ATTENDANCE REPORTS */}
        <TabsContent value="attendance" className="space-y-6 mt-6">
          {/* Attendance Summary */}
          <div className="grid grid-cols-1 md:grid-cols-3 gap-6">
            <Card className="border-border/50 shadow-sm">
              <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-3">
                <CardTitle className="text-sm font-medium text-muted-foreground">
                  School Average
                </CardTitle>
                <TrendingUp className="h-4 w-4 text-muted-foreground" />
              </CardHeader>
              <CardContent>
                <p className="text-3xl font-bold text-foreground">{avgAttendance}%</p>
                <p className="text-xs text-muted-foreground mt-1">Attendance Rate</p>
              </CardContent>
            </Card>

            <Card className="border-border/50 shadow-sm">
              <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-3">
                <CardTitle className="text-sm font-medium text-muted-foreground">
                  Total Absences
                </CardTitle>
                <PieChart className="h-4 w-4 text-destructive" />
              </CardHeader>
              <CardContent>
                <p className="text-3xl font-bold text-foreground">
                  {attendanceData.reduce((sum, item) => sum + item.absent, 0)}
                </p>
                <p className="text-xs text-muted-foreground mt-1">This month</p>
              </CardContent>
            </Card>

            <Card className="border-border/50 shadow-sm">
              <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-3">
                <CardTitle className="text-sm font-medium text-muted-foreground">
                  Best Class
                </CardTitle>
                <BarChart3 className="h-4 w-4 text-muted-foreground" />
              </CardHeader>
              <CardContent>
                {attendanceData.length > 0 ? (
                  <>
                    <p className="text-3xl font-bold text-foreground">
                      {Math.max(...attendanceData.map(d => d.rate)).toFixed(1)}%
                    </p>
                    <p className="text-xs text-muted-foreground mt-1">
                      Class {attendanceData.reduce((prev, current) => 
                        (prev.rate > current.rate) ? prev : current
                      ).class}
                    </p>
                  </>
                ) : (
                  <>
                    <p className="text-3xl font-bold text-foreground">-</p>
                    <p className="text-xs text-muted-foreground mt-1">No data yet</p>
                  </>
                )}
              </CardContent>
            </Card>
          </div>

          {/* Attendance Trends */}
          <Card className="border-border/50">
            <CardHeader>
              <CardTitle>Attendance Trends by Class</CardTitle>
            </CardHeader>
            <CardContent>
              {attendanceData.length === 0 ? (
                <div className="text-center py-12 text-muted-foreground">
                  <p>No attendance data available yet</p>
                  <p className="text-sm mt-2">Mark attendance in the Attendance page to see trends</p>
                </div>
              ) : (
                <div className="overflow-x-auto border border-border/50 rounded-lg">
                  <table className="w-full text-sm">
                    <thead className="bg-muted border-b border-border">
                      <tr>
                        <th className="px-4 py-3 text-left font-semibold">Class</th>
                        <th className="px-4 py-3 text-center font-semibold">Attendance Rate</th>
                        <th className="px-4 py-3 text-center font-semibold">Trend</th>
                        <th className="px-4 py-3 text-center font-semibold">Students</th>
                        <th className="px-4 py-3 text-center font-semibold">Absences</th>
                      </tr>
                    </thead>
                    <tbody>
                      {attendanceData.map((item) => (
                        <tr key={item.class} className="border-b border-border/50 hover:bg-muted/50">
                          <td className="px-4 py-3 font-medium">{item.class}</td>
                          <td className="px-4 py-3 text-center font-semibold text-foreground">
                            {item.rate}%
                          </td>
                          <td className="px-4 py-3 text-center">
                            <div className="flex items-center justify-center gap-2 w-24 mx-auto">
                              <div className="flex-1 h-2 bg-border rounded-full overflow-hidden">
                                <div
                                  className="h-full bg-secondary"
                                  style={{ width: `${item.rate}%` }}
                                />
                              </div>
                            </div>
                          </td>
                          <td className="px-4 py-3 text-center">{item.students}</td>
                          <td className="px-4 py-3 text-center">
                            <Badge variant="outline">{item.absent}</Badge>
                          </td>
                        </tr>
                      ))}
                    </tbody>
                  </table>
                </div>
              )}
            </CardContent>
          </Card>

          <div className="flex gap-2">
            <Button onClick={handleDownloadAttendanceReport} className="gap-2">
              <Download className="w-4 h-4" />
              Download PDF
            </Button>
            <Button 
              onClick={() => handleDownloadCSV(attendanceData, 'Attendance_Report')} 
              variant="outline" 
              className="gap-2"
            >
              <Download className="w-4 h-4" />
              Download CSV
            </Button>
          </div>
        </TabsContent>

        {/* ENROLLMENT REPORTS */}
        <TabsContent value="enrollment" className="space-y-6 mt-6">
          {/* Enrollment Summary */}
          <div className="grid grid-cols-1 md:grid-cols-4 gap-6">
            <Card className="border-border/50 shadow-sm">
              <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-3">
                <CardTitle className="text-sm font-medium text-muted-foreground">
                  Total Enrollment
                </CardTitle>
                <Users className="h-4 w-4 text-muted-foreground" />
              </CardHeader>
              <CardContent>
                <p className="text-3xl font-bold text-foreground">{totalEnrollment}</p>
                <p className="text-xs text-muted-foreground mt-1">All Students</p>
              </CardContent>
            </Card>

            <Card className="border-border/50 shadow-sm">
              <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-3">
                <CardTitle className="text-sm font-medium text-muted-foreground">
                  Boys
                </CardTitle>
                <PieChart className="h-4 w-4 text-muted-foreground" />
              </CardHeader>
              <CardContent>
                <p className="text-3xl font-bold text-foreground">{totalBoys}</p>
                <p className="text-xs text-muted-foreground mt-1">
                  {((totalBoys / totalEnrollment) * 100).toFixed(1)}%
                </p>
              </CardContent>
            </Card>

            <Card className="border-border/50 shadow-sm">
              <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-3">
                <CardTitle className="text-sm font-medium text-muted-foreground">
                  Girls
                </CardTitle>
                <PieChart className="h-4 w-4 text-muted-foreground" />
              </CardHeader>
              <CardContent>
                <p className="text-3xl font-bold text-foreground">{totalGirls}</p>
                <p className="text-xs text-muted-foreground mt-1">
                  {((totalGirls / totalEnrollment) * 100).toFixed(1)}%
                </p>
              </CardContent>
            </Card>

            <Card className="border-border/50 shadow-sm">
              <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-3">
                <CardTitle className="text-sm font-medium text-muted-foreground">
                  Classes
                </CardTitle>
                <BarChart3 className="h-4 w-4 text-muted-foreground" />
              </CardHeader>
              <CardContent>
                <p className="text-3xl font-bold text-foreground">
                  {enrollmentData.length}
                </p>
                <p className="text-xs text-muted-foreground mt-1">Active Classes</p>
              </CardContent>
            </Card>
          </div>

          {/* Enrollment Distribution */}
          <Card className="border-border/50">
            <CardHeader>
              <CardTitle>Enrollment by Class</CardTitle>
            </CardHeader>
            <CardContent>
              {enrollmentData.length === 0 ? (
                <div className="text-center py-12 text-muted-foreground">
                  <p>No enrollment data available yet</p>
                  <p className="text-sm mt-2">Add students in the Registrar page to see enrollment reports</p>
                </div>
              ) : (
                <div className="overflow-x-auto border border-border/50 rounded-lg">
                  <table className="w-full text-sm">
                    <thead className="bg-muted border-b border-border">
                      <tr>
                        <th className="px-4 py-3 text-left font-semibold">Class</th>
                        <th className="px-4 py-3 text-center font-semibold">Boys</th>
                        <th className="px-4 py-3 text-center font-semibold">Girls</th>
                        <th className="px-4 py-3 text-center font-semibold">Total</th>
                        <th className="px-4 py-3 text-center font-semibold">Distribution</th>
                      </tr>
                    </thead>
                    <tbody>
                      {enrollmentData.map((item) => (
                        <tr key={item.class} className="border-b border-border/50 hover:bg-muted/50">
                          <td className="px-4 py-3 font-medium">{item.class}</td>
                          <td className="px-4 py-3 text-center text-foreground font-semibold">
                            {item.boys}
                          </td>
                          <td className="px-4 py-3 text-center text-foreground font-semibold">
                            {item.girls}
                          </td>
                          <td className="px-4 py-3 text-center font-semibold">{item.total}</td>
                          <td className="px-4 py-3 text-center">
                            <div className="flex items-center justify-center gap-1 w-20 mx-auto">
                              <div
                                className="h-2 bg-foreground/70 rounded-l"
                                style={{
                                  width: `${(item.boys / item.total) * 100}%`,
                                }}
                              />
                              <div
                                className="h-2 bg-foreground/40 rounded-r"
                                style={{
                                  width: `${(item.girls / item.total) * 100}%`,
                                }}
                              />
                            </div>
                          </td>
                        </tr>
                      ))}
                    </tbody>
                  </table>
                </div>
              )}
            </CardContent>
          </Card>

          <div className="flex gap-2">
            <Button onClick={handleDownloadEnrollmentReport} className="gap-2">
              <Download className="w-4 h-4" />
              Download PDF
            </Button>
            <Button 
              onClick={() => handleDownloadCSV(enrollmentData, 'Enrollment_Report')} 
              variant="outline" 
              className="gap-2"
            >
              <Download className="w-4 h-4" />
              Download CSV
            </Button>
          </div>
        </TabsContent>
      </Tabs>
      )}
    </Layout>
  );
}
