import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import { supabase } from '../lib/supabase';
import { SpecialDayType, EmployeeSpecialDayType } from '../types';

export function useSpecialDayTypes(companyId?: string) {
  return useQuery({
    queryKey: ['special-day-types', companyId],
    queryFn: async () => {
      const { data, error } = await supabase
        .from('special_day_types')
        .select('*')
        .eq('company_id', companyId!)
        .eq('is_active', true)
        .order('display_order')
        .order('name');
      if (error) throw error;
      return data as SpecialDayType[];
    },
    enabled: !!companyId,
  });
}

export function useCreateSpecialDayType() {
  const queryClient = useQueryClient();

  return useMutation({
    mutationFn: async (dayType: {
      company_id: string;
      name: string;
      code: string;
      calculation_mode: 'rounding' | 'fixed_hours';
      multiplier?: number;
      base_minutes?: number;
      extra_minutes?: number;
      extra_multiplier?: number;
      applies_to_all?: boolean;
      display_order?: number;
    }) => {
      const { data, error } = await supabase
        .from('special_day_types')
        .insert(dayType)
        .select()
        .single();
      if (error) throw error;
      return data as SpecialDayType;
    },
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['special-day-types'] });
    },
  });
}

export function useUpdateSpecialDayType() {
  const queryClient = useQueryClient();

  return useMutation({
    mutationFn: async ({ id, ...updates }: { id: string } & Partial<SpecialDayType>) => {
      const { data, error } = await supabase
        .from('special_day_types')
        .update(updates)
        .eq('id', id)
        .select()
        .single();
      if (error) throw error;
      return data as SpecialDayType;
    },
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['special-day-types'] });
    },
  });
}

export function useDeleteSpecialDayType() {
  const queryClient = useQueryClient();

  return useMutation({
    mutationFn: async (id: string) => {
      const { error } = await supabase
        .from('special_day_types')
        .update({ is_active: false })
        .eq('id', id);
      if (error) throw error;
    },
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['special-day-types'] });
    },
  });
}

export function useToggleSpecialDay() {
  const queryClient = useQueryClient();

  return useMutation({
    mutationFn: async (params: {
      employee_id: string;
      date: string;
      special_day_type_id: string | null;
    }) => {
      const { data, error } = await supabase.functions.invoke('toggle-special-day', {
        body: params,
      });
      if (error) throw error;
      return data;
    },
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['monthly-summary'] });
      queryClient.invalidateQueries({ queryKey: ['daily-summaries'] });
    },
  });
}

export function useEmployeeSpecialDayTypes(employeeId?: string) {
  return useQuery({
    queryKey: ['employee-special-day-types', employeeId],
    queryFn: async () => {
      const { data, error } = await supabase
        .from('employee_special_day_types')
        .select('*, special_day_type:special_day_types(*)')
        .eq('employee_id', employeeId!);
      if (error) throw error;
      return data as EmployeeSpecialDayType[];
    },
    enabled: !!employeeId,
  });
}

export function useAssignSpecialDayType() {
  const queryClient = useQueryClient();

  return useMutation({
    mutationFn: async (params: {
      employee_ids: string[];
      special_day_type_id: string;
      action?: 'remove';
    }) => {
      const { data, error } = await supabase.functions.invoke('assign-special-day-type', {
        body: params,
      });
      if (error) throw error;
      return data;
    },
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['employee-special-day-types'] });
    },
  });
}
