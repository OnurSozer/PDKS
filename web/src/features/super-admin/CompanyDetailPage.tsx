import React from 'react';
import { useTranslation } from 'react-i18next';
import { useParams, Link } from 'react-router-dom';
import { useQuery } from '@tanstack/react-query';
import { supabase } from '../../lib/supabase';
import { Company, Profile } from '../../types';
import { ArrowLeft, Building2, User } from 'lucide-react';

export function CompanyDetailPage() {
  const { t } = useTranslation();
  const { id } = useParams<{ id: string }>();

  const { data: company, isLoading: companyLoading } = useQuery({
    queryKey: ['company', id],
    queryFn: async () => {
      const { data, error } = await supabase
        .from('companies')
        .select('*')
        .eq('id', id!)
        .single();
      if (error) throw error;
      return data as Company;
    },
    enabled: !!id,
  });

  const { data: operators = [] } = useQuery({
    queryKey: ['company-operators', id],
    queryFn: async () => {
      const { data, error } = await supabase
        .from('profiles')
        .select('*')
        .eq('company_id', id!)
        .eq('role', 'operator');
      if (error) throw error;
      return data as Profile[];
    },
    enabled: !!id,
  });

  const { data: employeeCount = 0 } = useQuery({
    queryKey: ['company-employee-count', id],
    queryFn: async () => {
      const { count, error } = await supabase
        .from('profiles')
        .select('*', { count: 'exact', head: true })
        .eq('company_id', id!)
        .in('role', ['employee', 'chef']);
      if (error) throw error;
      return count ?? 0;
    },
    enabled: !!id,
  });

  if (companyLoading) {
    return (
      <div className="flex items-center justify-center py-12">
        <div className="animate-spin rounded-full h-8 w-8 border-b-2 border-primary-600"></div>
      </div>
    );
  }

  if (!company) {
    return <div className="text-center py-12 text-gray-500">{t('common.noData')}</div>;
  }

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
        {t('superAdmin.companyDetail')}
      </h1>

      <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
        {/* Company Info */}
        <div className="bg-white rounded-lg border border-gray-200 p-6">
          <div className="flex items-center gap-3 mb-4">
            <Building2 className="w-5 h-5 text-primary-600" />
            <h2 className="text-lg font-semibold">{t('superAdmin.companyInfo')}</h2>
          </div>
          <dl className="space-y-3">
            <div>
              <dt className="text-sm font-medium text-gray-500">{t('common.name')}</dt>
              <dd className="text-sm text-gray-900">{company.name}</dd>
            </div>
            <div>
              <dt className="text-sm font-medium text-gray-500">{t('common.email')}</dt>
              <dd className="text-sm text-gray-900">{company.email || '-'}</dd>
            </div>
            <div>
              <dt className="text-sm font-medium text-gray-500">{t('common.phone')}</dt>
              <dd className="text-sm text-gray-900">{company.phone || '-'}</dd>
            </div>
            <div>
              <dt className="text-sm font-medium text-gray-500">{t('common.address')}</dt>
              <dd className="text-sm text-gray-900">{company.address || '-'}</dd>
            </div>
            <div>
              <dt className="text-sm font-medium text-gray-500">{t('common.status')}</dt>
              <dd>
                <span
                  className={`inline-flex px-2 py-1 text-xs font-medium rounded-full ${
                    company.is_active
                      ? 'bg-green-100 text-green-700'
                      : 'bg-red-100 text-red-700'
                  }`}
                >
                  {company.is_active ? t('common.active') : t('common.inactive')}
                </span>
              </dd>
            </div>
            <div>
              <dt className="text-sm font-medium text-gray-500">{t('nav.employees')}</dt>
              <dd className="text-sm text-gray-900">{employeeCount}</dd>
            </div>
          </dl>
        </div>

        {/* Operator Info */}
        <div className="bg-white rounded-lg border border-gray-200 p-6">
          <div className="flex items-center gap-3 mb-4">
            <User className="w-5 h-5 text-primary-600" />
            <h2 className="text-lg font-semibold">{t('superAdmin.operatorInfo')}</h2>
          </div>
          {operators.length === 0 ? (
            <p className="text-sm text-gray-500">{t('common.noData')}</p>
          ) : (
            <div className="space-y-4">
              {operators.map((op) => (
                <div key={op.id} className="border border-gray-100 rounded-lg p-4">
                  <dl className="space-y-2">
                    <div>
                      <dt className="text-sm font-medium text-gray-500">{t('common.name')}</dt>
                      <dd className="text-sm text-gray-900">
                        {op.first_name} {op.last_name}
                      </dd>
                    </div>
                    <div>
                      <dt className="text-sm font-medium text-gray-500">{t('common.email')}</dt>
                      <dd className="text-sm text-gray-900">{op.email}</dd>
                    </div>
                    <div>
                      <dt className="text-sm font-medium text-gray-500">{t('common.phone')}</dt>
                      <dd className="text-sm text-gray-900">{op.phone || '-'}</dd>
                    </div>
                    <div>
                      <dt className="text-sm font-medium text-gray-500">{t('common.status')}</dt>
                      <dd>
                        <span
                          className={`inline-flex px-2 py-1 text-xs font-medium rounded-full ${
                            op.is_active
                              ? 'bg-green-100 text-green-700'
                              : 'bg-red-100 text-red-700'
                          }`}
                        >
                          {op.is_active ? t('common.active') : t('common.inactive')}
                        </span>
                      </dd>
                    </div>
                  </dl>
                </div>
              ))}
            </div>
          )}
        </div>
      </div>
    </div>
  );
}
