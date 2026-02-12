import React, { useState } from 'react';
import { useTranslation } from 'react-i18next';
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import { useForm } from 'react-hook-form';
import { zodResolver } from '@hookform/resolvers/zod';
import { z } from 'zod';
import { ColumnDef } from '@tanstack/react-table';
import { supabase } from '../../lib/supabase';
import { useAuth } from '../../hooks/useAuth';
import { LeaveType, LeaveRecord } from '../../types';
import { DataTable } from '../../components/shared/DataTable';
import { Plus, X } from 'lucide-react';

const leaveTypeSchema = z.object({
  name: z.string().min(1),
  default_days_per_year: z.coerce.number().optional(),
  is_paid: z.boolean(),
});

type LeaveTypeFormData = z.infer<typeof leaveTypeSchema>;

export function LeavePage() {
  const { t } = useTranslation();
  const { profile } = useAuth();
  const companyId = profile?.company_id || undefined;
  const queryClient = useQueryClient();
  const [showCreateType, setShowCreateType] = useState(false);
  const [activeTab, setActiveTab] = useState<'records' | 'types'>('records');

  const { data: leaveTypes = [] } = useQuery({
    queryKey: ['leave-types', companyId],
    queryFn: async () => {
      const { data, error } = await supabase
        .from('leave_types')
        .select('*')
        .eq('company_id', companyId!)
        .order('name');
      if (error) throw error;
      return data as LeaveType[];
    },
    enabled: !!companyId,
  });

  const { data: leaveRecords = [], isLoading } = useQuery({
    queryKey: ['leave-records', companyId],
    queryFn: async () => {
      const { data, error } = await supabase
        .from('leave_records')
        .select('*, employee:profiles!leave_records_employee_id_fkey(id, first_name, last_name, email), leave_type:leave_types!leave_records_leave_type_id_fkey(id, name, is_paid)')
        .eq('company_id', companyId!)
        .order('start_date', { ascending: false });
      if (error) throw error;
      return data as LeaveRecord[];
    },
    enabled: !!companyId,
  });

  const {
    register,
    handleSubmit,
    reset,
    formState: { errors },
  } = useForm<LeaveTypeFormData>({
    resolver: zodResolver(leaveTypeSchema),
    defaultValues: { is_paid: true },
  });

  const createTypeMutation = useMutation({
    mutationFn: async (data: LeaveTypeFormData) => {
      const { error } = await supabase.from('leave_types').insert({
        company_id: companyId,
        name: data.name,
        default_days_per_year: data.default_days_per_year || null,
        is_paid: data.is_paid,
      });
      if (error) throw error;
    },
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['leave-types'] });
      setShowCreateType(false);
      reset();
    },
  });

  const inputClasses = "mt-1 block w-full px-3 py-2 bg-zinc-800 border border-zinc-700 rounded-lg text-white focus:outline-none focus:border-amber-500 focus:ring-1 focus:ring-amber-500/20 text-sm";

  const recordColumns: ColumnDef<LeaveRecord, any>[] = [
    {
      id: 'employee',
      header: t('sessions.employee'),
      accessorFn: (row) => {
        const emp = row.employee as any;
        return emp ? `${emp.first_name} ${emp.last_name}` : '-';
      },
    },
    {
      id: 'leave_type_name',
      header: t('leave.typeName'),
      accessorFn: (row) => (row.leave_type as any)?.name || '-',
    },
    {
      accessorKey: 'start_date',
      header: t('leave.startDate'),
      cell: ({ getValue }) => new Date(getValue() as string).toLocaleDateString(),
    },
    {
      accessorKey: 'end_date',
      header: t('leave.endDate'),
      cell: ({ getValue }) => new Date(getValue() as string).toLocaleDateString(),
    },
    {
      accessorKey: 'total_days',
      header: t('leave.totalDays'),
    },
    {
      accessorKey: 'reason',
      header: t('leave.reason'),
      cell: ({ getValue }) => getValue() || '-',
    },
    {
      accessorKey: 'status',
      header: t('common.status'),
      cell: ({ getValue }) => {
        const status = getValue() as string;
        return (
          <span
            className={`inline-flex px-2 py-1 text-xs font-medium rounded-full ${
              status === 'active' ? 'bg-emerald-500/10 text-emerald-400 border border-emerald-500/20' : 'bg-rose-500/10 text-rose-400 border border-rose-500/20'
            }`}
          >
            {status === 'active' ? t('common.active') : t('sessions.statusCancelled')}
          </span>
        );
      },
    },
  ];

  const typeColumns: ColumnDef<LeaveType, any>[] = [
    { accessorKey: 'name', header: t('leave.typeName') },
    {
      accessorKey: 'default_days_per_year',
      header: t('leave.defaultDays'),
      cell: ({ getValue }) => getValue() || '-',
    },
    {
      accessorKey: 'is_paid',
      header: t('leave.isPaid'),
      cell: ({ getValue }) => (
        <span
          className={`inline-flex px-2 py-1 text-xs font-medium rounded-full ${
            getValue() ? 'bg-emerald-500/10 text-emerald-400 border border-emerald-500/20' : 'bg-zinc-700 text-zinc-400'
          }`}
        >
          {getValue() ? t('common.yes') : t('common.no')}
        </span>
      ),
    },
    {
      accessorKey: 'is_active',
      header: t('common.status'),
      cell: ({ getValue }) => (
        <span
          className={`inline-flex px-2 py-1 text-xs font-medium rounded-full ${
            getValue() ? 'bg-emerald-500/10 text-emerald-400 border border-emerald-500/20' : 'bg-rose-500/10 text-rose-400 border border-rose-500/20'
          }`}
        >
          {getValue() ? t('common.active') : t('common.inactive')}
        </span>
      ),
    },
  ];

  return (
    <div>
      <h1 className="text-2xl font-bold font-display text-white mb-6">{t('leave.title')}</h1>

      {/* Tabs */}
      <div className="flex gap-1 mb-6 border-b border-zinc-800">
        <button
          onClick={() => setActiveTab('records')}
          className={`px-4 py-2 text-sm font-medium border-b-2 transition-colors ${
            activeTab === 'records'
              ? 'border-amber-500 text-amber-400'
              : 'border-transparent text-zinc-500 hover:text-zinc-300'
          }`}
        >
          {t('leave.leaveRecords')}
        </button>
        <button
          onClick={() => setActiveTab('types')}
          className={`px-4 py-2 text-sm font-medium border-b-2 transition-colors ${
            activeTab === 'types'
              ? 'border-amber-500 text-amber-400'
              : 'border-transparent text-zinc-500 hover:text-zinc-300'
          }`}
        >
          {t('leave.leaveTypes')}
        </button>
      </div>

      {activeTab === 'records' && (
        isLoading ? (
          <div className="flex items-center justify-center py-12">
            <div className="animate-spin rounded-full h-8 w-8 border-b-2 border-amber-500"></div>
          </div>
        ) : (
          <DataTable data={leaveRecords} columns={recordColumns} searchPlaceholder={`${t('common.search')}...`} />
        )
      )}

      {activeTab === 'types' && (
        <div>
          <div className="flex justify-end mb-4">
            <button
              onClick={() => setShowCreateType(true)}
              className="inline-flex items-center gap-2 px-4 py-2 text-sm font-semibold text-black bg-amber-500 rounded-lg hover:bg-amber-400 shadow-lg shadow-amber-500/20 transition-all"
            >
              <Plus className="w-4 h-4" />
              {t('leave.createLeaveType')}
            </button>
          </div>
          <DataTable data={leaveTypes} columns={typeColumns} />
        </div>
      )}

      {/* Create leave type modal */}
      {showCreateType && (
        <div className="fixed inset-0 z-50 flex items-center justify-center">
          <div className="fixed inset-0 bg-black/60 backdrop-blur-sm" onClick={() => setShowCreateType(false)} />
          <div className="relative bg-zinc-900 border border-zinc-800 rounded-xl shadow-xl max-w-md w-full mx-4 p-6">
            <div className="flex items-center justify-between mb-4">
              <h2 className="text-lg font-semibold text-white">{t('leave.createLeaveType')}</h2>
              <button onClick={() => setShowCreateType(false)} className="text-zinc-400 hover:text-white transition-colors">
                <X className="w-5 h-5" />
              </button>
            </div>
            <form onSubmit={handleSubmit((data) => createTypeMutation.mutate(data))} className="space-y-4">
              <div>
                <label className="block text-sm font-medium text-zinc-300">{t('leave.typeName')} *</label>
                <input {...register('name')} className={inputClasses} />
                {errors.name && <p className="mt-1 text-sm text-rose-400">{t('common.required')}</p>}
              </div>
              <div>
                <label className="block text-sm font-medium text-zinc-300">{t('leave.defaultDays')}</label>
                <input type="number" {...register('default_days_per_year')} className={inputClasses} />
              </div>
              <div className="flex items-center gap-2">
                <input type="checkbox" {...register('is_paid')} id="is_paid" className="h-4 w-4 rounded border-zinc-600 text-amber-500 focus:ring-amber-500/20 bg-zinc-800" />
                <label htmlFor="is_paid" className="text-sm font-medium text-zinc-300">{t('leave.isPaid')}</label>
              </div>
              <div className="flex justify-end gap-3 pt-2">
                <button type="button" onClick={() => setShowCreateType(false)} className="px-4 py-2 text-sm font-medium text-zinc-300 bg-zinc-800 border border-zinc-700 rounded-lg hover:bg-zinc-700 transition-colors">
                  {t('common.cancel')}
                </button>
                <button type="submit" disabled={createTypeMutation.isPending} className="px-4 py-2 text-sm font-semibold text-black bg-amber-500 rounded-lg hover:bg-amber-400 shadow-lg shadow-amber-500/20 disabled:opacity-50 transition-all">
                  {createTypeMutation.isPending ? t('common.loading') : t('common.create')}
                </button>
              </div>
            </form>
          </div>
        </div>
      )}
    </div>
  );
}
