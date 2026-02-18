export async function logActivity(
  supabaseAdmin: any,
  params: {
    company_id: string;
    employee_id: string;
    performed_by: string;
    action_type: string;
    resource_type: string;
    resource_id?: string;
    details?: Record<string, any>;
  }
) {
  try {
    await supabaseAdmin.from("activity_logs").insert({
      company_id: params.company_id,
      employee_id: params.employee_id,
      performed_by: params.performed_by,
      action_type: params.action_type,
      resource_type: params.resource_type,
      resource_id: params.resource_id || null,
      details: params.details || {},
    });
  } catch (_) {
    // Fire-and-forget — never block the main flow
  }
}
