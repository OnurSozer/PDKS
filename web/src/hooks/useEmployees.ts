import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import { supabase } from '../lib/supabase';
import { Profile, CreateEmployeeRequest } from '../types';

export function useEmployees(companyId?: string) {
  return useQuery({
    queryKey: ['employees', companyId],
    queryFn: async () => {
      let query = supabase
        .from('profiles')
        .select('*')
        .in('role', ['employee', 'chef'])
        .eq('is_active', true)
        .order('first_name');

      if (companyId) {
        query = query.eq('company_id', companyId);
      }

      const { data, error } = await query;
      if (error) throw error;
      return data as Profile[];
    },
    enabled: !!companyId,
  });
}

export function useEmployee(employeeId?: string) {
  return useQuery({
    queryKey: ['employee', employeeId],
    queryFn: async () => {
      const { data, error } = await supabase
        .from('profiles')
        .select('*')
        .eq('id', employeeId!)
        .single();
      if (error) throw error;
      return data as Profile;
    },
    enabled: !!employeeId,
  });
}

export function useCreateEmployee() {
  const queryClient = useQueryClient();

  return useMutation({
    mutationFn: async (req: CreateEmployeeRequest) => {
      const { data, error } = await supabase.functions.invoke('create-employee', {
        body: req,
      });
      if (error) throw error;
      return data;
    },
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['employees'] });
    },
  });
}

export function useDeleteEmployee() {
  const queryClient = useQueryClient();

  return useMutation({
    mutationFn: async (employeeId: string) => {
      const { data, error } = await supabase.functions.invoke('delete-employee', {
        body: { employee_id: employeeId },
      });
      if (error) throw error;
      return data;
    },
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['employees'] });
    },
  });
}

export function useAllProfiles() {
  return useQuery({
    queryKey: ['all-profiles'],
    queryFn: async () => {
      const { data, error } = await supabase
        .from('profiles')
        .select('*')
        .order('created_at', { ascending: false });
      if (error) throw error;
      return data as Profile[];
    },
  });
}
