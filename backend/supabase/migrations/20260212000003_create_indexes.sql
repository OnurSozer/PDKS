-- ============================================================
-- PDKS Performance Indexes
-- ============================================================

-- Work sessions: fast lookup by employee + date
CREATE INDEX idx_work_sessions_employee_date ON work_sessions(employee_id, session_date);

-- Work sessions: fast lookup by company + date (operator views)
CREATE INDEX idx_work_sessions_company_date ON work_sessions(company_id, session_date);

-- Work sessions: find open sessions (for clock-out checks)
CREATE INDEX idx_work_sessions_active ON work_sessions(employee_id, status) WHERE status = 'active';

-- Daily summaries: fast lookup by company + date (reporting)
CREATE INDEX idx_daily_summaries_company_date ON daily_summaries(company_id, summary_date);

-- Daily summaries: fast lookup by employee + date
CREATE INDEX idx_daily_summaries_employee_date ON daily_summaries(employee_id, summary_date);

-- Profiles: fast lookup by company
CREATE INDEX idx_profiles_company ON profiles(company_id);

-- Profiles: fast lookup by role
CREATE INDEX idx_profiles_role ON profiles(role);

-- Employee schedules: fast lookup by employee
CREATE INDEX idx_employee_schedules_employee ON employee_schedules(employee_id);

-- Employee schedules: fast lookup by company
CREATE INDEX idx_employee_schedules_company ON employee_schedules(company_id);

-- Employee overtime rules: fast lookup by employee
CREATE INDEX idx_employee_overtime_rules_employee ON employee_overtime_rules(employee_id);

-- Employee overtime rules: fast lookup by company
CREATE INDEX idx_employee_overtime_rules_company ON employee_overtime_rules(company_id);

-- Leave records: fast lookup by employee
CREATE INDEX idx_leave_records_employee ON leave_records(employee_id);

-- Leave records: fast lookup by company + dates (operator views)
CREATE INDEX idx_leave_records_company_dates ON leave_records(company_id, start_date, end_date);

-- Leave balances: fast lookup by employee + year
CREATE INDEX idx_leave_balances_employee_year ON leave_balances(employee_id, year);

-- Leave balances: fast lookup by company
CREATE INDEX idx_leave_balances_company ON leave_balances(company_id);

-- Device tokens: fast lookup by user
CREATE INDEX idx_device_tokens_user ON device_tokens(user_id) WHERE is_active = true;

-- Shift templates: fast lookup by company
CREATE INDEX idx_shift_templates_company ON shift_templates(company_id);
