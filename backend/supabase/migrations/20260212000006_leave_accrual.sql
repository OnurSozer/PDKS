-- ============================================================
-- Leave Accrual System
-- 1. employee_leave_entitlements table
-- 2. leave_accrual_mode column on notification_settings
-- 3. RLS policies, indexes, trigger
-- ============================================================

-- ============================================================
-- EMPLOYEE LEAVE ENTITLEMENTS
-- ============================================================
CREATE TABLE employee_leave_entitlements (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  employee_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  leave_type_id UUID NOT NULL REFERENCES leave_types(id) ON DELETE CASCADE,
  company_id UUID NOT NULL REFERENCES companies(id) ON DELETE CASCADE,
  days_per_year DECIMAL(5,1) NOT NULL,
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now(),
  UNIQUE(employee_id, leave_type_id)
);

-- Index on employee_id for fast lookups
CREATE INDEX idx_employee_leave_entitlements_employee
  ON employee_leave_entitlements(employee_id);

-- updated_at trigger
CREATE TRIGGER set_updated_at BEFORE UPDATE ON employee_leave_entitlements
  FOR EACH ROW EXECUTE FUNCTION public.handle_updated_at();

-- ============================================================
-- RLS POLICIES
-- ============================================================
ALTER TABLE employee_leave_entitlements ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Super admins can do everything on employee_leave_entitlements"
  ON employee_leave_entitlements FOR ALL
  USING ((auth.jwt()->>'user_role') = 'super_admin');

CREATE POLICY "Operators manage entitlements in their company"
  ON employee_leave_entitlements FOR ALL
  USING (
    company_id = (auth.jwt()->>'company_id')::uuid
    AND (auth.jwt()->>'user_role') = 'operator'
  );

CREATE POLICY "Employees and chefs can view their own entitlements"
  ON employee_leave_entitlements FOR SELECT
  USING (employee_id = auth.uid());

-- ============================================================
-- ADD leave_accrual_mode TO notification_settings
-- ============================================================
ALTER TABLE notification_settings
  ADD COLUMN leave_accrual_mode TEXT DEFAULT 'monthly'
  CHECK (leave_accrual_mode IN ('monthly', 'yearly'));
