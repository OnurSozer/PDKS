import React, { useState } from 'react';
import { useTranslation } from 'react-i18next';
import { useParams, Link } from 'react-router-dom';
import { ColumnDef } from '@tanstack/react-table';
import { useEmployee } from '../../hooks/useEmployees';
import { useSessions } from '../../hooks/useSessions';
import { useAuth } from '../../hooks/useAuth';
import { WorkSession } from '../../types';
import { DataTable } from '../../components/shared/DataTable';
import { formatMinutes } from '../../lib/utils';
import { ArrowLeft, User } from 'lucide-react';
import { format, subDays } from 'date-fns';

export function EmployeeDetailPage() {
  const { t } = useTranslation();
  const { id } = useParams<{ id: string }>();
  const { profile: authProfile } = useAuth();
  const companyId = authProfile?.company_id || undefined;

  const { data: employee, isLoading: employeeLoading } = useEmployee(id);
  const [startDate] = useState(format(subDays(new Date(), 30), 'yyyy-MM-dd'));
  const [endDate] = useState(format(new Date(), 'yyyy-MM-dd'));

  const { data: sessions = [] } = useSessions({
    companyId,
    employeeId: id,
    startDate,
    endDate,
  });

  const sessionColumns: ColumnDef<WorkSession, any>[] = [
    {
      accessorKey: 'session_date',
      header: t('sessions.sessionDate'),
      cell: ({ getValue }) => new Date(getValue() as string).toLocaleDateString(),
    },
    {
      accessorKey: 'clock_in',
      header: t('sessions.clockIn'),
      cell: ({ getValue }) => new Date(getValue() as string).toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' }),
    },
    {
      accessorKey: 'clock_out',
      header: t('sessions.clockOut'),
      cell: ({ getValue }) => {
        const val = getValue() as string;
        return val ? new Date(val).toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' }) : '-';
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
      accessorKey: 'status',
      header: t('common.status'),
      cell: ({ getValue }) => {
        const status = getValue() as string;
        const statusStyles: Record<string, string> = {
          active: 'bg-emerald-500/10 text-emerald-400 border border-emerald-500/20',
          completed: 'bg-sky-500/10 text-sky-400 border border-sky-500/20',
          edited: 'bg-amber-500/10 text-amber-400 border border-amber-500/20',
          cancelled: 'bg-rose-500/10 text-rose-400 border border-rose-500/20',
        };
        const statusLabels: Record<string, string> = {
          active: t('sessions.statusActive'),
          completed: t('sessions.statusCompleted'),
          edited: t('sessions.statusEdited'),
          cancelled: t('sessions.statusCancelled'),
        };
        return (
          <span className={`inline-flex px-2 py-1 text-xs font-medium rounded-full ${statusStyles[status] || ''}`}>
            {statusLabels[status] || status}
          </span>
        );
      },
    },
  ];

  if (employeeLoading) {
    return (
      <div className="flex items-center justify-center py-12">
        <div className="animate-spin rounded-full h-8 w-8 border-b-2 border-amber-500"></div>
      </div>
    );
  }

  if (!employee) {
    return <div className="text-center py-12 text-zinc-500">{t('common.noData')}</div>;
  }

  return (
    <div>
      <Link
        to="/operator/employees"
        className="inline-flex items-center gap-1 text-sm text-zinc-400 hover:text-white mb-4 transition-colors"
      >
        <ArrowLeft className="w-4 h-4" />
        {t('common.back')}
      </Link>

      <h1 className="text-2xl font-bold font-display text-white mb-6">
        {t('employees.employeeDetail')}
      </h1>

      {/* Employee info */}
      <div className="bg-zinc-900/80 backdrop-blur-sm rounded-xl border border-zinc-800 p-6 mb-6">
        <div className="flex items-center gap-4 mb-4">
          <div className="p-3 bg-amber-500/10 rounded-full">
            <User className="w-6 h-6 text-amber-500" />
          </div>
          <div>
            <h2 className="text-lg font-semibold text-white">
              {employee.first_name} {employee.last_name}
            </h2>
            <span
              className={`inline-flex px-2 py-1 text-xs font-medium rounded-full ${
                employee.role === 'chef'
                  ? 'bg-amber-500/10 text-amber-400 border border-amber-500/20'
                  : 'bg-sky-500/10 text-sky-400 border border-sky-500/20'
              }`}
            >
              {employee.role === 'chef' ? t('employees.roleChef') : t('employees.roleEmployee')}
            </span>
          </div>
        </div>
        <div className="grid grid-cols-1 sm:grid-cols-3 gap-4">
          <div>
            <dt className="text-sm font-medium text-zinc-400">{t('common.email')}</dt>
            <dd className="text-sm text-zinc-200">{employee.email}</dd>
          </div>
          <div>
            <dt className="text-sm font-medium text-zinc-400">{t('common.phone')}</dt>
            <dd className="text-sm text-zinc-200">{employee.phone || '-'}</dd>
          </div>
          <div>
            <dt className="text-sm font-medium text-zinc-400">{t('employees.startDate')}</dt>
            <dd className="text-sm text-zinc-200">
              {employee.start_date ? new Date(employee.start_date).toLocaleDateString() : '-'}
            </dd>
          </div>
        </div>
      </div>

      {/* Session history */}
      <div className="bg-zinc-900/80 backdrop-blur-sm rounded-xl border border-zinc-800 p-6">
        <h2 className="text-lg font-semibold text-white mb-4">{t('employees.sessionHistory')}</h2>
        <DataTable data={sessions} columns={sessionColumns} />
      </div>
    </div>
  );
}
