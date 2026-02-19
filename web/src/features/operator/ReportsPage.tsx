import React, { useState } from 'react';
import { useTranslation } from 'react-i18next';
import { useAuth } from '../../hooks/useAuth';
import { useEmployees } from '../../hooks/useEmployees';
import { useDailySummaries } from '../../hooks/useReports';
import { StatCard } from '../../components/shared/StatCard';
import { DateRangePicker } from '../../components/shared/DateRangePicker';
import { ExportButton } from '../../components/shared/ExportButton';
import { formatMinutes } from '../../lib/utils';
import { format, subDays } from 'date-fns';
import { Clock, Timer, AlertTriangle, Calendar } from 'lucide-react';
import {
  BarChart,
  Bar,
  XAxis,
  YAxis,
  CartesianGrid,
  Tooltip,
  ResponsiveContainer,
  LineChart,
  Line,
} from 'recharts';

const darkTooltipStyle = {
  contentStyle: { backgroundColor: '#18181b', border: '1px solid #3f3f46', borderRadius: '8px' },
  itemStyle: { color: '#e4e4e7' },
  labelStyle: { color: '#a1a1aa' },
};

export function ReportsPage() {
  const { t } = useTranslation();
  const { profile } = useAuth();
  const companyId = profile?.company_id || undefined;

  const [startDate, setStartDate] = useState(format(subDays(new Date(), 30), 'yyyy-MM-dd'));
  const [endDate, setEndDate] = useState(format(new Date(), 'yyyy-MM-dd'));
  const [employeeFilter, setEmployeeFilter] = useState('');

  const { data: employees = [] } = useEmployees(companyId);
  const { data: summaries = [], isLoading } = useDailySummaries({
    companyId,
    employeeId: employeeFilter || undefined,
    startDate,
    endDate,
  });

  const totalWorkDays = new Set(summaries.map((s) => s.summary_date)).size;
  const totalWorkMinutes = summaries.reduce((sum, s) => sum + s.total_work_minutes, 0);
  const totalOvertimeMinutes = summaries.reduce((sum, s) => sum + s.total_overtime_minutes, 0);
  const totalLateCount = summaries.filter((s) => s.is_late).length;

  const dateGroups = summaries.reduce<Record<string, { work: number; overtime: number; late: number }>>((acc, s) => {
    if (!acc[s.summary_date]) {
      acc[s.summary_date] = { work: 0, overtime: 0, late: 0 };
    }
    acc[s.summary_date].work += s.total_work_minutes;
    acc[s.summary_date].overtime += s.total_overtime_minutes;
    if (s.is_late) acc[s.summary_date].late += 1;
    return acc;
  }, {});

  const chartData = Object.entries(dateGroups)
    .sort((a, b) => a[0].localeCompare(b[0]))
    .map(([date, data]) => ({
      date: new Date(date).toLocaleDateString(undefined, { month: 'short', day: 'numeric' }),
      workHours: Math.round((data.work / 60) * 10) / 10,
      overtimeHours: Math.round((data.overtime / 60) * 10) / 10,
      lateCount: data.late,
    }));

  const exportData = summaries.map((s) => ({
    employee: s.employee ? `${(s.employee as any).first_name} ${(s.employee as any).last_name}` : s.employee_id,
    date: s.summary_date,
    totalHours: Math.round((s.total_work_minutes / 60) * 10) / 10,
    regularHours: Math.round((s.total_regular_minutes / 60) * 10) / 10,
    overtimeHours: Math.round((s.total_overtime_minutes / 60) * 10) / 10,
    isLate: s.is_late ? t('common.yes') : t('common.no'),
    lateMinutes: s.late_minutes,
    status: s.status,
  }));

  const exportColumns = [
    { header: t('sessions.employee'), key: 'employee' },
    { header: t('common.date'), key: 'date' },
    { header: t('reports.totalWorkHours'), key: 'totalHours' },
    { header: t('sessions.regularHours'), key: 'regularHours' },
    { header: t('sessions.overtimeHours'), key: 'overtimeHours' },
    { header: t('reports.totalLate'), key: 'isLate' },
    { header: `${t('reports.totalLate')} (min)`, key: 'lateMinutes' },
    { header: t('common.status'), key: 'status' },
  ];

  return (
    <div>
      <h1 className="text-2xl font-bold font-display text-white mb-6">{t('reports.title')}</h1>

      <div className="flex flex-wrap items-end gap-4 mb-6">
        <DateRangePicker
          startDate={startDate}
          endDate={endDate}
          onStartDateChange={setStartDate}
          onEndDateChange={setEndDate}
        />
        <div>
          <label className="block text-xs font-medium text-zinc-400 mb-1">
            {t('reports.selectEmployee')}
          </label>
          <select
            value={employeeFilter}
            onChange={(e) => setEmployeeFilter(e.target.value)}
            className="px-3 py-2 bg-zinc-800 border border-zinc-700 rounded-lg text-white focus:outline-none focus:border-amber-500 focus:ring-1 focus:ring-amber-500/20 text-sm"
          >
            <option value="">{t('reports.allEmployees')}</option>
            {employees.map((emp) => (
              <option key={emp.id} value={emp.id}>
                {emp.first_name} {emp.last_name}
              </option>
            ))}
          </select>
        </div>
        <ExportButton
          data={exportData}
          columns={exportColumns}
          filename={`attendance-report-${startDate}-${endDate}`}
        />
      </div>

      {isLoading ? (
        <div className="flex items-center justify-center py-12">
          <div className="animate-spin rounded-full h-8 w-8 border-b-2 border-amber-500"></div>
        </div>
      ) : (
        <>
          <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-4 mb-8">
            <StatCard title={t('reports.totalWorkDays')} value={totalWorkDays} icon={Calendar} color="blue" />
            <StatCard title={t('reports.totalWorkHours')} value={formatMinutes(totalWorkMinutes)} icon={Clock} color="green" />
            <StatCard title={t('reports.totalOvertime')} value={formatMinutes(totalOvertimeMinutes)} icon={Timer} color="yellow" />
            <StatCard title={t('reports.totalLate')} value={totalLateCount} icon={AlertTriangle} color="red" />
          </div>

          <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
            <div className="bg-zinc-900/80 backdrop-blur-sm rounded-xl border border-zinc-800 p-6">
              <h2 className="text-lg font-semibold text-white mb-4">{t('reports.dailyHours')}</h2>
              {chartData.length > 0 ? (
                <ResponsiveContainer width="100%" height={300}>
                  <BarChart data={chartData}>
                    <CartesianGrid strokeDasharray="3 3" stroke="#3f3f46" />
                    <XAxis dataKey="date" tick={{ fill: '#a1a1aa', fontSize: 11 }} />
                    <YAxis tick={{ fill: '#a1a1aa' }} />
                    <Tooltip {...darkTooltipStyle} />
                    <Bar dataKey="workHours" fill="#0ea5e9" name={t('sessions.regularHours')} />
                    <Bar dataKey="overtimeHours" fill="#f59e0b" name={t('sessions.overtimeHours')} />
                  </BarChart>
                </ResponsiveContainer>
              ) : (
                <div className="flex items-center justify-center h-[300px] text-zinc-500">{t('common.noData')}</div>
              )}
            </div>

            <div className="bg-zinc-900/80 backdrop-blur-sm rounded-xl border border-zinc-800 p-6">
              <h2 className="text-lg font-semibold text-white mb-4">{t('reports.overtimeTrend')}</h2>
              {chartData.length > 0 ? (
                <ResponsiveContainer width="100%" height={300}>
                  <LineChart data={chartData}>
                    <CartesianGrid strokeDasharray="3 3" stroke="#3f3f46" />
                    <XAxis dataKey="date" tick={{ fill: '#a1a1aa', fontSize: 11 }} />
                    <YAxis tick={{ fill: '#a1a1aa' }} />
                    <Tooltip {...darkTooltipStyle} />
                    <Line type="monotone" dataKey="overtimeHours" stroke="#f59e0b" strokeWidth={2} name={t('sessions.overtimeHours')} />
                    <Line type="monotone" dataKey="lateCount" stroke="#ef4444" strokeWidth={2} name={t('reports.totalLate')} />
                  </LineChart>
                </ResponsiveContainer>
              ) : (
                <div className="flex items-center justify-center h-[300px] text-zinc-500">{t('common.noData')}</div>
              )}
            </div>
          </div>
        </>
      )}
    </div>
  );
}
