-- Activity Logs table for tracking all employee actions
CREATE TABLE activity_logs (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id UUID NOT NULL REFERENCES companies(id) ON DELETE CASCADE,
  employee_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  performed_by UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  action_type TEXT NOT NULL,
  resource_type TEXT NOT NULL,
  resource_id UUID,
  details JSONB DEFAULT '{}',
  created_at TIMESTAMPTZ DEFAULT now()
);

-- Indexes
CREATE INDEX idx_activity_logs_company ON activity_logs(company_id);
CREATE INDEX idx_activity_logs_employee ON activity_logs(employee_id);
CREATE INDEX idx_activity_logs_action ON activity_logs(company_id, action_type);
CREATE INDEX idx_activity_logs_created ON activity_logs(company_id, created_at DESC);

-- RLS
ALTER TABLE activity_logs ENABLE ROW LEVEL SECURITY;

-- Operators can read their company's logs
CREATE POLICY "operator_view_activity_logs" ON activity_logs
  FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM profiles
      WHERE profiles.id = auth.uid()
      AND profiles.role = 'operator'
      AND profiles.company_id = activity_logs.company_id
    )
  );

-- Service role inserts (edge functions use supabaseAdmin)
CREATE POLICY "service_insert_activity_logs" ON activity_logs
  FOR INSERT WITH CHECK (true);

-- Super admin can see all
CREATE POLICY "super_admin_all_activity_logs" ON activity_logs
  FOR ALL USING (
    EXISTS (
      SELECT 1 FROM profiles
      WHERE profiles.id = auth.uid()
      AND profiles.role = 'super_admin'
    )
  );
