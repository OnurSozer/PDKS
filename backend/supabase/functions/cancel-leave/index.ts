import { serve } from "https://deno.land/std@0.177.0/http/server.ts";
import { corsHeaders } from "../_shared/cors.ts";
import { getSupabaseAdmin, getSupabaseClient } from "../_shared/supabase-client.ts";
import { getAuthUser, requireRole } from "../_shared/auth.ts";
import { logActivity } from "../_shared/activity-log.ts";

/**
 * Cancel a leave record. Reverses the leave_balances.used_days update
 * and recalculates daily summaries for affected dates.
 */
serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  try {
    const authHeader = req.headers.get("Authorization")!;
    const supabase = getSupabaseClient(authHeader);
    const user = await getAuthUser(supabase);
    requireRole(user, ["employee", "chef", "operator"]);

    const { leave_record_id } = await req.json();
    if (!leave_record_id) throw new Error("leave_record_id is required");

    const supabaseAdmin = getSupabaseAdmin();

    // Fetch the leave record
    const { data: leaveRecord, error: fetchError } = await supabaseAdmin
      .from("leave_records")
      .select("*")
      .eq("id", leave_record_id)
      .single();

    if (fetchError || !leaveRecord) throw new Error("Leave record not found");

    // Authorization: employees can only cancel their own, operators their company's
    if (user.role === "employee" || user.role === "chef") {
      if (leaveRecord.employee_id !== user.id) {
        throw new Error("Forbidden: not your leave record");
      }
    } else if (user.role === "operator") {
      if (leaveRecord.company_id !== user.company_id) {
        throw new Error("Forbidden: leave record belongs to another company");
      }
    }

    if (leaveRecord.status === "cancelled") {
      throw new Error("Leave record is already cancelled");
    }

    // 1. Cancel the leave record
    const { data: updatedRecord, error: cancelError } = await supabaseAdmin
      .from("leave_records")
      .update({ status: "cancelled" })
      .eq("id", leave_record_id)
      .select()
      .single();

    if (cancelError) throw new Error(`Failed to cancel leave record: ${cancelError.message}`);

    logActivity(supabaseAdmin, {
      company_id: leaveRecord.company_id,
      employee_id: leaveRecord.employee_id,
      performed_by: user.id,
      action_type: "leave_cancel",
      resource_type: "leave_record",
      resource_id: leave_record_id,
      details: { start_date: leaveRecord.start_date, end_date: leaveRecord.end_date, total_days: leaveRecord.total_days },
    });

    // 2. Reverse the balance update (only for deductible leave types)
    const { data: leaveType } = await supabaseAdmin
      .from("leave_types")
      .select("is_deductible")
      .eq("id", leaveRecord.leave_type_id)
      .single();

    const isDeductible = leaveType?.is_deductible !== false;

    if (isDeductible) {
      const currentYear = new Date(leaveRecord.start_date).getFullYear();
      const { data: balance } = await supabaseAdmin
        .from("leave_balances")
        .select("*")
        .eq("employee_id", leaveRecord.employee_id)
        .eq("leave_type_id", leaveRecord.leave_type_id)
        .eq("year", currentYear)
        .single();

      if (balance) {
        const newUsedDays = Math.max(
          0,
          parseFloat(balance.used_days) - parseFloat(leaveRecord.total_days)
        );
        await supabaseAdmin
          .from("leave_balances")
          .update({ used_days: newUsedDays })
          .eq("id", balance.id);
      }
    }

    // 3. Recalculate daily summaries for each affected date
    const startDate = new Date(leaveRecord.start_date);
    const endDate = new Date(leaveRecord.end_date);
    const current = new Date(startDate);

    while (current <= endDate) {
      const dateStr = current.toISOString().split("T")[0];
      try {
        await fetch(
          `${Deno.env.get("SUPABASE_URL")}/functions/v1/recalculate-daily-summary`,
          {
            method: "POST",
            headers: {
              Authorization: `Bearer ${Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")}`,
              "Content-Type": "application/json",
            },
            body: JSON.stringify({
              employee_id: leaveRecord.employee_id,
              date: dateStr,
            }),
          }
        );
      } catch (e) {
        console.error(`Failed to recalculate summary for ${dateStr}:`, e);
      }
      current.setDate(current.getDate() + 1);
    }

    return new Response(
      JSON.stringify({ leave_record: updatedRecord }),
      {
        headers: { ...corsHeaders, "Content-Type": "application/json" },
        status: 200,
      }
    );
  } catch (error) {
    const msg = (error as Error).message;
    const status = msg === "Unauthorized" ? 401 : msg.startsWith("Forbidden") ? 403 : 400;
    return new Response(JSON.stringify({ error: msg }), {
      headers: { ...corsHeaders, "Content-Type": "application/json" },
      status,
    });
  }
});
