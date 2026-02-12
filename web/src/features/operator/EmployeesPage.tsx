import React from 'react';
import { useTranslation } from 'react-i18next';
import { Link } from 'react-router-dom';
import { ColumnDef } from '@tanstack/react-table';
import { useAuth } from '../../hooks/useAuth';
import { useEmployees } from '../../hooks/useEmployees';
import { Profile } from '../../types';
import { DataTable } from '../../components/shared/DataTable';
import { Plus, Eye } from 'lucide-react';

export function EmployeesPage() {
  const { t } = useTranslation();
  const { profile } = useAuth();
  const companyId = profile?.company_id || undefined;
  const { data: employees = [], isLoading } = useEmployees(companyId);

  const columns: ColumnDef<Profile, any>[] = [
    {
      accessorFn: (row) => `${row.first_name} ${row.last_name}`,
      id: 'name',
      header: t('common.name'),
    },
    {
      accessorKey: 'email',
      header: t('common.email'),
    },
    {
      accessorKey: 'phone',
      header: t('common.phone'),
      cell: ({ getValue }) => getValue() || '-',
    },
    {
      accessorKey: 'role',
      header: t('employees.role'),
      cell: ({ getValue }) => {
        const role = getValue() as string;
        return (
          <span
            className={`inline-flex px-2 py-1 text-xs font-medium rounded-full ${
              role === 'chef'
                ? 'bg-orange-100 text-orange-700'
                : 'bg-blue-100 text-blue-700'
            }`}
          >
            {role === 'chef' ? t('employees.roleChef') : t('employees.roleEmployee')}
          </span>
        );
      },
    },
    {
      accessorKey: 'start_date',
      header: t('employees.startDate'),
      cell: ({ getValue }) => {
        const val = getValue() as string;
        return val ? new Date(val).toLocaleDateString() : '-';
      },
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
      id: 'actions',
      header: t('common.actions'),
      cell: ({ row }) => (
        <Link
          to={`/operator/employees/${row.original.id}`}
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
          {t('employees.title')}
        </h1>
        <Link
          to="/operator/employees/new"
          className="inline-flex items-center gap-2 px-4 py-2 text-sm font-medium text-white bg-primary-600 rounded-md hover:bg-primary-700"
        >
          <Plus className="w-4 h-4" />
          {t('employees.createEmployee')}
        </Link>
      </div>
      <DataTable
        data={employees}
        columns={columns}
        searchPlaceholder={`${t('common.search')}...`}
      />
    </div>
  );
}
