import React, { useState } from 'react';
import { useTranslation } from 'react-i18next';
import { useQuery } from '@tanstack/react-query';
import { useAuth } from '../../hooks/useAuth';
import { useEmployees } from '../../hooks/useEmployees';
import { supabase } from '../../lib/supabase';
import { MonthlyEmployeeSummary, SpecialDayType } from '../../types';
import { useSpecialDayTypes, useToggleSpecialDay } from '../../hooks/useSpecialDayTypes';
import { Calendar, Users, TrendingUp, TrendingDown, Clock, Star, Info, Download } from 'lucide-react';

function formatMinutesToHours(minutes: number): string {
  const h = Math.floor(Math.abs(minutes) / 60);
  const m = Math.abs(minutes) % 60;
  const sign = minutes < 0 ? '-' : '';
  return `${sign}${h}h ${m}m`;
}

export function MonthlySummaryPage() {
  const { t } = useTranslation();
  const { profile } = useAuth();
  const companyId = profile?.company_id || undefined;

  const now = new Date();
  const [selectedMonth, setSelectedMonth] = useState(
    `${now.getFullYear()}-${String(now.getMonth() + 1).padStart(2, '0')}`
  );
  const [selectedEmployeeId, setSelectedEmployeeId] = useState<string>('');
  const [expandedEmployee, setExpandedEmployee] = useState<string | null>(null);
  const [showFormula, setShowFormula] = useState(false);

  const { data: employees } = useEmployees(companyId);
  const { data: specialDayTypes = [] } = useSpecialDayTypes(companyId);
  const toggleSpecialDay = useToggleSpecialDay();

  const { data: monthlyData, isLoading } = useQuery({
    queryKey: ['monthly-summary', companyId, selectedMonth, selectedEmployeeId],
    queryFn: async () => {
      const params = new URLSearchParams({ month: selectedMonth });
      if (selectedEmployeeId) params.set('employee_id', selectedEmployeeId);

      const response = await fetch(
        `${process.env.REACT_APP_SUPABASE_URL}/functions/v1/get-monthly-summary?${params}`,
        {
          method: 'GET',
          headers: {
            Authorization: `Bearer ${(await supabase.auth.getSession()).data.session?.access_token}`,
            'Content-Type': 'application/json',
          },
        }
      );

      if (!response.ok) {
        const err = await response.json();
        throw new Error(err.error || 'Failed to fetch monthly summary');
      }

      return response.json() as Promise<{
        summaries: MonthlyEmployeeSummary[];
        month: string;
        settings: { overtime_multiplier: number; weekend_multiplier: number; holiday_multiplier: number; monthly_work_days_constant: number };
      }>;
    },
    enabled: !!companyId && !!selectedMonth,
  });

  const summaries = monthlyData?.summaries || [];
  const settings = monthlyData?.settings;

  // Aggregate stats
  const totalEmployees = summaries.length;
  const totalNetOTMinutes = summaries.reduce((s, e) => s + Math.max(0, e.net_minutes), 0);
  const totalDeficitMinutes = summaries.reduce((s, e) => s + e.deficit_minutes, 0);
  const avgOTPercent = totalEmployees > 0
    ? summaries.reduce((s, e) => s + e.overtime_percentage, 0) / totalEmployees
    : 0;

  const handleExport = () => {
    if (!summaries.length) return;

    // Build per-type column headers
    const typeHeaders = specialDayTypes.map((sdt) => sdt.name);

    const headers = [
      t('common.name'),
      t('monthlySummary.workDays'),
      t('monthlySummary.totalHours'),
      t('monthlySummary.expectedHours'),
      ...typeHeaders,
      t('monthlySummary.netOT'),
      t('monthlySummary.deficit'),
      t('monthlySummary.otDays'),
      t('monthlySummary.otPercent'),
      t('monthlySummary.lateDays'),
      t('monthlySummary.absentDays'),
      t('monthlySummary.leaveDays'),
    ];

    const rows = summaries.map((s) => [
      s.employee_name,
      s.work_days,
      formatMinutesToHours(s.total_work_minutes),
      formatMinutesToHours(s.expected_work_minutes),
      ...specialDayTypes.map((sdt) => {
        const stat = s.special_day_stats?.[sdt.id];
        return stat ? `${stat.days}d (${formatMinutesToHours(stat.minutes)})` : '0';
      }),
      formatMinutesToHours(s.net_minutes),
      formatMinutesToHours(s.deficit_minutes),
      s.overtime_days.toFixed(2),
      `${s.overtime_percentage.toFixed(2)}%`,
      s.late_days,
      s.absent_days,
      s.leave_days,
    ]);

    const csv = [headers.join(','), ...rows.map((r) => r.join(','))].join('\n');
    const blob = new Blob([csv], { type: 'text/csv;charset=utf-8;' });
    const link = document.createElement('a');
    link.href = URL.createObjectURL(blob);
    link.download = `monthly-summary-${selectedMonth}.csv`;
    link.click();
  };

  const inputClasses = "block w-full px-3 py-2 bg-zinc-800 border border-zinc-700 rounded-lg text-white focus:outline-none focus:border-amber-500 focus:ring-1 focus:ring-amber-500/20 text-sm";

  return (
    <div>
      <div className="flex items-center justify-between mb-6">
        <h1 className="text-2xl font-bold font-display text-white">{t('monthlySummary.title')}</h1>
        <div className="flex items-center gap-2">
          <button
            onClick={() => setShowFormula(!showFormula)}
            className="inline-flex items-center gap-1.5 px-3 py-2 text-sm font-medium text-zinc-400 bg-zinc-800 rounded-lg hover:bg-zinc-700 hover:text-white transition-colors"
          >
            <Info className="w-4 h-4" />
            {t('monthlySummary.formula')}
          </button>
          <button
            onClick={handleExport}
            disabled={!summaries.length}
            className="inline-flex items-center gap-2 px-4 py-2 text-sm font-semibold text-black bg-amber-500 rounded-lg hover:bg-amber-400 shadow-lg shadow-amber-500/20 disabled:opacity-50 transition-all"
          >
            <Download className="w-4 h-4" />
            {t('common.export')}
          </button>
        </div>
      </div>

      {/* Formula Explanation */}
      {showFormula && (
        <div className="bg-zinc-900/80 backdrop-blur-sm rounded-xl border border-zinc-800 p-6 mb-6">
          <h3 className="text-sm font-semibold text-amber-400 mb-3">{t('monthlySummary.formulaTitle')}</h3>
          <div className="space-y-2 text-sm text-zinc-300 font-mono">
            <p>{t('monthlySummary.formulaLine1')}</p>
            <p>{t('monthlySummary.formulaLine2', { multiplier: settings?.overtime_multiplier || 1.5 })}</p>
            <p>{t('monthlySummary.formulaLine2b', { multiplier: settings?.weekend_multiplier || 1.5 })}</p>
            <p>{t('monthlySummary.formulaLine2c', { multiplier: settings?.holiday_multiplier || 2.0 })}</p>
            <p>{t('monthlySummary.formulaLine3')}</p>
            <p>{t('monthlySummary.formulaLine4', { constant: settings?.monthly_work_days_constant || 21.66 })}</p>
          </div>
        </div>
      )}

      {/* Filters */}
      <div className="flex flex-wrap gap-4 mb-6">
        <div className="w-48">
          <label className="block text-xs font-medium text-zinc-400 mb-1">
            <Calendar className="w-3 h-3 inline mr-1" />
            {t('monthlySummary.month')}
          </label>
          <input
            type="month"
            value={selectedMonth}
            onChange={(e) => setSelectedMonth(e.target.value)}
            className={inputClasses}
          />
        </div>
        <div className="w-64">
          <label className="block text-xs font-medium text-zinc-400 mb-1">
            <Users className="w-3 h-3 inline mr-1" />
            {t('reports.selectEmployee')}
          </label>
          <select
            value={selectedEmployeeId}
            onChange={(e) => setSelectedEmployeeId(e.target.value)}
            className={inputClasses}
          >
            <option value="">{t('reports.allEmployees')}</option>
            {employees?.map((emp) => (
              <option key={emp.id} value={emp.id}>
                {emp.first_name} {emp.last_name}
              </option>
            ))}
          </select>
        </div>
      </div>

      {/* Stat Cards */}
      <div className="grid grid-cols-2 md:grid-cols-4 gap-4 mb-6">
        <div className="bg-zinc-900/80 backdrop-blur-sm rounded-xl border border-zinc-800 p-4">
          <div className="flex items-center gap-2 mb-1">
            <Users className="w-4 h-4 text-zinc-400" />
            <span className="text-xs font-medium text-zinc-400">{t('monthlySummary.totalEmployees')}</span>
          </div>
          <p className="text-2xl font-bold text-white">{totalEmployees}</p>
        </div>
        <div className="bg-zinc-900/80 backdrop-blur-sm rounded-xl border border-zinc-800 p-4">
          <div className="flex items-center gap-2 mb-1">
            <TrendingUp className="w-4 h-4 text-emerald-400" />
            <span className="text-xs font-medium text-zinc-400">{t('monthlySummary.netOTHours')}</span>
          </div>
          <p className="text-2xl font-bold text-emerald-400">{formatMinutesToHours(totalNetOTMinutes)}</p>
        </div>
        <div className="bg-zinc-900/80 backdrop-blur-sm rounded-xl border border-zinc-800 p-4">
          <div className="flex items-center gap-2 mb-1">
            <TrendingDown className="w-4 h-4 text-rose-400" />
            <span className="text-xs font-medium text-zinc-400">{t('monthlySummary.netDeficitHours')}</span>
          </div>
          <p className="text-2xl font-bold text-rose-400">{formatMinutesToHours(totalDeficitMinutes)}</p>
        </div>
        <div className="bg-zinc-900/80 backdrop-blur-sm rounded-xl border border-zinc-800 p-4">
          <div className="flex items-center gap-2 mb-1">
            <Clock className="w-4 h-4 text-amber-400" />
            <span className="text-xs font-medium text-zinc-400">{t('monthlySummary.avgOTPercent')}</span>
          </div>
          <p className="text-2xl font-bold text-amber-400">{avgOTPercent.toFixed(2)}%</p>
        </div>
      </div>

      {/* Data Table */}
      <div className="bg-zinc-900/80 backdrop-blur-sm rounded-xl border border-zinc-800 overflow-hidden">
        {isLoading ? (
          <div className="p-8 text-center text-zinc-400">{t('common.loading')}</div>
        ) : summaries.length === 0 ? (
          <div className="p-8 text-center text-zinc-400">{t('common.noData')}</div>
        ) : (
          <div className="overflow-x-auto">
            <table className="w-full">
              <thead>
                <tr className="border-b border-zinc-800">
                  <th className="px-4 py-3 text-left text-xs font-semibold text-zinc-400 uppercase tracking-wider">{t('common.name')}</th>
                  <th className="px-4 py-3 text-center text-xs font-semibold text-zinc-400 uppercase tracking-wider">{t('monthlySummary.workDays')}</th>
                  <th className="px-4 py-3 text-center text-xs font-semibold text-zinc-400 uppercase tracking-wider">{t('monthlySummary.totalHours')}</th>
                  <th className="px-4 py-3 text-center text-xs font-semibold text-zinc-400 uppercase tracking-wider">{t('monthlySummary.expectedHours')}</th>
                  <th className="px-4 py-3 text-center text-xs font-semibold text-zinc-400 uppercase tracking-wider">
                    <div className="flex items-center justify-center gap-1">
                      <Star className="w-3 h-3" />
                      {t('specialDayTypes.specialDays')}
                    </div>
                  </th>
                  <th className="px-4 py-3 text-center text-xs font-semibold text-zinc-400 uppercase tracking-wider">{t('monthlySummary.netOT')}</th>
                  <th className="px-4 py-3 text-center text-xs font-semibold text-zinc-400 uppercase tracking-wider">{t('monthlySummary.deficit')}</th>
                  <th className="px-4 py-3 text-center text-xs font-semibold text-zinc-400 uppercase tracking-wider">{t('monthlySummary.otDays')}</th>
                  <th className="px-4 py-3 text-center text-xs font-semibold text-zinc-400 uppercase tracking-wider">{t('monthlySummary.otPercent')}</th>
                  <th className="px-4 py-3 text-center text-xs font-semibold text-zinc-400 uppercase tracking-wider">{t('monthlySummary.lateDays')}</th>
                  <th className="px-4 py-3 text-center text-xs font-semibold text-zinc-400 uppercase tracking-wider">{t('monthlySummary.absentDays')}</th>
                  <th className="px-4 py-3 text-center text-xs font-semibold text-zinc-400 uppercase tracking-wider">{t('monthlySummary.leaveDays')}</th>
                </tr>
              </thead>
              <tbody className="divide-y divide-zinc-800/50">
                {summaries.map((summary) => (
                  <React.Fragment key={summary.employee_id}>
                    <tr
                      className="hover:bg-zinc-800/30 transition-colors cursor-pointer"
                      onClick={() =>
                        setExpandedEmployee(
                          expandedEmployee === summary.employee_id ? null : summary.employee_id
                        )
                      }
                    >
                      <td className="px-4 py-3 text-sm text-white font-medium">{summary.employee_name}</td>
                      <td className="px-4 py-3 text-sm text-zinc-300 text-center">{summary.work_days}</td>
                      <td className="px-4 py-3 text-sm text-zinc-300 text-center">{formatMinutesToHours(summary.total_work_minutes)}</td>
                      <td className="px-4 py-3 text-sm text-zinc-300 text-center">{formatMinutesToHours(summary.expected_work_minutes)}</td>
                      <td className="px-4 py-3 text-sm text-center">
                        {summary.special_day_stats && Object.keys(summary.special_day_stats).length > 0 ? (
                          <div className="flex flex-wrap gap-1 justify-center">
                            {Object.entries(summary.special_day_stats).map(([typeId, stat]) => (
                              <span
                                key={typeId}
                                className="inline-flex items-center gap-1 px-2 py-0.5 rounded-full text-xs font-medium bg-purple-500/10 text-purple-400"
                                title={stat.name}
                              >
                                <Star className="w-3 h-3" />
                                {stat.days}
                              </span>
                            ))}
                          </div>
                        ) : summary.boss_call_days > 0 ? (
                          <span className="inline-flex items-center gap-1 px-2 py-0.5 rounded-full text-xs font-medium bg-purple-500/10 text-purple-400">
                            <Star className="w-3 h-3" />
                            {summary.boss_call_days}
                          </span>
                        ) : (
                          <span className="text-zinc-500">0</span>
                        )}
                      </td>
                      <td className="px-4 py-3 text-sm text-center">
                        <span className={summary.net_minutes >= 0 ? 'text-emerald-400' : 'text-rose-400'}>
                          {formatMinutesToHours(summary.net_minutes)}
                        </span>
                      </td>
                      <td className="px-4 py-3 text-sm text-center">
                        {summary.deficit_minutes > 0 ? (
                          <span className="text-rose-400">{formatMinutesToHours(summary.deficit_minutes)}</span>
                        ) : (
                          <span className="text-zinc-500">-</span>
                        )}
                      </td>
                      <td className="px-4 py-3 text-sm text-amber-400 text-center font-medium">{summary.overtime_days.toFixed(2)}</td>
                      <td className="px-4 py-3 text-sm text-amber-400 text-center font-bold">{summary.overtime_percentage.toFixed(2)}%</td>
                      <td className="px-4 py-3 text-sm text-center">
                        {summary.late_days > 0 ? (
                          <span className="text-orange-400">{summary.late_days}</span>
                        ) : (
                          <span className="text-zinc-500">0</span>
                        )}
                      </td>
                      <td className="px-4 py-3 text-sm text-center">
                        {summary.absent_days > 0 ? (
                          <span className="text-rose-400">{summary.absent_days}</span>
                        ) : (
                          <span className="text-zinc-500">0</span>
                        )}
                      </td>
                      <td className="px-4 py-3 text-sm text-center">
                        {summary.leave_days > 0 ? (
                          <span className="text-blue-400">{summary.leave_days}</span>
                        ) : (
                          <span className="text-zinc-500">0</span>
                        )}
                      </td>
                    </tr>

                    {/* Expanded daily detail */}
                    {expandedEmployee === summary.employee_id && (
                      <tr>
                        <td colSpan={12} className="px-4 py-3 bg-zinc-950/50">
                          <div className="max-h-64 overflow-y-auto">
                            <table className="w-full text-xs">
                              <thead>
                                <tr className="border-b border-zinc-800">
                                  <th className="px-2 py-1 text-left text-zinc-500">{t('common.date')}</th>
                                  <th className="px-2 py-1 text-center text-zinc-500">{t('monthlySummary.type')}</th>
                                  <th className="px-2 py-1 text-center text-zinc-500">{t('monthlySummary.worked')}</th>
                                  <th className="px-2 py-1 text-center text-zinc-500">{t('monthlySummary.expected')}</th>
                                  <th className="px-2 py-1 text-center text-zinc-500">{t('monthlySummary.effective')}</th>
                                  <th className="px-2 py-1 text-center text-zinc-500">{t('specialDayTypes.specialDays')}</th>
                                  <th className="px-2 py-1 text-center text-zinc-500">{t('common.status')}</th>
                                </tr>
                              </thead>
                              <tbody className="divide-y divide-zinc-800/30">
                                {summary.daily_details
                                  .filter((d) => d.is_work_day || d.total_work_minutes > 0 || d.is_boss_call || d.special_day_type_id)
                                  .map((day) => (
                                    <tr key={day.date} className="hover:bg-zinc-800/20">
                                      <td className="px-2 py-1 text-zinc-300">
                                        {new Date(day.date + 'T00:00:00').toLocaleDateString(undefined, {
                                          weekday: 'short',
                                          month: 'short',
                                          day: 'numeric',
                                        })}
                                      </td>
                                      <td className="px-2 py-1 text-center">
                                        <span
                                          className={`px-1.5 py-0.5 rounded text-xs ${
                                            day.work_day_type === 'holiday'
                                              ? 'bg-red-500/10 text-red-400'
                                              : day.work_day_type === 'weekend'
                                              ? 'bg-blue-500/10 text-blue-400'
                                              : 'bg-zinc-800 text-zinc-400'
                                          }`}
                                        >
                                          {day.work_day_type}
                                          {day.work_day_type === 'weekend' && day.total_work_minutes > 0 && (
                                            <span className="ml-1 text-amber-400 font-semibold">
                                              {'\u00d7'}{settings?.weekend_multiplier || 1.5}
                                            </span>
                                          )}
                                          {day.work_day_type === 'holiday' && day.total_work_minutes > 0 && (
                                            <span className="ml-1 text-amber-400 font-semibold">
                                              {'\u00d7'}{settings?.holiday_multiplier || 2.0}
                                            </span>
                                          )}
                                        </span>
                                      </td>
                                      <td className="px-2 py-1 text-center text-zinc-300">
                                        {formatMinutesToHours(day.total_work_minutes)}
                                      </td>
                                      <td className="px-2 py-1 text-center text-zinc-400">
                                        {formatMinutesToHours(day.expected_work_minutes)}
                                      </td>
                                      <td className="px-2 py-1 text-center text-zinc-300">
                                        {day.effective_work_minutes !== day.total_work_minutes ? (
                                          <span className="text-purple-400 font-medium">
                                            {formatMinutesToHours(day.effective_work_minutes)}
                                          </span>
                                        ) : (
                                          '-'
                                        )}
                                      </td>
                                      <td className="px-2 py-1 text-center">
                                        <select
                                          value={day.special_day_type_id || ''}
                                          onChange={(e) => {
                                            const val = e.target.value || null;
                                            toggleSpecialDay.mutate({
                                              employee_id: summary.employee_id,
                                              date: day.date,
                                              special_day_type_id: val,
                                            });
                                          }}
                                          className="bg-zinc-800 border border-zinc-700 rounded px-1.5 py-0.5 text-xs text-zinc-300 focus:outline-none focus:border-amber-500"
                                        >
                                          <option value="">-</option>
                                          {specialDayTypes.map((sdt) => (
                                            <option key={sdt.id} value={sdt.id}>{sdt.name}</option>
                                          ))}
                                        </select>
                                      </td>
                                      <td className="px-2 py-1 text-center">
                                        {day.is_leave ? (
                                          <span className="text-blue-400">{t('monthlySummary.statusLeave')}</span>
                                        ) : day.is_absent ? (
                                          <span className="text-rose-400">{t('monthlySummary.statusAbsent')}</span>
                                        ) : day.is_late ? (
                                          <span className="text-orange-400">{t('monthlySummary.statusLate')}</span>
                                        ) : day.total_work_minutes > 0 ? (
                                          <span className="text-emerald-400">{t('monthlySummary.statusPresent')}</span>
                                        ) : null}
                                      </td>
                                    </tr>
                                  ))}
                              </tbody>
                            </table>
                          </div>
                        </td>
                      </tr>
                    )}
                  </React.Fragment>
                ))}
              </tbody>
            </table>
          </div>
        )}
      </div>
    </div>
  );
}
