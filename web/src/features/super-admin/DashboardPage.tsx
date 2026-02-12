import React from 'react';
import { useTranslation } from 'react-i18next';
import { useQuery } from '@tanstack/react-query';
import { supabase } from '../../lib/supabase';
import { StatCard } from '../../components/shared/StatCard';
import { Building2, Users, Clock } from 'lucide-react';

export function SuperAdminDashboardPage() {
  const { t } = useTranslation();

  const { data: companiesCount = 0 } = useQuery({
    queryKey: ['admin-companies-count'],
    queryFn: async () => {
      const { count, error } = await supabase
        .from('companies')
        .select('*', { count: 'exact', head: true });
      if (error) throw error;
      return count ?? 0;
    },
  });

  const { data: usersCount = 0 } = useQuery({
    queryKey: ['admin-users-count'],
    queryFn: async () => {
      const { count, error } = await supabase
        .from('profiles')
        .select('*', { count: 'exact', head: true });
      if (error) throw error;
      return count ?? 0;
    },
  });

  const { data: activeSessionsCount = 0 } = useQuery({
    queryKey: ['admin-active-sessions-count'],
    queryFn: async () => {
      const { count, error } = await supabase
        .from('work_sessions')
        .select('*', { count: 'exact', head: true })
        .eq('status', 'active');
      if (error) throw error;
      return count ?? 0;
    },
    refetchInterval: 30000,
  });

  return (
    <div>
      <h1 className="text-2xl font-bold text-gray-900 mb-6">
        {t('nav.dashboard')}
      </h1>
      <div className="grid grid-cols-1 md:grid-cols-3 gap-6">
        <StatCard
          title={t('superAdmin.totalCompanies')}
          value={companiesCount}
          icon={Building2}
          color="blue"
        />
        <StatCard
          title={t('superAdmin.totalUsers')}
          value={usersCount}
          icon={Users}
          color="green"
        />
        <StatCard
          title={t('superAdmin.activeSessions')}
          value={activeSessionsCount}
          icon={Clock}
          color="purple"
        />
      </div>
    </div>
  );
}
