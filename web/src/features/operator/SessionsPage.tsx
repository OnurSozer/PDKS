import React, { useState } from 'react';
import { useTranslation } from 'react-i18next';
import { ColumnDef } from '@tanstack/react-table';
import { useAuth } from '../../hooks/useAuth';
import { useEmployees } from '../../hooks/useEmployees';
import { useSessions } from '../../hooks/useSessions';
import { WorkSession } from '../../types';
import { DataTable } from '../../components/shared/DataTable';
import { DateRangePicker } from '../../components/shared/DateRangePicker';
import { EditSessionModal } from './EditSessionModal';
import { formatMinutes, formatTime } from '../../lib/utils';
import { format, startOfMonth } from 'date-fns';
import { Pencil } from 'lucide-react';

export function SessionsPage() {
  const { t } = useTranslation();
  const { profile } = useAuth();
  const companyId = profile?.company_id || undefined;

  const [startDate, setStartDate] = useState(format(startOfMonth(new Date()), 'yyyy-MM-dd'));
  const [endDate, setEndDate] = useState(format(new Date(), 'yyyy-MM-dd'));
  const [employeeFilter, setEmployeeFilter] = useState('');
  const [showCancelled, setShowCancelled] = useState(false);
  const [editSession, setEditSession] = useState<WorkSession | null>(null);

  const { data: employees = [] } = useEmployees(companyId);
  const { data: allSessions = [], isLoading } = useSessions({
    companyId,
    employeeId: employeeFilter || undefined,
    startDate,
    endDate,
  });

  const sessions = showCancelled
    ? allSessions
    : allSessions.filter((s) => s.status !== 'cancelled');

  const columns: ColumnDef<WorkSession, any>[] = [
    {
      id: 'employee',
      header: t('sessions.employee'),
      accessorFn: (row) => {
        const emp = row.employee as any;
        return emp ? `${emp.first_name} ${emp.last_name}` : '-';
      },
    },
    {
      accessorKey: 'session_date',
      header: t('sessions.sessionDate'),
      cell: ({ getValue }) => new Date(getValue() as string).toLocaleDateString(),
    },
    {
      accessorKey: 'clock_in',
      header: t('sessions.clockIn'),
      cell: ({ getValue }) => formatTime(getValue() as string),
    },
    {
      accessorKey: 'clock_out',
      header: t('sessions.clockOut'),
      cell: ({ getValue }) => {
        const val = getValue() as string;
        return val ? formatTime(val) : '-';
      },
    },
    {
      accessorKey: 'total_minutes',
      header: t('sessions.duration'),
      cell: ({ getValue }) => {
        const val = getValue() as number;
        return val ? formatMinutes(val) : '-';
      },
    },
    {
      accessorKey: 'overtime_minutes',
      header: t('sessions.overtimeHours'),
      cell: ({ getValue }) => {
        const val = getValue() as number;
        return val ? formatMinutes(val) : '-';
      },
    },
    {
      accessorKey: 'status',
      header: t('common.status'),
      cell: ({ getValue }) => {
        const status = getValue() as string;
        const styles: Record<string, string> = {
          active: 'bg-emerald-500/10 text-emerald-400 border border-emerald-500/20',
          completed: 'bg-sky-500/10 text-sky-400 border border-sky-500/20',
          edited: 'bg-amber-500/10 text-amber-400 border border-amber-500/20',
          cancelled: 'bg-rose-500/10 text-rose-400 border border-rose-500/20',
        };
        const labels: Record<string, string> = {
          active: t('sessions.statusActive'),
          completed: t('sessions.statusCompleted'),
          edited: t('sessions.statusEdited'),
          cancelled: t('sessions.statusCancelled'),
        };
        return (
          <span className={`inline-flex px-2 py-1 text-xs font-medium rounded-full ${styles[status] || ''}`}>
            {labels[status] || status}
          </span>
        );
      },
    },
    {
      id: 'actions',
      header: t('common.actions'),
      cell: ({ row }) => (
        <button
          onClick={() => setEditSession(row.original)}
          className="inline-flex items-center gap-1 text-sm text-amber-500 hover:text-amber-400 transition-colors"
        >
          <Pencil className="w-4 h-4" />
          {t('common.edit')}
        </button>
      ),
      enableSorting: false,
    },
  ];

  return (
    <div>
      <h1 className="text-2xl font-bold font-display text-white mb-6">
        {t('sessions.title')}
      </h1>

      <div className="flex flex-wrap items-end gap-4 mb-6">
        <DateRangePicker
          startDate={startDate}
          endDate={endDate}
          onStartDateChange={setStartDate}
          onEndDateChange={setEndDate}
        />
        <div>
          <label className="block text-xs font-medium text-zinc-400 mb-1">
            {t('sessions.employee')}
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
        <label className="flex items-center gap-2 cursor-pointer pb-0.5">
          <input
            type="checkbox"
            checked={showCancelled}
            onChange={(e) => setShowCancelled(e.target.checked)}
            className="w-4 h-4 text-amber-500 bg-zinc-800 border-zinc-600 rounded focus:ring-amber-500/20"
          />
          <span className="text-sm text-zinc-300">{t('sessions.showCancelled')}</span>
        </label>
      </div>

      {isLoading ? (
        <div className="flex items-center justify-center py-12">
          <div className="animate-spin rounded-full h-8 w-8 border-b-2 border-amber-500"></div>
        </div>
      ) : (
        <DataTable data={sessions} columns={columns} />
      )}

      {editSession && (
        <EditSessionModal
          session={editSession}
          onClose={() => setEditSession(null)}
        />
      )}
    </div>
  );
}
