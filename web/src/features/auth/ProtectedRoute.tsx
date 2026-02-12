import React from 'react';
import { Navigate } from 'react-router-dom';
import { useAuth } from '../../hooks/useAuth';

interface ProtectedRouteProps {
  children: React.ReactNode;
  allowedRoles: string[];
}

export function ProtectedRoute({ children, allowedRoles }: ProtectedRouteProps) {
  const { profile, loading, session } = useAuth();

  if (loading) {
    return (
      <div className="min-h-screen flex items-center justify-center">
        <div className="animate-spin rounded-full h-8 w-8 border-b-2 border-primary-600"></div>
      </div>
    );
  }

  if (!session) {
    return <Navigate to="/login" replace />;
  }

  if (!profile) {
    return (
      <div className="min-h-screen flex items-center justify-center">
        <div className="animate-spin rounded-full h-8 w-8 border-b-2 border-primary-600"></div>
      </div>
    );
  }

  if (!allowedRoles.includes(profile.role)) {
    // Redirect to appropriate dashboard based on actual role
    if (profile.role === 'super_admin') {
      return <Navigate to="/admin/dashboard" replace />;
    }
    if (profile.role === 'operator') {
      return <Navigate to="/operator/dashboard" replace />;
    }
    // employee/chef should not be on web
    return <Navigate to="/login" replace />;
  }

  return <>{children}</>;
}
