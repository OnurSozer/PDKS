export interface Company {
  id: string;
  name: string;
  address?: string;
  phone?: string;
  email?: string;
  is_active: boolean;
  settings: Record<string, any>;
  created_at: string;
  updated_at: string;
}

export interface Profile {
  id: string;
  company_id: string | null;
  role: 'super_admin' | 'operator' | 'employee' | 'chef';
  first_name: string;
  last_name: string;
  email: string;
  phone?: string;
  start_date?: string;
  is_active: boolean;
  created_at: string;
  updated_at: string;
}

export interface ShiftTemplate {
  id: string;
  company_id: string;
  name: string;
  start_time: string;
  end_time: string;
  break_duration_minutes: number;
  work_days: number[];
  is_active: boolean;
  created_at?: string;
  updated_at?: string;
}

export interface EmployeeSchedule {
  id: string;
  employee_id: string;
  company_id: string;
  shift_template_id?: string;
  shift_template?: ShiftTemplate;
  custom_start_time?: string;
  custom_end_time?: string;
  custom_break_duration_minutes?: number;
  custom_work_days?: number[];
  effective_from: string;
  effective_to?: string;
  created_at?: string;
  updated_at?: string;
}

export interface OvertimeRule {
  id: string;
  company_id: string;
  name: string;
  description?: string;
  rule_type: 'daily_threshold' | 'weekly_threshold' | 'custom';
  threshold_minutes?: number;
  multiplier: number;
  is_active: boolean;
  priority: number;
  created_at?: string;
  updated_at?: string;
}

export interface EmployeeOvertimeRule {
  id: string;
  employee_id: string;
  overtime_rule_id: string;
  overtime_rule?: OvertimeRule;
  created_at?: string;
}

export interface WorkSession {
  id: string;
  employee_id: string;
  company_id: string;
  clock_in: string;
  clock_out?: string;
  clock_out_submitted_by?: 'employee' | 'operator' | 'system';
  session_date: string;
  total_minutes?: number;
  regular_minutes?: number;
  overtime_minutes?: number;
  overtime_multiplier?: number;
  status: 'active' | 'completed' | 'edited' | 'cancelled';
  notes?: string;
  edited_by?: string;
  edited_at?: string;
  created_at?: string;
  updated_at?: string;
  // Joined fields
  employee?: Profile;
}

export interface DailySummary {
  id: string;
  employee_id: string;
  company_id: string;
  summary_date: string;
  total_sessions: number;
  total_work_minutes: number;
  total_regular_minutes: number;
  total_overtime_minutes: number;
  expected_work_minutes: number;
  is_late: boolean;
  late_minutes: number;
  is_absent: boolean;
  is_leave: boolean;
  status: 'pending' | 'complete' | 'incomplete' | 'leave' | 'absent' | 'holiday';
  created_at?: string;
  updated_at?: string;
  // Joined
  employee?: Profile;
}

export interface LeaveType {
  id: string;
  company_id: string;
  name: string;
  default_days_per_year?: number;
  is_paid: boolean;
  is_active: boolean;
  created_at?: string;
}

export interface LeaveBalance {
  id: string;
  employee_id: string;
  leave_type_id: string;
  leave_type?: LeaveType;
  year: number;
  total_days: number;
  used_days: number;
  created_at?: string;
  updated_at?: string;
}

export interface LeaveRecord {
  id: string;
  employee_id: string;
  company_id: string;
  leave_type_id: string;
  leave_type?: LeaveType;
  employee?: Profile;
  start_date: string;
  end_date: string;
  total_days: number;
  reason?: string;
  status: 'active' | 'cancelled';
  created_at: string;
  updated_at?: string;
}

export interface NotificationSettings {
  id: string;
  company_id: string;
  forgot_clockout_enabled: boolean;
  forgot_clockout_time: string;
  forgot_clockout_offset_minutes: number;
  created_at?: string;
  updated_at?: string;
}

export interface DeviceToken {
  id: string;
  user_id: string;
  token: string;
  platform: 'android' | 'ios';
  is_active: boolean;
  created_at?: string;
  updated_at?: string;
}

// Auth types
export interface AuthUser {
  id: string;
  email: string;
  profile: Profile;
}

// API request/response types
export interface CreateCompanyRequest {
  company: {
    name: string;
    address?: string;
    phone?: string;
    email?: string;
  };
  operator: {
    email: string;
    password: string;
    first_name: string;
    last_name: string;
    phone?: string;
  };
}

export interface CreateEmployeeRequest {
  email: string;
  password: string;
  first_name: string;
  last_name: string;
  phone?: string;
  start_date?: string;
  role: 'employee' | 'chef';
  schedule?: {
    shift_template_id?: string;
    custom_start_time?: string;
    custom_end_time?: string;
    custom_work_days?: number[];
  };
}

export interface EditSessionRequest {
  session_id: string;
  clock_in?: string;
  clock_out?: string;
  notes?: string;
}

export interface AttendanceReportParams {
  start_date: string;
  end_date: string;
  employee_id?: string;
}

export interface AttendanceReport {
  summaries: DailySummary[];
  employees: Profile[];
}
