import { serve } from "https://deno.land/std@0.177.0/http/server.ts";
import { corsHeaders } from "../_shared/cors.ts";
import { getSupabaseAdmin } from "../_shared/supabase-client.ts";

/**
 * Temporary debug function to inspect calculation data.
 * Returns work_sessions and daily_summaries for verification.
 */
serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  try {
    const supabaseAdmin = getSupabaseAdmin();

    // Get all non-cancelled sessions
    const { data: sessions } = await supabaseAdmin
      .from("work_sessions")
      .select("id, employee_id, session_date, clock_in, clock_out, total_minutes, regular_minutes, overtime_minutes, overtime_multiplier, status")
      .neq("status", "cancelled")
      .order("session_date", { ascending: true });

    // Get all daily summaries
    const { data: summaries } = await supabaseAdmin
      .from("daily_summaries")
      .select("employee_id, summary_date, total_work_minutes, expected_work_minutes, total_regular_minutes, total_overtime_minutes, deficit_minutes, status, work_day_type")
      .order("summary_date", { ascending: true });

    // Get shift templates
    const { data: schedules } = await supabaseAdmin
      .from("employee_schedules")
      .select("employee_id, effective_from, effective_to, custom_start_time, custom_end_time, custom_work_days, custom_break_duration_minutes, shift_template:shift_templates(name, start_time, end_time, work_days, break_duration_minutes)");

    return new Response(
      JSON.stringify({ sessions, summaries, schedules }, null, 2),
      {
        headers: { ...corsHeaders, "Content-Type": "application/json" },
        status: 200,
      }
    );
  } catch (error) {
    return new Response(
      JSON.stringify({ error: (error as Error).message }),
      {
        headers: { ...corsHeaders, "Content-Type": "application/json" },
        status: 400,
      }
    );
  }
});
