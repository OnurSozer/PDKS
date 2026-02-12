import React from 'react';
import { useTranslation } from 'react-i18next';
import { useQuery } from '@tanstack/react-query';
import { Link } from 'react-router-dom';
import { ColumnDef } from '@tanstack/react-table';
import { supabase } from '../../lib/supabase';
import { Company } from '../../types';
import { DataTable } from '../../components/shared/DataTable';
import { Plus, Eye } from 'lucide-react';

export function CompaniesPage() {
  const { t } = useTranslation();

  const { data: companies = [], isLoading } = useQuery({
    queryKey: ['companies'],
    queryFn: async () => {
      const { data, error } = await supabase
        .from('companies')
        .select('*')
        .order('created_at', { ascending: false });
      if (error) throw error;
      return data as Company[];
    },
  });

  const columns: ColumnDef<Company, any>[] = [
    {
      accessorKey: 'name',
      header: t('common.name'),
    },
    {
      accessorKey: 'email',
      header: t('common.email'),
      cell: ({ getValue }) => getValue() || '-',
    },
    {
      accessorKey: 'phone',
      header: t('common.phone'),
      cell: ({ getValue }) => getValue() || '-',
    },
    {
      accessorKey: 'is_active',
      header: t('common.status'),
      cell: ({ getValue }) => (
        <span
          className={`inline-flex px-2 py-1 text-xs font-medium rounded-full ${
            getValue()
              ? 'bg-green-100 text-green-700'
              : 'bg-red-100 text-red-700'
          }`}
        >
          {getValue() ? t('common.active') : t('common.inactive')}
        </span>
      ),
    },
    {
      accessorKey: 'created_at',
      header: t('common.date'),
      cell: ({ getValue }) => new Date(getValue() as string).toLocaleDateString(),
    },
    {
      id: 'actions',
      header: t('common.actions'),
      cell: ({ row }) => (
        <Link
          to={`/admin/companies/${row.original.id}`}
          className="inline-flex items-center gap-1 text-sm text-primary-600 hover:text-primary-700"
        >
          <Eye className="w-4 h-4" />
          {t('common.view')}
        </Link>
      ),
      enableSorting: false,
    },
  ];

  if (isLoading) {
    return (
      <div className="flex items-center justify-center py-12">
        <div className="animate-spin rounded-full h-8 w-8 border-b-2 border-primary-600"></div>
      </div>
    );
  }

  return (
    <div>
      <div className="flex items-center justify-between mb-6">
        <h1 className="text-2xl font-bold text-gray-900">
          {t('superAdmin.companyList')}
        </h1>
        <Link
          to="/admin/companies/new"
          className="inline-flex items-center gap-2 px-4 py-2 text-sm font-medium text-white bg-primary-600 rounded-md hover:bg-primary-700"
        >
          <Plus className="w-4 h-4" />
          {t('superAdmin.createCompany')}
        </Link>
      </div>
      <DataTable
        data={companies}
        columns={columns}
        searchPlaceholder={`${t('common.search')}...`}
      />
    </div>
  );
}
