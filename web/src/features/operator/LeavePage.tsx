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

  // Leave types
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

  // Leave records
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
              status === 'active' ? 'bg-green-100 text-green-700' : 'bg-red-100 text-red-700'
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
            getValue() ? 'bg-green-100 text-green-700' : 'bg-gray-100 text-gray-700'
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
            getValue() ? 'bg-green-100 text-green-700' : 'bg-red-100 text-red-700'
          }`}
        >
          {getValue() ? t('common.active') : t('common.inactive')}
        </span>
      ),
    },
  ];

  return (
    <div>
      <h1 className="text-2xl font-bold text-gray-900 mb-6">{t('leave.title')}</h1>

      {/* Tabs */}
      <div className="flex gap-1 mb-6 border-b border-gray-200">
        <button
          onClick={() => setActiveTab('records')}
          className={`px-4 py-2 text-sm font-medium border-b-2 transition-colors ${
            activeTab === 'records'
              ? 'border-primary-600 text-primary-600'
              : 'border-transparent text-gray-500 hover:text-gray-700'
          }`}
        >
          {t('leave.leaveRecords')}
        </button>
        <button
          onClick={() => setActiveTab('types')}
          className={`px-4 py-2 text-sm font-medium border-b-2 transition-colors ${
            activeTab === 'types'
              ? 'border-primary-600 text-primary-600'
              : 'border-transparent text-gray-500 hover:text-gray-700'
          }`}
        >
          {t('leave.leaveTypes')}
        </button>
      </div>

      {activeTab === 'records' && (
        isLoading ? (
          <div className="flex items-center justify-center py-12">
            <div className="animate-spin rounded-full h-8 w-8 border-b-2 border-primary-600"></div>
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
              className="inline-flex items-center gap-2 px-4 py-2 text-sm font-medium text-white bg-primary-600 rounded-md hover:bg-primary-700"
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
          <div className="fixed inset-0 bg-black bg-opacity-50" onClick={() => setShowCreateType(false)} />
          <div className="relative bg-white rounded-lg shadow-xl max-w-md w-full mx-4 p-6">
            <div className="flex items-center justify-between mb-4">
              <h2 className="text-lg font-semibold">{t('leave.createLeaveType')}</h2>
              <button onClick={() => setShowCreateType(false)}>
                <X className="w-5 h-5 text-gray-400" />
              </button>
            </div>
            <form onSubmit={handleSubmit((data) => createTypeMutation.mutate(data))} className="space-y-4">
              <div>
                <label className="block text-sm font-medium text-gray-700">{t('leave.typeName')} *</label>
                <input {...register('name')} className="mt-1 block w-full px-3 py-2 border border-gray-300 rounded-md shadow-sm focus:outline-none focus:ring-primary-500 focus:border-primary-500 text-sm" />
                {errors.name && <p className="mt-1 text-sm text-red-600">{t('common.required')}</p>}
              </div>
              <div>
                <label className="block text-sm font-medium text-gray-700">{t('leave.defaultDays')}</label>
                <input type="number" {...register('default_days_per_year')} className="mt-1 block w-full px-3 py-2 border border-gray-300 rounded-md shadow-sm focus:outline-none focus:ring-primary-500 focus:border-primary-500 text-sm" />
              </div>
              <div className="flex items-center gap-2">
                <input type="checkbox" {...register('is_paid')} id="is_paid" className="h-4 w-4 rounded border-gray-300 text-primary-600 focus:ring-primary-500" />
                <label htmlFor="is_paid" className="text-sm font-medium text-gray-700">{t('leave.isPaid')}</label>
              </div>
              <div className="flex justify-end gap-3 pt-2">
                <button type="button" onClick={() => setShowCreateType(false)} className="px-4 py-2 text-sm font-medium text-gray-700 bg-white border border-gray-300 rounded-md hover:bg-gray-50">
                  {t('common.cancel')}
                </button>
                <button type="submit" disabled={createTypeMutation.isPending} className="px-4 py-2 text-sm font-medium text-white bg-primary-600 rounded-md hover:bg-primary-700 disabled:opacity-50">
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
