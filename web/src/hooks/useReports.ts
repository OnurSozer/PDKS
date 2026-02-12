import { useQuery } from '@tanstack/react-query';
import { supabase } from '../lib/supabase';
import { DailySummary } from '../types';

interface ReportFilter {
  companyId?: string;
  employeeId?: string;
  startDate?: string;
  endDate?: string;
}

export function useDailySummaries(filter: ReportFilter) {
  return useQuery({
    queryKey: ['daily-summaries', filter],
    queryFn: async () => {
      let query = supabase
        .from('daily_summaries')
        .select('*, employee:profiles!daily_summaries_employee_id_fkey(id, first_name, last_name, email, role)')
        .order('summary_date', { ascending: false });

      if (filter.companyId) {
        query = query.eq('company_id', filter.companyId);
      }
      if (filter.employeeId) {
        query = query.eq('employee_id', filter.employeeId);
      }
      if (filter.startDate) {
        query = query.gte('summary_date', filter.startDate);
      }
      if (filter.endDate) {
        query = query.lte('summary_date', filter.endDate);
      }

      const { data, error } = await query;
      if (error) throw error;
      return data as DailySummary[];
    },
    enabled: !!filter.companyId && !!filter.startDate && !!filter.endDate,
  });
}

export function useTodaySummaries(companyId?: string) {
  const today = new Date().toISOString().split('T')[0];

  return useQuery({
    queryKey: ['today-summaries', companyId, today],
    queryFn: async () => {
      const { data, error } = await supabase
        .from('daily_summaries')
        .select('*, employee:profiles!daily_summaries_employee_id_fkey(id, first_name, last_name, email, role)')
        .eq('company_id', companyId!)
        .eq('summary_date', today);
      if (error) throw error;
      return data as DailySummary[];
    },
    enabled: !!companyId,
    refetchInterval: 60000,
  });
}
