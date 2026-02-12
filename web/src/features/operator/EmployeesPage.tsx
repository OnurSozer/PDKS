import React, { useState } from 'react';
import { useTranslation } from 'react-i18next';
import { Link } from 'react-router-dom';
import { ColumnDef } from '@tanstack/react-table';
import { useAuth } from '../../hooks/useAuth';
import { useEmployees, useDeleteEmployee } from '../../hooks/useEmployees';
import { Profile } from '../../types';
import { DataTable } from '../../components/shared/DataTable';
import { Plus, Eye, Trash2 } from 'lucide-react';

export function EmployeesPage() {
  const { t } = useTranslation();
  const { profile } = useAuth();
  const companyId = profile?.company_id || undefined;
  const { data: employees = [], isLoading } = useEmployees(companyId);
  const deleteEmployee = useDeleteEmployee();
  const [deletingId, setDeletingId] = useState<string | null>(null);

  const handleDelete = (emp: Profile) => {
    if (!window.confirm(`${emp.first_name} ${emp.last_name} - ${t('common.confirm')}?`)) return;
    setDeletingId(emp.id);
    deleteEmployee.mutate(emp.id, {
      onSettled: () => setDeletingId(null),
    });
  };

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
                ? 'bg-amber-500/10 text-amber-400 border border-amber-500/20'
                : 'bg-sky-500/10 text-sky-400 border border-sky-500/20'
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
              ? 'bg-emerald-500/10 text-emerald-400 border border-emerald-500/20'
              : 'bg-rose-500/10 text-rose-400 border border-rose-500/20'
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
        <div className="flex items-center gap-2">
          <Link
            to={`/operator/employees/${row.original.id}`}
            className="inline-flex items-center gap-1 text-sm text-amber-500 hover:text-amber-400 transition-colors"
          >
            <Eye className="w-4 h-4" />
            {t('common.view')}
          </Link>
          <button
            onClick={() => handleDelete(row.original)}
            disabled={deletingId === row.original.id}
            className="inline-flex items-center gap-1 text-sm text-rose-500 hover:text-rose-400 transition-colors disabled:opacity-50"
          >
            <Trash2 className="w-4 h-4" />
            {t('common.delete')}
          </button>
        </div>
      ),
      enableSorting: false,
    },
  ];

  if (isLoading) {
    return (
      <div className="flex items-center justify-center py-12">
        <div className="animate-spin rounded-full h-8 w-8 border-b-2 border-amber-500"></div>
      </div>
    );
  }

  return (
    <div>
      <div className="flex items-center justify-between mb-6">
        <h1 className="text-2xl font-bold font-display text-white">
          {t('employees.title')}
        </h1>
        <Link
          to="/operator/employees/new"
          className="inline-flex items-center gap-2 px-4 py-2 text-sm font-semibold text-black bg-amber-500 rounded-lg hover:bg-amber-400 shadow-lg shadow-amber-500/20 transition-all"
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
