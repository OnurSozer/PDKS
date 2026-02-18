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
 * 4. Get overtime rules for employee (+ company_work_settings as fallback)
 * 5. Apply rules to split regular vs overtime
 * 6. Update session with calculated values
 * 7. Determine work_day_type (regular/weekend/holiday)
 * 8. Trigger daily summary recalculation
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
    let workDays = [1, 2, 3, 4, 5]; // Default: Mon-Fri

    if (schedules && schedules.length > 0) {
      const schedule = schedules[0];
      const template = schedule.shift_template;

      const startTime = template?.start_time || schedule.custom_start_time;
      const endTime = template?.end_time || schedule.custom_end_time;
      workDays = template?.work_days || schedule.custom_work_days || [1, 2, 3, 4, 5];

      if (startTime && endTime) {
        const [startH, startM] = startTime.split(":").map(Number);
        const [endH, endM] = endTime.split(":").map(Number);
        expectedMinutes = (endH * 60 + endM) - (startH * 60 + startM);
        if (expectedMinutes < 0) expectedMinutes += 1440; // Handle overnight shifts

        // Subtract break duration from expected minutes
        const breakMinutes = template?.break_duration_minutes ?? schedule.custom_break_duration_minutes ?? 0;
        expectedMinutes -= breakMinutes;
      }
    }

    // Get employee's profile for company_id
    const { data: profile } = await supabaseAdmin
      .from("profiles")
      .select("company_id")
      .eq("id", session.employee_id)
      .single();

    const companyId = profile?.company_id;

    // Fetch company work settings once (used for fallback OT multiplier + weekend/holiday multipliers)
    let companyWorkSettings: any = null;
    if (companyId) {
      const { data: ws } = await supabaseAdmin
        .from("company_work_settings")
        .select("overtime_multiplier, weekend_multiplier, holiday_multiplier")
        .eq("company_id", companyId)
        .single();
      companyWorkSettings = ws;
    }

    // Determine work_day_type
    const sessionDate = new Date(session.session_date + "T00:00:00");
    const dayOfWeek = sessionDate.getDay();
    const isoDay = dayOfWeek === 0 ? 7 : dayOfWeek;
    const isScheduledWorkDay = workDays.includes(isoDay);

    let workDayType = "regular";
    let isHoliday = false;

    if (companyId) {
      // Check if it's a holiday
      const { data: holidayCheck } = await supabaseAdmin
        .from("company_holidays")
        .select("id")
        .eq("company_id", companyId)
        .eq("holiday_date", session.session_date)
        .limit(1);

      if (holidayCheck && holidayCheck.length > 0) {
        workDayType = "holiday";
        isHoliday = true;
      } else {
        // Check recurring holidays (match month-day)
        const { data: recurringCheck } = await supabaseAdmin
          .from("company_holidays")
          .select("holiday_date")
          .eq("company_id", companyId)
          .eq("is_recurring", true);

        if (recurringCheck) {
          const sessionMonthDay = session.session_date.substring(5); // "MM-DD"
          for (const rh of recurringCheck) {
            if ((rh.holiday_date as string).substring(5) === sessionMonthDay) {
              workDayType = "holiday";
              isHoliday = true;
              break;
            }
          }
        }
      }

      if (!isHoliday && !isScheduledWorkDay) {
        workDayType = "weekend";
      }
    } else if (!isScheduledWorkDay) {
      workDayType = "weekend";
    }

    // Non-work days have no expected minutes
    if (workDayType === "weekend" || workDayType === "holiday") {
      expectedMinutes = 0;
    }

    // 4. Get overtime rules for this employee
    const { data: employeeOvertimeRules } = await supabaseAdmin
      .from("employee_overtime_rules")
      .select("overtime_rule:overtime_rules(*)")
      .eq("employee_id", session.employee_id);

    let regularMinutes = totalMinutes;
    let overtimeMinutes = 0;
    let overtimeMultiplier = 1.0;

    // On work days, apply overtime rules (daily/weekly threshold)
    // On non-work days, all hours are regular — overtime only via boss call/special day
    if (workDayType === "regular") {
      regularMinutes = Math.min(totalMinutes, expectedMinutes);
      overtimeMinutes = Math.max(0, totalMinutes - expectedMinutes);

      if (employeeOvertimeRules && employeeOvertimeRules.length > 0) {
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
            const dayOfWeekForCalc = sessionDate.getDay();
            const mondayOffset = dayOfWeekForCalc === 0 ? -6 : 1 - dayOfWeekForCalc;
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
              overtimeMinutes = Math.min(totalMinutes, overThreshold);
              regularMinutes = totalMinutes - overtimeMinutes;
              overtimeMultiplier = parseFloat(rule.multiplier) || 1.5;
              break;
            }
          }
        }
      } else if (companyId && companyWorkSettings) {
        overtimeMultiplier = parseFloat(companyWorkSettings.overtime_multiplier) || 1.5;
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

    // 7. Trigger daily summary recalculation with work_day_type info
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
          work_day_type: workDayType,
          is_holiday: isHoliday,
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
        work_day_type: workDayType,
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
