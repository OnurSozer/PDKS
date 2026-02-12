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

  return (
    <div>
      <Link
        to="/admin/companies"
        className="inline-flex items-center gap-1 text-sm text-gray-600 hover:text-gray-900 mb-4"
      >
        <ArrowLeft className="w-4 h-4" />
        {t('common.back')}
      </Link>

      <h1 className="text-2xl font-bold text-gray-900 mb-6">
        {t('superAdmin.createCompany')}
      </h1>

      {error && (
        <div className="mb-4 bg-red-50 border border-red-200 text-red-700 px-4 py-3 rounded">
          {error}
        </div>
      )}

      <form onSubmit={handleSubmit(onSubmit)} className="space-y-8 max-w-2xl">
        {/* Company Info */}
        <div className="bg-white rounded-lg border border-gray-200 p-6">
          <h2 className="text-lg font-semibold mb-4">{t('superAdmin.companyInfo')}</h2>
          <div className="space-y-4">
            <div>
              <label className="block text-sm font-medium text-gray-700">
                {t('superAdmin.companyName')} *
              </label>
              <input
                {...register('companyName')}
                className="mt-1 block w-full px-3 py-2 border border-gray-300 rounded-md shadow-sm focus:outline-none focus:ring-primary-500 focus:border-primary-500"
              />
              {errors.companyName && (
                <p className="mt-1 text-sm text-red-600">{t('common.required')}</p>
              )}
            </div>
            <div>
              <label className="block text-sm font-medium text-gray-700">
                {t('common.email')}
              </label>
              <input
                {...register('companyEmail')}
                type="email"
                className="mt-1 block w-full px-3 py-2 border border-gray-300 rounded-md shadow-sm focus:outline-none focus:ring-primary-500 focus:border-primary-500"
              />
            </div>
            <div className="grid grid-cols-2 gap-4">
              <div>
                <label className="block text-sm font-medium text-gray-700">
                  {t('common.phone')}
                </label>
                <input
                  {...register('companyPhone')}
                  className="mt-1 block w-full px-3 py-2 border border-gray-300 rounded-md shadow-sm focus:outline-none focus:ring-primary-500 focus:border-primary-500"
                />
              </div>
              <div>
                <label className="block text-sm font-medium text-gray-700">
                  {t('common.address')}
                </label>
                <input
                  {...register('companyAddress')}
                  className="mt-1 block w-full px-3 py-2 border border-gray-300 rounded-md shadow-sm focus:outline-none focus:ring-primary-500 focus:border-primary-500"
                />
              </div>
            </div>
          </div>
        </div>

        {/* Operator Info */}
        <div className="bg-white rounded-lg border border-gray-200 p-6">
          <h2 className="text-lg font-semibold mb-4">{t('superAdmin.operatorInfo')}</h2>
          <div className="space-y-4">
            <div className="grid grid-cols-2 gap-4">
              <div>
                <label className="block text-sm font-medium text-gray-700">
                  {t('superAdmin.operatorFirstName')} *
                </label>
                <input
                  {...register('operatorFirstName')}
                  className="mt-1 block w-full px-3 py-2 border border-gray-300 rounded-md shadow-sm focus:outline-none focus:ring-primary-500 focus:border-primary-500"
                />
                {errors.operatorFirstName && (
                  <p className="mt-1 text-sm text-red-600">{t('common.required')}</p>
                )}
              </div>
              <div>
                <label className="block text-sm font-medium text-gray-700">
                  {t('superAdmin.operatorLastName')} *
                </label>
                <input
                  {...register('operatorLastName')}
                  className="mt-1 block w-full px-3 py-2 border border-gray-300 rounded-md shadow-sm focus:outline-none focus:ring-primary-500 focus:border-primary-500"
                />
                {errors.operatorLastName && (
                  <p className="mt-1 text-sm text-red-600">{t('common.required')}</p>
                )}
              </div>
            </div>
            <div>
              <label className="block text-sm font-medium text-gray-700">
                {t('superAdmin.operatorEmail')} *
              </label>
              <input
                {...register('operatorEmail')}
                type="email"
                className="mt-1 block w-full px-3 py-2 border border-gray-300 rounded-md shadow-sm focus:outline-none focus:ring-primary-500 focus:border-primary-500"
              />
              {errors.operatorEmail && (
                <p className="mt-1 text-sm text-red-600">{t('common.required')}</p>
              )}
            </div>
            <div>
              <label className="block text-sm font-medium text-gray-700">
                {t('superAdmin.operatorPassword')} *
              </label>
              <input
                {...register('operatorPassword')}
                type="password"
                className="mt-1 block w-full px-3 py-2 border border-gray-300 rounded-md shadow-sm focus:outline-none focus:ring-primary-500 focus:border-primary-500"
              />
              {errors.operatorPassword && (
                <p className="mt-1 text-sm text-red-600">{t('common.required')}</p>
              )}
            </div>
            <div>
              <label className="block text-sm font-medium text-gray-700">
                {t('superAdmin.operatorPhone')}
              </label>
              <input
                {...register('operatorPhone')}
                className="mt-1 block w-full px-3 py-2 border border-gray-300 rounded-md shadow-sm focus:outline-none focus:ring-primary-500 focus:border-primary-500"
              />
            </div>
          </div>
        </div>

        <div className="flex justify-end gap-3">
          <Link
            to="/admin/companies"
            className="px-4 py-2 text-sm font-medium text-gray-700 bg-white border border-gray-300 rounded-md hover:bg-gray-50"
          >
            {t('common.cancel')}
          </Link>
          <button
            type="submit"
            disabled={mutation.isPending}
            className="px-4 py-2 text-sm font-medium text-white bg-primary-600 rounded-md hover:bg-primary-700 disabled:opacity-50"
          >
            {mutation.isPending ? t('common.loading') : t('common.create')}
          </button>
        </div>
      </form>
    </div>
  );
}
