-- Add is_deductible and allows_half_day to leave_types
ALTER TABLE leave_types ADD COLUMN IF NOT EXISTS is_deductible BOOLEAN DEFAULT true;
ALTER TABLE leave_types ADD COLUMN IF NOT EXISTS allows_half_day BOOLEAN DEFAULT false;

-- Mark sick leave types as non-deductible
UPDATE leave_types SET is_deductible = false WHERE name ILIKE '%hastalık%' OR name ILIKE '%sick%';

-- Add is_half_day to leave_records
ALTER TABLE leave_records ADD COLUMN IF NOT EXISTS is_half_day BOOLEAN DEFAULT false;
