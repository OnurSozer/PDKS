import { useQuery } from '@tanstack/react-query';
import { supabase } from '../lib/supabase';
import { ActivityLog } from '../types';

export function useActivityLogs(
  companyId?: string,
  filters?: {
    employeeId?: string;
    actionType?: string;
    startDate?: string;
    endDate?: string;
    page?: number;
    pageSize?: number;
  }
) {
  const page = filters?.page ?? 1;
  const pageSize = filters?.pageSize ?? 20;
  const offset = (page - 1) * pageSize;

  return useQuery({
    queryKey: ['activity-logs', companyId, filters],
    queryFn: async () => {
      let query = supabase
        .from('activity_logs')
        .select(
          '*, employee:profiles!activity_logs_employee_id_fkey(id, first_name, last_name), performer:profiles!activity_logs_performed_by_fkey(id, first_name, last_name)',
          { count: 'exact' }
        )
        .eq('company_id', companyId!)
        .order('created_at', { ascending: false });

      if (filters?.employeeId) {
        query = query.eq('employee_id', filters.employeeId);
      }
      if (filters?.actionType) {
        query = query.eq('action_type', filters.actionType);
      }
      if (filters?.startDate) {
        query = query.gte('created_at', filters.startDate);
      }
      if (filters?.endDate) {
        query = query.lte('created_at', filters.endDate + 'T23:59:59');
      }

      query = query.range(offset, offset + pageSize - 1);

      const { data, error, count } = await query;
      if (error) throw error;
      return { data: data as ActivityLog[], count: count ?? 0 };
    },
    enabled: !!companyId,
  });
}
