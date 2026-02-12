import React, { useState } from 'react';
import { useTranslation } from 'react-i18next';
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import { useForm } from 'react-hook-form';
import { zodResolver } from '@hookform/resolvers/zod';
import { z } from 'zod';
import { ColumnDef } from '@tanstack/react-table';
import { supabase } from '../../lib/supabase';
import { useAuth } from '../../hooks/useAuth';
import { useEmployees } from '../../hooks/useEmployees';
import { ShiftTemplate } from '../../types';
import { DataTable } from '../../components/shared/DataTable';
import { Plus, X, Calendar } from 'lucide-react';

const DAY_OPTIONS = [
  { value: 1, labelKey: 'days.monday' },
  { value: 2, labelKey: 'days.tuesday' },
  { value: 3, labelKey: 'days.wednesday' },
  { value: 4, labelKey: 'days.thursday' },
  { value: 5, labelKey: 'days.friday' },
  { value: 6, labelKey: 'days.saturday' },
  { value: 7, labelKey: 'days.sunday' },
];

const templateSchema = z.object({
  name: z.string().min(1),
  start_time: z.string().min(1),
  end_time: z.string().min(1),
  break_duration_minutes: z.coerce.number().min(0),
  work_days: z.array(z.number()).min(1),
});

type TemplateFormData = z.infer<typeof templateSchema>;

export function SchedulesPage() {
  const { t } = useTranslation();
  const { profile } = useAuth();
  const companyId = profile?.company_id || undefined;
  const queryClient = useQueryClient();

  const [showCreateForm, setShowCreateForm] = useState(false);
  const [showAssignForm, setShowAssignForm] = useState(false);
  const [assignTemplateId, setAssignTemplateId] = useState('');
  const [assignEmployeeId, setAssignEmployeeId] = useState('');
  const [assignEffectiveFrom, setAssignEffectiveFrom] = useState(new Date().toISOString().split('T')[0]);

  const { data: templates = [], isLoading } = useQuery({
    queryKey: ['shift-templates', companyId],
    queryFn: async () => {
      const { data, error } = await supabase
        .from('shift_templates')
        .select('*')
        .eq('company_id', companyId!)
        .order('name');
      if (error) throw error;
      return data as ShiftTemplate[];
    },
    enabled: !!companyId,
  });

  const { data: employees = [] } = useEmployees(companyId);

  const {
    register,
    handleSubmit,
    reset,
    watch,
    setValue,
    formState: { errors },
  } = useForm<TemplateFormData>({
    resolver: zodResolver(templateSchema),
    defaultValues: { work_days: [1, 2, 3, 4, 5], break_duration_minutes: 60 },
  });

  const workDays = watch('work_days');

  const createMutation = useMutation({
    mutationFn: async (data: TemplateFormData) => {
      const { error } = await supabase.from('shift_templates').insert({
        company_id: companyId,
        name: data.name,
        start_time: data.start_time,
        end_time: data.end_time,
        break_duration_minutes: data.break_duration_minutes,
        work_days: data.work_days,
      });
      if (error) throw error;
    },
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['shift-templates'] });
      setShowCreateForm(false);
      reset();
    },
  });

  const assignMutation = useMutation({
    mutationFn: async () => {
      const { error } = await supabase.from('employee_schedules').insert({
        employee_id: assignEmployeeId,
        company_id: companyId,
        shift_template_id: assignTemplateId,
        effective_from: assignEffectiveFrom,
      });
      if (error) throw error;
    },
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['employee-schedules'] });
      setShowAssignForm(false);
      setAssignTemplateId('');
      setAssignEmployeeId('');
    },
  });

  const toggleDay = (day: number) => {
    const current = workDays || [];
    const newDays = current.includes(day)
      ? current.filter((d) => d !== day)
      : [...current, day].sort();
    setValue('work_days', newDays);
  };

  const dayLabelsShort: Record<number, string> = {
    1: t('days.mondayShort'),
    2: t('days.tuesdayShort'),
    3: t('days.wednesdayShort'),
    4: t('days.thursdayShort'),
    5: t('days.fridayShort'),
    6: t('days.saturdayShort'),
    7: t('days.sundayShort'),
  };

  const columns: ColumnDef<ShiftTemplate, any>[] = [
    { accessorKey: 'name', header: t('schedules.templateName') },
    { accessorKey: 'start_time', header: t('schedules.startTime') },
    { accessorKey: 'end_time', header: t('schedules.endTime') },
    {
      accessorKey: 'break_duration_minutes',
      header: t('schedules.breakDuration'),
      cell: ({ getValue }) => `${getValue()} min`,
    },
    {
      accessorKey: 'work_days',
      header: t('schedules.workDays'),
      cell: ({ getValue }) => {
        const days = getValue() as number[];
        return days?.map((d) => dayLabelsShort[d]).join(', ') || '-';
      },
    },
    {
      id: 'actions',
      header: t('common.actions'),
      cell: ({ row }) => (
        <button
          onClick={() => {
            setAssignTemplateId(row.original.id);
            setShowAssignForm(true);
          }}
          className="inline-flex items-center gap-1 text-sm text-primary-600 hover:text-primary-700"
        >
          <Calendar className="w-4 h-4" />
          {t('schedules.assignSchedule')}
        </button>
      ),
      enableSorting: false,
    },
  ];

  return (
    <div>
      <div className="flex items-center justify-between mb-6">
        <h1 className="text-2xl font-bold text-gray-900">{t('schedules.title')}</h1>
        <button
          onClick={() => setShowCreateForm(true)}
          className="inline-flex items-center gap-2 px-4 py-2 text-sm font-medium text-white bg-primary-600 rounded-md hover:bg-primary-700"
        >
          <Plus className="w-4 h-4" />
          {t('schedules.createTemplate')}
        </button>
      </div>

      {/* Create template modal */}
      {showCreateForm && (
        <div className="fixed inset-0 z-50 flex items-center justify-center">
          <div className="fixed inset-0 bg-black bg-opacity-50" onClick={() => setShowCreateForm(false)} />
          <div className="relative bg-white rounded-lg shadow-xl max-w-md w-full mx-4 p-6">
            <div className="flex items-center justify-between mb-4">
              <h2 className="text-lg font-semibold">{t('schedules.createTemplate')}</h2>
              <button onClick={() => setShowCreateForm(false)}>
                <X className="w-5 h-5 text-gray-400" />
              </button>
            </div>
            <form onSubmit={handleSubmit((data) => createMutation.mutate(data))} className="space-y-4">
              <div>
                <label className="block text-sm font-medium text-gray-700">{t('schedules.templateName')} *</label>
                <input {...register('name')} className="mt-1 block w-full px-3 py-2 border border-gray-300 rounded-md shadow-sm focus:outline-none focus:ring-primary-500 focus:border-primary-500 text-sm" />
                {errors.name && <p className="mt-1 text-sm text-red-600">{t('common.required')}</p>}
              </div>
              <div className="grid grid-cols-2 gap-4">
                <div>
                  <label className="block text-sm font-medium text-gray-700">{t('schedules.startTime')} *</label>
                  <input type="time" {...register('start_time')} className="mt-1 block w-full px-3 py-2 border border-gray-300 rounded-md shadow-sm focus:outline-none focus:ring-primary-500 focus:border-primary-500 text-sm" />
                </div>
                <div>
                  <label className="block text-sm font-medium text-gray-700">{t('schedules.endTime')} *</label>
                  <input type="time" {...register('end_time')} className="mt-1 block w-full px-3 py-2 border border-gray-300 rounded-md shadow-sm focus:outline-none focus:ring-primary-500 focus:border-primary-500 text-sm" />
                </div>
              </div>
              <div>
                <label className="block text-sm font-medium text-gray-700">{t('schedules.breakDuration')}</label>
                <input type="number" {...register('break_duration_minutes')} className="mt-1 block w-full px-3 py-2 border border-gray-300 rounded-md shadow-sm focus:outline-none focus:ring-primary-500 focus:border-primary-500 text-sm" />
              </div>
              <div>
                <label className="block text-sm font-medium text-gray-700 mb-2">{t('schedules.workDays')} *</label>
                <div className="flex flex-wrap gap-2">
                  {DAY_OPTIONS.map((day) => (
                    <button
                      key={day.value}
                      type="button"
                      onClick={() => toggleDay(day.value)}
                      className={`px-3 py-1 text-sm rounded-md border ${
                        workDays?.includes(day.value)
                          ? 'bg-primary-100 border-primary-300 text-primary-700'
                          : 'bg-white border-gray-300 text-gray-600'
                      }`}
                    >
                      {t(day.labelKey)}
                    </button>
                  ))}
                </div>
                {errors.work_days && <p className="mt-1 text-sm text-red-600">{t('common.required')}</p>}
              </div>
              <div className="flex justify-end gap-3 pt-2">
                <button type="button" onClick={() => setShowCreateForm(false)} className="px-4 py-2 text-sm font-medium text-gray-700 bg-white border border-gray-300 rounded-md hover:bg-gray-50">
                  {t('common.cancel')}
                </button>
                <button type="submit" disabled={createMutation.isPending} className="px-4 py-2 text-sm font-medium text-white bg-primary-600 rounded-md hover:bg-primary-700 disabled:opacity-50">
                  {createMutation.isPending ? t('common.loading') : t('common.create')}
                </button>
              </div>
            </form>
          </div>
        </div>
      )}

      {/* Assign schedule modal */}
      {showAssignForm && (
        <div className="fixed inset-0 z-50 flex items-center justify-center">
          <div className="fixed inset-0 bg-black bg-opacity-50" onClick={() => setShowAssignForm(false)} />
          <div className="relative bg-white rounded-lg shadow-xl max-w-md w-full mx-4 p-6">
            <div className="flex items-center justify-between mb-4">
              <h2 className="text-lg font-semibold">{t('schedules.assignSchedule')}</h2>
              <button onClick={() => setShowAssignForm(false)}>
                <X className="w-5 h-5 text-gray-400" />
              </button>
            </div>
            <div className="space-y-4">
              <div>
                <label className="block text-sm font-medium text-gray-700">{t('sessions.employee')} *</label>
                <select
                  value={assignEmployeeId}
                  onChange={(e) => setAssignEmployeeId(e.target.value)}
                  className="mt-1 block w-full px-3 py-2 border border-gray-300 rounded-md shadow-sm focus:outline-none focus:ring-primary-500 focus:border-primary-500 text-sm"
                >
                  <option value="">{t('common.select')}...</option>
                  {employees.map((emp) => (
                    <option key={emp.id} value={emp.id}>
                      {emp.first_name} {emp.last_name}
                    </option>
                  ))}
                </select>
              </div>
              <div>
                <label className="block text-sm font-medium text-gray-700">{t('schedules.effectiveFrom')} *</label>
                <input
                  type="date"
                  value={assignEffectiveFrom}
                  onChange={(e) => setAssignEffectiveFrom(e.target.value)}
                  className="mt-1 block w-full px-3 py-2 border border-gray-300 rounded-md shadow-sm focus:outline-none focus:ring-primary-500 focus:border-primary-500 text-sm"
                />
              </div>
              <div className="flex justify-end gap-3 pt-2">
                <button onClick={() => setShowAssignForm(false)} className="px-4 py-2 text-sm font-medium text-gray-700 bg-white border border-gray-300 rounded-md hover:bg-gray-50">
                  {t('common.cancel')}
                </button>
                <button
                  onClick={() => assignMutation.mutate()}
                  disabled={!assignEmployeeId || assignMutation.isPending}
                  className="px-4 py-2 text-sm font-medium text-white bg-primary-600 rounded-md hover:bg-primary-700 disabled:opacity-50"
                >
                  {assignMutation.isPending ? t('common.loading') : t('schedules.assignSchedule')}
                </button>
              </div>
            </div>
          </div>
        </div>
      )}

      {isLoading ? (
        <div className="flex items-center justify-center py-12">
          <div className="animate-spin rounded-full h-8 w-8 border-b-2 border-primary-600"></div>
        </div>
      ) : (
        <DataTable data={templates} columns={columns} searchPlaceholder={`${t('common.search')}...`} />
      )}
    </div>
  );
}
