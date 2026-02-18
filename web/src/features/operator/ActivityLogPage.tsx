import React, { useState } from 'react';
import { useTranslation } from 'react-i18next';
import { useAuth } from '../../hooks/useAuth';
import { useEmployees } from '../../hooks/useEmployees';
import { useActivityLogs } from '../../hooks/useActivityLogs';
import { ActivityLog } from '../../types';
import { ChevronLeft, ChevronRight } from 'lucide-react';

const ACTION_TYPES = [
  'clock_in',
  'clock_out',
  'session_create',
  'session_update',
  'session_delete',
  'leave_record',
  'leave_cancel',
  'boss_call_on',
  'boss_call_off',
] as const;

const ACTION_COLORS: Record<string, string> = {
  clock_in: 'bg-green-500/10 text-green-400',
  clock_out: 'bg-blue-500/10 text-blue-400',
  session_create: 'bg-emerald-500/10 text-emerald-400',
  session_update: 'bg-amber-500/10 text-amber-400',
  session_delete: 'bg-red-500/10 text-red-400',
  leave_record: 'bg-purple-500/10 text-purple-400',
  leave_cancel: 'bg-rose-500/10 text-rose-400',
  boss_call_on: 'bg-orange-500/10 text-orange-400',
  boss_call_off: 'bg-zinc-500/10 text-zinc-400',
};

function formatTime(isoString?: string): string {
  if (!isoString) return '-';
  const d = new Date(isoString);
  return d.toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' });
}

function formatDate(isoString?: string): string {
  if (!isoString) return '-';
  return new Date(isoString + 'T00:00:00').toLocaleDateString();
}

function renderDetails(log: ActivityLog, t: (key: string) => string): string {
  const d = log.details || {};
  switch (log.action_type) {
    case 'clock_in':
      return formatTime(d.clock_in);
    case 'clock_out': {
      let s = formatTime(d.clock_out);
      if (d.submitted_by) s += ` (${t('activityLog.submittedBy')}: ${d.submitted_by})`;
      return s;
    }
    case 'session_create':
      return `${formatDate(d.session_date)} ${formatTime(d.clock_in)} → ${formatTime(d.clock_out)}`;
    case 'session_update':
      return `${formatTime(d.old_clock_in)} → ${formatTime(d.old_clock_out)}  ⟶  ${formatTime(d.new_clock_in)} → ${formatTime(d.new_clock_out)}`;
    case 'session_delete':
      return formatDate(d.session_date);
    case 'leave_record':
      return `${formatDate(d.start_date)} - ${formatDate(d.end_date)} (${d.total_days}d) ${d.leave_type || ''}`;
    case 'leave_cancel':
      return `${formatDate(d.start_date)} - ${formatDate(d.end_date)} (${d.total_days}d)`;
    case 'boss_call_on':
    case 'boss_call_off':
      return `${formatDate(d.date)} — ${d.effective_work_minutes ?? '-'} min`;
    default:
      return JSON.stringify(d);
  }
}

export function ActivityLogPage() {
  const { t } = useTranslation();
  const { profile } = useAuth();
  const companyId = profile?.company_id || undefined;

  const [employeeId, setEmployeeId] = useState('');
  const [actionType, setActionType] = useState('');
  const [startDate, setStartDate] = useState('');
  const [endDate, setEndDate] = useState('');
  const [page, setPage] = useState(1);
  const pageSize = 20;

  const { data: employees } = useEmployees(companyId);
  const { data: result, isLoading } = useActivityLogs(companyId, {
    employeeId: employeeId || undefined,
    actionType: actionType || undefined,
    startDate: startDate || undefined,
    endDate: endDate || undefined,
    page,
    pageSize,
  });

  const logs = result?.data ?? [];
  const totalCount = result?.count ?? 0;
  const totalPages = Math.max(1, Math.ceil(totalCount / pageSize));

  const inputClasses =
    'block w-full px-3 py-2 bg-zinc-800 border border-zinc-700 rounded-lg text-white focus:outline-none focus:border-amber-500 focus:ring-1 focus:ring-amber-500/20 text-sm';

  return (
    <div>
      <h1 className="text-2xl font-bold font-display text-white mb-6">
        {t('activityLog.title')}
      </h1>

      {/* Filters */}
      <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-4 mb-6">
        <select
          value={employeeId}
          onChange={(e) => { setEmployeeId(e.target.value); setPage(1); }}
          className={inputClasses}
        >
          <option value="">{t('activityLog.allEmployees')}</option>
          {employees?.map((emp) => (
            <option key={emp.id} value={emp.id}>
              {emp.first_name} {emp.last_name}
            </option>
          ))}
        </select>

        <select
          value={actionType}
          onChange={(e) => { setActionType(e.target.value); setPage(1); }}
          className={inputClasses}
        >
          <option value="">{t('activityLog.allActions')}</option>
          {ACTION_TYPES.map((at) => (
            <option key={at} value={at}>
              {t(`activityLog.${at}`)}
            </option>
          ))}
        </select>

        <input
          type="date"
          value={startDate}
          onChange={(e) => { setStartDate(e.target.value); setPage(1); }}
          placeholder={t('activityLog.startDate')}
          className={inputClasses}
        />

        <input
          type="date"
          value={endDate}
          onChange={(e) => { setEndDate(e.target.value); setPage(1); }}
          placeholder={t('activityLog.endDate')}
          className={inputClasses}
        />
      </div>

      {/* Table */}
      <div className="bg-zinc-900/80 backdrop-blur-sm rounded-xl border border-zinc-800 overflow-hidden">
        {isLoading ? (
          <div className="p-8 text-center text-zinc-400">{t('common.loading')}</div>
        ) : logs.length === 0 ? (
          <div className="p-8 text-center text-zinc-400">{t('activityLog.noLogs')}</div>
        ) : (
          <div className="overflow-x-auto">
            <table className="w-full">
              <thead>
                <tr className="border-b border-zinc-800">
                  <th className="px-6 py-3 text-left text-xs font-semibold text-zinc-400 uppercase tracking-wider">
                    {t('activityLog.dateTime')}
                  </th>
                  <th className="px-6 py-3 text-left text-xs font-semibold text-zinc-400 uppercase tracking-wider">
                    {t('activityLog.employee')}
                  </th>
                  <th className="px-6 py-3 text-left text-xs font-semibold text-zinc-400 uppercase tracking-wider">
                    {t('activityLog.action')}
                  </th>
                  <th className="px-6 py-3 text-left text-xs font-semibold text-zinc-400 uppercase tracking-wider">
                    {t('activityLog.details')}
                  </th>
                  <th className="px-6 py-3 text-left text-xs font-semibold text-zinc-400 uppercase tracking-wider">
                    {t('activityLog.performedBy')}
                  </th>
                </tr>
              </thead>
              <tbody className="divide-y divide-zinc-800/50">
                {logs.map((log) => (
                  <tr key={log.id} className="hover:bg-zinc-800/30 transition-colors">
                    <td className="px-6 py-4 text-sm text-zinc-300 whitespace-nowrap">
                      {new Date(log.created_at).toLocaleString()}
                    </td>
                    <td className="px-6 py-4 text-sm text-white font-medium whitespace-nowrap">
                      {log.employee?.first_name} {log.employee?.last_name}
                    </td>
                    <td className="px-6 py-4 text-sm whitespace-nowrap">
                      <span
                        className={`inline-flex px-2 py-0.5 rounded-full text-xs font-medium ${ACTION_COLORS[log.action_type] || 'bg-zinc-500/10 text-zinc-400'}`}
                      >
                        {t(`activityLog.${log.action_type}`)}
                      </span>
                    </td>
                    <td className="px-6 py-4 text-sm text-zinc-300 max-w-xs truncate">
                      {renderDetails(log, t)}
                    </td>
                    <td className="px-6 py-4 text-sm text-zinc-300 whitespace-nowrap">
                      {log.performer?.first_name} {log.performer?.last_name}
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        )}
      </div>

      {/* Pagination */}
      {totalPages > 1 && (
        <div className="flex items-center justify-center gap-4 mt-6">
          <button
            onClick={() => setPage((p) => Math.max(1, p - 1))}
            disabled={page <= 1}
            className="inline-flex items-center gap-1 px-3 py-1.5 text-sm font-medium text-zinc-400 bg-zinc-800 rounded-lg hover:bg-zinc-700 hover:text-white disabled:opacity-40 disabled:cursor-not-allowed transition-colors"
          >
            <ChevronLeft className="w-4 h-4" />
            {t('activityLog.previous')}
          </button>
          <span className="text-sm text-zinc-400">
            {t('activityLog.page')} {page} / {totalPages}
          </span>
          <button
            onClick={() => setPage((p) => Math.min(totalPages, p + 1))}
            disabled={page >= totalPages}
            className="inline-flex items-center gap-1 px-3 py-1.5 text-sm font-medium text-zinc-400 bg-zinc-800 rounded-lg hover:bg-zinc-700 hover:text-white disabled:opacity-40 disabled:cursor-not-allowed transition-colors"
          >
            {t('activityLog.next')}
            <ChevronRight className="w-4 h-4" />
          </button>
        </div>
      )}
    </div>
  );
}
