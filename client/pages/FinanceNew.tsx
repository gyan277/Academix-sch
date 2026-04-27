import { useState } from "react";
import Layout from "@/components/Layout";
import { Tabs, TabsContent, TabsList, TabsTrigger } from "@/components/ui/tabs";
import { DollarSign, TrendingDown, Settings, Users } from "lucide-react";
import { useAuth } from "@/hooks/use-auth";
import { useAcademicYear } from "@/hooks/use-academic-year";
import ClassFeesConfig from "@/components/finance/ClassFeesConfig";
import ExpensesDashboard from "@/components/finance/ExpensesDashboard";
import IncomeDashboard from "@/components/finance/IncomeDashboard";
import TeacherCollections from "@/components/finance/TeacherCollections";

export default function Finance() {
  const { profile } = useAuth();
  const { academicYear, term } = useAcademicYear();
  const [activeTab, setActiveTab] = useState("income");

  if (!profile?.school_id) {
    return (
      <Layout title="Finance" subtitle="Manage school finances">
        <div className="text-center py-12">
          <p className="text-muted-foreground">Loading...</p>
        </div>
      </Layout>
    );
  }

  return (
    <Layout title="Finance" subtitle="Manage income, expenses, and class fees">
      <div className="space-y-6">
        <Tabs value={activeTab} onValueChange={setActiveTab} className="w-full">
          <TabsList className="grid w-full grid-cols-4 h-auto">
            <TabsTrigger value="income" className="gap-1 sm:gap-2 text-xs sm:text-sm py-2">
              <DollarSign className="w-3 h-3 sm:w-4 sm:h-4" />
              <span className="hidden sm:inline">Income</span>
              <span className="sm:hidden">Income</span>
            </TabsTrigger>
            <TabsTrigger value="expenses" className="gap-1 sm:gap-2 text-xs sm:text-sm py-2">
              <TrendingDown className="w-3 h-3 sm:w-4 sm:h-4" />
              <span className="hidden sm:inline">Expenses</span>
              <span className="sm:hidden">Expenses</span>
            </TabsTrigger>
            <TabsTrigger value="class-fees" className="gap-1 sm:gap-2 text-xs sm:text-sm py-2">
              <Settings className="w-3 h-3 sm:w-4 sm:h-4" />
              <span className="hidden sm:inline">Class Fees</span>
              <span className="sm:hidden">Fees</span>
            </TabsTrigger>
            <TabsTrigger value="teacher-collections" className="gap-1 sm:gap-2 text-xs sm:text-sm py-2">
              <Users className="w-3 h-3 sm:w-4 sm:h-4" />
              <span className="hidden sm:inline">Teacher Collections</span>
              <span className="sm:hidden">Teachers</span>
            </TabsTrigger>
          </TabsList>

          <TabsContent value="income" className="mt-6">
            <IncomeDashboard
              schoolId={profile.school_id}
              academicYear={academicYear}
              term={term}
            />
          </TabsContent>

          <TabsContent value="expenses" className="mt-6">
            <ExpensesDashboard
              schoolId={profile.school_id}
              academicYear={academicYear}
              term={term}
            />
          </TabsContent>

          <TabsContent value="class-fees" className="mt-6">
            <ClassFeesConfig
              schoolId={profile.school_id}
              academicYear={academicYear}
              term={term}
            />
          </TabsContent>

          <TabsContent value="teacher-collections" className="mt-6">
            <TeacherCollections
              schoolId={profile.school_id}
              academicYear={academicYear}
              term={term}
            />
          </TabsContent>
        </Tabs>
      </div>
    </Layout>
  );
}
