-- ============================================================
-- Migration: Special Day Types System
-- Replaces hardcoded boss_call boolean with a generic,
-- table-driven "special day types" system.
-- ============================================================

-- 1. New table: special_day_types
CREATE TABLE special_day_types (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id UUID NOT NULL REFERENCES companies(id) ON DELETE CASCADE,
  name TEXT NOT NULL,
  code TEXT NOT NULL,
  calculation_mode TEXT NOT NULL DEFAULT 'rounding'
    CHECK (calculation_mode IN ('rounding', 'fixed_hours')),
  multiplier DECIMAL(4,2) DEFAULT 1.50,
  base_minutes INTEGER DEFAULT 0,
  extra_minutes INTEGER DEFAULT 0,
  extra_multiplier DECIMAL(4,2) DEFAULT 1.50,
  applies_to_all BOOLEAN DEFAULT true,
  is_active BOOLEAN DEFAULT true,
  display_order INTEGER DEFAULT 0,
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now(),
  UNIQUE(company_id, code)
);

-- 2. New table: employee_special_day_types (junction for per-employee eligibility)
CREATE TABLE employee_special_day_types (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  employee_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  special_day_type_id UUID NOT NULL REFERENCES special_day_types(id) ON DELETE CASCADE,
  company_id UUID NOT NULL REFERENCES companies(id) ON DELETE CASCADE,
  created_at TIMESTAMPTZ DEFAULT now(),
  UNIQUE(employee_id, special_day_type_id)
);

-- 3. Add special_day_type_id to daily_summaries
ALTER TABLE daily_summaries
  ADD COLUMN special_day_type_id UUID REFERENCES special_day_types(id) ON DELETE SET NULL;

-- ============================================================
-- Data Migration: seed boss_call type per company
-- ============================================================

-- For each company that has work settings, create a "Patron Çağırdı" type
INSERT INTO special_day_types (company_id, name, code, calculation_mode, multiplier, applies_to_all, display_order)
SELECT
  cws.company_id,
  'Patron Çağırdı',
  'boss_call',
  'rounding',
  cws.boss_call_multiplier,
  true,
  0
FROM company_work_settings cws
ON CONFLICT (company_id, code) DO NOTHING;

-- For companies without work settings but with daily_summaries that have boss_call
INSERT INTO special_day_types (company_id, name, code, calculation_mode, multiplier, applies_to_all, display_order)
SELECT DISTINCT
  ds.company_id,
  'Patron Çağırdı',
  'boss_call',
  'rounding',
  1.50,
  true,
  0
FROM daily_summaries ds
WHERE ds.is_boss_call = true
  AND NOT EXISTS (
    SELECT 1 FROM special_day_types sdt
    WHERE sdt.company_id = ds.company_id AND sdt.code = 'boss_call'
  )
ON CONFLICT (company_id, code) DO NOTHING;

-- Backfill special_day_type_id on existing boss_call rows
UPDATE daily_summaries ds
SET special_day_type_id = sdt.id
FROM special_day_types sdt
WHERE ds.is_boss_call = true
  AND ds.company_id = sdt.company_id
  AND sdt.code = 'boss_call'
  AND ds.special_day_type_id IS NULL;

-- ============================================================
-- Indexes
-- ============================================================
CREATE INDEX idx_special_day_types_company_id ON special_day_types(company_id);
CREATE INDEX idx_special_day_types_company_code ON special_day_types(company_id, code);
CREATE INDEX idx_special_day_types_active ON special_day_types(company_id, is_active);
CREATE INDEX idx_employee_special_day_types_employee ON employee_special_day_types(employee_id);
CREATE INDEX idx_employee_special_day_types_type ON employee_special_day_types(special_day_type_id);
CREATE INDEX idx_daily_summaries_special_day_type ON daily_summaries(special_day_type_id) WHERE special_day_type_id IS NOT NULL;

-- ============================================================
-- Triggers: updated_at
-- ============================================================
CREATE TRIGGER set_updated_at_special_day_types
  BEFORE UPDATE ON special_day_types
  FOR EACH ROW EXECUTE FUNCTION handle_updated_at();

-- ============================================================
-- RLS Policies: special_day_types
-- ============================================================
ALTER TABLE special_day_types ENABLE ROW LEVEL SECURITY;

CREATE POLICY "super_admin_all_special_day_types" ON special_day_types
  FOR ALL
  USING (
    EXISTS (
      SELECT 1 FROM profiles
      WHERE profiles.id = auth.uid()
      AND profiles.role = 'super_admin'
    )
  );

CREATE POLICY "operator_manage_special_day_types" ON special_day_types
  FOR ALL
  USING (
    EXISTS (
      SELECT 1 FROM profiles
      WHERE profiles.id = auth.uid()
      AND profiles.role = 'operator'
      AND profiles.company_id = special_day_types.company_id
    )
  );

CREATE POLICY "employee_view_special_day_types" ON special_day_types
  FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM profiles
      WHERE profiles.id = auth.uid()
      AND profiles.role IN ('employee', 'chef')
      AND profiles.company_id = special_day_types.company_id
    )
  );

-- ============================================================
-- RLS Policies: employee_special_day_types
-- ============================================================
ALTER TABLE employee_special_day_types ENABLE ROW LEVEL SECURITY;

CREATE POLICY "super_admin_all_employee_special_day_types" ON employee_special_day_types
  FOR ALL
  USING (
    EXISTS (
      SELECT 1 FROM profiles
      WHERE profiles.id = auth.uid()
      AND profiles.role = 'super_admin'
    )
  );

CREATE POLICY "operator_manage_employee_special_day_types" ON employee_special_day_types
  FOR ALL
  USING (
    EXISTS (
      SELECT 1 FROM profiles
      WHERE profiles.id = auth.uid()
      AND profiles.role = 'operator'
      AND profiles.company_id = employee_special_day_types.company_id
    )
  );

CREATE POLICY "employee_view_own_special_day_types" ON employee_special_day_types
  FOR SELECT
  USING (
    employee_id = auth.uid()
  );
