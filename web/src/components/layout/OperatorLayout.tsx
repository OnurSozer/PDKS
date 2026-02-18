import React, { useState } from 'react';
import { Link, Outlet, useLocation } from 'react-router-dom';
import { useTranslation } from 'react-i18next';
import { useAuth } from '../../hooks/useAuth';
import { LanguageSwitcher } from '../shared/LanguageSwitcher';
import { cn } from '../../lib/utils';
import {
  LayoutDashboard,
  Users,
  Clock,
  Calendar,
  Timer,
  Palmtree,
  BarChart3,
  Settings,
  LogOut,
  Menu,
  X,
  CalendarDays,
  FileSpreadsheet,
  ScrollText,
} from 'lucide-react';

const navItems = [
  { path: '/operator/dashboard', icon: LayoutDashboard, labelKey: 'nav.dashboard' },
  { path: '/operator/employees', icon: Users, labelKey: 'nav.employees' },
  { path: '/operator/sessions', icon: Clock, labelKey: 'nav.sessions' },
  { path: '/operator/schedules', icon: Calendar, labelKey: 'nav.schedules' },
  { path: '/operator/overtime', icon: Timer, labelKey: 'nav.overtime' },
  { path: '/operator/leave', icon: Palmtree, labelKey: 'nav.leave' },
  { path: '/operator/holidays', icon: CalendarDays, labelKey: 'nav.holidays' },
  { path: '/operator/reports', icon: BarChart3, labelKey: 'nav.reports' },
  { path: '/operator/monthly-summary', icon: FileSpreadsheet, labelKey: 'nav.monthlySummary' },
  { path: '/operator/activity-log', icon: ScrollText, labelKey: 'nav.activityLog' },
  { path: '/operator/settings', icon: Settings, labelKey: 'nav.settings' },
];

export function OperatorLayout() {
  const { t } = useTranslation();
  const { signOut, profile } = useAuth();
  const location = useLocation();
  const [sidebarOpen, setSidebarOpen] = useState(false);

  return (
    <div className="min-h-screen bg-zinc-950 font-body lg:flex">
      {/* Mobile sidebar overlay */}
      {sidebarOpen && (
        <div
          className="fixed inset-0 z-40 bg-black/60 backdrop-blur-sm lg:hidden"
          onClick={() => setSidebarOpen(false)}
        />
      )}

      {/* Sidebar */}
      <aside
        className={cn(
          'fixed inset-y-0 left-0 z-50 w-64 bg-zinc-950 border-r border-zinc-800 transform transition-transform duration-200 lg:translate-x-0 lg:static lg:z-auto lg:shrink-0',
          sidebarOpen ? 'translate-x-0' : '-translate-x-full'
        )}
      >
        <div className="flex items-center justify-between h-16 px-6 border-b border-zinc-800">
          <Link to="/operator/dashboard" className="text-xl font-bold font-display text-amber-500">
            {t('app.name')}
          </Link>
          <button
            className="lg:hidden text-zinc-400 hover:text-white"
            onClick={() => setSidebarOpen(false)}
          >
            <X className="w-5 h-5" />
          </button>
        </div>
        <nav className="p-4 space-y-1">
          {navItems.map((item) => (
            <Link
              key={item.path}
              to={item.path}
              onClick={() => setSidebarOpen(false)}
              className={cn(
                'flex items-center gap-3 px-3 py-2 text-sm font-medium rounded-lg transition-colors',
                location.pathname.startsWith(item.path)
                  ? 'bg-amber-500/10 text-amber-400 border-l-2 border-amber-500'
                  : 'text-zinc-400 hover:bg-zinc-800 hover:text-white'
              )}
            >
              <item.icon className="w-5 h-5" />
              {t(item.labelKey)}
            </Link>
          ))}
        </nav>
      </aside>

      {/* Main content */}
      <div className="flex-1 min-w-0">
        {/* Header */}
        <header className="sticky top-0 z-30 flex items-center justify-between h-16 px-6 bg-zinc-900/80 backdrop-blur-sm border-b border-zinc-800">
          <button
            className="lg:hidden text-zinc-400 hover:text-white"
            onClick={() => setSidebarOpen(true)}
          >
            <Menu className="w-5 h-5" />
          </button>
          <div className="hidden lg:block">
            <h1 className="text-sm font-medium text-zinc-400">
              {t('operator.title')}
            </h1>
          </div>
          <div className="flex items-center gap-4">
            <LanguageSwitcher />
            <span className="text-sm text-zinc-400">
              {profile?.first_name} {profile?.last_name}
            </span>
            <button
              onClick={signOut}
              className="inline-flex items-center gap-1.5 px-3 py-1.5 text-sm font-medium text-rose-400 hover:bg-rose-500/10 rounded-lg transition-colors"
            >
              <LogOut className="w-4 h-4" />
              {t('auth.logout')}
            </button>
          </div>
        </header>

        {/* Page content */}
        <main className="p-6">
          <Outlet />
        </main>
      </div>
    </div>
  );
}
