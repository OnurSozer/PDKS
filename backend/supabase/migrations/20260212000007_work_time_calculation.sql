-- ============================================================
-- Migration: Work Time Calculation System
-- Adds: company_holidays, company_work_settings tables
-- Adds: new columns on daily_summaries for deficit/boss call/holiday tracking
-- ============================================================

-- 1. New table: company_holidays
CREATE TABLE company_holidays (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id UUID NOT NULL REFERENCES companies(id) ON DELETE CASCADE,
  name TEXT NOT NULL,
  holiday_date DATE NOT NULL,
  is_recurring BOOLEAN DEFAULT false,
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now(),
  UNIQUE(company_id, holiday_date)
);

-- 2. New table: company_work_settings
CREATE TABLE company_work_settings (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id UUID NOT NULL REFERENCES companies(id) ON DELETE CASCADE,
  monthly_work_days_constant DECIMAL(5,2) NOT NULL DEFAULT 21.66,
  overtime_multiplier DECIMAL(3,2) NOT NULL DEFAULT 1.50,
  weekend_multiplier DECIMAL(3,2) NOT NULL DEFAULT 1.50,
  holiday_multiplier DECIMAL(3,2) NOT NULL DEFAULT 2.00,
  boss_call_multiplier DECIMAL(3,2) NOT NULL DEFAULT 1.50,
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now(),
  UNIQUE(company_id)
);

-- 3. New columns on daily_summaries
ALTER TABLE daily_summaries
  ADD COLUMN deficit_minutes INTEGER DEFAULT 0,
  ADD COLUMN is_holiday BOOLEAN DEFAULT false,
  ADD COLUMN is_boss_call BOOLEAN DEFAULT false,
  ADD COLUMN effective_work_minutes INTEGER DEFAULT 0,
  ADD COLUMN work_day_type TEXT DEFAULT 'regular'
    CHECK (work_day_type IN ('regular', 'weekend', 'holiday'));

-- ============================================================
-- Indexes
-- ============================================================
CREATE INDEX idx_company_holidays_company_id ON company_holidays(company_id);
CREATE INDEX idx_company_holidays_date ON company_holidays(holiday_date);
CREATE INDEX idx_company_holidays_company_date ON company_holidays(company_id, holiday_date);
CREATE INDEX idx_company_work_settings_company_id ON company_work_settings(company_id);
CREATE INDEX idx_daily_summaries_boss_call ON daily_summaries(is_boss_call) WHERE is_boss_call = true;
CREATE INDEX idx_daily_summaries_work_day_type ON daily_summaries(work_day_type);

-- ============================================================
-- Triggers: updated_at
-- ============================================================
CREATE TRIGGER set_updated_at_company_holidays
  BEFORE UPDATE ON company_holidays
  FOR EACH ROW EXECUTE FUNCTION handle_updated_at();

CREATE TRIGGER set_updated_at_company_work_settings
  BEFORE UPDATE ON company_work_settings
  FOR EACH ROW EXECUTE FUNCTION handle_updated_at();

-- ============================================================
-- RLS Policies: company_holidays
-- ============================================================
ALTER TABLE company_holidays ENABLE ROW LEVEL SECURITY;

-- Super admins can do everything
CREATE POLICY "super_admin_all_company_holidays" ON company_holidays
  FOR ALL
  USING (
    EXISTS (
      SELECT 1 FROM profiles
      WHERE profiles.id = auth.uid()
      AND profiles.role = 'super_admin'
    )
  );

-- Operators can manage their company's holidays
CREATE POLICY "operator_manage_company_holidays" ON company_holidays
  FOR ALL
  USING (
    EXISTS (
      SELECT 1 FROM profiles
      WHERE profiles.id = auth.uid()
      AND profiles.role = 'operator'
      AND profiles.company_id = company_holidays.company_id
    )
  );

-- Employees can view their company's holidays
CREATE POLICY "employee_view_company_holidays" ON company_holidays
  FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM profiles
      WHERE profiles.id = auth.uid()
      AND profiles.role IN ('employee', 'chef')
      AND profiles.company_id = company_holidays.company_id
    )
  );

-- ============================================================
-- RLS Policies: company_work_settings
-- ============================================================
ALTER TABLE company_work_settings ENABLE ROW LEVEL SECURITY;

-- Super admins can do everything
CREATE POLICY "super_admin_all_company_work_settings" ON company_work_settings
  FOR ALL
  USING (
    EXISTS (
      SELECT 1 FROM profiles
      WHERE profiles.id = auth.uid()
      AND profiles.role = 'super_admin'
    )
  );

-- Operators can manage their company's work settings
CREATE POLICY "operator_manage_company_work_settings" ON company_work_settings
  FOR ALL
  USING (
    EXISTS (
      SELECT 1 FROM profiles
      WHERE profiles.id = auth.uid()
      AND profiles.role = 'operator'
      AND profiles.company_id = company_work_settings.company_id
    )
  );

-- Employees can view their company's work settings
CREATE POLICY "employee_view_company_work_settings" ON company_work_settings
  FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM profiles
      WHERE profiles.id = auth.uid()
      AND profiles.role IN ('employee', 'chef')
      AND profiles.company_id = company_work_settings.company_id
    )
  );
