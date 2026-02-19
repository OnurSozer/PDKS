-- Notification logs table for tracking operator-sent custom notifications
CREATE TABLE notification_logs (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id UUID REFERENCES companies(id),
  sent_by UUID REFERENCES profiles(id),
  title TEXT NOT NULL,
  body TEXT NOT NULL,
  recipient_count INTEGER DEFAULT 0,
  notification_type TEXT DEFAULT 'custom',
  created_at TIMESTAMPTZ DEFAULT now()
);

ALTER TABLE notification_logs ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Operators can view own company logs"
  ON notification_logs FOR SELECT
  USING (company_id = (SELECT company_id FROM profiles WHERE id = auth.uid()));
