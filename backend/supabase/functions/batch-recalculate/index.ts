import { serve } from "https://deno.land/std@0.177.0/http/server.ts";
import { corsHeaders } from "../_shared/cors.ts";
import { getSupabaseAdmin } from "../_shared/supabase-client.ts";

/**
 * Batch recalculation function.
 * 1. Triggers calculate-session for all completed/edited sessions that have clock_out.
 * 2. Cleans up stale daily_summaries for dates that have NO active sessions
 *    (e.g. all sessions were deleted/cancelled).
 */
serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  try {
    const supabaseAdmin = getSupabaseAdmin();

    // ─── Step 1: Recalculate all existing sessions ──────────────────────
    const { data: sessions, error } = await supabaseAdmin
      .from("work_sessions")
      .select("id, employee_id, session_date")
      .in("status", ["completed", "edited"])
      .not("clock_out", "is", null)
      .order("session_date", { ascending: true });

    if (error) throw new Error(`Failed to fetch sessions: ${error.message}`);

    let successCount = 0;
    let failCount = 0;
    const errors: string[] = [];

    // Track which (employee_id, date) pairs have sessions
    const datesWithSessions = new Set<string>();

    for (const session of (sessions || [])) {
      datesWithSessions.add(`${session.employee_id}::${session.session_date}`);
      try {
        const calcResponse = await fetch(
          `${Deno.env.get("SUPABASE_URL")}/functions/v1/calculate-session`,
          {
            method: "POST",
            headers: {
              Authorization: `Bearer ${Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")}`,
              "Content-Type": "application/json",
            },
            body: JSON.stringify({ session_id: session.id }),
          }
        );

        if (calcResponse.ok) {
          successCount++;
        } else {
          failCount++;
          const errText = await calcResponse.text();
          errors.push(`Session ${session.id} (${session.session_date}): ${errText}`);
        }
      } catch (e) {
        failCount++;
        errors.push(`Session ${session.id}: ${(e as Error).message}`);
      }
    }

    // ─── Step 2: Clean up stale daily_summaries ─────────────────────────
    // Find all daily_summaries and check which ones have no corresponding sessions
    const { data: allSummaries, error: sumError } = await supabaseAdmin
      .from("daily_summaries")
      .select("id, employee_id, summary_date, total_work_minutes, total_overtime_minutes");

    let cleanedCount = 0;
    let recalcSummaryCount = 0;

    if (!sumError && allSummaries) {
      for (const summary of allSummaries) {
        const key = `${summary.employee_id}::${summary.summary_date}`;
        if (!datesWithSessions.has(key)) {
          // This daily_summary has no active sessions — check if it has stale data
          // Trigger recalculate-daily-summary which will correctly set values to 0
          try {
            const recalcResponse = await fetch(
              `${Deno.env.get("SUPABASE_URL")}/functions/v1/recalculate-daily-summary`,
              {
                method: "POST",
                headers: {
                  Authorization: `Bearer ${Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")}`,
                  "Content-Type": "application/json",
                },
                body: JSON.stringify({
                  employee_id: summary.employee_id,
                  date: summary.summary_date,
                }),
              }
            );

            if (recalcResponse.ok) {
              recalcSummaryCount++;
            } else {
              errors.push(`Stale summary ${summary.summary_date}: ${await recalcResponse.text()}`);
            }
          } catch (e) {
            errors.push(`Stale summary ${summary.summary_date}: ${(e as Error).message}`);
          }
          cleanedCount++;
        }
      }
    }

    return new Response(
      JSON.stringify({
        message: `Recalculated ${successCount}/${(sessions || []).length} sessions, cleaned ${recalcSummaryCount}/${cleanedCount} stale summaries`,
        sessions_total: (sessions || []).length,
        sessions_success: successCount,
        sessions_failed: failCount,
        stale_summaries_found: cleanedCount,
        stale_summaries_recalculated: recalcSummaryCount,
        errors: errors.slice(0, 20),
      }),
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
