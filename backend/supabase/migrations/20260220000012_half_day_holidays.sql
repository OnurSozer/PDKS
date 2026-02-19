-- Add half-day support to company_holidays
ALTER TABLE company_holidays ADD COLUMN IF NOT EXISTS is_half_day BOOLEAN DEFAULT false;

-- Allow 'half_holiday' in daily_summaries.work_day_type
ALTER TABLE daily_summaries DROP CONSTRAINT IF EXISTS daily_summaries_work_day_type_check;
ALTER TABLE daily_summaries ADD CONSTRAINT daily_summaries_work_day_type_check
  CHECK (work_day_type IN ('regular', 'weekend', 'holiday', 'half_holiday'));
