import { useState, useEffect } from "react";
import { useNavigate, useLocation } from "react-router-dom";
import { Button } from "@/components/ui/button";
import {
  LayoutDashboard,
  Users,
  BookOpen,
  Calendar,
  DollarSign,
  BarChart3,
  Settings,
  LogOut,
  ChevronDown,
  Menu,
  X,
} from "lucide-react";
import { cn } from "@/lib/utils";
import { useAuth } from "@/hooks/use-auth";
import { supabase } from "@/lib/supabase";

interface NavItem {
  label: string;
  icon: React.ReactNode;
  href?: string;
  children?: NavItem[];
  roles?: string[]; // Roles that can access this route
}

const navItems: NavItem[] = [
  {
    label: "Dashboard",
    icon: <LayoutDashboard className="w-5 h-5" />,
    href: "/dashboard",
    roles: ["admin"],
  },
  {
    label: "Registrar",
    icon: <Users className="w-5 h-5" />,
    href: "/registrar",
    roles: ["admin", "registrar"],
  },
  {
    label: "Academic Engine",
    icon: <BookOpen className="w-5 h-5" />,
    href: "/academic",
    roles: ["teacher"],
  },
  {
    label: "Attendance",
    icon: <Calendar className="w-5 h-5" />,
    href: "/attendance",
    roles: ["teacher"],
  },
  {
    label: "Fee Collection",
    icon: <DollarSign className="w-5 h-5" />,
    href: "/teacher-dashboard",
    roles: ["teacher"],
  },
  {
    label: "Finance",
    icon: <DollarSign className="w-5 h-5" />,
    href: "/finance",
    roles: ["admin"],
  },
  {
    label: "Reports & Analytics",
    icon: <BarChart3 className="w-5 h-5" />,
    href: "/reports",
    roles: ["admin"],
  },
  {
    label: "Settings",
    icon: <Settings className="w-5 h-5" />,
    href: "/settings",
    roles: ["admin"],
  },
];

interface SidebarProps {
  open?: boolean;
  onClose?: () => void;
}

export default function Sidebar({ open = true, onClose }: SidebarProps) {
  const navigate = useNavigate();
  const location = useLocation();
  const { userRole, loading, logout, profile } = useAuth();
  const [expandedItems, setExpandedItems] = useState<string[]>([]);
  const [feeCollectionEnabled, setFeeCollectionEnabled] = useState(false);

  // Check if teacher fee collection is enabled
  useEffect(() => {
    const checkFeatureEnabled = async () => {
      if (userRole === 'teacher' && profile?.school_id) {
        try {
          const { data, error } = await supabase
            .rpc('is_teacher_fee_collection_enabled', { p_school_id: profile.school_id });
          
          if (!error) {
            setFeeCollectionEnabled(data || false);
          }
        } catch (error) {
          console.error('Error checking fee collection feature:', error);
        }
      }
    };

    checkFeatureEnabled();
  }, [userRole, profile?.school_id]);

  // Filter nav items based on user role and feature flags
  const filteredNavItems = navItems.filter((item) => {
    if (!item.roles) return true;
    if (!item.roles.includes(userRole)) return false;
    
    // Hide Fee Collection if feature is not enabled
    if (item.label === "Fee Collection" && !feeCollectionEnabled) {
      return false;
    }
    
    return true;
  });

  const toggleExpanded = (label: string) => {
    setExpandedItems((prev) =>
      prev.includes(label) ? prev.filter((l) => l !== label) : [...prev, label]
    );
  };

  const handleNavigation = (href?: string) => {
    if (href) {
      navigate(href);
      onClose?.();
    }
  };

  const handleLogout = () => {
    logout();
  };

  const isActive = (href?: string) => {
    if (!href) return false;
    if (href === "/dashboard") return location.pathname === "/dashboard";
    return location.pathname.startsWith(href);
  };

  return (
    <>
      {/* Mobile Menu Button - shown only on mobile */}
      <div className="hidden max-sm:flex items-center justify-between p-4 bg-sidebar border-b border-sidebar-border">
        <div className="flex items-center space-x-2">
          <img src="/logo.png" alt="Pendoun Logo" className="w-8 h-8 rounded-lg object-contain" />
          <span className="font-bold text-sidebar-foreground">Pendoun</span>
        </div>
      </div>

      {/* Sidebar */}
      <aside
        className={cn(
          "fixed top-0 left-0 z-40 h-screen w-64 bg-sidebar border-r border-sidebar-border transition-transform duration-300 max-sm:translate-x-0 max-sm:pt-16 overflow-y-auto flex flex-col sidebar-texture",
          !open && "max-sm:-translate-x-full"
        )}
      >
        {/* Logo - Desktop only */}
        <div className="hidden sm:flex items-center space-x-3 px-6 py-6 border-b border-sidebar-border">
          <img src="/logo.png" alt="Pendoun Logo" className="w-10 h-10 rounded-lg object-contain flex-shrink-0" />
          <div className="flex-1 min-w-0">
            <h1 className="font-bold text-sidebar-primary-foreground">Pendoun</h1>
            <p className="text-xs text-sidebar-accent-foreground/60 truncate">
              School Management
            </p>
          </div>
        </div>

        {/* Navigation Items */}
        <nav className="flex-1 px-3 py-6 space-y-2">
          {loading ? (
            // Loading skeleton
            <div className="space-y-2">
              {[1, 2, 3, 4].map((i) => (
                <div key={i} className="px-4 py-3 rounded-lg bg-sidebar-accent/50 animate-pulse">
                  <div className="h-5 bg-sidebar-accent rounded w-3/4"></div>
                </div>
              ))}
            </div>
          ) : (
            filteredNavItems.map((item) => {
            const active = isActive(item.href);
            const expanded = expandedItems.includes(item.label);

            return (
              <div key={item.label}>
                <button
                  onClick={() => {
                    if (item.children) {
                      toggleExpanded(item.label);
                    } else {
                      handleNavigation(item.href);
                    }
                  }}
                  className={cn(
                    "w-full flex items-center justify-between px-4 py-3 rounded-lg transition-colors",
                    active
                      ? "bg-sidebar-primary text-sidebar-primary-foreground"
                      : "text-sidebar-foreground hover:bg-sidebar-accent"
                  )}
                >
                  <div className="flex items-center space-x-3">
                    {item.icon}
                    <span className="font-medium">{item.label}</span>
                  </div>
                  {item.children && (
                    <ChevronDown
                      className={cn(
                        "w-4 h-4 transition-transform",
                        expanded && "rotate-180"
                      )}
                    />
                  )}
                </button>

                {/* Sub-items */}
                {item.children && expanded && (
                  <div className="ml-4 mt-2 space-y-2 border-l border-sidebar-border pl-4">
                    {item.children.map((child) => (
                      <button
                        key={child.label}
                        onClick={() => handleNavigation(child.href)}
                        className={cn(
                          "w-full text-left px-3 py-2 rounded text-sm transition-colors",
                          isActive(child.href)
                            ? "text-sidebar-primary bg-sidebar-primary/10"
                            : "text-sidebar-foreground hover:bg-sidebar-accent"
                        )}
                      >
                        {child.label}
                      </button>
                    ))}
                  </div>
                )}
              </div>
            );
          })
          )}
        </nav>

        {/* User Section */}
        <div className="px-3 py-6 border-t border-sidebar-border space-y-3">
          <Button
            onClick={handleLogout}
            variant="ghost"
            className="w-full justify-start text-sidebar-foreground hover:bg-sidebar-accent"
          >
            <LogOut className="w-5 h-5 mr-3" />
            Logout
          </Button>
        </div>
      </aside>

      {/* Mobile Overlay */}
      {open && (
        <div
          className="fixed inset-0 bg-black/50 z-30 sm:hidden"
          onClick={onClose}
        />
      )}
    </>
  );
}
