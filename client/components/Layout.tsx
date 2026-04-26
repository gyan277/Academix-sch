import { useState, useEffect } from "react";
import Sidebar from "./Sidebar";
import { Button } from "@/components/ui/button";
import { Menu, Bell, User, Calendar, DollarSign, UserPlus, Receipt, BookOpen } from "lucide-react";
import { cn } from "@/lib/utils";
import { useAuth } from "@/hooks/use-auth";
import { useNavigate } from "react-router-dom";
import { useAcademicYear } from "@/hooks/use-academic-year";
import { supabase } from "@/lib/supabase";
import { useToast } from "@/hooks/use-toast";
import {
  Select,
  SelectContent,
  SelectItem,
  SelectTrigger,
  SelectValue,
} from "@/components/ui/select";
import {
  Popover,
  PopoverContent,
  PopoverTrigger,
} from "@/components/ui/popover";
import { ScrollArea } from "@/components/ui/scroll-area";

interface LayoutProps {
  children: React.ReactNode;
  title?: string;
  subtitle?: string;
}

interface Activity {
  id: string;
  activity_type: string;
  title: string;
  description: string;
  created_at: string;
  metadata?: any;
}

export default function Layout({ children, title, subtitle }: LayoutProps) {
  const [sidebarOpen, setSidebarOpen] = useState(false);
  const [activities, setActivities] = useState<Activity[]>([]);
  const [unreadCount, setUnreadCount] = useState(0);
  const [notificationOpen, setNotificationOpen] = useState(false);
  const { userName, userRole, loading, profile } = useAuth();
  const { academicYear, term } = useAcademicYear();
  const { toast } = useToast();
  const navigate = useNavigate();

  // Load recent activities
  useEffect(() => {
    if (profile?.school_id) {
      loadActivities();
      
      // Set up real-time subscription
      const channel = supabase
        .channel('activity_changes')
        .on(
          'postgres_changes',
          {
            event: 'INSERT',
            schema: 'public',
            table: 'activity_log',
            filter: `school_id=eq.${profile.school_id}`
          },
          () => {
            loadActivities();
          }
        )
        .subscribe();

      return () => {
        supabase.removeChannel(channel);
      };
    }
  }, [profile?.school_id]);

  const loadActivities = async () => {
    if (!profile?.school_id) return;

    try {
      const { data, error } = await supabase
        .from('activity_log')
        .select('*')
        .eq('school_id', profile.school_id)
        .order('created_at', { ascending: false })
        .limit(20);

      if (error) throw error;

      setActivities(data || []);
      setUnreadCount(data?.length || 0);
    } catch (error) {
      console.error('Error loading activities:', error);
    }
  };

  const getActivityIcon = (type: string) => {
    switch (type) {
      case 'payment':
        return <DollarSign className="w-4 h-4 text-green-600" />;
      case 'student_registered':
        return <UserPlus className="w-4 h-4 text-blue-600" />;
      case 'expense_added':
        return <Receipt className="w-4 h-4 text-orange-600" />;
      case 'score_entered':
        return <BookOpen className="w-4 h-4 text-purple-600" />;
      default:
        return <Bell className="w-4 h-4 text-gray-600" />;
    }
  };

  const formatTimeAgo = (dateString: string) => {
    const date = new Date(dateString);
    const now = new Date();
    const seconds = Math.floor((now.getTime() - date.getTime()) / 1000);

    if (seconds < 60) return 'Just now';
    if (seconds < 3600) return `${Math.floor(seconds / 60)}m ago`;
    if (seconds < 86400) return `${Math.floor(seconds / 3600)}h ago`;
    if (seconds < 604800) return `${Math.floor(seconds / 86400)}d ago`;
    return date.toLocaleDateString();
  };

  const getRoleBadge = () => {
    switch (userRole) {
      case "admin":
        return "Administrator";
      case "teacher":
        return "Teacher";
      case "registrar":
        return "Registrar";
      default:
        return "User";
    }
  };

  const handleProfileClick = () => {
    // Only admin can access settings
    if (userRole === "admin") {
      navigate("/settings");
    }
  };

  const handleAcademicYearChange = async (newYear: string) => {
    if (!profile?.school_id) return;

    try {
      const { error } = await supabase
        .from("school_settings")
        .update({ current_academic_year: newYear })
        .eq("id", profile.school_id);

      if (error) throw error;

      toast({
        title: "Academic Year Updated",
        description: `Changed to ${newYear}`,
      });

      // Reload page to refresh all data
      window.location.reload();
    } catch (error: any) {
      console.error("Error updating academic year:", error);
      toast({
        title: "Error",
        description: "Failed to update academic year",
        variant: "destructive",
      });
    }
  };

  const handleTermChange = async (newTerm: string) => {
    if (!profile?.school_id) return;

    try {
      const { error } = await supabase
        .from("school_settings")
        .update({ current_term: newTerm })
        .eq("id", profile.school_id);

      if (error) throw error;

      toast({
        title: "Term Updated",
        description: `Changed to ${newTerm}`,
      });

      // Reload page to refresh all data
      window.location.reload();
    } catch (error: any) {
      console.error("Error updating term:", error);
      toast({
        title: "Error",
        description: "Failed to update term",
        variant: "destructive",
      });
    }
  };

  // Generate academic year options (2024/2025 to 2033/2034)
  // To add more years: Change the start year (2024) or increase the range (10 years)
  const startYear = 2024; // ← Change this to start from a different year
  const yearRange = 10;   // ← Change this to show more/fewer years (currently shows 10 years)
  
  const academicYearOptions = [];
  for (let i = 0; i < yearRange; i++) {
    const year = startYear + i;
    const nextYear = year + 1;
    academicYearOptions.push(`${year}/${nextYear}`);
  }

  return (
    <div className="min-h-screen bg-background">
      <Sidebar open={sidebarOpen} onClose={() => setSidebarOpen(false)} />

      {/* Main Content */}
      <div className="sm:ml-64 flex flex-col min-h-screen">
        {/* Header */}
        <header className="bg-white border-b border-border sticky top-0 z-20 shadow-sm paper-texture">
          <div className="px-4 sm:px-6 py-4 flex items-center justify-between">
            <div className="flex items-center space-x-4">
              <Button
                variant="ghost"
                size="icon"
                className="sm:hidden"
                onClick={() => setSidebarOpen(true)}
              >
                <Menu className="w-5 h-5" />
              </Button>
              {title && (
                <div>
                  <h1 className="text-2xl font-bold text-foreground">{title}</h1>
                  {subtitle && (
                    <p className="text-sm text-muted-foreground">{subtitle}</p>
                  )}
                </div>
              )}
            </div>

            {/* Header Actions */}
            <div className="flex items-center space-x-4">
              {/* Academic Year/Term Selector - Only for Admin */}
              {userRole === "admin" && !loading && (
                <div className="hidden md:flex items-center space-x-2 px-4 py-2 bg-muted/50 rounded-lg border border-border">
                  <Calendar className="w-4 h-4 text-muted-foreground" />
                  <Select value={academicYear} onValueChange={handleAcademicYearChange}>
                    <SelectTrigger className="w-[130px] h-8 border-0 bg-transparent">
                      <SelectValue />
                    </SelectTrigger>
                    <SelectContent>
                      {academicYearOptions.map((year) => (
                        <SelectItem key={year} value={year}>
                          {year}
                        </SelectItem>
                      ))}
                    </SelectContent>
                  </Select>
                  <span className="text-muted-foreground">•</span>
                  <Select value={term} onValueChange={handleTermChange}>
                    <SelectTrigger className="w-[100px] h-8 border-0 bg-transparent">
                      <SelectValue />
                    </SelectTrigger>
                    <SelectContent>
                      <SelectItem value="Term 1">Term 1</SelectItem>
                      <SelectItem value="Term 2">Term 2</SelectItem>
                      <SelectItem value="Term 3">Term 3</SelectItem>
                    </SelectContent>
                  </Select>
                </div>
              )}

              <Popover open={notificationOpen} onOpenChange={setNotificationOpen}>
                <PopoverTrigger asChild>
                  <Button variant="ghost" size="icon" className="relative">
                    <Bell className="w-5 h-5 text-muted-foreground" />
                    {unreadCount > 0 && (
                      <span className="absolute top-1 right-1 w-5 h-5 bg-destructive text-white text-xs rounded-full flex items-center justify-center">
                        {unreadCount > 9 ? '9+' : unreadCount}
                      </span>
                    )}
                  </Button>
                </PopoverTrigger>
                <PopoverContent className="w-96 p-0" align="end">
                  <div className="flex items-center justify-between p-4 border-b">
                    <h3 className="font-semibold">Recent Activities</h3>
                    {activities.length > 0 && (
                      <Button
                        variant="ghost"
                        size="sm"
                        className="text-xs"
                        onClick={() => {
                          setUnreadCount(0);
                          setNotificationOpen(false);
                        }}
                      >
                        Mark all as read
                      </Button>
                    )}
                  </div>
                  <ScrollArea className="h-[400px]">
                    {activities.length === 0 ? (
                      <div className="p-8 text-center text-muted-foreground">
                        <Bell className="w-12 h-12 mx-auto mb-2 opacity-20" />
                        <p className="text-sm">No recent activities</p>
                      </div>
                    ) : (
                      <div className="divide-y">
                        {activities.map((activity) => (
                          <div
                            key={activity.id}
                            className="p-4 hover:bg-muted/50 transition-colors cursor-pointer"
                          >
                            <div className="flex items-start gap-3">
                              <div className="mt-1">
                                {getActivityIcon(activity.activity_type)}
                              </div>
                              <div className="flex-1 min-w-0">
                                <p className="text-sm font-medium text-foreground">
                                  {activity.title}
                                </p>
                                <p className="text-xs text-muted-foreground mt-1 line-clamp-2">
                                  {activity.description}
                                </p>
                                <p className="text-xs text-muted-foreground mt-2">
                                  {formatTimeAgo(activity.created_at)}
                                </p>
                              </div>
                            </div>
                          </div>
                        ))}
                      </div>
                    )}
                  </ScrollArea>
                </PopoverContent>
              </Popover>
              <div className="flex items-center space-x-3 pl-4 border-l border-border">
                {loading ? (
                  // Loading skeleton for user info
                  <>
                    <div className="hidden sm:block text-right space-y-1">
                      <div className="h-4 w-24 bg-muted rounded animate-pulse"></div>
                      <div className="h-3 w-20 bg-muted rounded animate-pulse"></div>
                    </div>
                    <div className="w-10 h-10 rounded-full bg-muted animate-pulse"></div>
                  </>
                ) : (
                  <>
                    <div className="hidden sm:block text-right">
                      <p className="text-sm font-medium text-foreground">{userName}</p>
                      <p className="text-xs text-muted-foreground">{getRoleBadge()}</p>
                    </div>
                    <Button
                      variant="ghost"
                      size="icon"
                      onClick={handleProfileClick}
                      className={cn(
                        "w-10 h-10 rounded-full bg-primary/10",
                        userRole === "admin" && "cursor-pointer hover:bg-primary/20"
                      )}
                      title={userRole === "admin" ? "Go to Settings" : "Profile"}
                    >
                      <User className="w-5 h-5 text-primary" />
                    </Button>
                  </>
                )}
              </div>
            </div>
          </div>
        </header>

        {/* Page Content */}
        <main className="flex-1 overflow-auto">
          <div className="px-4 sm:px-6 py-6 max-w-7xl mx-auto w-full">
            {children}
          </div>
        </main>

        {/* Footer */}
        <footer className="border-t border-border bg-white py-6 px-4 sm:px-6">
          <div className="max-w-7xl mx-auto text-center text-sm text-muted-foreground">
            <p>© 2026 Glinax Tech Innovations. All rights reserved.</p>
          </div>
        </footer>
      </div>
    </div>
  );
}
