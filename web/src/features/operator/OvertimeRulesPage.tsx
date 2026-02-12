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
import { OvertimeRule } from '../../types';
import { DataTable } from '../../components/shared/DataTable';
import { Plus, X, UserPlus } from 'lucide-react';

const ruleSchema = z.object({
  name: z.string().min(1),
  description: z.string().optional(),
  rule_type: z.enum(['daily_threshold', 'weekly_threshold', 'custom']),
  threshold_minutes: z.coerce.number().optional(),
  multiplier: z.coerce.number().min(1).max(10),
  priority: z.coerce.number().min(0),
});

type RuleFormData = z.infer<typeof ruleSchema>;

export function OvertimeRulesPage() {
  const { t } = useTranslation();
  const { profile } = useAuth();
  const companyId = profile?.company_id || undefined;
  const queryClient = useQueryClient();

  const [showCreateForm, setShowCreateForm] = useState(false);
  const [showAssignForm, setShowAssignForm] = useState(false);
  const [assignRuleId, setAssignRuleId] = useState('');
  const [assignEmployeeId, setAssignEmployeeId] = useState('');

  const { data: rules = [], isLoading } = useQuery({
    queryKey: ['overtime-rules', companyId],
    queryFn: async () => {
      const { data, error } = await supabase
        .from('overtime_rules')
        .select('*')
        .eq('company_id', companyId!)
        .order('priority', { ascending: false });
      if (error) throw error;
      return data as OvertimeRule[];
    },
    enabled: !!companyId,
  });

  const { data: employees = [] } = useEmployees(companyId);

  const {
    register,
    handleSubmit,
    reset,
    formState: { errors },
  } = useForm<RuleFormData>({
    resolver: zodResolver(ruleSchema),
    defaultValues: { rule_type: 'daily_threshold', multiplier: 1.5, priority: 0 },
  });

  const createMutation = useMutation({
    mutationFn: async (data: RuleFormData) => {
      const { error } = await supabase.from('overtime_rules').insert({
        company_id: companyId,
        name: data.name,
        description: data.description || null,
        rule_type: data.rule_type,
        threshold_minutes: data.threshold_minutes || null,
        multiplier: data.multiplier,
        priority: data.priority,
      });
      if (error) throw error;
    },
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['overtime-rules'] });
      setShowCreateForm(false);
      reset();
    },
  });

  const assignMutation = useMutation({
    mutationFn: async () => {
      const { error } = await supabase.from('employee_overtime_rules').insert({
        employee_id: assignEmployeeId,
        overtime_rule_id: assignRuleId,
      });
      if (error) throw error;
    },
    onSuccess: () => {
      setShowAssignForm(false);
      setAssignRuleId('');
      setAssignEmployeeId('');
    },
  });

  const ruleTypeLabels: Record<string, string> = {
    daily_threshold: t('overtimeRules.dailyThreshold'),
    weekly_threshold: t('overtimeRules.weeklyThreshold'),
    custom: t('overtimeRules.custom'),
  };

  const columns: ColumnDef<OvertimeRule, any>[] = [
    { accessorKey: 'name', header: t('overtimeRules.ruleName') },
    {
      accessorKey: 'rule_type',
      header: t('overtimeRules.ruleType'),
      cell: ({ getValue }) => ruleTypeLabels[getValue() as string] || getValue(),
    },
    {
      accessorKey: 'threshold_minutes',
      header: t('overtimeRules.thresholdMinutes'),
      cell: ({ getValue }) => {
        const val = getValue() as number;
        return val ? `${val} min` : '-';
      },
    },
    {
      accessorKey: 'multiplier',
      header: t('overtimeRules.multiplier'),
      cell: ({ getValue }) => `${getValue()}x`,
    },
    { accessorKey: 'priority', header: t('overtimeRules.priority') },
    {
      id: 'actions',
      header: t('common.actions'),
      cell: ({ row }) => (
        <button
          onClick={() => {
            setAssignRuleId(row.original.id);
            setShowAssignForm(true);
          }}
          className="inline-flex items-center gap-1 text-sm text-primary-600 hover:text-primary-700"
        >
          <UserPlus className="w-4 h-4" />
          {t('overtimeRules.assignRule')}
        </button>
      ),
      enableSorting: false,
    },
  ];

  return (
    <div>
      <div className="flex items-center justify-between mb-6">
        <h1 className="text-2xl font-bold text-gray-900">{t('overtimeRules.title')}</h1>
        <button
          onClick={() => setShowCreateForm(true)}
          className="inline-flex items-center gap-2 px-4 py-2 text-sm font-medium text-white bg-primary-600 rounded-md hover:bg-primary-700"
        >
          <Plus className="w-4 h-4" />
          {t('overtimeRules.createRule')}
        </button>
      </div>

      {/* Create rule modal */}
      {showCreateForm && (
        <div className="fixed inset-0 z-50 flex items-center justify-center">
          <div className="fixed inset-0 bg-black bg-opacity-50" onClick={() => setShowCreateForm(false)} />
          <div className="relative bg-white rounded-lg shadow-xl max-w-md w-full mx-4 p-6">
            <div className="flex items-center justify-between mb-4">
              <h2 className="text-lg font-semibold">{t('overtimeRules.createRule')}</h2>
              <button onClick={() => setShowCreateForm(false)}>
                <X className="w-5 h-5 text-gray-400" />
              </button>
            </div>
            <form onSubmit={handleSubmit((data) => createMutation.mutate(data))} className="space-y-4">
              <div>
                <label className="block text-sm font-medium text-gray-700">{t('overtimeRules.ruleName')} *</label>
                <input {...register('name')} className="mt-1 block w-full px-3 py-2 border border-gray-300 rounded-md shadow-sm focus:outline-none focus:ring-primary-500 focus:border-primary-500 text-sm" />
                {errors.name && <p className="mt-1 text-sm text-red-600">{t('common.required')}</p>}
              </div>
              <div>
                <label className="block text-sm font-medium text-gray-700">{t('common.description')}</label>
                <textarea {...register('description')} rows={2} className="mt-1 block w-full px-3 py-2 border border-gray-300 rounded-md shadow-sm focus:outline-none focus:ring-primary-500 focus:border-primary-500 text-sm" />
              </div>
              <div>
                <label className="block text-sm font-medium text-gray-700">{t('overtimeRules.ruleType')} *</label>
                <select {...register('rule_type')} className="mt-1 block w-full px-3 py-2 border border-gray-300 rounded-md shadow-sm focus:outline-none focus:ring-primary-500 focus:border-primary-500 text-sm">
                  <option value="daily_threshold">{t('overtimeRules.dailyThreshold')}</option>
                  <option value="weekly_threshold">{t('overtimeRules.weeklyThreshold')}</option>
                  <option value="custom">{t('overtimeRules.custom')}</option>
                </select>
              </div>
              <div className="grid grid-cols-3 gap-4">
                <div>
                  <label className="block text-sm font-medium text-gray-700">{t('overtimeRules.thresholdMinutes')}</label>
                  <input type="number" {...register('threshold_minutes')} className="mt-1 block w-full px-3 py-2 border border-gray-300 rounded-md shadow-sm focus:outline-none focus:ring-primary-500 focus:border-primary-500 text-sm" />
                </div>
                <div>
                  <label className="block text-sm font-medium text-gray-700">{t('overtimeRules.multiplier')} *</label>
                  <input type="number" step="0.1" {...register('multiplier')} className="mt-1 block w-full px-3 py-2 border border-gray-300 rounded-md shadow-sm focus:outline-none focus:ring-primary-500 focus:border-primary-500 text-sm" />
                </div>
                <div>
                  <label className="block text-sm font-medium text-gray-700">{t('overtimeRules.priority')}</label>
                  <input type="number" {...register('priority')} className="mt-1 block w-full px-3 py-2 border border-gray-300 rounded-md shadow-sm focus:outline-none focus:ring-primary-500 focus:border-primary-500 text-sm" />
                </div>
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

      {/* Assign rule modal */}
      {showAssignForm && (
        <div className="fixed inset-0 z-50 flex items-center justify-center">
          <div className="fixed inset-0 bg-black bg-opacity-50" onClick={() => setShowAssignForm(false)} />
          <div className="relative bg-white rounded-lg shadow-xl max-w-md w-full mx-4 p-6">
            <div className="flex items-center justify-between mb-4">
              <h2 className="text-lg font-semibold">{t('overtimeRules.assignRule')}</h2>
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
              <div className="flex justify-end gap-3 pt-2">
                <button onClick={() => setShowAssignForm(false)} className="px-4 py-2 text-sm font-medium text-gray-700 bg-white border border-gray-300 rounded-md hover:bg-gray-50">
                  {t('common.cancel')}
                </button>
                <button
                  onClick={() => assignMutation.mutate()}
                  disabled={!assignEmployeeId || assignMutation.isPending}
                  className="px-4 py-2 text-sm font-medium text-white bg-primary-600 rounded-md hover:bg-primary-700 disabled:opacity-50"
                >
                  {assignMutation.isPending ? t('common.loading') : t('overtimeRules.assignRule')}
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
        <DataTable data={rules} columns={columns} searchPlaceholder={`${t('common.search')}...`} />
      )}
    </div>
  );
}
