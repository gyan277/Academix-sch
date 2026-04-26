import "./global.css";

import { Toaster } from "@/components/ui/toaster";
import { createRoot } from "react-dom/client";
import { Toaster as Sonner } from "@/components/ui/sonner";
import { TooltipProvider } from "@/components/ui/tooltip";
import { QueryClient, QueryClientProvider } from "@tanstack/react-query";
import { BrowserRouter, Routes, Route, Navigate } from "react-router-dom";
import ProtectedRoute from "@/components/ProtectedRoute";
import Login from "./pages/Login";
import Dashboard from "./pages/Dashboard";
import Registrar from "./pages/Registrar";
import Academic from "./pages/Academic";
import Attendance from "./pages/Attendance";
import Finance from "./pages/FinanceNew";
import Reports from "./pages/Reports";
import Settings from "./pages/Settings";
import NotFound from "./pages/NotFound";

const queryClient = new QueryClient();

const App = () => (
  <QueryClientProvider client={queryClient}>
    <TooltipProvider>
      <Toaster />
      <Sonner />
      <BrowserRouter>
        <Routes>
          <Route path="/login" element={<Login />} />
          <Route path="/" element={<Navigate to="/dashboard" replace />} />

          {/* Protected Routes */}
          <Route 
            path="/dashboard" 
            element={<ProtectedRoute element={<Dashboard />} allowedRoles={["admin"]} />} 
          />
          <Route 
            path="/registrar" 
            element={<ProtectedRoute element={<Registrar />} allowedRoles={["admin", "registrar"]} />} 
          />
          <Route 
            path="/academic" 
            element={<ProtectedRoute element={<Academic />} allowedRoles={["admin", "teacher"]} />} 
          />
          <Route 
            path="/attendance" 
            element={<ProtectedRoute element={<Attendance />} allowedRoles={["admin", "teacher"]} />} 
          />
          <Route 
            path="/finance" 
            element={<ProtectedRoute element={<Finance />} allowedRoles={["admin"]} />} 
          />
          <Route 
            path="/reports" 
            element={<ProtectedRoute element={<Reports />} allowedRoles={["admin"]} />} 
          />
          <Route 
            path="/settings" 
            element={<ProtectedRoute element={<Settings />} allowedRoles={["admin"]} />} 
          />

          {/* 404 */}
          <Route path="*" element={<NotFound />} />
        </Routes>
      </BrowserRouter>
    </TooltipProvider>
  </QueryClientProvider>
);

createRoot(document.getElementById("root")!).render(<App />);
