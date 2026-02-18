import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import { supabase } from '../lib/supabase';
import { CompanyWorkSettings } from '../types';

export function useWorkSettings(companyId?: string) {
  return useQuery({
    queryKey: ['work-settings', companyId],
    queryFn: async () => {
      const { data, error } = await supabase
        .from('company_work_settings')
        .select('*')
        .eq('company_id', companyId!)
        .single();
      if (error && error.code !== 'PGRST116') throw error;
      return data as CompanyWorkSettings | null;
    },
    enabled: !!companyId,
  });
}

export function useSaveWorkSettings() {
  const queryClient = useQueryClient();

  return useMutation({
    mutationFn: async (settings: {
      company_id: string;
      monthly_work_days_constant: number;
      overtime_multiplier: number;
      weekend_multiplier: number;
      holiday_multiplier: number;
      boss_call_multiplier: number;
    }) => {
      const { data, error } = await supabase
        .from('company_work_settings')
        .upsert(settings, { onConflict: 'company_id' })
        .select()
        .single();
      if (error) throw error;
      return data as CompanyWorkSettings;
    },
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['work-settings'] });
    },
  });
}
