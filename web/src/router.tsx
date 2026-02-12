import React from 'react';
import { createBrowserRouter, Navigate } from 'react-router-dom';
import { ProtectedRoute } from './features/auth/ProtectedRoute';
import { LoginPage } from './features/auth/LoginPage';
import { ForgotPasswordPage } from './features/auth/ForgotPasswordPage';
import { ResetPasswordPage } from './features/auth/ResetPasswordPage';
import { SuperAdminLayout } from './components/layout/SuperAdminLayout';
import { OperatorLayout } from './components/layout/OperatorLayout';

// Super Admin Pages
import { SuperAdminDashboardPage } from './features/super-admin/DashboardPage';
import { CompaniesPage } from './features/super-admin/CompaniesPage';
import { CompanyDetailPage } from './features/super-admin/CompanyDetailPage';
import { CreateCompanyForm } from './features/super-admin/CreateCompanyForm';

// Operator Pages
import { OperatorDashboardPage } from './features/operator/DashboardPage';
import { EmployeesPage } from './features/operator/EmployeesPage';
import { EmployeeDetailPage } from './features/operator/EmployeeDetailPage';
import { CreateEmployeeForm } from './features/operator/CreateEmployeeForm';
import { SessionsPage } from './features/operator/SessionsPage';
import { SchedulesPage } from './features/operator/SchedulesPage';
import { OvertimeRulesPage } from './features/operator/OvertimeRulesPage';
import { LeavePage } from './features/operator/LeavePage';
import { ReportsPage } from './features/operator/ReportsPage';
import { SettingsPage } from './features/operator/SettingsPage';

// Root redirect component
function RootRedirect() {
  return <Navigate to="/login" replace />;
}

export const router = createBrowserRouter([
  {
    path: '/',
    element: <RootRedirect />,
  },
  {
    path: '/login',
    element: <LoginPage />,
  },
  {
    path: '/forgot-password',
    element: <ForgotPasswordPage />,
  },
  {
    path: '/reset-password',
    element: <ResetPasswordPage />,
  },

  // Super Admin routes
  {
    path: '/admin',
    element: (
      <ProtectedRoute allowedRoles={['super_admin']}>
        <SuperAdminLayout />
      </ProtectedRoute>
    ),
    children: [
      { index: true, element: <Navigate to="/admin/dashboard" replace /> },
      { path: 'dashboard', element: <SuperAdminDashboardPage /> },
      { path: 'companies', element: <CompaniesPage /> },
      { path: 'companies/new', element: <CreateCompanyForm /> },
      { path: 'companies/:id', element: <CompanyDetailPage /> },
    ],
  },

  // Operator routes
  {
    path: '/operator',
    element: (
      <ProtectedRoute allowedRoles={['operator']}>
        <OperatorLayout />
      </ProtectedRoute>
    ),
    children: [
      { index: true, element: <Navigate to="/operator/dashboard" replace /> },
      { path: 'dashboard', element: <OperatorDashboardPage /> },
      { path: 'employees', element: <EmployeesPage /> },
      { path: 'employees/new', element: <CreateEmployeeForm /> },
      { path: 'employees/:id', element: <EmployeeDetailPage /> },
      { path: 'sessions', element: <SessionsPage /> },
      { path: 'schedules', element: <SchedulesPage /> },
      { path: 'overtime', element: <OvertimeRulesPage /> },
      { path: 'leave', element: <LeavePage /> },
      { path: 'reports', element: <ReportsPage /> },
      { path: 'settings', element: <SettingsPage /> },
    ],
  },
]);
