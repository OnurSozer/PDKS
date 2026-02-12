-- ============================================================
-- PDKS Row Level Security Policies
-- ============================================================

-- ============================================================
-- COMPANIES
-- ============================================================
ALTER TABLE companies ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Super admins can do everything on companies"
  ON companies FOR ALL
  USING ((auth.jwt()->>'user_role') = 'super_admin');

CREATE POLICY "Operators can view their own company"
  ON companies FOR SELECT
  USING (id = (auth.jwt()->>'company_id')::uuid);

-- ============================================================
-- PROFILES
-- ============================================================
ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Super admins can do everything on profiles"
  ON profiles FOR ALL
  USING ((auth.jwt()->>'user_role') = 'super_admin');

CREATE POLICY "Operators manage profiles in their company"
  ON profiles FOR ALL
  USING (
    company_id = (auth.jwt()->>'company_id')::uuid
    AND (auth.jwt()->>'user_role') = 'operator'
  );

CREATE POLICY "Employees and chefs can view their own profile"
  ON profiles FOR SELECT
  USING (id = auth.uid());

CREATE POLICY "Employees and chefs can update their own profile"
  ON profiles FOR UPDATE
  USING (id = auth.uid())
  WITH CHECK (id = auth.uid());

-- ============================================================
-- SHIFT TEMPLATES
-- ============================================================
ALTER TABLE shift_templates ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Super admins can do everything on shift_templates"
  ON shift_templates FOR ALL
  USING ((auth.jwt()->>'user_role') = 'super_admin');

CREATE POLICY "Operators manage shift templates in their company"
  ON shift_templates FOR ALL
  USING (
    company_id = (auth.jwt()->>'company_id')::uuid
    AND (auth.jwt()->>'user_role') = 'operator'
  );

CREATE POLICY "Employees and chefs can view shift templates in their company"
  ON shift_templates FOR SELECT
  USING (company_id = (auth.jwt()->>'company_id')::uuid);

-- ============================================================
-- EMPLOYEE SCHEDULES
-- ============================================================
ALTER TABLE employee_schedules ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Super admins can do everything on employee_schedules"
  ON employee_schedules FOR ALL
  USING ((auth.jwt()->>'user_role') = 'super_admin');

CREATE POLICY "Operators manage schedules in their company"
  ON employee_schedules FOR ALL
  USING (
    company_id = (auth.jwt()->>'company_id')::uuid
    AND (auth.jwt()->>'user_role') = 'operator'
  );

CREATE POLICY "Employees and chefs can view their own schedule"
  ON employee_schedules FOR SELECT
  USING (employee_id = auth.uid());

-- ============================================================
-- OVERTIME RULES
-- ============================================================
ALTER TABLE overtime_rules ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Super admins can do everything on overtime_rules"
  ON overtime_rules FOR ALL
  USING ((auth.jwt()->>'user_role') = 'super_admin');

CREATE POLICY "Operators manage overtime rules in their company"
  ON overtime_rules FOR ALL
  USING (
    company_id = (auth.jwt()->>'company_id')::uuid
    AND (auth.jwt()->>'user_role') = 'operator'
  );

CREATE POLICY "Employees and chefs can view overtime rules in their company"
  ON overtime_rules FOR SELECT
  USING (company_id = (auth.jwt()->>'company_id')::uuid);

-- ============================================================
-- EMPLOYEE OVERTIME RULES
-- ============================================================
ALTER TABLE employee_overtime_rules ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Super admins can do everything on employee_overtime_rules"
  ON employee_overtime_rules FOR ALL
  USING ((auth.jwt()->>'user_role') = 'super_admin');

CREATE POLICY "Operators manage employee overtime rules in their company"
  ON employee_overtime_rules FOR ALL
  USING (
    company_id = (auth.jwt()->>'company_id')::uuid
    AND (auth.jwt()->>'user_role') = 'operator'
  );

CREATE POLICY "Employees and chefs can view their own overtime rules"
  ON employee_overtime_rules FOR SELECT
  USING (employee_id = auth.uid());

-- ============================================================
-- WORK SESSIONS
-- ============================================================
ALTER TABLE work_sessions ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Employees and chefs see own sessions"
  ON work_sessions FOR SELECT
  USING (employee_id = auth.uid());

CREATE POLICY "Employees and chefs can insert own sessions"
  ON work_sessions FOR INSERT
  WITH CHECK (employee_id = auth.uid());

CREATE POLICY "Employees and chefs can update own open sessions"
  ON work_sessions FOR UPDATE
  USING (employee_id = auth.uid() AND status = 'active');

CREATE POLICY "Operators manage company sessions"
  ON work_sessions FOR ALL
  USING (
    company_id = (auth.jwt()->>'company_id')::uuid
    AND (auth.jwt()->>'user_role') = 'operator'
  );

CREATE POLICY "Super admins can view all sessions"
  ON work_sessions FOR SELECT
  USING ((auth.jwt()->>'user_role') = 'super_admin');

-- ============================================================
-- DAILY SUMMARIES
-- ============================================================
ALTER TABLE daily_summaries ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Super admins can view all daily summaries"
  ON daily_summaries FOR SELECT
  USING ((auth.jwt()->>'user_role') = 'super_admin');

CREATE POLICY "Operators manage daily summaries in their company"
  ON daily_summaries FOR ALL
  USING (
    company_id = (auth.jwt()->>'company_id')::uuid
    AND (auth.jwt()->>'user_role') = 'operator'
  );

CREATE POLICY "Employees and chefs can view their own daily summaries"
  ON daily_summaries FOR SELECT
  USING (employee_id = auth.uid());

-- ============================================================
-- LEAVE TYPES
-- ============================================================
ALTER TABLE leave_types ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Super admins can do everything on leave_types"
  ON leave_types FOR ALL
  USING ((auth.jwt()->>'user_role') = 'super_admin');

CREATE POLICY "Operators manage leave types in their company"
  ON leave_types FOR ALL
  USING (
    company_id = (auth.jwt()->>'company_id')::uuid
    AND (auth.jwt()->>'user_role') = 'operator'
  );

CREATE POLICY "Employees and chefs can view leave types in their company"
  ON leave_types FOR SELECT
  USING (company_id = (auth.jwt()->>'company_id')::uuid);

-- ============================================================
-- LEAVE BALANCES
-- ============================================================
ALTER TABLE leave_balances ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Super admins can do everything on leave_balances"
  ON leave_balances FOR ALL
  USING ((auth.jwt()->>'user_role') = 'super_admin');

CREATE POLICY "Operators manage leave balances in their company"
  ON leave_balances FOR ALL
  USING (
    company_id = (auth.jwt()->>'company_id')::uuid
    AND (auth.jwt()->>'user_role') = 'operator'
  );

CREATE POLICY "Employees and chefs can view their own leave balances"
  ON leave_balances FOR SELECT
  USING (employee_id = auth.uid());

-- ============================================================
-- LEAVE RECORDS
-- ============================================================
ALTER TABLE leave_records ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Employees and chefs manage own leave records"
  ON leave_records FOR ALL
  USING (employee_id = auth.uid());

CREATE POLICY "Operators manage company leave records"
  ON leave_records FOR ALL
  USING (
    company_id = (auth.jwt()->>'company_id')::uuid
    AND (auth.jwt()->>'user_role') = 'operator'
  );

CREATE POLICY "Super admins view all leave records"
  ON leave_records FOR SELECT
  USING ((auth.jwt()->>'user_role') = 'super_admin');

-- ============================================================
-- NOTIFICATION SETTINGS
-- ============================================================
ALTER TABLE notification_settings ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Super admins can do everything on notification_settings"
  ON notification_settings FOR ALL
  USING ((auth.jwt()->>'user_role') = 'super_admin');

CREATE POLICY "Operators manage notification settings in their company"
  ON notification_settings FOR ALL
  USING (
    company_id = (auth.jwt()->>'company_id')::uuid
    AND (auth.jwt()->>'user_role') = 'operator'
  );

-- ============================================================
-- DEVICE TOKENS
-- ============================================================
ALTER TABLE device_tokens ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users manage own device tokens"
  ON device_tokens FOR ALL
  USING (user_id = auth.uid());
