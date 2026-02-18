-- Allow employees to update their own completed sessions (for soft-delete of manual entries)
DROP POLICY "Employees and chefs can update own open sessions" ON work_sessions;

CREATE POLICY "Employees and chefs can update own sessions"
  ON work_sessions FOR UPDATE
  USING (employee_id = auth.uid() AND status IN ('active', 'completed'));

-- Allow employees to delete their own sessions
CREATE POLICY "Employees and chefs can delete own sessions"
  ON work_sessions FOR DELETE
  USING (employee_id = auth.uid());
