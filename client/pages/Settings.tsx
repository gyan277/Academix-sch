import { useState, useEffect } from "react";
import Layout from "@/components/Layout";
import { Button } from "@/components/ui/button";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { Tabs, TabsContent, TabsList, TabsTrigger } from "@/components/ui/tabs";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import {
  Dialog,
  DialogContent,
  DialogDescription,
  DialogHeader,
  DialogTitle,
  DialogTrigger,
} from "@/components/ui/dialog";
import {
  Settings,
  Building2,
  Calendar,
  Plus,
  Upload,
  Trash2,
  Download,
  Check,
  X,
} from "lucide-react";
import { useToast } from "@/hooks/use-toast";
import { useAuth } from "@/hooks/use-auth";
import { supabase } from "@/lib/supabase";
import { TeacherManagementInterface } from "@/components/TeacherManagement";
import { useAcademicYear } from "@/hooks/use-academic-year";

interface Term {
  id: string;
  name: string;
  startDate: string;
  endDate: string;
}

interface Grade {
  grade: string;
  minScore: number;
  maxScore: number;
}

interface CalendarEvent {
  id: string;
  title: string;
  date: string;
  type: "holiday" | "exam" | "event";
}

interface Subject {
  id: string;
  subject_code: string;
  subject_name: string;
}

interface ClassSubject {
  id: string;
  class: string;
  subject_id: string;
  is_active: boolean;
}

export default function SettingsPage() {
  const { toast } = useToast();
  const { profile } = useAuth();
  
  // School settings - will be loaded from database
  const [schoolName, setSchoolName] = useState("");
  const [schoolAddress, setSchoolAddress] = useState("");
  const [schoolPhone, setSchoolPhone] = useState("");
  const [schoolEmail, setSchoolEmail] = useState("");
  const [academicYear, setAcademicYear] = useState("");
  const [currentTerm, setCurrentTerm] = useState("");
  
  // File upload states
  const [schoolLogo, setSchoolLogo] = useState<File | null>(null);
  const [logoPreview, setLogoPreview] = useState<string>("");
  const [signature, setSignature] = useState<File | null>(null);
  const [signaturePreview, setSignaturePreview] = useState<string>("");
  
  // Dialog states
  const [isAddTermOpen, setIsAddTermOpen] = useState(false);
  const [isAddEventOpen, setIsAddEventOpen] = useState(false);

  const [terms, setTerms] = useState<Term[]>([]);

  const [grades, setGrades] = useState<Grade[]>([]);
  const [loadingGrades, setLoadingGrades] = useState(true);

  const [editingGrade, setEditingGrade] = useState<string | null>(null);
  const [editingGradeData, setEditingGradeData] = useState<Grade | null>(null);
  const [isAddGradeOpen, setIsAddGradeOpen] = useState(false);
  const [newGrade, setNewGrade] = useState({
    grade: "",
    minScore: 0,
    maxScore: 0,
  });

  const [events, setEvents] = useState<CalendarEvent[]>([]);

  // Class subjects state
  const [selectedClassForSubjects, setSelectedClassForSubjects] = useState("P1");
  const [allSubjects, setAllSubjects] = useState<Subject[]>([]);
  const [classSubjects, setClassSubjects] = useState<ClassSubject[]>([]);
  const [loadingSubjects, setLoadingSubjects] = useState(false);
  const [savingSubjects, setSavingSubjects] = useState(false);

  // Password change state
  const [currentPassword, setCurrentPassword] = useState("");
  const [newPassword, setNewPassword] = useState("");
  const [confirmPassword, setConfirmPassword] = useState("");
  const [changingPassword, setChangingPassword] = useState(false);

  // Teacher fee collection toggle
  const [enableTeacherFeeCollection, setEnableTeacherFeeCollection] = useState(false);

  const classes = ["Creche", "Nursery 1", "Nursery 2", "KG1", "KG2", "Primary 1", "Primary 2", "Primary 3", "Primary 4", "Primary 5", "Primary 6", "JHS 1", "JHS 2", "JHS 3"];
  const { academicYear: currentAcademicYear } = useAcademicYear();

  // Load grades from database on mount
  useEffect(() => {
    loadGrades();
    loadAllSubjects();
    loadSchoolSettings();
    loadTerms();
    loadEvents();
  }, []);

  // Load class subjects when selected class changes
  useEffect(() => {
    if (selectedClassForSubjects) {
      loadClassSubjects();
    }
  }, [selectedClassForSubjects]);

  async function loadGrades() {
    try {
      setLoadingGrades(true);
      const { data, error } = await supabase
        .from('grading_scale')
        .select('*')
        .order('sort_order', { ascending: false });

      if (error) throw error;

      if (data) {
        setGrades(data.map(g => ({
          grade: g.grade,
          minScore: g.min_score,
          maxScore: g.max_score,
        })));
      }
    } catch (error) {
      console.error('Error loading grades:', error);
      toast({
        title: 'Error',
        description: 'Failed to load grading scale',
        variant: 'destructive',
      });
    } finally {
      setLoadingGrades(false);
    }
  }

  async function loadAllSubjects() {
    try {
      const { data, error } = await supabase
        .from('subjects')
        .select('*')
        .order('subject_name');

      if (error) throw error;
      setAllSubjects(data || []);
    } catch (error) {
      console.error('Error loading subjects:', error);
      toast({
        title: 'Error',
        description: 'Failed to load subjects',
        variant: 'destructive',
      });
    }
  }

  async function loadSchoolSettings() {
    if (!profile?.school_id) return;

    try {
      const { data, error } = await supabase
        .from('school_settings')
        .select('*')
        .eq('school_id', profile.school_id)
        .single();

      if (error && error.code !== 'PGRST116') throw error;

      if (data) {
        setSchoolName(data.school_name || '');
        setSchoolAddress(data.school_address || '');
        setSchoolPhone(data.school_phone || '');
        setSchoolEmail(data.school_email || '');
        setAcademicYear(data.current_academic_year || '2024/2025');
        setCurrentTerm(data.current_term || 'Term 1');
        setLogoPreview(data.school_logo_url || '');
        setSignaturePreview(data.headmaster_signature_url || '');
        setEnableTeacherFeeCollection(data.enable_teacher_fee_collection || false);
      }
    } catch (error) {
      console.error('Error loading school settings:', error);
    }
  }

  async function loadTerms() {
    if (!profile?.school_id) return;

    try {
      const { data, error } = await supabase
        .from('academic_terms')
        .select('*')
        .eq('school_id', profile.school_id)
        .eq('academic_year', '2024/2025')
        .order('start_date');

      if (error) throw error;

      if (data) {
        setTerms(data.map(t => ({
          id: t.id,
          name: t.name,
          startDate: t.start_date,
          endDate: t.end_date,
        })));
      }
    } catch (error) {
      console.error('Error loading terms:', error);
    }
  }

  async function loadEvents() {
    if (!profile?.school_id) return;

    try {
      const { data, error } = await supabase
        .from('calendar_events')
        .select('*')
        .eq('school_id', profile.school_id)
        .order('event_date');

      if (error) throw error;

      if (data) {
        setEvents(data.map(e => ({
          id: e.id,
          title: e.title,
          date: e.event_date,
          type: e.event_type as "holiday" | "exam" | "event",
        })));
      }
    } catch (error) {
      console.error('Error loading events:', error);
    }
  }

  async function loadClassSubjects() {
    try {
      setLoadingSubjects(true);
      const { data, error } = await supabase
        .from('class_subjects')
        .select('*')
        .eq('class', selectedClassForSubjects)
        .eq('academic_year', currentAcademicYear);

      if (error) throw error;
      setClassSubjects(data || []);
    } catch (error) {
      console.error('Error loading class subjects:', error);
      toast({
        title: 'Error',
        description: 'Failed to load class subjects',
        variant: 'destructive',
      });
    } finally {
      setLoadingSubjects(false);
    }
  }

  const isSubjectAssigned = (subjectId: string) => {
    return classSubjects.some(cs => cs.subject_id === subjectId && cs.is_active);
  };

  const handleToggleSubject = async (subjectId: string, isCurrentlyAssigned: boolean) => {
    if (!profile?.school_id) {
      toast({
        title: "Error",
        description: "School information not found. Please contact support.",
        variant: "destructive",
      });
      return;
    }

    try {
      if (isCurrentlyAssigned) {
        // Deactivate the subject
        const { error } = await supabase
          .from('class_subjects')
          .update({ is_active: false })
          .eq('class', selectedClassForSubjects)
          .eq('subject_id', subjectId)
          .eq('academic_year', currentAcademicYear);

        if (error) throw error;
      } else {
        // Check if record exists but is inactive
        const existing = classSubjects.find(cs => cs.subject_id === subjectId);
        
        if (existing) {
          // Reactivate
          const { error } = await supabase
            .from('class_subjects')
            .update({ is_active: true })
            .eq('id', existing.id);

          if (error) throw error;
        } else {
          // Insert new
          const { error } = await supabase
            .from('class_subjects')
            .insert({
              class: selectedClassForSubjects,
              subject_id: subjectId,
              academic_year: currentAcademicYear,
              is_active: true,
              school_id: profile.school_id,
            });

          if (error) throw error;
        }
      }

      // Reload class subjects
      await loadClassSubjects();

      toast({
        title: 'Success',
        description: `Subject ${isCurrentlyAssigned ? 'removed from' : 'added to'} ${selectedClassForSubjects}`,
      });
    } catch (error) {
      console.error('Error toggling subject:', error);
      toast({
        title: 'Error',
        description: 'Failed to update class subjects',
        variant: 'destructive',
      });
    }
  };

  const handleCopySubjectsToClass = async (targetClass: string) => {
    if (!profile?.school_id) {
      toast({
        title: "Error",
        description: "School information not found. Please contact support.",
        variant: "destructive",
      });
      return;
    }

    try {
      setSavingSubjects(true);

      // Get active subjects from current class
      const activeSubjects = classSubjects
        .filter(cs => cs.is_active)
        .map(cs => cs.subject_id);

      if (activeSubjects.length === 0) {
        toast({
          title: 'No Subjects',
          description: 'No subjects to copy from this class',
          variant: 'destructive',
        });
        return;
      }

      // Insert subjects for target class
      const inserts = activeSubjects.map(subjectId => ({
        class: targetClass,
        subject_id: subjectId,
        academic_year: currentAcademicYear,
        is_active: true,
        school_id: profile.school_id,
      }));

      const { error } = await supabase
        .from('class_subjects')
        .upsert(inserts, {
          onConflict: 'class,subject_id,academic_year',
          ignoreDuplicates: false,
        });

      if (error) throw error;

      toast({
        title: 'Success',
        description: `Copied ${activeSubjects.length} subjects to ${targetClass}`,
      });
    } catch (error) {
      console.error('Error copying subjects:', error);
      toast({
        title: 'Error',
        description: 'Failed to copy subjects',
        variant: 'destructive',
      });
    } finally {
      setSavingSubjects(false);
    }
  };

  const [newTerm, setNewTerm] = useState({
    name: "",
    startDate: "",
    endDate: "",
  });

  const [newEvent, setNewEvent] = useState<{
    title: string;
    date: string;
    type: "holiday" | "exam" | "event";
  }>({
    title: "",
    date: "",
    type: "holiday",
  });

  const handleAddTerm = async () => {
    if (!profile?.school_id) return;
    
    if (newTerm.name && newTerm.startDate && newTerm.endDate) {
      try {
        const { error } = await supabase
          .from('academic_terms')
          .insert({
            school_id: profile.school_id,
            name: newTerm.name,
            start_date: newTerm.startDate,
            end_date: newTerm.endDate,
            academic_year: '2024/2025',
          });

        if (error) throw error;

        await loadTerms();
        setNewTerm({ name: "", startDate: "", endDate: "" });
        setIsAddTermOpen(false);
        toast({
          title: "Term Added",
          description: `${newTerm.name} has been added successfully.`,
        });
      } catch (error) {
        console.error('Error adding term:', error);
        toast({
          title: "Error",
          description: "Failed to add term.",
          variant: "destructive",
        });
      }
    }
  };

  const handleDeleteTerm = async (id: string) => {
    const term = terms.find((t) => t.id === id);
    
    try {
      const { error } = await supabase
        .from('academic_terms')
        .delete()
        .eq('id', id);

      if (error) throw error;

      setTerms(terms.filter((t) => t.id !== id));
      toast({
        title: "Term Deleted",
        description: `${term?.name} has been removed.`,
        variant: "destructive",
      });
    } catch (error) {
      console.error('Error deleting term:', error);
      toast({
        title: "Error",
        description: "Failed to delete term.",
        variant: "destructive",
      });
    }
  };

  const handleAddEvent = async () => {
    if (!profile?.school_id) return;
    
    if (newEvent.title && newEvent.date) {
      try {
        const { error } = await supabase
          .from('calendar_events')
          .insert({
            school_id: profile.school_id,
            title: newEvent.title,
            event_date: newEvent.date,
            event_type: newEvent.type,
          });

        if (error) throw error;

        await loadEvents();
        setNewEvent({ title: "", date: "", type: "holiday" });
        setIsAddEventOpen(false);
        toast({
          title: "Event Added",
          description: `${newEvent.title} has been added to the calendar.`,
        });
      } catch (error) {
        console.error('Error adding event:', error);
        toast({
          title: "Error",
          description: "Failed to add event.",
          variant: "destructive",
        });
      }
    }
  };

  const handleDeleteEvent = async (id: string) => {
    const event = events.find((e) => e.id === id);
    
    try {
      const { error } = await supabase
        .from('calendar_events')
        .delete()
        .eq('id', id);

      if (error) throw error;

      setEvents(events.filter((e) => e.id !== id));
      toast({
        title: "Event Deleted",
        description: `${event?.title} has been removed.`,
        variant: "destructive",
      });
    } catch (error) {
      console.error('Error deleting event:', error);
      toast({
        title: "Error",
        description: "Failed to delete event.",
        variant: "destructive",
      });
    }
  };

  const handleSaveProfile = async () => {
    if (!profile?.school_id) {
      console.error('No school_id in profile');
      toast({
        title: "Error",
        description: "School information not found.",
        variant: "destructive",
      });
      return;
    }

    console.log('Saving profile for school_id:', profile.school_id);
    console.log('Data to save:', {
      school_name: schoolName,
      school_address: schoolAddress,
      school_phone: schoolPhone,
      school_email: schoolEmail,
      current_academic_year: academicYear,
      current_term: currentTerm,
    });

    try {
      // First check if record exists
      const { data: existing } = await supabase
        .from('school_settings')
        .select('id')
        .eq('school_id', profile.school_id)
        .single();

      console.log('Existing record:', existing);

      const updateData = {
        school_id: profile.school_id,
        school_name: schoolName || null,
        school_address: schoolAddress || null,
        school_phone: schoolPhone || null,
        school_email: schoolEmail || null,
        current_academic_year: academicYear || '2024/2025',
        current_term: currentTerm || 'Term 1',
      };

      const { data, error } = await supabase
        .from('school_settings')
        .upsert(updateData, {
          onConflict: 'school_id',
        })
        .select();

      if (error) {
        console.error('Database error:', error);
        throw error;
      }

      console.log('Save successful:', data);

      toast({
        title: "Profile Updated",
        description: "School profile has been saved successfully.",
      });
    } catch (error: any) {
      console.error('Error saving profile:', error);
      toast({
        title: "Error",
        description: error.message || "Failed to save school profile.",
        variant: "destructive",
      });
    }
  };

  const handleLogoUpload = async (e: React.ChangeEvent<HTMLInputElement>) => {
    const file = e.target.files?.[0];
    if (!file) return;

    console.log('Starting logo upload...', { fileName: file.name, fileSize: file.size, fileType: file.type });

    if (file.size > 5 * 1024 * 1024) {
      toast({
        title: "File Too Large",
        description: "Please upload an image smaller than 5MB.",
        variant: "destructive",
      });
      return;
    }
    if (!file.type.startsWith("image/")) {
      toast({
        title: "Invalid File Type",
        description: "Please upload an image file (PNG, JPG).",
        variant: "destructive",
      });
      return;
    }

    if (!profile?.school_id) {
      console.error('No school_id found in profile');
      toast({
        title: "Error",
        description: "School information not found.",
        variant: "destructive",
      });
      return;
    }

    console.log('School ID:', profile.school_id);

    try {
      // Show preview immediately
      const reader = new FileReader();
      reader.onloadend = () => {
        setLogoPreview(reader.result as string);
      };
      reader.readAsDataURL(file);

      // Upload to Supabase Storage
      const fileExt = file.name.split('.').pop();
      const fileName = `${profile.school_id}/logo.${fileExt}`;
      
      console.log('Uploading to storage:', fileName);

      // Upload new logo (upsert will replace if exists)
      const { data: uploadData, error: uploadError } = await supabase.storage
        .from('school-assets')
        .upload(fileName, file, {
          cacheControl: '3600',
          upsert: true
        });

      if (uploadError) {
        console.error('Storage upload error:', uploadError);
        throw uploadError;
      }

      console.log('Upload successful:', uploadData);

      // Get public URL
      const { data: { publicUrl } } = supabase.storage
        .from('school-assets')
        .getPublicUrl(fileName);

      console.log('Public URL:', publicUrl);
      setLogoPreview(publicUrl);

      // Save URL to database
      const { error: dbError } = await supabase
        .from('school_settings')
        .update({ school_logo_url: publicUrl })
        .eq('school_id', profile.school_id);

      if (dbError) {
        console.error('Database update error:', dbError);
        throw dbError;
      }

      console.log('Database updated successfully');

      toast({
        title: "Logo Uploaded",
        description: `${file.name} has been uploaded successfully.`,
      });
    } catch (error: any) {
      console.error('Error uploading logo:', error);
      toast({
        title: "Upload Failed",
        description: error.message || "Failed to upload logo. Please try again.",
        variant: "destructive",
      });
    }
  };

  const handleSignatureUpload = async (e: React.ChangeEvent<HTMLInputElement>) => {
    const file = e.target.files?.[0];
    if (!file) return;

    console.log('Starting signature upload...', { fileName: file.name, fileSize: file.size, fileType: file.type });

    if (file.size > 5 * 1024 * 1024) {
      toast({
        title: "File Too Large",
        description: "Please upload an image smaller than 5MB.",
        variant: "destructive",
      });
      return;
    }
    if (!file.type.startsWith("image/")) {
      toast({
        title: "Invalid File Type",
        description: "Please upload an image file (PNG, JPG).",
        variant: "destructive",
      });
      return;
    }

    if (!profile?.school_id) {
      console.error('No school_id found in profile');
      toast({
        title: "Error",
        description: "School information not found.",
        variant: "destructive",
      });
      return;
    }

    console.log('School ID:', profile.school_id);

    try {
      // Show preview immediately
      const reader = new FileReader();
      reader.onloadend = () => {
        setSignaturePreview(reader.result as string);
      };
      reader.readAsDataURL(file);

      // Upload to Supabase Storage
      const fileExt = file.name.split('.').pop();
      const fileName = `${profile.school_id}/signature.${fileExt}`;
      
      console.log('Uploading to storage:', fileName);

      // Upload new signature (upsert will replace if exists)
      const { data: uploadData, error: uploadError } = await supabase.storage
        .from('school-assets')
        .upload(fileName, file, {
          cacheControl: '3600',
          upsert: true
        });

      if (uploadError) {
        console.error('Storage upload error:', uploadError);
        throw uploadError;
      }

      console.log('Upload successful:', uploadData);

      // Get public URL
      const { data: { publicUrl } } = supabase.storage
        .from('school-assets')
        .getPublicUrl(fileName);

      console.log('Public URL:', publicUrl);
      setSignaturePreview(publicUrl);

      // Save URL to database
      const { error: dbError } = await supabase
        .from('school_settings')
        .update({ headmaster_signature_url: publicUrl })
        .eq('school_id', profile.school_id);

      if (dbError) {
        console.error('Database update error:', dbError);
        throw dbError;
      }

      console.log('Database updated successfully');

      toast({
        title: "Signature Uploaded",
        description: `${file.name} has been uploaded successfully.`,
      });
    } catch (error: any) {
      console.error('Error uploading signature:', error);
      toast({
        title: "Upload Failed",
        description: error.message || "Failed to upload signature. Please try again.",
        variant: "destructive",
      });
    }
  };

  const handleAddGrade = async () => {
    if (newGrade.grade && newGrade.minScore >= 0 && newGrade.maxScore >= newGrade.minScore) {
      // Check for overlapping ranges
      const hasOverlap = grades.some(
        (g) =>
          (newGrade.minScore >= g.minScore && newGrade.minScore <= g.maxScore) ||
          (newGrade.maxScore >= g.minScore && newGrade.maxScore <= g.maxScore)
      );

      if (hasOverlap) {
        toast({
          title: "Invalid Range",
          description: "Score range overlaps with existing grade.",
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
        // Insert into database
        const { error } = await supabase
          .from('grading_scale')
          .insert({
            grade: newGrade.grade,
            min_score: newGrade.minScore,
            max_score: newGrade.maxScore,
            sort_order: newGrade.minScore, // Use minScore as sort order
            school_id: profile.school_id,
          });

        if (error) {
          console.error('Error adding grade:', error);
          toast({
            title: 'Error Adding Grade',
            description: 'Could not save grade to database.',
            variant: 'destructive',
          });
          return;
        }

        // Reload grades from database
        await loadGrades();
        
        setNewGrade({ grade: "", minScore: 0, maxScore: 0 });
        setIsAddGradeOpen(false);
        toast({
          title: "Grade Added",
          description: `Grade ${newGrade.grade} has been added successfully.`,
        });
      } catch (err) {
        console.error('Unexpected error adding grade:', err);
        toast({
          title: 'Error',
          description: 'An unexpected error occurred.',
          variant: 'destructive',
        });
      }
    }
  };

  const handleUpdateGrade = async (oldGrade: string, updates: Partial<Grade>) => {
    try {
      // Update in database
      const { error } = await supabase
        .from('grading_scale')
        .update({
          grade: updates.grade,
          min_score: updates.minScore,
          max_score: updates.maxScore,
          sort_order: updates.minScore, // Update sort order
        })
        .eq('grade', oldGrade);

      if (error) {
        console.error('Error updating grade:', error);
        toast({
          title: 'Error Updating Grade',
          description: 'Could not save changes to database.',
          variant: 'destructive',
        });
        return;
      }

      // Reload grades from database
      await loadGrades();
      
      setEditingGrade(null);
      setEditingGradeData(null);
      toast({
        title: "Grade Updated",
        description: `Grade ${oldGrade} has been updated.`,
      });
    } catch (err) {
      console.error('Unexpected error updating grade:', err);
      toast({
        title: 'Error',
        description: 'An unexpected error occurred.',
        variant: 'destructive',
      });
    }
  };

  const handleStartEditGrade = (grade: Grade) => {
    setEditingGrade(grade.grade);
    setEditingGradeData({ ...grade });
  };

  const handleCancelEditGrade = () => {
    setEditingGrade(null);
    setEditingGradeData(null);
  };

  const handleSaveEditGrade = () => {
    if (editingGradeData && editingGrade) {
      handleUpdateGrade(editingGrade, editingGradeData);
    }
  };

  const handleDeleteGrade = async (gradeToDelete: string) => {
    try {
      // Delete from database
      const { error } = await supabase
        .from('grading_scale')
        .delete()
        .eq('grade', gradeToDelete);

      if (error) {
        console.error('Error deleting grade:', error);
        toast({
          title: 'Error Deleting Grade',
          description: 'Could not delete grade from database.',
          variant: 'destructive',
        });
        return;
      }

      // Reload grades from database
      await loadGrades();
      
      toast({
        title: "Grade Deleted",
        description: `Grade ${gradeToDelete} has been removed.`,
        variant: "destructive",
      });
    } catch (err) {
      console.error('Unexpected error deleting grade:', err);
      toast({
        title: 'Error',
        description: 'An unexpected error occurred.',
        variant: 'destructive',
      });
    }
  };

  const handleSaveGrades = () => {
    // In production, this would save to database
    toast({
      title: "Grading System Updated",
      description: "All student grades will be recalculated based on the new grading scale.",
    });
  };

  const handleExportData = () => {
    // In production, this would trigger a download
    toast({
      title: "Export Started",
      description: "Your data export is being prepared. Check your downloads folder.",
    });
  };

  const handleSaveSchoolSettings = async () => {
    if (!profile?.school_id) {
      toast({
        title: "Error",
        description: "School information not found. Please contact support.",
        variant: "destructive",
      });
      return;
    }

    try {
      const { error } = await supabase
        .from('school_settings')
        .update({
          school_name: schoolName,
          school_address: schoolAddress,
          school_phone: schoolPhone,
          school_email: schoolEmail,
          current_academic_year: academicYear,
          current_term: currentTerm,
          enable_teacher_fee_collection: enableTeacherFeeCollection,
        })
        .eq('id', profile.school_id);

      if (error) throw error;

      toast({
        title: "Settings Saved",
        description: "School settings have been updated successfully.",
      });
      
      // Reload settings to confirm
      await loadSchoolSettings();
    } catch (error) {
      console.error('Error saving school settings:', error);
      toast({
        title: "Error",
        description: "Failed to save school settings.",
        variant: "destructive",
      });
    }
  };

  const handleImportData = () => {
    // In production, this would open a file picker
    toast({
      title: "Import Data",
      description: "Please select a file to import.",
    });
  };

  return (
    <Layout title="Settings" subtitle="Configure your school and system preferences">
      <Tabs defaultValue="profile" className="w-full">
        <TabsList className="grid w-full max-w-2xl grid-cols-6">
          <TabsTrigger value="profile">Profile</TabsTrigger>
          <TabsTrigger value="terms">Terms</TabsTrigger>
          <TabsTrigger value="grades">Grades</TabsTrigger>
          <TabsTrigger value="subjects">Subjects</TabsTrigger>
          <TabsTrigger value="calendar">Calendar</TabsTrigger>
          {profile?.role === 'admin' && (
            <TabsTrigger value="teachers">Teachers</TabsTrigger>
          )}
        </TabsList>

        {/* PROFILE TAB */}
        <TabsContent value="profile" className="space-y-6 mt-6">
          <Card className="border-border/50">
            <CardHeader>
              <CardTitle className="flex items-center gap-2">
                School Profile
              </CardTitle>
            </CardHeader>
            <CardContent className="space-y-6">
              <div className="space-y-4">
                <div>
                  <Label htmlFor="schoolName">School Name</Label>
                  <Input
                    id="schoolName"
                    value={schoolName}
                    onChange={(e) => setSchoolName(e.target.value)}
                    className="mt-2"
                  />
                </div>
                <div>
                  <Label htmlFor="address">Address</Label>
                  <Input
                    id="address"
                    value={schoolAddress}
                    onChange={(e) => setSchoolAddress(e.target.value)}
                    className="mt-2"
                  />
                </div>
                <div className="grid grid-cols-1 sm:grid-cols-2 gap-4">
                  <div>
                    <Label htmlFor="phone">Phone Number</Label>
                    <Input
                      id="phone"
                      value={schoolPhone}
                      onChange={(e) => setSchoolPhone(e.target.value)}
                      className="mt-2"
                    />
                  </div>
                  <div>
                    <Label htmlFor="email">Email Address</Label>
                    <Input
                      id="email"
                      type="email"
                      value={schoolEmail}
                      onChange={(e) => setSchoolEmail(e.target.value)}
                      className="mt-2"
                    />
                  </div>
                </div>
                
                {/* Teacher Fee Collection Toggle */}
                <div className="space-y-3 pt-4 border-t border-border">
                  <div className="flex items-center justify-between">
                    <div className="space-y-1">
                      <Label htmlFor="teacherFeeCollection" className="text-base font-semibold">
                        Teacher Fee Collection
                      </Label>
                      <p className="text-sm text-muted-foreground">
                        Allow teachers to collect bus and canteen fees from their assigned class. 
                        Admin must confirm before payments are recorded.
                      </p>
                    </div>
                    <div className="flex items-center space-x-2">
                      <input
                        type="checkbox"
                        id="teacherFeeCollection"
                        checked={enableTeacherFeeCollection}
                        onChange={(e) => setEnableTeacherFeeCollection(e.target.checked)}
                        className="w-5 h-5 rounded border-input"
                      />
                    </div>
                  </div>
                </div>
                
                <Button onClick={handleSaveSchoolSettings} className="w-full sm:w-auto">
                  <Check className="w-4 h-4 mr-2" />
                  Save School Settings
                </Button>
              </div>

              <div className="space-y-4 pt-4 border-t border-border">
                <h4 className="font-semibold text-foreground">Assets</h4>
                <div className="space-y-4">
                  <div>
                    <Label>School Logo</Label>
                    {logoPreview ? (
                      <div className="mt-2 space-y-3">
                        <div className="relative w-32 h-32 border-2 border-border rounded-lg overflow-hidden">
                          <img
                            src={logoPreview}
                            alt="School Logo"
                            className="w-full h-full object-cover"
                          />
                        </div>
                        <div className="flex gap-2">
                          <Button
                            variant="outline"
                            size="sm"
                            onClick={() => {
                              setSchoolLogo(null);
                              setLogoPreview("");
                              toast({
                                title: "Logo Removed",
                                description: "School logo has been removed.",
                              });
                            }}
                          >
                            <X className="w-4 h-4 mr-2" />
                            Remove
                          </Button>
                          <label htmlFor="logo-upload">
                            <Button variant="outline" size="sm" asChild>
                              <span className="cursor-pointer">
                                <Upload className="w-4 h-4 mr-2" />
                                Change
                              </span>
                            </Button>
                          </label>
                        </div>
                      </div>
                    ) : (
                      <label htmlFor="logo-upload">
                        <div className="mt-2 border-2 border-dashed border-border/50 rounded-lg p-6 flex flex-col items-center justify-center cursor-pointer hover:border-primary/50 transition-colors">
                          <Upload className="w-8 h-8 text-muted-foreground mb-2" />
                          <p className="text-sm text-muted-foreground">
                            Click to upload or drag and drop
                          </p>
                          <p className="text-xs text-muted-foreground mt-1">
                            PNG, JPG up to 5MB
                          </p>
                        </div>
                      </label>
                    )}
                    <input
                      id="logo-upload"
                      type="file"
                      accept="image/*"
                      className="hidden"
                      onChange={handleLogoUpload}
                    />
                  </div>
                  <div>
                    <Label>Headmaster's Signature</Label>
                    {signaturePreview ? (
                      <div className="mt-2 space-y-3">
                        <div className="relative w-48 h-24 border-2 border-border rounded-lg overflow-hidden bg-white">
                          <img
                            src={signaturePreview}
                            alt="Signature"
                            className="w-full h-full object-contain"
                          />
                        </div>
                        <div className="flex gap-2">
                          <Button
                            variant="outline"
                            size="sm"
                            onClick={() => {
                              setSignature(null);
                              setSignaturePreview("");
                              toast({
                                title: "Signature Removed",
                                description: "Headmaster's signature has been removed.",
                              });
                            }}
                          >
                            <X className="w-4 h-4 mr-2" />
                            Remove
                          </Button>
                          <label htmlFor="signature-upload">
                            <Button variant="outline" size="sm" asChild>
                              <span className="cursor-pointer">
                                <Upload className="w-4 h-4 mr-2" />
                                Change
                              </span>
                            </Button>
                          </label>
                        </div>
                      </div>
                    ) : (
                      <label htmlFor="signature-upload">
                        <div className="mt-2 border-2 border-dashed border-border/50 rounded-lg p-6 flex flex-col items-center justify-center cursor-pointer hover:border-primary/50 transition-colors">
                          <Upload className="w-8 h-8 text-muted-foreground mb-2" />
                          <p className="text-sm text-muted-foreground">
                            Click to upload or drag and drop
                          </p>
                          <p className="text-xs text-muted-foreground mt-1">
                            PNG, JPG up to 5MB
                          </p>
                        </div>
                      </label>
                    )}
                    <input
                      id="signature-upload"
                      type="file"
                      accept="image/*"
                      className="hidden"
                      onChange={handleSignatureUpload}
                    />
                  </div>
                </div>
              </div>

              <div className="space-y-4 pt-4 border-t border-border">
                <h4 className="font-semibold text-foreground">Data Management</h4>
                <div className="grid grid-cols-1 sm:grid-cols-2 gap-4">
                  <Button
                    variant="outline"
                    onClick={handleExportData}
                    className="gap-2"
                  >
                    <Download className="w-4 h-4" />
                    Export Data
                  </Button>
                  <Button
                    variant="outline"
                    onClick={handleImportData}
                    className="gap-2"
                  >
                    <Upload className="w-4 h-4" />
                    Import Data
                  </Button>
                </div>
              </div>

              <Button onClick={handleSaveProfile} className="gap-2">
                <Settings className="w-4 h-4" />
                Save Changes
              </Button>
            </CardContent>
          </Card>
        </TabsContent>

        {/* TERMS TAB */}
        <TabsContent value="terms" className="space-y-6 mt-6">
          <Card className="border-border/50">
            <CardHeader>
              <CardTitle className="flex items-center gap-2">
                <Calendar className="w-5 h-5" />
                Academic Terms
              </CardTitle>
            </CardHeader>
            <CardContent className="space-y-6">
              {/* Add Term Dialog */}
              <Dialog open={isAddTermOpen} onOpenChange={setIsAddTermOpen}>
                <DialogTrigger asChild>
                  <Button className="gap-2">
                    <Plus className="w-4 h-4" />
                    Add New Term
                  </Button>
                </DialogTrigger>
                <DialogContent>
                  <DialogHeader>
                    <DialogTitle>Add New Academic Term</DialogTitle>
                    <DialogDescription>
                      Define the term dates for your academic year
                    </DialogDescription>
                  </DialogHeader>
                  <div className="space-y-4">
                    <div>
                      <Label htmlFor="termName">Term Name</Label>
                      <Input
                        id="termName"
                        value={newTerm.name}
                        onChange={(e) =>
                          setNewTerm({ ...newTerm, name: e.target.value })
                        }
                        placeholder="Term 4"
                      />
                    </div>
                    <div>
                      <Label htmlFor="termStart">Start Date</Label>
                      <Input
                        id="termStart"
                        type="date"
                        value={newTerm.startDate}
                        onChange={(e) =>
                          setNewTerm({ ...newTerm, startDate: e.target.value })
                        }
                      />
                    </div>
                    <div>
                      <Label htmlFor="termEnd">End Date</Label>
                      <Input
                        id="termEnd"
                        type="date"
                        value={newTerm.endDate}
                        onChange={(e) =>
                          setNewTerm({ ...newTerm, endDate: e.target.value })
                        }
                      />
                    </div>
                    <Button onClick={handleAddTerm} className="w-full">
                      <Check className="w-4 h-4 mr-2" />
                      Add Term
                    </Button>
                  </div>
                </DialogContent>
              </Dialog>

              {/* Terms List */}
              <div className="space-y-3">
                {terms.map((term) => (
                  <div
                    key={term.id}
                    className="p-4 border border-border/50 rounded-lg flex items-center justify-between hover:bg-muted/50"
                  >
                    <div>
                      <p className="font-semibold text-foreground">{term.name}</p>
                      <p className="text-sm text-muted-foreground">
                        {term.startDate} to {term.endDate}
                      </p>
                    </div>
                    <Button
                      variant="ghost"
                      size="icon"
                      onClick={() => handleDeleteTerm(term.id)}
                    >
                      <Trash2 className="w-4 h-4 text-destructive" />
                    </Button>
                  </div>
                ))}
              </div>
            </CardContent>
          </Card>
        </TabsContent>

        {/* GRADES TAB */}
        <TabsContent value="grades" className="space-y-6 mt-6">
          <Card className="border-border/50">
            <CardHeader>
              <div className="flex items-center justify-between">
                <CardTitle>Grading Scale</CardTitle>
                <Dialog open={isAddGradeOpen} onOpenChange={setIsAddGradeOpen}>
                  <DialogTrigger asChild>
                    <Button className="gap-2">
                      <Plus className="w-4 h-4" />
                      Add Grade
                    </Button>
                  </DialogTrigger>
                  <DialogContent>
                    <DialogHeader>
                      <DialogTitle>Add New Grade</DialogTitle>
                      <DialogDescription>
                        Define a new grade with score range
                      </DialogDescription>
                    </DialogHeader>
                    <div className="space-y-4">
                      <div>
                        <Label htmlFor="gradeName">Grade Name</Label>
                        <Input
                          id="gradeName"
                          value={newGrade.grade}
                          onChange={(e) =>
                            setNewGrade({ ...newGrade, grade: e.target.value })
                          }
                          placeholder="e.g., A1, B+, etc."
                        />
                      </div>
                      <div className="grid grid-cols-2 gap-4">
                        <div>
                          <Label htmlFor="minScore">Min Score</Label>
                          <Input
                            id="minScore"
                            type="number"
                            min="0"
                            max="100"
                            value={newGrade.minScore}
                            onChange={(e) =>
                              setNewGrade({
                                ...newGrade,
                                minScore: parseInt(e.target.value) || 0,
                              })
                            }
                          />
                        </div>
                        <div>
                          <Label htmlFor="maxScore">Max Score</Label>
                          <Input
                            id="maxScore"
                            type="number"
                            min="0"
                            max="100"
                            value={newGrade.maxScore}
                            onChange={(e) =>
                              setNewGrade({
                                ...newGrade,
                                maxScore: parseInt(e.target.value) || 0,
                              })
                            }
                          />
                        </div>
                      </div>
                      <Button onClick={handleAddGrade} className="w-full">
                        <Check className="w-4 h-4 mr-2" />
                        Add Grade
                      </Button>
                    </div>
                  </DialogContent>
                </Dialog>
              </div>
            </CardHeader>
            <CardContent className="space-y-4">
              <div className="overflow-x-auto border border-border/50 rounded-lg">
                <table className="w-full text-sm">
                  <thead className="bg-muted border-b border-border">
                    <tr>
                      <th className="px-4 py-3 text-left font-semibold">Grade</th>
                      <th className="px-4 py-3 text-center font-semibold">Min Score</th>
                      <th className="px-4 py-3 text-center font-semibold">Max Score</th>
                      <th className="px-4 py-3 text-center font-semibold">Score Range</th>
                      <th className="px-4 py-3 text-center font-semibold">Actions</th>
                    </tr>
                  </thead>
                  <tbody>
                    {grades.map((grade) => (
                      <tr key={grade.grade} className="border-b border-border/50 hover:bg-muted/50">
                        <td className="px-4 py-3 font-semibold text-primary">
                          {editingGrade === grade.grade && editingGradeData ? (
                            <Input
                              value={editingGradeData.grade}
                              onChange={(e) =>
                                setEditingGradeData({ ...editingGradeData, grade: e.target.value })
                              }
                              className="w-20"
                            />
                          ) : (
                            grade.grade
                          )}
                        </td>
                        <td className="px-4 py-3 text-center">
                          {editingGrade === grade.grade && editingGradeData ? (
                            <Input
                              type="number"
                              min="0"
                              max="100"
                              value={editingGradeData.minScore}
                              onChange={(e) =>
                                setEditingGradeData({
                                  ...editingGradeData,
                                  minScore: parseInt(e.target.value) || 0,
                                })
                              }
                              className="w-20 mx-auto"
                            />
                          ) : (
                            grade.minScore
                          )}
                        </td>
                        <td className="px-4 py-3 text-center">
                          {editingGrade === grade.grade && editingGradeData ? (
                            <Input
                              type="number"
                              min="0"
                              max="100"
                              value={editingGradeData.maxScore}
                              onChange={(e) =>
                                setEditingGradeData({
                                  ...editingGradeData,
                                  maxScore: parseInt(e.target.value) || 0,
                                })
                              }
                              className="w-20 mx-auto"
                            />
                          ) : (
                            grade.maxScore
                          )}
                        </td>
                        <td className="px-4 py-3 text-center">
                          <div className="flex items-center justify-center">
                            <div className="flex-1 max-w-xs h-2 bg-border rounded-full overflow-hidden">
                              <div
                                className="h-full bg-foreground"
                                style={{
                                  width: `${((grade.maxScore - grade.minScore + 1) / 100) * 100}%`,
                                }}
                              />
                            </div>
                          </div>
                        </td>
                        <td className="px-4 py-3 text-center">
                          <div className="flex items-center justify-center gap-2">
                            {editingGrade === grade.grade ? (
                              <>
                                <Button
                                  variant="ghost"
                                  size="sm"
                                  onClick={handleSaveEditGrade}
                                >
                                  <Check className="w-4 h-4 text-green-600" />
                                </Button>
                                <Button
                                  variant="ghost"
                                  size="sm"
                                  onClick={handleCancelEditGrade}
                                >
                                  <X className="w-4 h-4 text-red-600" />
                                </Button>
                              </>
                            ) : (
                              <>
                                <Button
                                  variant="ghost"
                                  size="sm"
                                  onClick={() => handleStartEditGrade(grade)}
                                >
                                  Edit
                                </Button>
                                <Button
                                  variant="ghost"
                                  size="sm"
                                  onClick={() => handleDeleteGrade(grade.grade)}
                                >
                                  <Trash2 className="w-4 h-4 text-destructive" />
                                </Button>
                              </>
                            )}
                          </div>
                        </td>
                      </tr>
                    ))}
                  </tbody>
                </table>
              </div>

              <div className="flex items-center justify-between pt-4 border-t border-border">
                <p className="text-sm text-muted-foreground">
                  Changes to the grading scale will affect all student grade calculations
                </p>
                <Button onClick={handleSaveGrades} className="gap-2">
                  <Settings className="w-4 h-4" />
                  Save Grading Scale
                </Button>
              </div>
            </CardContent>
          </Card>
        </TabsContent>

        {/* CLASS SUBJECTS TAB */}
        <TabsContent value="subjects" className="space-y-6 mt-6">
          <Card className="border-border/50">
            <CardHeader>
              <CardTitle>Class Subjects Management</CardTitle>
              <p className="text-sm text-muted-foreground mt-2">
                Configure which subjects are taught in each class. Different classes can have different subjects.
              </p>
            </CardHeader>
            <CardContent className="space-y-6">
              {/* Class Selector */}
              <div className="grid grid-cols-1 sm:grid-cols-2 gap-4">
                <div>
                  <Label htmlFor="classSelect">Select Class</Label>
                  <select
                    id="classSelect"
                    value={selectedClassForSubjects}
                    onChange={(e) => setSelectedClassForSubjects(e.target.value)}
                    className="w-full px-3 py-2 border border-input rounded-md bg-background mt-2"
                  >
                    {classes.map((cls) => (
                      <option key={cls} value={cls}>
                        {cls}
                      </option>
                    ))}
                  </select>
                </div>
                <div className="flex items-end">
                  <Dialog>
                    <DialogTrigger asChild>
                      <Button variant="outline" className="w-full gap-2">
                        <Plus className="w-4 h-4" />
                        Copy to Another Class
                      </Button>
                    </DialogTrigger>
                    <DialogContent>
                      <DialogHeader>
                        <DialogTitle>Copy Subjects to Another Class</DialogTitle>
                        <DialogDescription>
                          Copy all subjects from {selectedClassForSubjects} to another class
                        </DialogDescription>
                      </DialogHeader>
                      <div className="space-y-4">
                        <Label>Select Target Class</Label>
                        <div className="grid grid-cols-3 gap-2">
                          {classes
                            .filter(cls => cls !== selectedClassForSubjects)
                            .map((cls) => (
                              <Button
                                key={cls}
                                variant="outline"
                                onClick={() => {
                                  handleCopySubjectsToClass(cls);
                                }}
                                disabled={savingSubjects}
                              >
                                {cls}
                              </Button>
                            ))}
                        </div>
                      </div>
                    </DialogContent>
                  </Dialog>
                </div>
              </div>

              {/* Subject Count */}
              <div className="p-4 bg-muted rounded-lg border border-border">
                <p className="text-sm font-semibold text-foreground">
                  {selectedClassForSubjects} has {classSubjects.filter(cs => cs.is_active).length} subjects assigned
                </p>
              </div>

              {/* Subjects List */}
              {loadingSubjects ? (
                <div className="text-center py-12">
                  <div className="animate-spin rounded-full h-8 w-8 border-b-2 border-primary mx-auto mb-2"></div>
                  <p className="text-sm text-muted-foreground">Loading subjects...</p>
                </div>
              ) : (
                <div className="space-y-3">
                  <h4 className="font-semibold text-foreground">Available Subjects</h4>
                  <div className="grid grid-cols-1 sm:grid-cols-2 gap-3">
                    {allSubjects.map((subject) => {
                      const isAssigned = isSubjectAssigned(subject.id);
                      return (
                        <div
                          key={subject.id}
                          className={`p-4 border rounded-lg cursor-pointer transition-colors ${
                            isAssigned
                              ? 'bg-primary/10 border-primary'
                              : 'bg-background border-border hover:bg-muted'
                          }`}
                          onClick={() => handleToggleSubject(subject.id, isAssigned)}
                        >
                          <div className="flex items-center justify-between">
                            <div className="flex-1">
                              <p className="font-medium text-foreground">{subject.subject_name}</p>
                              <p className="text-xs text-muted-foreground">{subject.subject_code}</p>
                            </div>
                            <div>
                              {isAssigned ? (
                                <Check className="w-5 h-5 text-primary" />
                              ) : (
                                <Plus className="w-5 h-5 text-muted-foreground" />
                              )}
                            </div>
                          </div>
                        </div>
                      );
                    })}
                  </div>
                  <p className="text-xs text-muted-foreground mt-4">
                    Click on a subject to add or remove it from {selectedClassForSubjects}
                  </p>
                </div>
              )}
            </CardContent>
          </Card>
        </TabsContent>

        {/* CALENDAR TAB */}
        <TabsContent value="calendar" className="space-y-6 mt-6">
          <Card className="border-border/50">
            <CardHeader>
              <CardTitle className="flex items-center gap-2">
                <Calendar className="w-5 h-5" />
                School Calendar
              </CardTitle>
            </CardHeader>
            <CardContent className="space-y-6">
              {/* Add Event Dialog */}
              <Dialog open={isAddEventOpen} onOpenChange={setIsAddEventOpen}>
                <DialogTrigger asChild>
                  <Button className="gap-2">
                    <Plus className="w-4 h-4" />
                    Add Calendar Event
                  </Button>
                </DialogTrigger>
                <DialogContent>
                  <DialogHeader>
                    <DialogTitle>Add Calendar Event</DialogTitle>
                    <DialogDescription>
                      Add holidays, exam dates, and school events
                    </DialogDescription>
                  </DialogHeader>
                  <div className="space-y-4">
                    <div>
                      <Label htmlFor="eventTitle">Event Title</Label>
                      <Input
                        id="eventTitle"
                        value={newEvent.title}
                        onChange={(e) =>
                          setNewEvent({ ...newEvent, title: e.target.value })
                        }
                        placeholder="e.g., School Sports Day"
                      />
                    </div>
                    <div>
                      <Label htmlFor="eventDate">Date</Label>
                      <Input
                        id="eventDate"
                        type="date"
                        value={newEvent.date}
                        onChange={(e) =>
                          setNewEvent({ ...newEvent, date: e.target.value })
                        }
                      />
                    </div>
                    <div>
                      <Label htmlFor="eventType">Event Type</Label>
                      <select
                        id="eventType"
                        value={newEvent.type}
                        onChange={(e) =>
                          setNewEvent({
                            ...newEvent,
                            type: e.target.value as "holiday" | "exam" | "event",
                          })
                        }
                        className="w-full px-3 py-2 border border-input rounded-md bg-background mt-2"
                      >
                        <option value="holiday">Holiday</option>
                        <option value="exam">Exam</option>
                        <option value="event">Event</option>
                      </select>
                    </div>
                    <Button onClick={handleAddEvent} className="w-full">
                      <Check className="w-4 h-4 mr-2" />
                      Add Event
                    </Button>
                  </div>
                </DialogContent>
              </Dialog>

              {/* Calendar Events */}
              <div className="space-y-3">
                {events.map((event) => (
                  <div
                    key={event.id}
                    className="p-4 border border-border/50 rounded-lg flex items-center justify-between hover:bg-muted/50"
                  >
                    <div className="flex items-center gap-3">
                      <div
                        className={`w-3 h-3 rounded-full border-2 ${
                          event.type === "holiday"
                            ? "bg-muted border-border"
                            : event.type === "exam"
                              ? "bg-foreground border-foreground"
                              : "bg-primary border-primary"
                        }`}
                      />
                      <div>
                        <p className="font-semibold text-foreground">
                          {event.title}
                        </p>
                        <p className="text-sm text-muted-foreground">{event.date}</p>
                      </div>
                    </div>
                    <Button
                      variant="ghost"
                      size="icon"
                      onClick={() => handleDeleteEvent(event.id)}
                    >
                      <Trash2 className="w-4 h-4 text-destructive" />
                    </Button>
                  </div>
                ))}
              </div>
            </CardContent>
          </Card>
        </TabsContent>

        {/* TEACHERS TAB - Admin Only */}
        {profile?.role === 'admin' && (
          <TabsContent value="teachers" className="space-y-6 mt-6">
            <TeacherManagementInterface />
          </TabsContent>
        )}
      </Tabs>
    </Layout>
  );
}
