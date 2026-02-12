import React, { useState } from 'react';
import { useTranslation } from 'react-i18next';
import { useNavigate, Link } from 'react-router-dom';
import { useForm } from 'react-hook-form';
import { zodResolver } from '@hookform/resolvers/zod';
import { z } from 'zod';
import { useQuery } from '@tanstack/react-query';
import { useCreateEmployee } from '../../hooks/useEmployees';
import { useAuth } from '../../hooks/useAuth';
import { supabase } from '../../lib/supabase';
import { LeaveType } from '../../types';
import { ArrowLeft } from 'lucide-react';

const schema = z.object({
  email: z.string().email(),
  password: z.string().min(6),
  first_name: z.string().min(1),
  last_name: z.string().min(1),
  phone: z.string().optional(),
  start_date: z.string().optional(),
  role: z.enum(['employee', 'chef']),
});

type FormData = z.infer<typeof schema>;

export function CreateEmployeeForm() {
  const { t } = useTranslation();
  const navigate = useNavigate();
  const [error, setError] = useState('');
  const createEmployee = useCreateEmployee();
  const { profile } = useAuth();
  const companyId = profile?.company_id || undefined;

  const [leaveEntitlements, setLeaveEntitlements] = useState<Record<string, number>>({});
  const [leaveBalances, setLeaveBalances] = useState<Record<string, number>>({});

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

  // Initialize defaults when leave types load
  React.useEffect(() => {
    if (leaveTypes.length > 0 && Object.keys(leaveEntitlements).length === 0) {
      const entDefaults: Record<string, number> = {};
      const balDefaults: Record<string, number> = {};
      leaveTypes.forEach((lt) => {
        const days = lt.default_days_per_year || 0;
        entDefaults[lt.id] = days;
        balDefaults[lt.id] = days;
      });
      setLeaveEntitlements(entDefaults);
      setLeaveBalances(balDefaults);
    }
  // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [leaveTypes]);

  const {
    register,
    handleSubmit,
    formState: { errors },
  } = useForm<FormData>({
    resolver: zodResolver(schema),
    defaultValues: { role: 'employee' },
  });

  const onSubmit = (data: FormData) => {
    setError('');

    const leave_entitlements = Object.entries(leaveEntitlements)
      .filter(([, days]) => days > 0)
      .map(([leave_type_id, days_per_year]) => ({ leave_type_id, days_per_year }));

    const leave_balances = Object.entries(leaveBalances)
      .filter(([, days]) => days > 0)
      .map(([leave_type_id, total_days]) => ({ leave_type_id, total_days }));

    createEmployee.mutate(
      {
        email: data.email,
        password: data.password,
        first_name: data.first_name,
        last_name: data.last_name,
        phone: data.phone || undefined,
        start_date: data.start_date || undefined,
        role: data.role,
        leave_entitlements: leave_entitlements.length > 0 ? leave_entitlements : undefined,
        leave_balances: leave_balances.length > 0 ? leave_balances : undefined,
      },
      {
        onSuccess: () => navigate('/operator/employees'),
        onError: (err: any) => setError(err.message || t('common.error')),
      }
    );
  };

  const inputClasses = "mt-1 block w-full px-3 py-2 bg-zinc-800 border border-zinc-700 rounded-lg text-white placeholder-zinc-500 focus:outline-none focus:border-amber-500 focus:ring-1 focus:ring-amber-500/20 text-sm";

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
        {t('employees.createEmployee')}
      </h1>

      {error && (
        <div className="mb-4 bg-rose-500/10 border border-rose-500/20 text-rose-400 px-4 py-3 rounded-lg text-sm">
          {error}
        </div>
      )}

      <form onSubmit={handleSubmit(onSubmit)} className="max-w-2xl">
        <div className="bg-zinc-900/80 backdrop-blur-sm rounded-xl border border-zinc-800 p-6 space-y-4">
          <div className="grid grid-cols-2 gap-4">
            <div>
              <label className="block text-sm font-medium text-zinc-300">
                {t('employees.firstName')} *
              </label>
              <input {...register('first_name')} className={inputClasses} />
              {errors.first_name && (
                <p className="mt-1 text-sm text-rose-400">{t('common.required')}</p>
              )}
            </div>
            <div>
              <label className="block text-sm font-medium text-zinc-300">
                {t('employees.lastName')} *
              </label>
              <input {...register('last_name')} className={inputClasses} />
              {errors.last_name && (
                <p className="mt-1 text-sm text-rose-400">{t('common.required')}</p>
              )}
            </div>
          </div>

          <div>
            <label className="block text-sm font-medium text-zinc-300">
              {t('employees.email')} *
            </label>
            <input {...register('email')} type="email" className={inputClasses} />
            {errors.email && (
              <p className="mt-1 text-sm text-rose-400">{t('common.required')}</p>
            )}
          </div>

          <div>
            <label className="block text-sm font-medium text-zinc-300">
              {t('employees.password')} *
            </label>
            <input {...register('password')} type="password" className={inputClasses} />
            {errors.password && (
              <p className="mt-1 text-sm text-rose-400">{t('common.required')}</p>
            )}
          </div>

          <div className="grid grid-cols-2 gap-4">
            <div>
              <label className="block text-sm font-medium text-zinc-300">
                {t('employees.phone')}
              </label>
              <input {...register('phone')} className={inputClasses} />
            </div>
            <div>
              <label className="block text-sm font-medium text-zinc-300">
                {t('employees.startDate')}
              </label>
              <input {...register('start_date')} type="date" className={inputClasses} />
            </div>
          </div>

          <div>
            <label className="block text-sm font-medium text-zinc-300">
              {t('employees.role')} *
            </label>
            <select {...register('role')} className={inputClasses}>
              <option value="employee">{t('employees.roleEmployee')}</option>
              <option value="chef">{t('employees.roleChef')}</option>
            </select>
          </div>
        </div>

        {leaveTypes.length > 0 && (
          <div className="mt-4 bg-zinc-900/80 backdrop-blur-sm rounded-xl border border-zinc-800 p-6 space-y-4">
            <h2 className="text-lg font-semibold text-white">
              {t('employees.initialLeaveBalances')}
            </h2>
            <div className="space-y-3">
              {leaveTypes.map((lt) => (
                <div key={lt.id} className="flex items-center gap-3">
                  <label className="text-sm text-zinc-300 w-48 shrink-0">
                    {lt.name}
                  </label>
                  <div className="flex items-center gap-2">
                    <div>
                      <span className="text-xs text-zinc-500 block mb-1">
                        {t('employees.yearlyEntitlement')}
                      </span>
                      <div className="flex items-center gap-1">
                        <input
                          type="number"
                          min={0}
                          step="0.5"
                          value={leaveEntitlements[lt.id] ?? lt.default_days_per_year ?? 0}
                          onChange={(e) =>
                            setLeaveEntitlements((prev) => ({
                              ...prev,
                              [lt.id]: Number(e.target.value) || 0,
                            }))
                          }
                          className={inputClasses + ' w-24'}
                        />
                        <span className="text-xs text-zinc-500">{t('employees.daysPerYear')}</span>
                      </div>
                    </div>
                    <div>
                      <span className="text-xs text-zinc-500 block mb-1">
                        {t('employees.initialBalance')}
                      </span>
                      <div className="flex items-center gap-1">
                        <input
                          type="number"
                          min={0}
                          step="0.5"
                          value={leaveBalances[lt.id] ?? lt.default_days_per_year ?? 0}
                          onChange={(e) =>
                            setLeaveBalances((prev) => ({
                              ...prev,
                              [lt.id]: Number(e.target.value) || 0,
                            }))
                          }
                          className={inputClasses + ' w-24'}
                        />
                        <span className="text-xs text-zinc-500">{t('employees.days')}</span>
                      </div>
                    </div>
                  </div>
                </div>
              ))}
            </div>
          </div>
        )}

        <div className="mt-6 flex justify-end gap-3">
          <Link
            to="/operator/employees"
            className="px-4 py-2 text-sm font-medium text-zinc-300 bg-zinc-800 border border-zinc-700 rounded-lg hover:bg-zinc-700 transition-colors"
          >
            {t('common.cancel')}
          </Link>
          <button
            type="submit"
            disabled={createEmployee.isPending}
            className="px-4 py-2 text-sm font-semibold text-black bg-amber-500 rounded-lg hover:bg-amber-400 shadow-lg shadow-amber-500/20 disabled:opacity-50 transition-all"
          >
            {createEmployee.isPending ? t('common.loading') : t('common.create')}
          </button>
        </div>
      </form>
    </div>
  );
}
