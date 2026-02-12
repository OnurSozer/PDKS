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

const PIE_COLORS = ['#10b981', '#ef4444', '#f59e0b', '#0ea5e9'];

const darkTooltipStyle = {
  contentStyle: { backgroundColor: '#18181b', border: '1px solid #3f3f46', borderRadius: '8px' },
  itemStyle: { color: '#e4e4e7' },
  labelStyle: { color: '#a1a1aa' },
};

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
      <h1 className="text-2xl font-bold font-display text-white mb-6">
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
        <div className="bg-zinc-900/80 backdrop-blur-sm rounded-xl border border-zinc-800 p-6">
          <h2 className="text-lg font-semibold text-white mb-4">{t('operator.todayOverview')}</h2>
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
                <Tooltip {...darkTooltipStyle} />
              </PieChart>
            </ResponsiveContainer>
          ) : (
            <div className="flex items-center justify-center h-[300px] text-zinc-500">
              {t('common.noData')}
            </div>
          )}
        </div>

        {/* Work hours bar chart */}
        <div className="bg-zinc-900/80 backdrop-blur-sm rounded-xl border border-zinc-800 p-6">
          <h2 className="text-lg font-semibold text-white mb-4">{t('reports.dailyHours')}</h2>
          {barData.length > 0 ? (
            <ResponsiveContainer width="100%" height={300}>
              <BarChart data={barData}>
                <CartesianGrid strokeDasharray="3 3" stroke="#3f3f46" />
                <XAxis dataKey="name" tick={{ fill: '#a1a1aa', fontSize: 12 }} />
                <YAxis tick={{ fill: '#a1a1aa' }} />
                <Tooltip {...darkTooltipStyle} />
                <Bar dataKey="hours" fill="#0ea5e9" name={t('sessions.regularHours')} />
                <Bar dataKey="overtime" fill="#f59e0b" name={t('sessions.overtimeHours')} />
              </BarChart>
            </ResponsiveContainer>
          ) : (
            <div className="flex items-center justify-center h-[300px] text-zinc-500">
              {t('common.noData')}
            </div>
          )}
        </div>
      </div>

      {/* Currently clocked in */}
      {activeSessions.length > 0 && (
        <div className="mt-6 bg-zinc-900/80 backdrop-blur-sm rounded-xl border border-zinc-800 p-6">
          <h2 className="text-lg font-semibold text-white mb-4 flex items-center gap-2">
            <Clock className="w-5 h-5 text-emerald-400" />
            {t('operator.openSessions')} ({activeSessions.length})
          </h2>
          <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 gap-3">
            {activeSessions.map((session) => (
              <div
                key={session.id}
                className="flex items-center gap-3 p-3 bg-emerald-500/10 rounded-lg border border-emerald-500/20"
              >
                <div className="w-2 h-2 rounded-full bg-emerald-500 animate-pulse" />
                <div>
                  <p className="text-sm font-medium text-white">
                    {(session.employee as any)?.first_name}{' '}
                    {(session.employee as any)?.last_name}
                  </p>
                  <p className="text-xs text-zinc-400">
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
