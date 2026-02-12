import { serve } from "https://deno.land/std@0.177.0/http/server.ts";
import { corsHeaders } from "../_shared/cors.ts";
import { getSupabaseAdmin } from "../_shared/supabase-client.ts";

/**
 * CORE BUSINESS LOGIC: Calculate regular/overtime minutes for a session.
 * This is called internally (via service_role) after clock-out or session edit.
 *
 * Logic:
 * 1. Get session data
 * 2. Get employee's schedule for session_date
 * 3. Calculate total worked minutes
 * 4. Get overtime rules for employee
 * 5. Apply rules to split regular vs overtime
 * 6. Update session with calculated values
 * 7. Trigger daily summary recalculation
 */
serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  try {
    const { session_id } = await req.json();
    if (!session_id) throw new Error("session_id is required");

    const supabaseAdmin = getSupabaseAdmin();

    // 1. Get the session
    const { data: session, error: sessionError } = await supabaseAdmin
      .from("work_sessions")
      .select("*")
      .eq("id", session_id)
      .single();

    if (sessionError || !session) throw new Error("Session not found");

    if (!session.clock_out) {
      throw new Error("Session has no clock_out time yet");
    }

    const clockIn = new Date(session.clock_in);
    const clockOut = new Date(session.clock_out);

    // 3. Calculate total worked minutes
    const totalMinutes = Math.round((clockOut.getTime() - clockIn.getTime()) / 60000);

    if (totalMinutes < 0) {
      throw new Error("Clock out time is before clock in time");
    }

    // 2. Get employee's schedule for the session_date
    const { data: schedules } = await supabaseAdmin
      .from("employee_schedules")
      .select("*, shift_template:shift_templates(*)")
      .eq("employee_id", session.employee_id)
      .lte("effective_from", session.session_date)
      .or(`effective_to.is.null,effective_to.gte.${session.session_date}`)
      .order("effective_from", { ascending: false })
      .limit(1);

    let expectedMinutes = 480; // Default: 8 hours

    if (schedules && schedules.length > 0) {
      const schedule = schedules[0];
      const template = schedule.shift_template;

      const startTime = template?.start_time || schedule.custom_start_time;
      const endTime = template?.end_time || schedule.custom_end_time;

      if (startTime && endTime) {
        const [startH, startM] = startTime.split(":").map(Number);
        const [endH, endM] = endTime.split(":").map(Number);
        expectedMinutes = (endH * 60 + endM) - (startH * 60 + startM);
        if (expectedMinutes < 0) expectedMinutes += 1440; // Handle overnight shifts
      }
    }

    // 4. Get overtime rules for this employee
    const { data: employeeOvertimeRules } = await supabaseAdmin
      .from("employee_overtime_rules")
      .select("overtime_rule:overtime_rules(*)")
      .eq("employee_id", session.employee_id);

    let regularMinutes = Math.min(totalMinutes, expectedMinutes);
    let overtimeMinutes = Math.max(0, totalMinutes - expectedMinutes);
    let overtimeMultiplier = 1.0;

    if (employeeOvertimeRules && employeeOvertimeRules.length > 0) {
      // Sort by priority descending, pick the first matching rule
      const rules = employeeOvertimeRules
        .map((eor: any) => eor.overtime_rule)
        .filter((r: any) => r && r.is_active)
        .sort((a: any, b: any) => (b.priority || 0) - (a.priority || 0));

      for (const rule of rules) {
        if (rule.rule_type === "daily_threshold" && rule.threshold_minutes) {
          if (totalMinutes > rule.threshold_minutes) {
            overtimeMinutes = totalMinutes - rule.threshold_minutes;
            regularMinutes = rule.threshold_minutes;
            overtimeMultiplier = parseFloat(rule.multiplier) || 1.5;
            break;
          }
        } else if (rule.rule_type === "weekly_threshold" && rule.threshold_minutes) {
          // Sum all completed sessions in the current week (Mon-Sun)
          const sessionDate = new Date(session.session_date);
          const dayOfWeek = sessionDate.getDay(); // 0=Sun, 1=Mon, ...
          const mondayOffset = dayOfWeek === 0 ? -6 : 1 - dayOfWeek;
          const monday = new Date(sessionDate);
          monday.setDate(sessionDate.getDate() + mondayOffset);
          const sunday = new Date(monday);
          sunday.setDate(monday.getDate() + 6);

          const mondayStr = monday.toISOString().split("T")[0];
          const sundayStr = sunday.toISOString().split("T")[0];

          const { data: weekSessions } = await supabaseAdmin
            .from("work_sessions")
            .select("total_minutes")
            .eq("employee_id", session.employee_id)
            .gte("session_date", mondayStr)
            .lte("session_date", sundayStr)
            .neq("id", session_id)
            .in("status", ["completed", "edited"]);

          const weekTotalSoFar = (weekSessions || []).reduce(
            (sum: number, s: any) => sum + (s.total_minutes || 0),
            0
          );

          const weekTotalWithCurrent = weekTotalSoFar + totalMinutes;

          if (weekTotalWithCurrent > rule.threshold_minutes) {
            const overThreshold = weekTotalWithCurrent - rule.threshold_minutes;
            // How much of THIS session is overtime
            overtimeMinutes = Math.min(totalMinutes, overThreshold);
            regularMinutes = totalMinutes - overtimeMinutes;
            overtimeMultiplier = parseFloat(rule.multiplier) || 1.5;
            break;
          }
        }
        // 'custom' type: no automatic handling, falls back to schedule-based
      }
    }

    // 6. Update session with calculated values
    const newStatus = session.status === "edited" ? "edited" : "completed";
    const { error: updateError } = await supabaseAdmin
      .from("work_sessions")
      .update({
        total_minutes: totalMinutes,
        regular_minutes: regularMinutes,
        overtime_minutes: overtimeMinutes,
        overtime_multiplier: overtimeMultiplier,
        status: newStatus,
      })
      .eq("id", session_id);

    if (updateError) throw new Error(`Failed to update session: ${updateError.message}`);

    // 7. Trigger daily summary recalculation
    const summaryResponse = await fetch(
      `${Deno.env.get("SUPABASE_URL")}/functions/v1/recalculate-daily-summary`,
      {
        method: "POST",
        headers: {
          Authorization: `Bearer ${Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")}`,
          "Content-Type": "application/json",
        },
        body: JSON.stringify({
          employee_id: session.employee_id,
          date: session.session_date,
        }),
      }
    );

    if (!summaryResponse.ok) {
      console.error("Failed to trigger recalculate-daily-summary:", await summaryResponse.text());
    }

    return new Response(
      JSON.stringify({
        total_minutes: totalMinutes,
        regular_minutes: regularMinutes,
        overtime_minutes: overtimeMinutes,
        overtime_multiplier: overtimeMultiplier,
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
