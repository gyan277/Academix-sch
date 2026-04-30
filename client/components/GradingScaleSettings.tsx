import { useState, useEffect } from "react";
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from "@/components/ui/card";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import { Plus, Trash2, Save, RotateCcw } from "lucide-react";
import { supabase } from "@/lib/supabase";
import { useToast } from "@/hooks/use-toast";
import { useAuth } from "@/hooks/use-auth";

interface GradeScale {
  id?: string;
  grade: string;
  minScore: number;
  maxScore: number;
}

export function GradingScaleSettings() {
  const { toast } = useToast();
  const { profile } = useAuth();
  const [gradingScale, setGradingScale] = useState<GradeScale[]>([]);
  const [loading, setLoading] = useState(false);
  const [saving, setSaving] = useState(false);

  const defaultGradingScale: GradeScale[] = [
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
  ];

  useEffect(() => {
    loadGradingScale();
  }, [profile?.school_id]);

  const loadGradingScale = async () => {
    if (!profile?.school_id) return;

    setLoading(true);
    try {
      const { data, error } = await supabase
        .from("grading_scale")
        .select("id, grade, min_score, max_score")
        .eq("school_id", profile.school_id)
        .order("min_score", { ascending: false });

      if (error) throw error;

      if (data && data.length > 0) {
        setGradingScale(
          data.map((g) => ({
            id: g.id,
            grade: g.grade,
            minScore: g.min_score,
            maxScore: g.max_score,
          }))
        );
      } else {
        // Use default if none exists
        setGradingScale(defaultGradingScale);
      }
    } catch (error: any) {
      console.error("Error loading grading scale:", error);
      toast({
        title: "Error",
        description: "Failed to load grading scale",
        variant: "destructive",
      });
    } finally {
      setLoading(false);
    }
  };

  const handleAddGrade = () => {
    setGradingScale([
      ...gradingScale,
      { grade: "", minScore: 0, maxScore: 0 },
    ]);
  };

  const handleRemoveGrade = (index: number) => {
    setGradingScale(gradingScale.filter((_, i) => i !== index));
  };

  const handleGradeChange = (index: number, field: keyof GradeScale, value: string | number) => {
    const updated = [...gradingScale];
    updated[index] = { ...updated[index], [field]: value };
    setGradingScale(updated);
  };

  const handleResetToDefault = () => {
    setGradingScale(defaultGradingScale);
    toast({
      title: "Reset to Default",
      description: "Grading scale reset to default values. Click Save to apply.",
    });
  };

  const validateGradingScale = (): boolean => {
    // Check for empty grades
    if (gradingScale.some((g) => !g.grade.trim())) {
      toast({
        title: "Validation Error",
        description: "All grades must have a name",
        variant: "destructive",
      });
      return false;
    }

    // Check for overlapping ranges
    for (let i = 0; i < gradingScale.length; i++) {
      const current = gradingScale[i];
      
      if (current.minScore > current.maxScore) {
        toast({
          title: "Validation Error",
          description: `Grade ${current.grade}: Min score cannot be greater than max score`,
          variant: "destructive",
        });
        return false;
      }

      if (current.minScore < 0 || current.maxScore > 100) {
        toast({
          title: "Validation Error",
          description: `Grade ${current.grade}: Scores must be between 0 and 100`,
          variant: "destructive",
        });
        return false;
      }
    }

    return true;
  };

  const handleSave = async () => {
    if (!profile?.school_id) {
      toast({
        title: "Error",
        description: "School information not found",
        variant: "destructive",
      });
      return;
    }

    if (!validateGradingScale()) return;

    setSaving(true);
    try {
      // Delete existing grading scale
      const { error: deleteError } = await supabase
        .from("grading_scale")
        .delete()
        .eq("school_id", profile.school_id);

      if (deleteError) throw deleteError;

      // Insert new grading scale
      const { error: insertError } = await supabase
        .from("grading_scale")
        .insert(
          gradingScale.map((g) => ({
            school_id: profile.school_id,
            grade: g.grade,
            min_score: g.minScore,
            max_score: g.maxScore,
          }))
        );

      if (insertError) throw insertError;

      toast({
        title: "Success",
        description: "Grading scale saved successfully",
      });

      // Reload to get IDs
      await loadGradingScale();
    } catch (error: any) {
      console.error("Error saving grading scale:", error);
      toast({
        title: "Error",
        description: error.message || "Failed to save grading scale",
        variant: "destructive",
      });
    } finally {
      setSaving(false);
    }
  };

  if (loading) {
    return (
      <Card>
        <CardContent className="pt-6">
          <div className="flex items-center justify-center py-8">
            <div className="animate-spin rounded-full h-8 w-8 border-b-2 border-primary"></div>
          </div>
        </CardContent>
      </Card>
    );
  }

  return (
    <div className="space-y-6">
      <Card>
        <CardHeader>
          <CardTitle>Grading Scale Configuration</CardTitle>
          <CardDescription>
            Customize your school's grading system. This will be used to calculate grades for all academic scores.
          </CardDescription>
        </CardHeader>
        <CardContent className="space-y-4">
          <div className="space-y-3">
            {gradingScale.map((scale, index) => (
              <div key={index} className="flex items-end gap-3 p-3 border border-border rounded-lg bg-muted/30">
                <div className="flex-1 grid grid-cols-3 gap-3">
                  <div className="space-y-2">
                    <Label htmlFor={`grade-${index}`}>Grade</Label>
                    <Input
                      id={`grade-${index}`}
                      value={scale.grade}
                      onChange={(e) => handleGradeChange(index, "grade", e.target.value)}
                      placeholder="A1"
                      className="uppercase"
                    />
                  </div>
                  <div className="space-y-2">
                    <Label htmlFor={`min-${index}`}>Min Score</Label>
                    <Input
                      id={`min-${index}`}
                      type="number"
                      min="0"
                      max="100"
                      value={scale.minScore}
                      onChange={(e) => handleGradeChange(index, "minScore", parseInt(e.target.value) || 0)}
                      placeholder="0"
                    />
                  </div>
                  <div className="space-y-2">
                    <Label htmlFor={`max-${index}`}>Max Score</Label>
                    <Input
                      id={`max-${index}`}
                      type="number"
                      min="0"
                      max="100"
                      value={scale.maxScore}
                      onChange={(e) => handleGradeChange(index, "maxScore", parseInt(e.target.value) || 0)}
                      placeholder="100"
                    />
                  </div>
                </div>
                <Button
                  variant="outline"
                  size="icon"
                  onClick={() => handleRemoveGrade(index)}
                  className="flex-shrink-0"
                >
                  <Trash2 className="w-4 h-4" />
                </Button>
              </div>
            ))}
          </div>

          <div className="flex gap-2">
            <Button variant="outline" onClick={handleAddGrade} className="flex-1">
              <Plus className="w-4 h-4 mr-2" />
              Add Grade
            </Button>
            <Button variant="outline" onClick={handleResetToDefault} className="flex-1">
              <RotateCcw className="w-4 h-4 mr-2" />
              Reset to Default
            </Button>
          </div>

          <div className="pt-4 border-t border-border">
            <Button onClick={handleSave} disabled={saving} className="w-full">
              <Save className="w-4 h-4 mr-2" />
              {saving ? "Saving..." : "Save Grading Scale"}
            </Button>
          </div>
        </CardContent>
      </Card>

      {/* Preview */}
      <Card>
        <CardHeader>
          <CardTitle>Grading Scale Preview</CardTitle>
          <CardDescription>
            How grades will be assigned based on total scores
          </CardDescription>
        </CardHeader>
        <CardContent>
          <div className="grid grid-cols-2 md:grid-cols-3 lg:grid-cols-4 gap-3">
            {gradingScale
              .sort((a, b) => b.minScore - a.minScore)
              .map((scale, index) => (
                <div
                  key={index}
                  className="p-3 border border-border rounded-lg text-center bg-muted/50"
                >
                  <div className="text-2xl font-bold text-primary">{scale.grade}</div>
                  <div className="text-sm text-muted-foreground mt-1">
                    {scale.minScore} - {scale.maxScore}
                  </div>
                </div>
              ))}
          </div>
        </CardContent>
      </Card>
    </div>
  );
}
