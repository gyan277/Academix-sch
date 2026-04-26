import { Navigate } from "react-router-dom";
import { useAuth } from "@/hooks/use-auth";

interface ProtectedRouteProps {
  element: React.ReactElement;
  allowedRoles?: string[];
}

export default function ProtectedRoute({ element, allowedRoles }: ProtectedRouteProps) {
  const { isAuthenticated, userRole, loading } = useAuth();

  // Show loading state while checking authentication
  if (loading) {
    return (
      <div className="min-h-screen flex items-center justify-center">
        <div className="text-center">
          <div className="animate-spin rounded-full h-12 w-12 border-b-2 border-primary mx-auto"></div>
          <p className="mt-4 text-muted-foreground">Loading...</p>
        </div>
      </div>
    );
  }

  if (!isAuthenticated) {
    return <Navigate to="/login" replace />;
  }

  // If allowedRoles is specified, check if user has permission
  if (allowedRoles && !allowedRoles.includes(userRole)) {
    // Redirect to appropriate page based on role
    if (userRole === "teacher") {
      return <Navigate to="/attendance" replace />;
    }
    if (userRole === "registrar") {
      return <Navigate to="/registrar" replace />;
    }
    return <Navigate to="/dashboard" replace />;
  }

  return element;
}
