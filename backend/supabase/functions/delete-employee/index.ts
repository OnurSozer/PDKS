import { serve } from "https://deno.land/std@0.177.0/http/server.ts";
import { corsHeaders } from "../_shared/cors.ts";
import { getSupabaseAdmin, getSupabaseClient } from "../_shared/supabase-client.ts";
import { getAuthUser, requireRole } from "../_shared/auth.ts";

serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  try {
    const authHeader = req.headers.get("Authorization")!;
    const supabase = getSupabaseClient(authHeader);
    const user = await getAuthUser(supabase);
    requireRole(user, ["operator"]);

    const { employee_id } = await req.json();
    if (!employee_id) throw new Error("employee_id is required");

    if (employee_id === user.id) {
      throw new Error("Cannot delete your own account");
    }

    const supabaseAdmin = getSupabaseAdmin();

    // Verify the target belongs to operator's company and is employee/chef
    const { data: target, error: targetError } = await supabaseAdmin
      .from("profiles")
      .select("company_id, role")
      .eq("id", employee_id)
      .single();

    if (targetError || !target) throw new Error("Employee not found");
    if (target.company_id !== user.company_id) {
      throw new Error("Forbidden: employee belongs to a different company");
    }
    if (!["employee", "chef"].includes(target.role)) {
      throw new Error("Forbidden: can only delete employee or chef roles");
    }

    // Delete related data (order matters for FK constraints)
    await supabaseAdmin.from("leave_balances").delete().eq("employee_id", employee_id);
    await supabaseAdmin.from("leave_records").delete().eq("employee_id", employee_id);
    await supabaseAdmin.from("employee_overtime_rules").delete().eq("employee_id", employee_id);
    await supabaseAdmin.from("employee_schedules").delete().eq("employee_id", employee_id);
    await supabaseAdmin.from("daily_summaries").delete().eq("employee_id", employee_id);
    await supabaseAdmin.from("work_sessions").delete().eq("employee_id", employee_id);
    await supabaseAdmin.from("device_tokens").delete().eq("user_id", employee_id);

    // Delete the profile
    const { error: profileError } = await supabaseAdmin
      .from("profiles")
      .delete()
      .eq("id", employee_id);

    if (profileError) throw new Error(`Failed to delete profile: ${profileError.message}`);

    // Delete the auth user
    const { error: authError } = await supabaseAdmin.auth.admin.deleteUser(employee_id);
    if (authError) {
      console.error("Failed to delete auth user:", authError.message);
    }

    return new Response(
      JSON.stringify({ success: true }),
      {
        headers: { ...corsHeaders, "Content-Type": "application/json" },
        status: 200,
      }
    );
  } catch (error) {
    const msg = (error as Error).message;
    const status = msg === "Unauthorized" ? 401 : msg.startsWith("Forbidden") ? 403 : 400;
    return new Response(
      JSON.stringify({ error: msg }),
      {
        headers: { ...corsHeaders, "Content-Type": "application/json" },
        status,
      }
    );
  }
});
