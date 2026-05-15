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
  HeadphonesIcon,
  Mail,
  Phone,
  MessageCircle,
} from "lucide-react";
import {
  Dialog,
  DialogContent,
  DialogDescription,
  DialogHeader,
  DialogTitle,
  DialogTrigger,
} from "@/components/ui/dialog";
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
          {/* Support Button */}
          <Dialog>
            <DialogTrigger asChild>
              <Button
                variant="ghost"
                className="w-full justify-start text-sidebar-foreground hover:bg-sidebar-accent"
              >
                <HeadphonesIcon className="w-5 h-5 mr-3" />
                Support
              </Button>
            </DialogTrigger>
            <DialogContent className="sm:max-w-md max-w-[95vw] max-h-[90vh] overflow-y-auto">
              <DialogHeader>
                <DialogTitle className="text-lg sm:text-xl">Contact Support</DialogTitle>
                <DialogDescription className="text-sm">
                  Need help? Get in touch with Glinax Tech Innovations
                </DialogDescription>
              </DialogHeader>
              <div className="space-y-3 py-4">
                {/* Email */}
                <a 
                  href="mailto:glinaxtechinnovations@gmail.com"
                  className="flex items-center space-x-3 p-4 rounded-lg bg-muted/50 hover:bg-muted transition-colors active:scale-[0.98]"
                >
                  <div className="flex-shrink-0 w-10 h-10 rounded-full bg-primary/10 flex items-center justify-center">
                    <Mail className="w-5 h-5 text-primary" />
                  </div>
                  <div className="flex-1 min-w-0">
                    <p className="text-sm font-medium mb-0.5">Email</p>
                    <p className="text-sm text-muted-foreground truncate">
                      glinaxtechinnovations@gmail.com
                    </p>
                  </div>
                </a>
                
                {/* Phone */}
                <a 
                  href="tel:+233531662582"
                  className="flex items-center space-x-3 p-4 rounded-lg bg-muted/50 hover:bg-muted transition-colors active:scale-[0.98]"
                >
                  <div className="flex-shrink-0 w-10 h-10 rounded-full bg-primary/10 flex items-center justify-center">
                    <Phone className="w-5 h-5 text-primary" />
                  </div>
                  <div className="flex-1 min-w-0">
                    <p className="text-sm font-medium mb-0.5">Phone</p>
                    <p className="text-sm text-muted-foreground">
                      +233 53 166 2582
                    </p>
                  </div>
                </a>
                
                {/* WhatsApp */}
                <a 
                  href="https://wa.me/233256027627"
                  target="_blank"
                  rel="noopener noreferrer"
                  className="flex items-center space-x-3 p-4 rounded-lg bg-green-500/10 hover:bg-green-500/20 transition-colors active:scale-[0.98] border border-green-500/20"
                >
                  <div className="flex-shrink-0 w-10 h-10 rounded-full bg-green-500/20 flex items-center justify-center">
                    <MessageCircle className="w-5 h-5 text-green-600 dark:text-green-400" />
                  </div>
                  <div className="flex-1 min-w-0">
                    <p className="text-sm font-medium mb-0.5 text-green-700 dark:text-green-300">WhatsApp</p>
                    <p className="text-sm text-green-600/80 dark:text-green-400/80">
                      +233 25 602 7627
                    </p>
                  </div>
                </a>
                
                {/* Company Info */}
                <div className="pt-4 border-t">
                  <p className="text-xs text-center text-muted-foreground leading-relaxed">
                    Powered by <span className="font-semibold text-foreground">Glinax Tech Innovations</span>
                  </p>
                </div>
              </div>
            </DialogContent>
          </Dialog>

          {/* Logout Button */}
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
