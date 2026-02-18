import { serve } from "https://deno.land/std@0.177.0/http/server.ts";
import { corsHeaders } from "../_shared/cors.ts";
import { getSupabaseClient, getSupabaseAdmin } from "../_shared/supabase-client.ts";
import { getAuthUser, requireRole } from "../_shared/auth.ts";

/**
 * Thin wrapper: looks up company's boss_call special day type,
 * delegates to the same calculation logic.
 * Kept for backward compatibility with existing callers.
 */
serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  try {
    const authHeader = req.headers.get("Authorization")!;
    const supabase = getSupabaseClient(authHeader);
    const user = await getAuthUser(supabase);
    requireRole(user, ["operator", "super_admin"]);

    const { employee_id, date, is_boss_call } = await req.json();
    if (!employee_id || !date) throw new Error("employee_id and date are required");
    if (typeof is_boss_call !== "boolean") throw new Error("is_boss_call must be a boolean");

    const supabaseAdmin = getSupabaseAdmin();

    // Get the daily summary
    const { data: summary, error: fetchError } = await supabaseAdmin
      .from("daily_summaries")
      .select("*")
      .eq("employee_id", employee_id)
      .eq("summary_date", date)
      .single();

    if (fetchError || !summary) {
      throw new Error("Daily summary not found for this employee and date");
    }

    if (!is_boss_call) {
      // Clear special day
      const { data: updated, error: updateError } = await supabaseAdmin
        .from("daily_summaries")
        .update({
          is_boss_call: false,
          special_day_type_id: null,
          effective_work_minutes: summary.total_work_minutes,
        })
        .eq("id", summary.id)
        .select()
        .single();

      if (updateError) throw new Error(`Failed to update daily summary: ${updateError.message}`);

      return new Response(JSON.stringify({ summary: updated }), {
        headers: { ...corsHeaders, "Content-Type": "application/json" },
        status: 200,
      });
    }

    // Look up the boss_call special day type for this company
    const { data: bossCallType } = await supabaseAdmin
      .from("special_day_types")
      .select("*")
      .eq("company_id", summary.company_id)
      .eq("code", "boss_call")
      .eq("is_active", true)
      .single();

    // Get company work settings for boss_call_multiplier (fallback)
    const { data: workSettings } = await supabaseAdmin
      .from("company_work_settings")
      .select("*")
      .eq("company_id", summary.company_id)
      .single();

    const bossCallMultiplier = bossCallType
      ? parseFloat(bossCallType.multiplier)
      : workSettings
        ? parseFloat(workSettings.boss_call_multiplier)
        : 1.5;

    const expectedDaily = summary.expected_work_minutes || 480;
    const halfDay = Math.round(expectedDaily / 2);
    const worked = summary.total_work_minutes;

    let roundedMinutes: number;
    if (worked <= 0) {
      roundedMinutes = halfDay;
    } else if (worked < halfDay) {
      roundedMinutes = halfDay;
    } else if (worked <= expectedDaily) {
      roundedMinutes = expectedDaily;
    } else {
      roundedMinutes = worked;
    }

    const effectiveWorkMinutes = Math.round(roundedMinutes * bossCallMultiplier);

    const { data: updated, error: updateError } = await supabaseAdmin
      .from("daily_summaries")
      .update({
        is_boss_call: true,
        special_day_type_id: bossCallType?.id || null,
        effective_work_minutes: effectiveWorkMinutes,
      })
      .eq("id", summary.id)
      .select()
      .single();

    if (updateError) throw new Error(`Failed to update daily summary: ${updateError.message}`);

    return new Response(JSON.stringify({ summary: updated }), {
      headers: { ...corsHeaders, "Content-Type": "application/json" },
      status: 200,
    });
  } catch (error) {
    const msg = (error as Error).message;
    const status = msg === "Unauthorized" ? 401 : msg.startsWith("Forbidden") ? 403 : 400;
    return new Response(JSON.stringify({ error: msg }), {
      headers: { ...corsHeaders, "Content-Type": "application/json" },
      status,
    });
  }
});
