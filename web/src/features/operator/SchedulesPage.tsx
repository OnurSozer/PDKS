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
import { ShiftTemplate, EmployeeSchedule } from '../../types';
import { DataTable } from '../../components/shared/DataTable';
import { Plus, X, Calendar, Pencil, Trash2 } from 'lucide-react';

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

  // Edit template state
  const [editingTemplate, setEditingTemplate] = useState<ShiftTemplate | null>(null);

  // Edit schedule state
  const [editingSchedule, setEditingSchedule] = useState<EmployeeSchedule | null>(null);
  const [editEffectiveFrom, setEditEffectiveFrom] = useState('');
  const [editEffectiveTo, setEditEffectiveTo] = useState('');

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

  // Fetch all employee schedules
  const { data: employeeSchedules = [], isLoading: schedulesLoading } = useQuery({
    queryKey: ['employee-schedules', companyId],
    queryFn: async () => {
      const { data, error } = await supabase
        .from('employee_schedules')
        .select('*, shift_template:shift_templates(*)')
        .eq('company_id', companyId!)
        .order('effective_from', { ascending: false });
      if (error) throw error;
      return data as EmployeeSchedule[];
    },
    enabled: !!companyId,
  });

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

  const {
    register: registerEdit,
    handleSubmit: handleSubmitEdit,
    reset: resetEdit,
    watch: watchEdit,
    setValue: setValueEdit,
    formState: { errors: editErrors },
  } = useForm<TemplateFormData>({
    resolver: zodResolver(templateSchema),
  });

  const editWorkDays = watchEdit('work_days');

  const toggleEditDay = (day: number) => {
    const current = editWorkDays || [];
    const newDays = current.includes(day)
      ? current.filter((d) => d !== day)
      : [...current, day].sort();
    setValueEdit('work_days', newDays);
  };

  const openEditTemplate = (template: ShiftTemplate) => {
    setEditingTemplate(template);
    resetEdit({
      name: template.name,
      start_time: template.start_time?.substring(0, 5) || '',
      end_time: template.end_time?.substring(0, 5) || '',
      break_duration_minutes: template.break_duration_minutes || 0,
      work_days: template.work_days || [1, 2, 3, 4, 5],
    });
  };

  const updateTemplateMutation = useMutation({
    mutationFn: async (data: TemplateFormData) => {
      if (!editingTemplate) return;
      const { error } = await supabase
        .from('shift_templates')
        .update({
          name: data.name,
          start_time: data.start_time,
          end_time: data.end_time,
          break_duration_minutes: data.break_duration_minutes,
          work_days: data.work_days,
        })
        .eq('id', editingTemplate.id);
      if (error) throw error;
    },
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['shift-templates'] });
      queryClient.invalidateQueries({ queryKey: ['employee-schedules'] });
      setEditingTemplate(null);
    },
  });

  const deleteTemplateMutation = useMutation({
    mutationFn: async (id: string) => {
      const { error } = await supabase
        .from('shift_templates')
        .delete()
        .eq('id', id);
      if (error) throw error;
    },
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['shift-templates'] });
      queryClient.invalidateQueries({ queryKey: ['employee-schedules'] });
    },
  });

  const assignMutation = useMutation({
    mutationFn: async () => {
      const { data, error } = await supabase.functions.invoke('assign-schedule', {
        body: {
          employee_ids: [assignEmployeeId],
          shift_template_id: assignTemplateId,
          effective_from: assignEffectiveFrom,
        },
      });
      if (error) throw error;
      if (data?.errors?.length > 0) throw new Error(data.errors[0].error);
    },
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['employee-schedules'] });
      setShowAssignForm(false);
      setAssignTemplateId('');
      setAssignEmployeeId('');
    },
  });

  const editMutation = useMutation({
    mutationFn: async () => {
      if (!editingSchedule) return;
      const { data, error } = await supabase.functions.invoke('assign-schedule', {
        body: {
          action: 'update',
          schedule_id: editingSchedule.id,
          effective_from: editEffectiveFrom,
          effective_to: editEffectiveTo || null,
        },
      });
      if (error) throw error;
      if (data?.error) throw new Error(data.error);
    },
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['employee-schedules'] });
      setEditingSchedule(null);
    },
  });

  const openEditModal = (schedule: EmployeeSchedule) => {
    setEditingSchedule(schedule);
    setEditEffectiveFrom(schedule.effective_from);
    setEditEffectiveTo(schedule.effective_to || '');
  };

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

  // Build employee name lookup
  const employeeNameMap: Record<string, string> = {};
  for (const emp of employees) {
    employeeNameMap[emp.id] = `${emp.first_name} ${emp.last_name}`;
  }

  const inputClasses = "mt-1 block w-full px-3 py-2 bg-zinc-800 border border-zinc-700 rounded-lg text-white focus:outline-none focus:border-amber-500 focus:ring-1 focus:ring-amber-500/20 text-sm";

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
        <div className="flex items-center gap-2">
          <button
            onClick={() => {
              setAssignTemplateId(row.original.id);
              setShowAssignForm(true);
            }}
            title={t('schedules.assignSchedule')}
            className="p-1.5 text-amber-500 hover:text-amber-400 hover:bg-amber-500/10 rounded-lg transition-colors"
          >
            <Calendar className="w-4 h-4" />
          </button>
          <button
            onClick={() => openEditTemplate(row.original)}
            title={t('common.edit')}
            className="p-1.5 text-blue-400 hover:text-blue-300 hover:bg-blue-500/10 rounded-lg transition-colors"
          >
            <Pencil className="w-4 h-4" />
          </button>
          <button
            onClick={() => {
              if (window.confirm(t('schedules.deleteTemplateConfirm'))) {
                deleteTemplateMutation.mutate(row.original.id);
              }
            }}
            title={t('common.delete')}
            className="p-1.5 text-rose-400 hover:text-rose-300 hover:bg-rose-500/10 rounded-lg transition-colors"
          >
            <Trash2 className="w-4 h-4" />
          </button>
        </div>
      ),
      enableSorting: false,
    },
  ];

  const scheduleColumns: ColumnDef<EmployeeSchedule, any>[] = [
    {
      accessorKey: 'employee_id',
      header: t('schedules.employee'),
      cell: ({ getValue }) => employeeNameMap[getValue() as string] || getValue(),
    },
    {
      id: 'template_name',
      header: t('schedules.template'),
      cell: ({ row }) => row.original.shift_template?.name || t('schedules.customSchedule'),
    },
    {
      accessorKey: 'effective_from',
      header: t('schedules.effectiveFrom'),
    },
    {
      accessorKey: 'effective_to',
      header: t('schedules.effectiveTo'),
      cell: ({ getValue }) => {
        const val = getValue() as string | null;
        return val || (
          <span className="inline-flex items-center px-2 py-0.5 rounded-full text-xs font-medium bg-emerald-500/10 text-emerald-400 border border-emerald-500/20">
            {t('schedules.ongoing')}
          </span>
        );
      },
    },
    {
      id: 'work_days_display',
      header: t('schedules.workDays'),
      cell: ({ row }) => {
        const tmpl = row.original.shift_template;
        const days = tmpl?.work_days || row.original.custom_work_days || [];
        return days.map((d) => dayLabelsShort[d]).join(', ') || '-';
      },
    },
    {
      id: 'actions',
      header: t('common.actions'),
      cell: ({ row }) => (
        <button
          onClick={() => openEditModal(row.original)}
          className="inline-flex items-center gap-1 text-sm text-amber-500 hover:text-amber-400 transition-colors"
        >
          <Pencil className="w-3.5 h-3.5" />
          {t('common.edit')}
        </button>
      ),
      enableSorting: false,
    },
  ];

  return (
    <div>
      <div className="flex items-center justify-between mb-6">
        <h1 className="text-2xl font-bold font-display text-white">{t('schedules.title')}</h1>
        <button
          onClick={() => setShowCreateForm(true)}
          className="inline-flex items-center gap-2 px-4 py-2 text-sm font-semibold text-black bg-amber-500 rounded-lg hover:bg-amber-400 shadow-lg shadow-amber-500/20 transition-all"
        >
          <Plus className="w-4 h-4" />
          {t('schedules.createTemplate')}
        </button>
      </div>

      {/* Create template modal */}
      {showCreateForm && (
        <div className="fixed inset-0 z-50 flex items-center justify-center">
          <div className="fixed inset-0 bg-black/60 backdrop-blur-sm" onClick={() => setShowCreateForm(false)} />
          <div className="relative bg-zinc-900 border border-zinc-800 rounded-xl shadow-xl max-w-md w-full mx-4 p-6">
            <div className="flex items-center justify-between mb-4">
              <h2 className="text-lg font-semibold text-white">{t('schedules.createTemplate')}</h2>
              <button onClick={() => setShowCreateForm(false)} className="text-zinc-400 hover:text-white transition-colors">
                <X className="w-5 h-5" />
              </button>
            </div>
            <form onSubmit={handleSubmit((data) => createMutation.mutate(data))} className="space-y-4">
              <div>
                <label className="block text-sm font-medium text-zinc-300">{t('schedules.templateName')} *</label>
                <input {...register('name')} className={inputClasses} />
                {errors.name && <p className="mt-1 text-sm text-rose-400">{t('common.required')}</p>}
              </div>
              <div className="grid grid-cols-2 gap-4">
                <div>
                  <label className="block text-sm font-medium text-zinc-300">{t('schedules.startTime')} *</label>
                  <input type="time" {...register('start_time')} className={inputClasses} />
                </div>
                <div>
                  <label className="block text-sm font-medium text-zinc-300">{t('schedules.endTime')} *</label>
                  <input type="time" {...register('end_time')} className={inputClasses} />
                </div>
              </div>
              <div>
                <label className="block text-sm font-medium text-zinc-300">{t('schedules.breakDuration')}</label>
                <input type="number" {...register('break_duration_minutes')} className={inputClasses} />
              </div>
              <div>
                <label className="block text-sm font-medium text-zinc-300 mb-2">{t('schedules.workDays')} *</label>
                <div className="flex flex-wrap gap-2">
                  {DAY_OPTIONS.map((day) => (
                    <button
                      key={day.value}
                      type="button"
                      onClick={() => toggleDay(day.value)}
                      className={`px-3 py-1 text-sm rounded-lg border ${
                        workDays?.includes(day.value)
                          ? 'bg-amber-500/10 border-amber-500/30 text-amber-400'
                          : 'bg-zinc-800 border-zinc-700 text-zinc-400'
                      }`}
                    >
                      {t(day.labelKey)}
                    </button>
                  ))}
                </div>
                {errors.work_days && <p className="mt-1 text-sm text-rose-400">{t('common.required')}</p>}
              </div>
              <div className="flex justify-end gap-3 pt-2">
                <button type="button" onClick={() => setShowCreateForm(false)} className="px-4 py-2 text-sm font-medium text-zinc-300 bg-zinc-800 border border-zinc-700 rounded-lg hover:bg-zinc-700 transition-colors">
                  {t('common.cancel')}
                </button>
                <button type="submit" disabled={createMutation.isPending} className="px-4 py-2 text-sm font-semibold text-black bg-amber-500 rounded-lg hover:bg-amber-400 shadow-lg shadow-amber-500/20 disabled:opacity-50 transition-all">
                  {createMutation.isPending ? t('common.loading') : t('common.create')}
                </button>
              </div>
            </form>
          </div>
        </div>
      )}

      {/* Edit template modal */}
      {editingTemplate && (
        <div className="fixed inset-0 z-50 flex items-center justify-center">
          <div className="fixed inset-0 bg-black/60 backdrop-blur-sm" onClick={() => setEditingTemplate(null)} />
          <div className="relative bg-zinc-900 border border-zinc-800 rounded-xl shadow-xl max-w-md w-full mx-4 p-6">
            <div className="flex items-center justify-between mb-4">
              <h2 className="text-lg font-semibold text-white">{t('schedules.editTemplate')}</h2>
              <button onClick={() => setEditingTemplate(null)} className="text-zinc-400 hover:text-white transition-colors">
                <X className="w-5 h-5" />
              </button>
            </div>
            <form onSubmit={handleSubmitEdit((data) => updateTemplateMutation.mutate(data))} className="space-y-4">
              <div>
                <label className="block text-sm font-medium text-zinc-300">{t('schedules.templateName')} *</label>
                <input {...registerEdit('name')} className={inputClasses} />
                {editErrors.name && <p className="mt-1 text-sm text-rose-400">{t('common.required')}</p>}
              </div>
              <div className="grid grid-cols-2 gap-4">
                <div>
                  <label className="block text-sm font-medium text-zinc-300">{t('schedules.startTime')} *</label>
                  <input type="time" {...registerEdit('start_time')} className={inputClasses} />
                </div>
                <div>
                  <label className="block text-sm font-medium text-zinc-300">{t('schedules.endTime')} *</label>
                  <input type="time" {...registerEdit('end_time')} className={inputClasses} />
                </div>
              </div>
              <div>
                <label className="block text-sm font-medium text-zinc-300">{t('schedules.breakDuration')}</label>
                <input type="number" {...registerEdit('break_duration_minutes')} className={inputClasses} />
              </div>
              <div>
                <label className="block text-sm font-medium text-zinc-300 mb-2">{t('schedules.workDays')} *</label>
                <div className="flex flex-wrap gap-2">
                  {DAY_OPTIONS.map((day) => (
                    <button
                      key={day.value}
                      type="button"
                      onClick={() => toggleEditDay(day.value)}
                      className={`px-3 py-1 text-sm rounded-lg border ${
                        editWorkDays?.includes(day.value)
                          ? 'bg-amber-500/10 border-amber-500/30 text-amber-400'
                          : 'bg-zinc-800 border-zinc-700 text-zinc-400'
                      }`}
                    >
                      {t(day.labelKey)}
                    </button>
                  ))}
                </div>
                {editErrors.work_days && <p className="mt-1 text-sm text-rose-400">{t('common.required')}</p>}
              </div>
              <div className="flex justify-end gap-3 pt-2">
                <button type="button" onClick={() => setEditingTemplate(null)} className="px-4 py-2 text-sm font-medium text-zinc-300 bg-zinc-800 border border-zinc-700 rounded-lg hover:bg-zinc-700 transition-colors">
                  {t('common.cancel')}
                </button>
                <button type="submit" disabled={updateTemplateMutation.isPending} className="px-4 py-2 text-sm font-semibold text-black bg-amber-500 rounded-lg hover:bg-amber-400 shadow-lg shadow-amber-500/20 disabled:opacity-50 transition-all">
                  {updateTemplateMutation.isPending ? t('common.loading') : t('common.save')}
                </button>
              </div>
            </form>
          </div>
        </div>
      )}

      {/* Assign schedule modal */}
      {showAssignForm && (
        <div className="fixed inset-0 z-50 flex items-center justify-center">
          <div className="fixed inset-0 bg-black/60 backdrop-blur-sm" onClick={() => setShowAssignForm(false)} />
          <div className="relative bg-zinc-900 border border-zinc-800 rounded-xl shadow-xl max-w-md w-full mx-4 p-6">
            <div className="flex items-center justify-between mb-4">
              <h2 className="text-lg font-semibold text-white">{t('schedules.assignSchedule')}</h2>
              <button onClick={() => setShowAssignForm(false)} className="text-zinc-400 hover:text-white transition-colors">
                <X className="w-5 h-5" />
              </button>
            </div>
            <div className="space-y-4">
              <div>
                <label className="block text-sm font-medium text-zinc-300">{t('schedules.employee')} *</label>
                <select
                  value={assignEmployeeId}
                  onChange={(e) => setAssignEmployeeId(e.target.value)}
                  className={inputClasses}
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
                <label className="block text-sm font-medium text-zinc-300">{t('schedules.effectiveFrom')} *</label>
                <input
                  type="date"
                  value={assignEffectiveFrom}
                  onChange={(e) => setAssignEffectiveFrom(e.target.value)}
                  className={inputClasses}
                />
              </div>
              <div className="flex justify-end gap-3 pt-2">
                <button onClick={() => setShowAssignForm(false)} className="px-4 py-2 text-sm font-medium text-zinc-300 bg-zinc-800 border border-zinc-700 rounded-lg hover:bg-zinc-700 transition-colors">
                  {t('common.cancel')}
                </button>
                <button
                  onClick={() => assignMutation.mutate()}
                  disabled={!assignEmployeeId || assignMutation.isPending}
                  className="px-4 py-2 text-sm font-semibold text-black bg-amber-500 rounded-lg hover:bg-amber-400 shadow-lg shadow-amber-500/20 disabled:opacity-50 transition-all"
                >
                  {assignMutation.isPending ? t('common.loading') : t('schedules.assignSchedule')}
                </button>
              </div>
            </div>
          </div>
        </div>
      )}

      {/* Edit schedule modal */}
      {editingSchedule && (
        <div className="fixed inset-0 z-50 flex items-center justify-center">
          <div className="fixed inset-0 bg-black/60 backdrop-blur-sm" onClick={() => setEditingSchedule(null)} />
          <div className="relative bg-zinc-900 border border-zinc-800 rounded-xl shadow-xl max-w-md w-full mx-4 p-6">
            <div className="flex items-center justify-between mb-4">
              <h2 className="text-lg font-semibold text-white">{t('schedules.editSchedule')}</h2>
              <button onClick={() => setEditingSchedule(null)} className="text-zinc-400 hover:text-white transition-colors">
                <X className="w-5 h-5" />
              </button>
            </div>
            <div className="space-y-4">
              {/* Employee name (read-only) */}
              <div>
                <label className="block text-sm font-medium text-zinc-300">{t('schedules.employee')}</label>
                <p className="mt-1 px-3 py-2 bg-zinc-800/50 border border-zinc-700/50 rounded-lg text-zinc-400 text-sm">
                  {employeeNameMap[editingSchedule.employee_id] || editingSchedule.employee_id}
                </p>
              </div>
              {/* Template name (read-only) */}
              <div>
                <label className="block text-sm font-medium text-zinc-300">{t('schedules.template')}</label>
                <p className="mt-1 px-3 py-2 bg-zinc-800/50 border border-zinc-700/50 rounded-lg text-zinc-400 text-sm">
                  {editingSchedule.shift_template?.name || t('schedules.customSchedule')}
                </p>
              </div>
              <div className="grid grid-cols-2 gap-4">
                <div>
                  <label className="block text-sm font-medium text-zinc-300">{t('schedules.effectiveFrom')} *</label>
                  <input
                    type="date"
                    value={editEffectiveFrom}
                    onChange={(e) => setEditEffectiveFrom(e.target.value)}
                    className={inputClasses}
                  />
                </div>
                <div>
                  <label className="block text-sm font-medium text-zinc-300">{t('schedules.effectiveTo')}</label>
                  <input
                    type="date"
                    value={editEffectiveTo}
                    onChange={(e) => setEditEffectiveTo(e.target.value)}
                    className={inputClasses}
                  />
                  {!editEffectiveTo && (
                    <p className="mt-1 text-xs text-emerald-400">{t('schedules.ongoing')}</p>
                  )}
                </div>
              </div>
              <div className="flex justify-end gap-3 pt-2">
                <button onClick={() => setEditingSchedule(null)} className="px-4 py-2 text-sm font-medium text-zinc-300 bg-zinc-800 border border-zinc-700 rounded-lg hover:bg-zinc-700 transition-colors">
                  {t('common.cancel')}
                </button>
                <button
                  onClick={() => editMutation.mutate()}
                  disabled={editMutation.isPending}
                  className="px-4 py-2 text-sm font-semibold text-black bg-amber-500 rounded-lg hover:bg-amber-400 shadow-lg shadow-amber-500/20 disabled:opacity-50 transition-all"
                >
                  {editMutation.isPending ? t('common.loading') : t('common.save')}
                </button>
              </div>
            </div>
          </div>
        </div>
      )}

      {/* Shift Templates table */}
      {isLoading ? (
        <div className="flex items-center justify-center py-12">
          <div className="animate-spin rounded-full h-8 w-8 border-b-2 border-amber-500"></div>
        </div>
      ) : (
        <DataTable data={templates} columns={columns} searchPlaceholder={`${t('common.search')}...`} />
      )}

      {/* Employee Schedules table */}
      <div className="mt-10">
        <h2 className="text-xl font-bold font-display text-white mb-4">{t('schedules.employeeSchedules')}</h2>
        {schedulesLoading ? (
          <div className="flex items-center justify-center py-12">
            <div className="animate-spin rounded-full h-8 w-8 border-b-2 border-amber-500"></div>
          </div>
        ) : employeeSchedules.length === 0 ? (
          <p className="text-zinc-500 text-sm py-8 text-center">{t('schedules.noSchedules')}</p>
        ) : (
          <DataTable data={employeeSchedules} columns={scheduleColumns} searchPlaceholder={`${t('common.search')}...`} />
        )}
      </div>
    </div>
  );
}
