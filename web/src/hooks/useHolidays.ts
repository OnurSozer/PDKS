import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import { supabase } from '../lib/supabase';
import { CompanyHoliday } from '../types';

export function useHolidays(companyId?: string, year?: number) {
  return useQuery({
    queryKey: ['holidays', companyId, year],
    queryFn: async () => {
      let query = supabase
        .from('company_holidays')
        .select('*')
        .eq('company_id', companyId!)
        .order('holiday_date', { ascending: true });

      if (year) {
        query = query
          .gte('holiday_date', `${year}-01-01`)
          .lte('holiday_date', `${year}-12-31`);
      }

      const { data, error } = await query;
      if (error) throw error;
      return data as CompanyHoliday[];
    },
    enabled: !!companyId,
  });
}

export function useCreateHoliday() {
  const queryClient = useQueryClient();

  return useMutation({
    mutationFn: async (holiday: {
      company_id: string;
      name: string;
      holiday_date: string;
      is_recurring: boolean;
    }) => {
      const { data, error } = await supabase
        .from('company_holidays')
        .insert(holiday)
        .select()
        .single();
      if (error) throw error;
      return data as CompanyHoliday;
    },
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['holidays'] });
    },
  });
}

export function useUpdateHoliday() {
  const queryClient = useQueryClient();

  return useMutation({
    mutationFn: async ({ id, ...updates }: { id: string; name?: string; holiday_date?: string; is_recurring?: boolean }) => {
      const { data, error } = await supabase
        .from('company_holidays')
        .update(updates)
        .eq('id', id)
        .select()
        .single();
      if (error) throw error;
      return data as CompanyHoliday;
    },
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['holidays'] });
    },
  });
}

export function useDeleteHoliday() {
  const queryClient = useQueryClient();

  return useMutation({
    mutationFn: async (id: string) => {
      const { error } = await supabase
        .from('company_holidays')
        .delete()
        .eq('id', id);
      if (error) throw error;
    },
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['holidays'] });
    },
  });
}
