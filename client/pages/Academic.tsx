import { useState, useEffect } from "react";
import Layout from "@/components/Layout";
import { Button } from "@/components/ui/button";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { Tabs, TabsContent, TabsList, TabsTrigger } from "@/components/ui/tabs";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import { BookOpen, FileText, Download } from "lucide-react";
import { useToast } from "@/hooks/use-toast";
import { generateStudentReportCard } from "@/lib/export-utils";
import { supabase } from "@/lib/supabase";
import { useAcademicYear } from "@/hooks/use-academic-year";

interface StudentScore {
  id: string;
  name: string;
  classScore: number;
  examScore: number;
}

interface SubjectScores {
  [subject: string]: {
    [studentId: string]: {
      classScore: number;
      examScore: number;
    };
  };
}

interface StudentReport {
  id: string;
  name: string;
  studentNumber: string;
  subjects: {
    name: string;
    classScore: number;
    examScore: number;
    total: number;
    grade: string;
  }[];
  totalScore: number;
  averageScore: number;
  classRank: number;
  remarks: string;
}

// Classes will be loaded from database
const classes = ["Creche", "Nursery 1", "Nursery 2", "KG1", "KG2", "Primary 1", "Primary 2", "Primary 3", "Primary 4", "Primary 5", "Primary 6", "JHS 1", "JHS 2", "JHS 3"];

export default function Academic() {
  const { toast } = useToast();
  const [selectedClass, setSelectedClass] = useState("P1");
  const [selectedSubject, setSelectedSubject] = useState("");
  const [subjects, setSubjects] = useState<string[]>([]);
  const [gradingPeriod, setGradingPeriod] = useState("mid-term");
  const [scores, setScores] = useState<StudentScore[]>([]);
  const [savedScores, setSavedScores] = useState<SubjectScores>({});
  const [reports, setReports] = useState<StudentReport[]>([]);
  const [remarks, setRemarks] = useState<{ [key: string]: string }>({});
  const [loadingData, setLoadingData] = useState(false);
  const [loadingSubjects, setLoadingSubjects] = useState(false);
  const [studentList, setStudentList] = useState<{ id: string; name: string }[]>([]);
  const [currentTerm, setCurrentTerm] = useState("Term 1");
  const [profileSchoolId, setProfileSchoolId] = useState<string | null>(null);
  const [profileUserId, setProfileUserId] = useState<string | null>(null);
  const [gradingScale, setGradingScale] = useState<Array<{ grade: string; minScore: number; maxScore: number }>>([]);
  const [scoreHistory, setScoreHistory] = useState<Array<{
    term: string;
    gradingPeriod: string;
    class: string;
    subject: string;
    studentCount: number;
    averageScore: number;
    date: string;
  }>>([]);
  const [loadingHistory, setLoadingHistory] = useState(false);
  const [teacherClasses, setTeacherClasses] = useState<string[]>([]);
  const [isTeacher, setIsTeacher] = useState(false);
  const [schoolLogo, setSchoolLogo] = useState<string>("");
  const [headmasterSignature, setHeadmasterSignature] = useState<string>("");
  const [schoolName, setSchoolName] = useState<string>("Your School");

  const { academicYear: currentAcademicYear } = useAcademicYear();

  // Load user profile and grading scale
  useEffect(() => {
    const loadProfile = async () => {
      const { data: { user } } = await supabase.auth.getUser();
      if (user) {
        const { data: profile } = await supabase
          .from('users')
          .select('school_id, role')
          .eq('id', user.id)
          .single();
        
        if (profile) {
          setProfileSchoolId(profile.school_id);
          setProfileUserId(user.id);
          setIsTeacher(profile.role === 'teacher');
          
          // Load teacher's assigned classes if they're a teacher
          if (profile.role === 'teacher') {
            const { data: assignments } = await supabase
              .from('teacher_classes')
              .select('class')
              .eq('teacher_id', user.id)
              .eq('academic_year', currentAcademicYear);
            
            if (assignments && assignments.length > 0) {
              const uniqueClasses = [...new Set(assignments.map(a => a.class))];
              setTeacherClasses(uniqueClasses);
              // Auto-select first assigned class
              if (uniqueClasses.length > 0) {
                setSelectedClass(uniqueClasses[0]);
              }
            }
          }
          
          // Load grading scale for this school
          const { data: grades } = await supabase
            .from('grading_scale')
            .select('grade, min_score, max_score')
            .eq('school_id', profile.school_id)
            .order('min_score', { ascending: false });
          
          if (grades && grades.length > 0) {
            setGradingScale(grades.map(g => ({
              grade: g.grade,
              minScore: g.min_score,
              maxScore: g.max_score,
            })));
          } else {
            // Default grading scale if none set
            setGradingScale([
              { grade: "A1", minScore: 80, maxScore: 100 },
              { grade: "A2", minScore: 75, maxScore: 79 },
              { grade: "B1", minScore: 70, maxScore: 74 },
              { grade: "B2", minScore: 65, maxScore: 69 },
              { grade: "B3", minScore: 60, maxScore: 64 },
              { grade: "C1", minScore: 55, maxScore: 59 },
              { grade: "C2", minScore: 50, maxScore: 54 },
              { grade: "C3", minScore: 45, maxScore: 49 },
              { grade: "D1", minScore: 40, maxScore: 44 },
              { grade: "D2", minScore: 35, maxScore: 39 },
              { grade: "E1", minScore: 30, maxScore: 34 },
              { grade: "F", minScore: 0, maxScore: 29 },
            ]);
          }

          // Load school settings (logo, signature, and school name)
          const { data: settings, error: settingsError } = await supabase
            .from('school_settings')
            .select('school_logo_url, headmaster_signature_url, school_name')
            .eq('school_id', profile.school_id)
            .single();
          
          console.log('Loading school settings for school_id:', profile.school_id);
          
          if (settingsError) {
            console.error('Error loading school settings:', settingsError);
          } else {
            console.log('School settings loaded:', settings);
            setSchoolLogo(settings?.school_logo_url || '');
            setHeadmasterSignature(settings?.headmaster_signature_url || '');
            setSchoolName(settings?.school_name || 'Your School');
            console.log('Logo URL:', settings?.school_logo_url);
            console.log('Signature URL:', settings?.headmaster_signature_url);
            console.log('School Name:', settings?.school_name);
          }
        }
      }
    };
    loadProfile();
  }, []);

  // Load students when class changes OR when profileSchoolId is loaded
  useEffect(() => {
    if (selectedClass && profileSchoolId) {
      loadStudents();
      loadSubjectsForClass();
    }
  }, [selectedClass, profileSchoolId]);

  // Load scores when subject changes
  useEffect(() => {
    if (selectedSubject && studentList.length > 0) {
      loadScoresForSubject();
    }
  }, [selectedSubject, studentList]);

  const loadSubjectsForClass = async () => {
    try {
      setLoadingSubjects(true);
      const { data, error } = await supabase
        .from("class_subjects")
        .select(`
          subject_id,
          subjects (
            subject_name
          )
        `)
        .eq("class", selectedClass)
        .eq("academic_year", currentAcademicYear)
        .eq("is_active", true);

      if (error) throw error;

      const subjectNames = (data || []).map((cs: any) => cs.subjects.subject_name);
      setSubjects(subjectNames);

      // Set first subject as selected if available
      if (subjectNames.length > 0 && !subjectNames.includes(selectedSubject)) {
        setSelectedSubject(subjectNames[0]);
      }
    } catch (error) {
      console.error("Error loading subjects:", error);
      toast({
        title: "Error",
        description: "Failed to load subjects for this class",
        variant: "destructive",
      });
    } finally {
      setLoadingSubjects(false);
    }
  };

  const loadStudents = async () => {
    try {
      setLoadingData(true);
      
      // CRITICAL: Explicitly filter by school_id to ensure multi-tenancy
      if (!profileSchoolId) {
        console.log("⚠️ Profile school_id not loaded yet, waiting...");
        setLoadingData(false);
        return;
      }

      console.log("🔍 Loading students for class:", selectedClass, "school_id:", profileSchoolId);
      
      const { data, error } = await supabase
        .from("students")
        .select("id, student_id, full_name, school_id")
        .eq("class", selectedClass)
        .eq("status", "active")
        .eq("school_id", profileSchoolId) // EXPLICIT school_id filter
        .order("full_name");

      if (error) {
        console.error("❌ Error loading students:", error);
        throw error;
      }

      console.log("✅ Loaded students:", data?.length || 0, "students");
      if (data && data.length > 0) {
        console.log("📋 First student:", data[0]);
      }

      // Store student list - USE UUID id, not student_id (student number)
      const students = (data || []).map((student) => ({
        id: student.id, // UUID - unique identifier
        name: student.full_name,
      }));
      setStudentList(students);

      // Convert to score records with default 0 scores
      const studentScores: StudentScore[] = students.map((student) => ({
        id: student.id,
        name: student.name,
        classScore: 0,
        examScore: 0,
      }));

      setScores(studentScores);
    } catch (error) {
      console.error("Error loading students:", error);
      toast({
        title: "Error",
        description: "Failed to load students from database",
        variant: "destructive",
      });
    } finally {
      setLoadingData(false);
    }
  };

  const loadScoresForSubject = async () => {
    if (!selectedSubject || !profileSchoolId) {
      // No subject selected or profile not loaded, use default zeros
      const updatedScores = studentList.map((student) => ({
        id: student.id,
        name: student.name,
        classScore: 0,
        examScore: 0,
      }));
      setScores(updatedScores);
      return;
    }

    try {
      // Get subject_id from subjects table
      const { data: subjectData } = await supabase
        .from('subjects')
        .select('id')
        .eq('subject_name', selectedSubject)
        .single();

      if (!subjectData) {
        // No scores saved yet, use default zeros
        const updatedScores = studentList.map((student) => ({
          id: student.id,
          name: student.name,
          classScore: 0,
          examScore: 0,
        }));
        setScores(updatedScores);
        return;
      }

      // Load scores from database
      const { data: scoresData, error } = await supabase
        .from('academic_scores')
        .select('student_id, class_score, exam_score')
        .eq('school_id', profileSchoolId)
        .eq('subject_id', subjectData.id)
        .eq('class', selectedClass)
        .eq('academic_year', currentAcademicYear)
        .eq('term', currentTerm)
        .eq('grading_period', gradingPeriod);

      if (error) throw error;

      // Create a map of student scores
      const scoresMap = new Map(
        (scoresData || []).map(score => [
          score.student_id,
          { classScore: score.class_score, examScore: score.exam_score }
        ])
      );

      // Merge with student list
      const updatedScores = studentList.map((student) => {
        const savedScore = scoresMap.get(student.id);
        return {
          id: student.id,
          name: student.name,
          classScore: savedScore?.classScore || 0,
          examScore: savedScore?.examScore || 0,
        };
      });

      setScores(updatedScores);

      // Also update savedScores state for report generation
      const subjectScoreData: { [studentId: string]: { classScore: number; examScore: number } } = {};
      updatedScores.forEach((score) => {
        subjectScoreData[score.id] = {
          classScore: score.classScore,
          examScore: score.examScore,
        };
      });

      setSavedScores({
        ...savedScores,
        [selectedSubject]: subjectScoreData,
      });
    } catch (error) {
      console.error('Error loading scores:', error);
      toast({
        title: 'Error',
        description: 'Failed to load scores from database',
        variant: 'destructive',
      });
    }
  };

  const handleSaveSubjectScores = async () => {
    if (!selectedSubject || !profileSchoolId || !profileUserId) {
      toast({
        title: 'Error',
        description: 'Missing required information. Please try again.',
        variant: 'destructive',
      });
      return;
    }

    try {
      // Get subject_id from subjects table
      const { data: subjectData, error: subjectError } = await supabase
        .from('subjects')
        .select('id')
        .eq('subject_name', selectedSubject)
        .single();

      if (subjectError || !subjectData) {
        toast({
          title: 'Error',
          description: 'Subject not found in database',
          variant: 'destructive',
        });
        return;
      }

      // Prepare score records for database
      const scoreRecords = scores.map((score) => {
        const totalScore = score.classScore + score.examScore;
        const grade = calculateGrade(totalScore);
        
        return {
          school_id: profileSchoolId,
          student_id: score.id,
          subject_id: subjectData.id,
          class: selectedClass,
          academic_year: currentAcademicYear,
          term: currentTerm,
          grading_period: gradingPeriod,
          class_score: score.classScore,
          exam_score: score.examScore,
          // total_score is auto-calculated by database
          grade: grade,
          recorded_by: profileUserId,
        };
      });

      // Upsert scores (insert or update if exists)
      const { error } = await supabase
        .from('academic_scores')
        .upsert(scoreRecords, {
          onConflict: 'student_id,subject_id,academic_year,term,grading_period',
        });

      if (error) throw error;

      // Save current scores for the selected subject in local state
      const subjectScoreData: { [studentId: string]: { classScore: number; examScore: number } } = {};
      
      scores.forEach((score) => {
        subjectScoreData[score.id] = {
          classScore: score.classScore,
          examScore: score.examScore,
        };
      });

      setSavedScores({
        ...savedScores,
        [selectedSubject]: subjectScoreData,
      });

      toast({
        title: "Scores Saved",
        description: `${selectedSubject} scores have been saved to database. You can now enter scores for other subjects.`,
      });
    } catch (error: any) {
      console.error('Error saving scores:', error);
      toast({
        title: 'Error',
        description: error.message || 'Failed to save scores to database',
        variant: 'destructive',
      });
    }
  };

  const loadScoreHistory = async () => {
    if (!profileSchoolId) return;

    try {
      setLoadingHistory(true);

      // Load score history grouped by term, grading period, class, and subject
      const { data, error } = await supabase
        .from('academic_scores')
        .select(`
          term,
          grading_period,
          class,
          academic_year,
          created_at,
          subject_id,
          subjects (subject_name),
          total_score
        `)
        .eq('school_id', profileSchoolId)
        .order('created_at', { ascending: false });

      if (error) throw error;

      // Group by term, grading period, class, and subject
      const grouped = new Map<string, {
        term: string;
        gradingPeriod: string;
        class: string;
        subject: string;
        scores: number[];
        date: string;
      }>();

      (data || []).forEach((record: any) => {
        const key = `${record.term}-${record.grading_period}-${record.class}-${record.subject_id}`;
        
        if (!grouped.has(key)) {
          grouped.set(key, {
            term: record.term,
            gradingPeriod: record.grading_period,
            class: record.class,
            subject: record.subjects?.subject_name || 'Unknown',
            scores: [],
            date: new Date(record.created_at).toLocaleDateString(),
          });
        }
        
        grouped.get(key)!.scores.push(record.total_score);
      });

      // Convert to array and calculate averages
      const history = Array.from(grouped.values()).map(item => ({
        term: item.term,
        gradingPeriod: item.gradingPeriod,
        class: item.class,
        subject: item.subject,
        studentCount: item.scores.length,
        averageScore: item.scores.reduce((a, b) => a + b, 0) / item.scores.length,
        date: item.date,
      }));

      setScoreHistory(history);
    } catch (error) {
      console.error('Error loading score history:', error);
      toast({
        title: 'Error',
        description: 'Failed to load score history',
        variant: 'destructive',
      });
    } finally {
      setLoadingHistory(false);
    }
  };

  const handleScoreChange = (id: string, field: "classScore" | "examScore", value: number) => {
    setScores(
      scores.map((score) =>
        score.id === id ? { ...score, [field]: Math.min(value, 50) } : score
      )
    );
  };

  const calculateGrade = (total: number): string => {
    // Use the school's custom grading scale from database
    for (const scale of gradingScale) {
      if (total >= scale.minScore && total <= scale.maxScore) {
        return scale.grade;
      }
    }
    // Fallback to F if no match
    return "F";
  };

  const handleGenerateReports = async () => {
    if (!profileSchoolId) {
      toast({
        title: "Error",
        description: "School information not found. Please try again.",
        variant: "destructive",
      });
      return;
    }

    try {
      // Load all scores for the selected class, term, and grading period from database
      const { data: scoresData, error } = await supabase
        .from('academic_scores')
        .select(`
          student_id,
          class_score,
          exam_score,
          total_score,
          grade,
          subject_id,
          subjects (subject_name),
          students (full_name, student_number)
        `)
        .eq('school_id', profileSchoolId)
        .eq('class', selectedClass)
        .eq('academic_year', currentAcademicYear)
        .eq('term', currentTerm)
        .eq('grading_period', gradingPeriod);

      if (error) throw error;

      if (!scoresData || scoresData.length === 0) {
        toast({
          title: "No Scores Found",
          description: "No scores have been saved for this class, term, and grading period yet.",
          variant: "destructive",
        });
        return;
      }

      // Group scores by student
      const studentScoresMap = new Map<string, {
        name: string;
        studentNumber: string;
        subjects: Array<{
          name: string;
          classScore: number;
          examScore: number;
          total: number;
          grade: string;
        }>;
      }>();

      scoresData.forEach((score: any) => {
        const studentId = score.student_id;
        const studentName = score.students?.full_name || 'Unknown Student';
        const studentNumber = score.students?.student_number || 'N/A';
        
        if (!studentScoresMap.has(studentId)) {
          studentScoresMap.set(studentId, {
            name: studentName,
            studentNumber: studentNumber,
            subjects: [],
          });
        }

        studentScoresMap.get(studentId)!.subjects.push({
          name: score.subjects?.subject_name || 'Unknown Subject',
          classScore: score.class_score,
          examScore: score.exam_score,
          total: score.total_score,
          grade: calculateGrade(score.total_score), // Recalculate grade to ensure accuracy
        });
      });

      // Generate reports
      const generatedReports: StudentReport[] = Array.from(studentScoresMap.entries()).map(([studentId, data]) => {
        const totalScore = data.subjects.reduce((sum, sub) => sum + sub.total, 0);
        const averageScore = totalScore / data.subjects.length;

        return {
          id: studentId,
          name: data.name,
          studentNumber: data.studentNumber,
          subjects: data.subjects,
          totalScore,
          averageScore,
          classRank: 0, // Will be calculated after sorting
          remarks: remarks[studentId] || "Good performance",
        };
      });

      // Sort by average score and assign ranks
      const sortedReports = generatedReports.sort((a, b) => b.averageScore - a.averageScore);
      sortedReports.forEach((report, index) => {
        report.classRank = index + 1;
      });

      setReports(sortedReports);
      toast({
        title: "Reports Generated",
        description: `${sortedReports.length} student reports with scores from database have been generated.`,
      });
    } catch (error: any) {
      console.error('Error generating reports:', error);
      toast({
        title: 'Error',
        description: error.message || 'Failed to generate reports from database',
        variant: 'destructive',
      });
    }
  };

  const handleDownloadReport = async (report: StudentReport) => {
    console.log('=== DOWNLOAD REPORT DEBUG ===');
    
    // CRITICAL: Reload school settings to get latest logo/signature/name URLs
    let currentLogoUrl = schoolLogo;
    let currentSignatureUrl = headmasterSignature;
    let currentSchoolName = schoolName;
    
    if (profileSchoolId) {
      console.log('Reloading school settings before PDF generation...');
      const { data: settings, error } = await supabase
        .from('school_settings')
        .select('school_logo_url, headmaster_signature_url, school_name')
        .eq('school_id', profileSchoolId)
        .single();
      
      if (error) {
        console.error('Error reloading school settings:', error);
      } else if (settings) {
        currentLogoUrl = settings.school_logo_url || '';
        currentSignatureUrl = settings.headmaster_signature_url || '';
        currentSchoolName = settings.school_name || 'Your School';
        console.log('Reloaded Logo URL:', currentLogoUrl);
        console.log('Reloaded Signature URL:', currentSignatureUrl);
        console.log('Reloaded School Name:', currentSchoolName);
        
        // Update state for future downloads
        setSchoolLogo(currentLogoUrl);
        setHeadmasterSignature(currentSignatureUrl);
        setSchoolName(currentSchoolName);
      }
    }
    
    console.log('Final Logo URL for PDF:', currentLogoUrl);
    console.log('Final Signature URL for PDF:', currentSignatureUrl);
    console.log('Final School Name for PDF:', currentSchoolName);
    
    const studentData = {
      name: report.name,
      id: report.studentNumber,
      class: selectedClass,
      term: gradingPeriod === "mid-term" ? "Mid-Term" : "End of Term",
      totalScore: report.totalScore,
      averageScore: report.averageScore,
      classRank: report.classRank,
      remarks: report.remarks,
      subjects: report.subjects,
      attendance: "95", // Mock data
    };

    try {
      await generateStudentReportCard(studentData, currentSchoolName, currentLogoUrl, currentSignatureUrl);
      toast({
        title: "Download Started",
        description: `Report card for ${report.name} is being downloaded.`,
      });
    } catch (error) {
      console.error('Error generating PDF:', error);
      toast({
        title: "Download Failed",
        description: "Failed to generate report card. Check console for details.",
        variant: "destructive",
      });
    }
  };

  const handleDownloadAllReports = async () => {
    for (let i = 0; i < reports.length; i++) {
      await handleDownloadReport(reports[i]);
      // Small delay between downloads
      if (i < reports.length - 1) {
        await new Promise(resolve => setTimeout(resolve, 500));
      }
    }
    
    toast({
      title: "Batch Download Started",
      description: `Downloading ${reports.length} report cards...`,
    });
  };

  return (
    <Layout title="Academic Engine" subtitle="SBA & Exam Management">
      <Tabs 
        defaultValue="entry" 
        className="w-full"
        onValueChange={(value) => {
          if (value === "history") {
            loadScoreHistory();
          }
        }}
      >
        <TabsList className="grid w-full max-w-md grid-cols-3">
          <TabsTrigger value="entry">Score Entry</TabsTrigger>
          <TabsTrigger value="reports">Reports</TabsTrigger>
          <TabsTrigger value="history">History</TabsTrigger>
        </TabsList>

        {/* SCORE ENTRY TAB */}
        <TabsContent value="entry" className="space-y-6 mt-6">
          <Card className="border-border/50">
            <CardHeader>
              <CardTitle className="flex items-center gap-2">
                <BookOpen className="w-5 h-5" />
                Score Entry Grid
              </CardTitle>
            </CardHeader>
            <CardContent className="space-y-6">
              {/* Filter Section */}
              <div className="grid grid-cols-1 sm:grid-cols-3 gap-4">
                <div>
                  <Label htmlFor="class">Class</Label>
                  <select
                    id="class"
                    value={selectedClass}
                    onChange={(e) => setSelectedClass(e.target.value)}
                    className="w-full px-3 py-2 border border-input rounded-md bg-background mt-2"
                    disabled={isTeacher && teacherClasses.length === 0}
                  >
                    {(isTeacher ? teacherClasses : classes).map((cls) => (
                      <option key={cls} value={cls}>
                        {cls}
                      </option>
                    ))}
                  </select>
                  {isTeacher && teacherClasses.length === 0 && (
                    <p className="text-xs text-muted-foreground mt-1">
                      No classes assigned. Contact admin.
                    </p>
                  )}
                </div>
                <div>
                  <Label htmlFor="subject">Subject</Label>
                  <select
                    id="subject"
                    value={selectedSubject}
                    onChange={(e) => setSelectedSubject(e.target.value)}
                    className="w-full px-3 py-2 border border-input rounded-md bg-background mt-2"
                    disabled={loadingSubjects || subjects.length === 0}
                  >
                    {loadingSubjects ? (
                      <option>Loading subjects...</option>
                    ) : subjects.length === 0 ? (
                      <option>No subjects assigned to {selectedClass}</option>
                    ) : (
                      subjects.map((subject) => (
                        <option key={subject} value={subject}>
                          {subject} {savedScores[subject] ? "✓" : ""}
                        </option>
                      ))
                    )}
                  </select>
                  {subjects.length === 0 && !loadingSubjects && (
                    <p className="text-xs text-destructive mt-1">
                      No subjects assigned. Admin should configure subjects in Settings.
                    </p>
                  )}
                </div>
                <div>
                  <Label htmlFor="period">Grading Period</Label>
                  <select
                    id="period"
                    value={gradingPeriod}
                    onChange={(e) => setGradingPeriod(e.target.value)}
                    className="w-full px-3 py-2 border border-input rounded-md bg-background mt-2"
                  >
                    <option value="mid-term">Mid-Term</option>
                    <option value="end-term">End-of-Term</option>
                  </select>
                </div>
              </div>

              {/* Progress Indicator */}
              {Object.keys(savedScores).length > 0 && (
                <div className="p-4 bg-muted rounded-lg border border-border">
                  <p className="text-sm font-semibold text-foreground mb-2">
                    Saved Subjects ({Object.keys(savedScores).length}/{subjects.length})
                  </p>
                  <div className="flex flex-wrap gap-2">
                    {subjects.map((subject) => (
                      <span
                        key={subject}
                        className={`px-3 py-1 rounded-full text-xs font-medium ${
                          savedScores[subject]
                            ? "bg-primary text-primary-foreground"
                            : "bg-background text-muted-foreground border border-border"
                        }`}
                      >
                        {subject} {savedScores[subject] && "✓"}
                      </span>
                    ))}
                  </div>
                </div>
              )}

              {/* Score Entry Table */}
              <div className="overflow-x-auto border border-border/50 rounded-lg">
                {loadingData ? (
                  <div className="text-center py-12">
                    <div className="animate-spin rounded-full h-8 w-8 border-b-2 border-primary mx-auto mb-2"></div>
                    <p className="text-sm text-muted-foreground">Loading students...</p>
                  </div>
                ) : scores.length === 0 ? (
                  <div className="text-center py-12 text-muted-foreground">
                    No students found in {selectedClass}. Please add students in the Registrar page.
                  </div>
                ) : (
                <table className="w-full min-w-[600px]">
                  <thead className="bg-muted border-b border-border">
                    <tr>
                      <th className="px-2 sm:px-4 py-3 text-left text-xs sm:text-sm font-semibold">Student</th>
                      <th className="px-2 sm:px-4 py-3 text-center text-xs sm:text-sm font-semibold">Class (50)</th>
                      <th className="px-2 sm:px-4 py-3 text-center text-xs sm:text-sm font-semibold">Exam (50)</th>
                      <th className="px-2 sm:px-4 py-3 text-center text-xs sm:text-sm font-semibold">Total</th>
                      <th className="px-2 sm:px-4 py-3 text-center text-xs sm:text-sm font-semibold">Grade</th>
                    </tr>
                  </thead>
                  <tbody>
                    {scores.map((score) => {
                      const totalMark = score.classScore + score.examScore;
                      const grade = calculateGrade(totalMark);
                      return (
                        <tr key={score.id} className="border-b border-border/50 hover:bg-muted/50">
                          <td className="px-2 sm:px-4 py-3 text-xs sm:text-sm font-medium">
                            <div className="max-w-[120px] sm:max-w-none truncate">{score.name}</div>
                          </td>
                          <td className="px-2 sm:px-4 py-3 text-center">
                            <Input
                              type="number"
                              min="0"
                              max="50"
                              value={score.classScore === 0 ? "" : score.classScore}
                              onChange={(e) =>
                                handleScoreChange(score.id, "classScore", parseInt(e.target.value) || 0)
                              }
                              placeholder="0"
                              className="w-12 sm:w-16 mx-auto text-center text-xs sm:text-sm"
                            />
                          </td>
                          <td className="px-2 sm:px-4 py-3 text-center">
                            <Input
                              type="number"
                              min="0"
                              max="50"
                              value={score.examScore === 0 ? "" : score.examScore}
                              onChange={(e) =>
                                handleScoreChange(score.id, "examScore", parseInt(e.target.value) || 0)
                              }
                              placeholder="0"
                              className="w-12 sm:w-16 mx-auto text-center text-xs sm:text-sm"
                            />
                          </td>
                          <td className="px-2 sm:px-4 py-3 text-center text-xs sm:text-sm font-semibold">
                            {totalMark}
                          </td>
                          <td className="px-2 sm:px-4 py-3 text-center">
                            <span className="inline-block px-2 sm:px-3 py-1 rounded-full text-xs font-bold bg-muted text-foreground border border-border">
                              {grade}
                            </span>
                          </td>
                        </tr>
                      );
                    })}
                  </tbody>
                </table>
                )}
              </div>

              <div className="flex flex-col sm:flex-row gap-3">
                <Button 
                  onClick={handleSaveSubjectScores} 
                  variant="outline" 
                  className="gap-2 flex-1" 
                  disabled={scores.length === 0 || !selectedSubject}
                >
                  <FileText className="w-4 h-4" />
                  {selectedSubject ? `Save ${selectedSubject} Scores` : "Save Scores"}
                </Button>
              </div>
            </CardContent>
          </Card>
        </TabsContent>

        {/* REPORTS TAB */}
        <TabsContent value="reports" className="space-y-6 mt-6">
          {/* Filters for Report Generation */}
          <Card className="border-border/50">
            <CardHeader>
              <CardTitle>Generate Reports</CardTitle>
            </CardHeader>
            <CardContent className="space-y-4">
              <div className="grid grid-cols-1 sm:grid-cols-4 gap-4">
                <div>
                  <Label htmlFor="report-class">Class</Label>
                  <select
                    id="report-class"
                    value={selectedClass}
                    onChange={(e) => setSelectedClass(e.target.value)}
                    className="w-full px-3 py-2 border border-input rounded-md bg-background mt-2"
                    disabled={isTeacher && teacherClasses.length === 0}
                  >
                    {(isTeacher ? teacherClasses : classes).map((cls) => (
                      <option key={cls} value={cls}>
                        {cls}
                      </option>
                    ))}
                  </select>
                </div>
                <div>
                  <Label htmlFor="report-term">Term</Label>
                  <select
                    id="report-term"
                    value={currentTerm}
                    onChange={(e) => setCurrentTerm(e.target.value)}
                    className="w-full px-3 py-2 border border-input rounded-md bg-background mt-2"
                  >
                    <option value="Term 1">Term 1</option>
                    <option value="Term 2">Term 2</option>
                    <option value="Term 3">Term 3</option>
                  </select>
                </div>
                <div>
                  <Label htmlFor="report-period">Grading Period</Label>
                  <select
                    id="report-period"
                    value={gradingPeriod}
                    onChange={(e) => setGradingPeriod(e.target.value)}
                    className="w-full px-3 py-2 border border-input rounded-md bg-background mt-2"
                  >
                    <option value="mid-term">Mid-Term</option>
                    <option value="end-term">End of Term</option>
                  </select>
                </div>
                <div className="flex items-end">
                  <Button 
                    onClick={handleGenerateReports} 
                    className="w-full gap-2"
                  >
                    <FileText className="w-4 h-4" />
                    Generate Reports
                  </Button>
                </div>
              </div>
            </CardContent>
          </Card>

          {reports.length === 0 ? (
            <Card className="border-border/50">
              <CardContent className="text-center py-8 text-muted-foreground">
                Select class, term, and grading period above, then click "Generate Reports" to load student reports from database.
              </CardContent>
            </Card>
          ) : (
            <div className="space-y-4">
              {reports.map((report) => (
                <Card key={report.id} className="border-border/50 hover:shadow-md transition-shadow">
                  <CardContent className="pt-6 space-y-4">
                    {/* Student Header */}
                    <div className="grid grid-cols-1 sm:grid-cols-4 gap-4 pb-4 border-b border-border">
                      <div>
                        <p className="text-sm text-muted-foreground">Student</p>
                        <p className="font-semibold text-foreground truncate">{report.name}</p>
                        <p className="text-xs text-muted-foreground">{report.id}</p>
                      </div>
                      <div>
                        <p className="text-sm text-muted-foreground">Total Score</p>
                        <p className="text-xl sm:text-2xl font-bold text-primary">{report.totalScore.toFixed(0)}</p>
                      </div>
                      <div>
                        <p className="text-sm text-muted-foreground">Average</p>
                        <p className="text-xl sm:text-2xl font-bold text-secondary">{report.averageScore.toFixed(1)}%</p>
                      </div>
                      <div>
                        <p className="text-sm text-muted-foreground">Class Rank</p>
                        <p className="text-xl sm:text-2xl font-bold text-foreground">#{report.classRank}</p>
                      </div>
                    </div>

                    {/* Subject Breakdown */}
                    <div>
                      <p className="text-sm font-semibold text-foreground mb-2">Subject Scores</p>
                      <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 gap-2">
                        {report.subjects.map((subject) => (
                          <div key={subject.name} className="p-3 bg-muted rounded-lg border border-border">
                            <p className="text-xs font-semibold text-foreground mb-1">{subject.name}</p>
                            <div className="flex items-center justify-between">
                              <div className="text-xs text-muted-foreground">
                                <span>Class: {subject.classScore}</span>
                                <span className="mx-1">•</span>
                                <span>Exam: {subject.examScore}</span>
                              </div>
                              <div className="flex items-center gap-2">
                                <span className="text-sm font-bold text-foreground">{subject.total}</span>
                                <span className="px-2 py-0.5 rounded text-xs font-bold bg-background border border-border">
                                  {subject.grade}
                                </span>
                              </div>
                            </div>
                          </div>
                        ))}
                      </div>
                    </div>

                    {/* Remarks and Actions */}
                    <div className="grid grid-cols-1 sm:grid-cols-2 gap-4 pt-4 border-t border-border">
                      <div>
                        <p className="text-sm text-muted-foreground mb-1">Teacher's Remarks</p>
                        <Input
                          value={remarks[report.id] || ""}
                          onChange={(e) =>
                            setRemarks({ ...remarks, [report.id]: e.target.value })
                          }
                          placeholder="Add remarks"
                          className="text-sm"
                        />
                      </div>
                      <div className="flex items-end gap-2">
                        <Button 
                          variant="outline" 
                          size="sm" 
                          className="gap-1 flex-1"
                          onClick={() => handleDownloadReport(report)}
                        >
                          <Download className="w-4 h-4" />
                          Download Report Card
                        </Button>
                      </div>
                    </div>
                  </CardContent>
                </Card>
              ))}

              <Button onClick={handleDownloadAllReports} className="w-full gap-2">
                <Download className="w-4 h-4" />
                Download All Report Cards (PDF)
              </Button>
            </div>
          )}
        </TabsContent>

        {/* HISTORY TAB */}
        <TabsContent value="history" className="space-y-6 mt-6">
          <Card className="border-border/50">
            <CardHeader>
              <CardTitle>Score History</CardTitle>
            </CardHeader>
            <CardContent>
              {loadingHistory ? (
                <div className="flex items-center justify-center py-8">
                  <div className="animate-spin rounded-full h-8 w-8 border-b-2 border-primary"></div>
                </div>
              ) : scoreHistory.length === 0 ? (
                <div className="text-center py-8 text-muted-foreground">
                  No score history found. Start entering scores to build your history.
                </div>
              ) : (
                <div className="space-y-3">
                  {scoreHistory.map((history, index) => (
                    <div 
                      key={index} 
                      className="p-4 border border-border/50 rounded-lg flex justify-between items-center hover:bg-muted/50"
                    >
                      <div>
                        <p className="font-semibold text-foreground">
                          {history.class} - {history.subject}
                        </p>
                        <p className="text-sm text-muted-foreground">
                          {history.term} ({history.gradingPeriod}) • {history.studentCount} students • Avg: {history.averageScore.toFixed(1)}%
                        </p>
                        <p className="text-xs text-muted-foreground mt-1">
                          Recorded: {history.date}
                        </p>
                      </div>
                      <div className="text-right">
                        <div className="text-2xl font-bold text-primary">
                          {history.averageScore.toFixed(0)}%
                        </div>
                        <p className="text-xs text-muted-foreground">Class Average</p>
                      </div>
                    </div>
                  ))}
                </div>
              )}
            </CardContent>
          </Card>
        </TabsContent>
      </Tabs>
    </Layout>
  );
}
