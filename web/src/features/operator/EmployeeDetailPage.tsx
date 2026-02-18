import React, { useState, useEffect } from 'react';
import { useTranslation } from 'react-i18next';
import { useParams, Link } from 'react-router-dom';
import { ColumnDef } from '@tanstack/react-table';
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import { useEmployee } from '../../hooks/useEmployees';
import { useSessions } from '../../hooks/useSessions';
import { useAuth } from '../../hooks/useAuth';
import { supabase } from '../../lib/supabase';
import { WorkSession, LeaveType, EmployeeLeaveEntitlement, SpecialDayType } from '../../types';
import { useSpecialDayTypes, useEmployeeSpecialDayTypes, useAssignSpecialDayType } from '../../hooks/useSpecialDayTypes';
import { DataTable } from '../../components/shared/DataTable';
import { formatMinutes, formatTime } from '../../lib/utils';
import { ArrowLeft, User, Save, Check } from 'lucide-react';
import { format, subDays } from 'date-fns';

export function EmployeeDetailPage() {
  const { t } = useTranslation();
  const { id } = useParams<{ id: string }>();
  const { profile: authProfile } = useAuth();
  const companyId = authProfile?.company_id || undefined;
  const queryClient = useQueryClient();

  const { data: employee, isLoading: employeeLoading } = useEmployee(id);
  const [startDate] = useState(format(subDays(new Date(), 30), 'yyyy-MM-dd'));
  const [endDate] = useState(format(new Date(), 'yyyy-MM-dd'));

  const { data: sessions = [] } = useSessions({
    companyId,
    employeeId: id,
    startDate,
    endDate,
  });

  // Fetch leave types for the company
  const { data: leaveTypes = [] } = useQuery({
    queryKey: ['leave-types', companyId],
    queryFn: async () => {
      const { data, error } = await supabase
        .from('leave_types')
        .select('*')
        .eq('company_id', companyId!)
        .eq('is_active', true)
        .order('name');
      if (error) throw error;
      return data as LeaveType[];
    },
    enabled: !!companyId,
  });

  // Fetch entitlements for this employee
  const { data: entitlements = [] } = useQuery({
    queryKey: ['employee-entitlements', id],
    queryFn: async () => {
      const { data, error } = await supabase
        .from('employee_leave_entitlements')
        .select('*, leave_type:leave_types(*)')
        .eq('employee_id', id!);
      if (error) throw error;
      return data as EmployeeLeaveEntitlement[];
    },
    enabled: !!id,
  });

  // Fetch special day types
  const { data: allSpecialDayTypes = [] } = useSpecialDayTypes(companyId);
  const { data: employeeSpecialDayTypes = [] } = useEmployeeSpecialDayTypes(id);
  const assignSpecialDayType = useAssignSpecialDayType();

  // Non-applies_to_all types that need per-employee assignment
  const assignableTypes = allSpecialDayTypes.filter((sdt) => !sdt.applies_to_all);
  const assignedTypeIds = new Set(employeeSpecialDayTypes.map((e) => e.special_day_type_id));

  // Local state for editable entitlements
  const [entitlementValues, setEntitlementValues] = useState<Record<string, number>>({});
  const [entitlementSaved, setEntitlementSaved] = useState(false);

  // Sync fetched entitlements to local state
  useEffect(() => {
    if (entitlements.length > 0 || leaveTypes.length > 0) {
      const values: Record<string, number> = {};
      // Start with leave type defaults
      leaveTypes.forEach((lt) => {
        values[lt.id] = lt.default_days_per_year || 0;
      });
      // Override with actual entitlements
      entitlements.forEach((ent) => {
        values[ent.leave_type_id] = Number(ent.days_per_year);
      });
      setEntitlementValues(values);
    }
  }, [entitlements, leaveTypes]);

  // Save entitlements mutation
  const saveEntitlementsMutation = useMutation({
    mutationFn: async () => {
      const entArr = Object.entries(entitlementValues).map(
        ([leave_type_id, days_per_year]) => ({ leave_type_id, days_per_year })
      );
      const { data, error } = await supabase.functions.invoke('update-entitlements', {
        body: { employee_id: id, entitlements: entArr },
      });
      if (error) throw error;
      return data;
    },
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['employee-entitlements', id] });
      setEntitlementSaved(true);
      setTimeout(() => setEntitlementSaved(false), 2000);
    },
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

  const inputClasses = "block w-24 px-3 py-2 bg-zinc-800 border border-zinc-700 rounded-lg text-white focus:outline-none focus:border-amber-500 focus:ring-1 focus:ring-amber-500/20 text-sm";

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

      {/* Leave Entitlements */}
      {leaveTypes.length > 0 && (
        <div className="bg-zinc-900/80 backdrop-blur-sm rounded-xl border border-zinc-800 p-6 mb-6">
          <h2 className="text-lg font-semibold text-white mb-4">
            {t('employees.leaveEntitlements')}
          </h2>
          <div className="space-y-3">
            {leaveTypes.map((lt) => (
              <div key={lt.id} className="flex items-center gap-3">
                <label className="text-sm text-zinc-300 w-48 shrink-0">
                  {lt.name}
                </label>
                <input
                  type="number"
                  min={0}
                  step="0.5"
                  value={entitlementValues[lt.id] ?? 0}
                  onChange={(e) =>
                    setEntitlementValues((prev) => ({
                      ...prev,
                      [lt.id]: Number(e.target.value) || 0,
                    }))
                  }
                  className={inputClasses}
                />
                <span className="text-sm text-zinc-500">{t('employees.daysPerYear')}</span>
              </div>
            ))}
          </div>
          <div className="mt-4 pt-4 border-t border-zinc-800">
            <button
              onClick={() => saveEntitlementsMutation.mutate()}
              disabled={saveEntitlementsMutation.isPending}
              className="inline-flex items-center gap-2 px-4 py-2 text-sm font-semibold text-black bg-amber-500 rounded-lg hover:bg-amber-400 shadow-lg shadow-amber-500/20 disabled:opacity-50 transition-all"
            >
              {entitlementSaved ? (
                <>
                  <Check className="w-4 h-4" />
                  {t('common.success')}
                </>
              ) : (
                <>
                  <Save className="w-4 h-4" />
                  {saveEntitlementsMutation.isPending ? t('common.loading') : t('common.save')}
                </>
              )}
            </button>
          </div>
        </div>
      )}

      {/* Eligible Day Types */}
      {assignableTypes.length > 0 && (
        <div className="bg-zinc-900/80 backdrop-blur-sm rounded-xl border border-zinc-800 p-6 mb-6">
          <h2 className="text-lg font-semibold text-white mb-4">
            {t('specialDayTypes.eligibleTypes')}
          </h2>
          <div className="space-y-2">
            {assignableTypes.map((sdt) => {
              const isAssigned = assignedTypeIds.has(sdt.id);
              return (
                <div key={sdt.id} className="flex items-center justify-between p-3 bg-zinc-800/50 rounded-lg">
                  <div>
                    <span className="text-sm font-medium text-white">{sdt.name}</span>
                    <span className="ml-2 text-xs text-zinc-500">({sdt.code})</span>
                    <span className={`ml-2 px-1.5 py-0.5 rounded text-xs ${
                      sdt.calculation_mode === 'rounding'
                        ? 'bg-purple-500/10 text-purple-400'
                        : 'bg-cyan-500/10 text-cyan-400'
                    }`}>
                      {sdt.calculation_mode === 'rounding'
                        ? t('specialDayTypes.modeRounding')
                        : t('specialDayTypes.modeFixedHours')}
                    </span>
                  </div>
                  <button
                    onClick={() => {
                      if (!id) return;
                      assignSpecialDayType.mutate({
                        employee_ids: [id],
                        special_day_type_id: sdt.id,
                        action: isAssigned ? 'remove' : undefined,
                      });
                    }}
                    disabled={assignSpecialDayType.isPending}
                    className={`px-3 py-1.5 text-xs font-medium rounded-lg transition-colors ${
                      isAssigned
                        ? 'bg-emerald-500/10 text-emerald-400 border border-emerald-500/20 hover:bg-rose-500/10 hover:text-rose-400 hover:border-rose-500/20'
                        : 'bg-zinc-700 text-zinc-400 hover:bg-amber-500/10 hover:text-amber-400'
                    }`}
                  >
                    {isAssigned ? t('common.active') : t('specialDayTypes.assignTypes')}
                  </button>
                </div>
              );
            })}
          </div>
        </div>
      )}

      {/* Session history */}
      <div className="bg-zinc-900/80 backdrop-blur-sm rounded-xl border border-zinc-800 p-6">
        <h2 className="text-lg font-semibold text-white mb-4">{t('employees.sessionHistory')}</h2>
        <DataTable data={sessions} columns={sessionColumns} />
      </div>
    </div>
  );
}
