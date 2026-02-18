import { serve } from "https://deno.land/std@0.177.0/http/server.ts";
import { corsHeaders } from "../_shared/cors.ts";
import { getSupabaseAdmin, getSupabaseClient } from "../_shared/supabase-client.ts";
import { getAuthUser, requireRole } from "../_shared/auth.ts";
import { logActivity } from "../_shared/activity-log.ts";

/**
 * Record leave for an employee (self-service, no approval needed).
 * MUST atomically:
 * 1. Create leave_record
 * 2. Update leave_balances.used_days
 * 3. Update daily_summaries for affected dates
 */
serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  try {
    const authHeader = req.headers.get("Authorization")!;
    const supabase = getSupabaseClient(authHeader);
    const user = await getAuthUser(supabase);
    requireRole(user, ["employee", "chef"]);

    const { leave_type_id, start_date, end_date, reason } = await req.json();

    if (!leave_type_id || !start_date || !end_date) {
      throw new Error("leave_type_id, start_date, and end_date are required");
    }

    const startDate = new Date(start_date);
    const endDate = new Date(end_date);

    if (endDate < startDate) {
      throw new Error("end_date must be on or after start_date");
    }

    // Calculate total days (simple: end - start + 1, weekdays only could be added later)
    const diffTime = endDate.getTime() - startDate.getTime();
    const totalDays = Math.round(diffTime / (1000 * 60 * 60 * 24)) + 1;

    const supabaseAdmin = getSupabaseAdmin();
    const currentYear = startDate.getFullYear();

    // Get leave type info
    const { data: leaveType, error: ltError } = await supabaseAdmin
      .from("leave_types")
      .select("*")
      .eq("id", leave_type_id)
      .single();

    if (ltError || !leaveType) {
      throw new Error("Leave type not found");
    }

    // Check leave balance — auto-create if missing
    let { data: balance, error: balanceError } = await supabaseAdmin
      .from("leave_balances")
      .select("*")
      .eq("employee_id", user.id)
      .eq("leave_type_id", leave_type_id)
      .eq("year", currentYear)
      .maybeSingle();

    if (!balance) {
      // Auto-create balance using leave type defaults
      const defaultDays = leaveType.default_days_per_year || 0;
      const { data: newBalance, error: createError } = await supabaseAdmin
        .from("leave_balances")
        .insert({
          employee_id: user.id,
          company_id: user.company_id,
          leave_type_id,
          year: currentYear,
          total_days: defaultDays,
          used_days: 0,
        })
        .select()
        .single();

      if (createError) throw new Error(`Failed to create leave balance: ${createError.message}`);
      balance = newBalance;
    }

    // Only check balance if the leave type has a day limit (total_days > 0)
    if (parseFloat(balance.total_days) > 0) {
      const remainingDays = parseFloat(balance.total_days) - parseFloat(balance.used_days);
      if (totalDays > remainingDays) {
        throw new Error(`Insufficient leave balance. Available: ${remainingDays} days, Requested: ${totalDays} days`);
      }
    }

    // 1. Create leave record
    const { data: leaveRecord, error: recordError } = await supabaseAdmin
      .from("leave_records")
      .insert({
        employee_id: user.id,
        company_id: user.company_id,
        leave_type_id,
        start_date,
        end_date,
        total_days: totalDays,
        reason: reason || null,
        status: "active",
      })
      .select()
      .single();

    if (recordError) throw new Error(`Failed to create leave record: ${recordError.message}`);

    // 2. Atomically update leave balance (used_days += totalDays)
    const newUsedDays = parseFloat(balance.used_days) + totalDays;
    const { error: updateBalanceError } = await supabaseAdmin
      .from("leave_balances")
      .update({ used_days: newUsedDays })
      .eq("id", balance.id);

    if (updateBalanceError) {
      // Rollback: delete leave record
      await supabaseAdmin.from("leave_records").delete().eq("id", leaveRecord.id);
      throw new Error(`Failed to update leave balance: ${updateBalanceError.message}`);
    }

    logActivity(supabaseAdmin, {
      company_id: user.company_id,
      employee_id: user.id,
      performed_by: user.id,
      action_type: "leave_record",
      resource_type: "leave_record",
      resource_id: leaveRecord.id,
      details: { start_date, end_date, total_days: totalDays, leave_type: leaveType.name },
    });

    // 3. Update daily_summaries for each day in the leave period
    const current = new Date(start_date);
    while (current <= endDate) {
      const dateStr = current.toISOString().split("T")[0];

      // Trigger daily summary recalculation
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
              employee_id: user.id,
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
      JSON.stringify({ leave_record: leaveRecord }),
      {
        headers: { ...corsHeaders, "Content-Type": "application/json" },
        status: 201,
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
