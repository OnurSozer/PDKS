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
  deficit_minutes: number;
  is_holiday: boolean;
  is_boss_call: boolean;
  special_day_type_id?: string | null;
  effective_work_minutes: number;
  work_day_type: 'regular' | 'weekend' | 'holiday';
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
  leave_accrual_mode?: 'monthly' | 'yearly';
  created_at?: string;
  updated_at?: string;
}

export interface EmployeeLeaveEntitlement {
  id: string;
  employee_id: string;
  leave_type_id: string;
  leave_type?: LeaveType;
  company_id: string;
  days_per_year: number;
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

export interface CompanyHoliday {
  id: string;
  company_id: string;
  name: string;
  holiday_date: string;
  is_recurring: boolean;
  created_at?: string;
  updated_at?: string;
}

export interface CompanyWorkSettings {
  id: string;
  company_id: string;
  monthly_work_days_constant: number;
  overtime_multiplier: number;
  weekend_multiplier: number;
  holiday_multiplier: number;
  boss_call_multiplier: number;
  created_at?: string;
  updated_at?: string;
}

export interface SpecialDayType {
  id: string;
  company_id: string;
  name: string;
  code: string;
  calculation_mode: 'rounding' | 'fixed_hours';
  multiplier: number;
  base_minutes: number;
  extra_minutes: number;
  extra_multiplier: number;
  applies_to_all: boolean;
  is_active: boolean;
  display_order: number;
  created_at?: string;
  updated_at?: string;
}

export interface EmployeeSpecialDayType {
  id: string;
  employee_id: string;
  special_day_type_id: string;
  special_day_type?: SpecialDayType;
  company_id: string;
  created_at?: string;
}

export interface SpecialDayStat {
  days: number;
  minutes: number;
  name: string;
  code: string;
}

export interface MonthlyEmployeeSummary {
  employee_id: string;
  employee_name: string;
  work_days: number;
  total_work_minutes: number;
  expected_work_minutes: number;
  boss_call_days: number;
  boss_call_minutes: number;
  special_day_stats?: Record<string, SpecialDayStat>;
  net_minutes: number;
  deficit_minutes: number;
  overtime_value: number;
  overtime_days: number;
  overtime_percentage: number;
  late_days: number;
  absent_days: number;
  leave_days: number;
  daily_details: MonthlyDayDetail[];
}

export interface MonthlyDayDetail {
  date: string;
  is_work_day: boolean;
  work_day_type: 'regular' | 'weekend' | 'holiday';
  total_work_minutes: number;
  expected_work_minutes: number;
  effective_work_minutes: number;
  is_boss_call: boolean;
  is_late: boolean;
  is_absent: boolean;
  is_leave: boolean;
  deficit_minutes: number;
  status: string;
  special_day_type_id?: string | null;
  special_day_type_name?: string | null;
  special_day_type_code?: string | null;
}

export interface ActivityLog {
  id: string;
  company_id: string;
  employee_id: string;
  performed_by: string;
  action_type: string;
  resource_type: string;
  resource_id?: string;
  details: Record<string, any>;
  created_at: string;
  // Joined
  employee?: Profile;
  performer?: Profile;
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
  leave_balances?: Array<{ leave_type_id: string; total_days: number }>;
  leave_entitlements?: Array<{ leave_type_id: string; days_per_year: number }>;
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
