ALTER TABLE work_sessions ADD COLUMN IF NOT EXISTS reminder_sent BOOLEAN DEFAULT false;
