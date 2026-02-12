import React, { useState } from 'react';
import { useTranslation } from 'react-i18next';
import { useNavigate, Link } from 'react-router-dom';
import { useForm } from 'react-hook-form';
import { zodResolver } from '@hookform/resolvers/zod';
import { z } from 'zod';
import { useMutation, useQueryClient } from '@tanstack/react-query';
import { supabase } from '../../lib/supabase';
import { ArrowLeft } from 'lucide-react';

const schema = z.object({
  companyName: z.string().min(1),
  companyAddress: z.string().optional(),
  companyPhone: z.string().optional(),
  companyEmail: z.string().email().optional().or(z.literal('')),
  operatorEmail: z.string().email(),
  operatorPassword: z.string().min(6),
  operatorFirstName: z.string().min(1),
  operatorLastName: z.string().min(1),
  operatorPhone: z.string().optional(),
});

type FormData = z.infer<typeof schema>;

export function CreateCompanyForm() {
  const { t } = useTranslation();
  const navigate = useNavigate();
  const queryClient = useQueryClient();
  const [error, setError] = useState('');

  const {
    register,
    handleSubmit,
    formState: { errors },
  } = useForm<FormData>({
    resolver: zodResolver(schema),
  });

  const mutation = useMutation({
    mutationFn: async (data: FormData) => {
      const { data: result, error } = await supabase.functions.invoke('create-company', {
        body: {
          company: {
            name: data.companyName,
            address: data.companyAddress || undefined,
            phone: data.companyPhone || undefined,
            email: data.companyEmail || undefined,
          },
          operator: {
            email: data.operatorEmail,
            password: data.operatorPassword,
            first_name: data.operatorFirstName,
            last_name: data.operatorLastName,
            phone: data.operatorPhone || undefined,
          },
        },
      });
      if (error) throw error;
      return result;
    },
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['companies'] });
      navigate('/admin/companies');
    },
    onError: (err: any) => {
      setError(err.message || t('common.error'));
    },
  });

  const onSubmit = (data: FormData) => {
    setError('');
    mutation.mutate(data);
  };

  const inputClasses = "mt-1 block w-full px-3 py-2 bg-zinc-800 border border-zinc-700 rounded-lg text-white placeholder-zinc-500 focus:outline-none focus:border-amber-500 focus:ring-1 focus:ring-amber-500/20 text-sm";

  return (
    <div>
      <Link
        to="/admin/companies"
        className="inline-flex items-center gap-1 text-sm text-zinc-400 hover:text-white mb-4 transition-colors"
      >
        <ArrowLeft className="w-4 h-4" />
        {t('common.back')}
      </Link>

      <h1 className="text-2xl font-bold font-display text-white mb-6">
        {t('superAdmin.createCompany')}
      </h1>

      {error && (
        <div className="mb-4 bg-rose-500/10 border border-rose-500/20 text-rose-400 px-4 py-3 rounded-lg text-sm">
          {error}
        </div>
      )}

      <form onSubmit={handleSubmit(onSubmit)} className="space-y-8 max-w-2xl">
        {/* Company Info */}
        <div className="bg-zinc-900/80 backdrop-blur-sm rounded-xl border border-zinc-800 p-6">
          <h2 className="text-lg font-semibold text-white mb-4">{t('superAdmin.companyInfo')}</h2>
          <div className="space-y-4">
            <div>
              <label className="block text-sm font-medium text-zinc-300">
                {t('superAdmin.companyName')} *
              </label>
              <input {...register('companyName')} className={inputClasses} />
              {errors.companyName && (
                <p className="mt-1 text-sm text-rose-400">{t('common.required')}</p>
              )}
            </div>
            <div>
              <label className="block text-sm font-medium text-zinc-300">
                {t('common.email')}
              </label>
              <input {...register('companyEmail')} type="email" className={inputClasses} />
            </div>
            <div className="grid grid-cols-2 gap-4">
              <div>
                <label className="block text-sm font-medium text-zinc-300">
                  {t('common.phone')}
                </label>
                <input {...register('companyPhone')} className={inputClasses} />
              </div>
              <div>
                <label className="block text-sm font-medium text-zinc-300">
                  {t('common.address')}
                </label>
                <input {...register('companyAddress')} className={inputClasses} />
              </div>
            </div>
          </div>
        </div>

        {/* Operator Info */}
        <div className="bg-zinc-900/80 backdrop-blur-sm rounded-xl border border-zinc-800 p-6">
          <h2 className="text-lg font-semibold text-white mb-4">{t('superAdmin.operatorInfo')}</h2>
          <div className="space-y-4">
            <div className="grid grid-cols-2 gap-4">
              <div>
                <label className="block text-sm font-medium text-zinc-300">
                  {t('superAdmin.operatorFirstName')} *
                </label>
                <input {...register('operatorFirstName')} className={inputClasses} />
                {errors.operatorFirstName && (
                  <p className="mt-1 text-sm text-rose-400">{t('common.required')}</p>
                )}
              </div>
              <div>
                <label className="block text-sm font-medium text-zinc-300">
                  {t('superAdmin.operatorLastName')} *
                </label>
                <input {...register('operatorLastName')} className={inputClasses} />
                {errors.operatorLastName && (
                  <p className="mt-1 text-sm text-rose-400">{t('common.required')}</p>
                )}
              </div>
            </div>
            <div>
              <label className="block text-sm font-medium text-zinc-300">
                {t('superAdmin.operatorEmail')} *
              </label>
              <input {...register('operatorEmail')} type="email" className={inputClasses} />
              {errors.operatorEmail && (
                <p className="mt-1 text-sm text-rose-400">{t('common.required')}</p>
              )}
            </div>
            <div>
              <label className="block text-sm font-medium text-zinc-300">
                {t('superAdmin.operatorPassword')} *
              </label>
              <input {...register('operatorPassword')} type="password" className={inputClasses} />
              {errors.operatorPassword && (
                <p className="mt-1 text-sm text-rose-400">{t('common.required')}</p>
              )}
            </div>
            <div>
              <label className="block text-sm font-medium text-zinc-300">
                {t('superAdmin.operatorPhone')}
              </label>
              <input {...register('operatorPhone')} className={inputClasses} />
            </div>
          </div>
        </div>

        <div className="flex justify-end gap-3">
          <Link
            to="/admin/companies"
            className="px-4 py-2 text-sm font-medium text-zinc-300 bg-zinc-800 border border-zinc-700 rounded-lg hover:bg-zinc-700 transition-colors"
          >
            {t('common.cancel')}
          </Link>
          <button
            type="submit"
            disabled={mutation.isPending}
            className="px-4 py-2 text-sm font-semibold text-black bg-amber-500 rounded-lg hover:bg-amber-400 shadow-lg shadow-amber-500/20 disabled:opacity-50 transition-all"
          >
            {mutation.isPending ? t('common.loading') : t('common.create')}
          </button>
        </div>
      </form>
    </div>
  );
}
