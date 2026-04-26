import { useState, useEffect } from "react";
import { useNavigate } from "react-router-dom";
import { supabase } from "@/lib/supabase";
import type { UserRole } from "@shared/api";
import type { User } from "@supabase/supabase-js";

interface UserProfile {
  id: string;
  email: string;
  full_name: string;
  role: UserRole;
  phone: string | null;
  school_id: string | null;
}

export function useAuth() {
  const navigate = useNavigate();
  const [user, setUser] = useState<User | null>(null);
  const [profile, setProfile] = useState<UserProfile | null>(null);
  const [assignedClasses, setAssignedClasses] = useState<string[]>([]);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    // Get initial session
    supabase.auth.getSession().then(({ data: { session } }) => {
      setUser(session?.user ?? null);
      if (session?.user) {
        loadUserProfile(session.user.id);
      } else {
        setLoading(false);
      }
    });

    // Listen for auth changes
    const {
      data: { subscription },
    } = supabase.auth.onAuthStateChange((_event, session) => {
      setUser(session?.user ?? null);
      if (session?.user) {
        loadUserProfile(session.user.id);
      } else {
        setProfile(null);
        setAssignedClasses([]);
        setLoading(false);
      }
    });

    return () => subscription.unsubscribe();
  }, []);

  const loadUserProfile = async (userId: string) => {
    try {
      // Fetch user profile
      const { data: userData, error: userError } = await supabase
        .from("users")
        .select("*")
        .eq("id", userId)
        .single();

      if (userError) throw userError;

      setProfile(userData);

      // Fetch assigned classes for teachers
      if (userData.role === "teacher") {
        const { data: classData } = await supabase
          .from("teacher_classes")
          .select("class")
          .eq("teacher_id", userId);

        if (classData) {
          setAssignedClasses(classData.map((c) => c.class));
        }
      }
    } catch (error) {
      console.error("Error loading user profile:", error);
    } finally {
      setLoading(false);
    }
  };

  const hasRole = (role: UserRole) => profile?.role === role;
  const hasAnyRole = (roles: UserRole[]) => profile ? roles.includes(profile.role) : false;

  const canAccessRoute = (route: string): boolean => {
    if (!profile) return false;

    // Admin can access everything
    if (profile.role === "admin") return true;

    // Teacher can only access attendance and academic
    if (profile.role === "teacher") {
      return route === "/attendance" || route === "/academic";
    }

    // Registrar can only access registrar
    if (profile.role === "registrar") {
      return route === "/registrar";
    }

    return false;
  };

  const logout = async () => {
    await supabase.auth.signOut();
    setUser(null);
    setProfile(null);
    setAssignedClasses([]);
    navigate("/login");
  };

  return {
    user,
    profile,
    isAuthenticated: !!user && !!profile,
    userEmail: profile?.email || "",
    userName: profile?.full_name || "",
    userRole: profile?.role || "teacher" as UserRole,
    userId: profile?.id || "",
    assignedClasses,
    loading,
    hasRole,
    hasAnyRole,
    canAccessRoute,
    logout,
  };
}
