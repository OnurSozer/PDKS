import React from 'react';
import { useTranslation } from 'react-i18next';
import { useAuth } from '../../hooks/useAuth';
import { useEmployees } from '../../hooks/useEmployees';
import { useActiveSessions } from '../../hooks/useSessions';
import { useTodaySummaries } from '../../hooks/useReports';
import { StatCard } from '../../components/shared/StatCard';
import { formatMinutes } from '../../lib/utils';
import { Users, Clock, AlertTriangle, Palmtree, Timer, UserCheck } from 'lucide-react';
import {
  BarChart,
  Bar,
  XAxis,
  YAxis,
  CartesianGrid,
  Tooltip,
  ResponsiveContainer,
  PieChart,
  Pie,
  Cell,
} from 'recharts';

const PIE_COLORS = ['#22c55e', '#ef4444', '#f59e0b', '#3b82f6'];

export function OperatorDashboardPage() {
  const { t } = useTranslation();
  const { profile } = useAuth();
  const companyId = profile?.company_id || undefined;

  const { data: employees = [] } = useEmployees(companyId);
  const { data: activeSessions = [] } = useActiveSessions(companyId);
  const { data: todaySummaries = [] } = useTodaySummaries(companyId);

  const presentCount = activeSessions.length;
  const lateCount = todaySummaries.filter((s) => s.is_late).length;
  const onLeaveCount = todaySummaries.filter((s) => s.is_leave).length;
  const absentCount = Math.max(0, employees.length - presentCount - onLeaveCount);
  const totalWorkMinutes = todaySummaries.reduce((sum, s) => sum + s.total_work_minutes, 0);

  const pieData = [
    { name: t('operator.employeesPresent'), value: presentCount },
    { name: t('operator.employeesAbsent'), value: absentCount },
    { name: t('operator.employeesLate'), value: lateCount },
    { name: t('operator.employeesOnLeave'), value: onLeaveCount },
  ].filter((d) => d.value > 0);

  const barData = todaySummaries
    .filter((s) => s.total_work_minutes > 0)
    .slice(0, 10)
    .map((s) => ({
      name: s.employee
        ? `${(s.employee as any).first_name} ${(s.employee as any).last_name?.charAt(0)}.`
        : s.employee_id.slice(0, 8),
      hours: Math.round((s.total_work_minutes / 60) * 10) / 10,
      overtime: Math.round((s.total_overtime_minutes / 60) * 10) / 10,
    }));

  return (
    <div>
      <h1 className="text-2xl font-bold text-gray-900 mb-6">
        {t('operator.todayOverview')}
      </h1>

      <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 xl:grid-cols-5 gap-4 mb-8">
        <StatCard
          title={t('operator.employeesPresent')}
          value={presentCount}
          icon={UserCheck}
          color="green"
        />
        <StatCard
          title={t('operator.employeesLate')}
          value={lateCount}
          icon={AlertTriangle}
          color="yellow"
        />
        <StatCard
          title={t('operator.employeesAbsent')}
          value={absentCount}
          icon={Users}
          color="red"
        />
        <StatCard
          title={t('operator.employeesOnLeave')}
          value={onLeaveCount}
          icon={Palmtree}
          color="purple"
        />
        <StatCard
          title={t('operator.totalWorkHours')}
          value={formatMinutes(totalWorkMinutes)}
          icon={Timer}
          color="blue"
        />
      </div>

      <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
        {/* Attendance breakdown pie chart */}
        <div className="bg-white rounded-lg border border-gray-200 p-6">
          <h2 className="text-lg font-semibold mb-4">{t('operator.todayOverview')}</h2>
          {pieData.length > 0 ? (
            <ResponsiveContainer width="100%" height={300}>
              <PieChart>
                <Pie
                  data={pieData}
                  cx="50%"
                  cy="50%"
                  innerRadius={60}
                  outerRadius={100}
                  paddingAngle={5}
                  dataKey="value"
                  label={({ name, value }) => `${name}: ${value}`}
                >
                  {pieData.map((_, index) => (
                    <Cell key={`cell-${index}`} fill={PIE_COLORS[index % PIE_COLORS.length]} />
                  ))}
                </Pie>
                <Tooltip />
              </PieChart>
            </ResponsiveContainer>
          ) : (
            <div className="flex items-center justify-center h-[300px] text-gray-400">
              {t('common.noData')}
            </div>
          )}
        </div>

        {/* Work hours bar chart */}
        <div className="bg-white rounded-lg border border-gray-200 p-6">
          <h2 className="text-lg font-semibold mb-4">{t('reports.dailyHours')}</h2>
          {barData.length > 0 ? (
            <ResponsiveContainer width="100%" height={300}>
              <BarChart data={barData}>
                <CartesianGrid strokeDasharray="3 3" />
                <XAxis dataKey="name" tick={{ fontSize: 12 }} />
                <YAxis />
                <Tooltip />
                <Bar dataKey="hours" fill="#3b82f6" name={t('sessions.regularHours')} />
                <Bar dataKey="overtime" fill="#f59e0b" name={t('sessions.overtimeHours')} />
              </BarChart>
            </ResponsiveContainer>
          ) : (
            <div className="flex items-center justify-center h-[300px] text-gray-400">
              {t('common.noData')}
            </div>
          )}
        </div>
      </div>

      {/* Currently clocked in */}
      {activeSessions.length > 0 && (
        <div className="mt-6 bg-white rounded-lg border border-gray-200 p-6">
          <h2 className="text-lg font-semibold mb-4 flex items-center gap-2">
            <Clock className="w-5 h-5 text-green-600" />
            {t('operator.openSessions')} ({activeSessions.length})
          </h2>
          <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 gap-3">
            {activeSessions.map((session) => (
              <div
                key={session.id}
                className="flex items-center gap-3 p-3 bg-green-50 rounded-lg border border-green-100"
              >
                <div className="w-2 h-2 rounded-full bg-green-500 animate-pulse" />
                <div>
                  <p className="text-sm font-medium text-gray-900">
                    {(session.employee as any)?.first_name}{' '}
                    {(session.employee as any)?.last_name}
                  </p>
                  <p className="text-xs text-gray-500">
                    {t('sessions.clockIn')}: {new Date(session.clock_in).toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' })}
                  </p>
                </div>
              </div>
            ))}
          </div>
        </div>
      )}
    </div>
  );
}
