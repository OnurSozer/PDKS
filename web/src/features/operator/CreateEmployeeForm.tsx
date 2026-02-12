import React, { useState } from 'react';
import { useTranslation } from 'react-i18next';
import { useNavigate, Link } from 'react-router-dom';
import { useForm } from 'react-hook-form';
import { zodResolver } from '@hookform/resolvers/zod';
import { z } from 'zod';
import { useCreateEmployee } from '../../hooks/useEmployees';
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
    createEmployee.mutate(
      {
        email: data.email,
        password: data.password,
        first_name: data.first_name,
        last_name: data.last_name,
        phone: data.phone || undefined,
        start_date: data.start_date || undefined,
        role: data.role,
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
