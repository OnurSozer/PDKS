import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import { supabase } from '../lib/supabase';
import { WorkSession, EditSessionRequest } from '../types';

interface SessionsFilter {
  companyId?: string;
  employeeId?: string;
  startDate?: string;
  endDate?: string;
  status?: string;
}

export function useSessions(filter: SessionsFilter) {
  return useQuery({
    queryKey: ['sessions', filter],
    queryFn: async () => {
      let query = supabase
        .from('work_sessions')
        .select('*, employee:profiles!work_sessions_employee_id_fkey(id, first_name, last_name, email, role)')
        .order('clock_in', { ascending: false });

      if (filter.companyId) {
        query = query.eq('company_id', filter.companyId);
      }
      if (filter.employeeId) {
        query = query.eq('employee_id', filter.employeeId);
      }
      if (filter.startDate) {
        query = query.gte('session_date', filter.startDate);
      }
      if (filter.endDate) {
        query = query.lte('session_date', filter.endDate);
      }
      if (filter.status) {
        query = query.eq('status', filter.status);
      }

      const { data, error } = await query;
      if (error) throw error;
      return data as WorkSession[];
    },
    enabled: !!filter.companyId,
  });
}

export function useEditSession() {
  const queryClient = useQueryClient();

  return useMutation({
    mutationFn: async (req: EditSessionRequest) => {
      const { data, error } = await supabase.functions.invoke('edit-session', {
        body: req,
        method: 'PUT',
      });
      if (error) throw error;
      return data;
    },
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['sessions'] });
    },
  });
}

export function useActiveSessions(companyId?: string) {
  return useQuery({
    queryKey: ['active-sessions', companyId],
    queryFn: async () => {
      const { data, error } = await supabase
        .from('work_sessions')
        .select('*, employee:profiles!work_sessions_employee_id_fkey(id, first_name, last_name, email, role)')
        .eq('company_id', companyId!)
        .eq('status', 'active')
        .order('clock_in', { ascending: false });
      if (error) throw error;
      return data as WorkSession[];
    },
    enabled: !!companyId,
    refetchInterval: 30000, // Refresh every 30s for live data
  });
}
