import { serve } from "https://deno.land/std@0.177.0/http/server.ts";
import { corsHeaders } from "../_shared/cors.ts";
import { getSupabaseAdmin } from "../_shared/supabase-client.ts";

/**
 * Recalculates the daily summary for a given employee + date.
 * Called internally after session calculation or leave changes.
 *
 * Now also handles: deficit_minutes, is_holiday, is_boss_call,
 * effective_work_minutes, and work_day_type.
 */
serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  try {
    const body = await req.json();
    const { employee_id, date, work_day_type: passedWorkDayType, is_holiday: passedIsHoliday } = body;

    if (!employee_id || !date) {
      throw new Error("employee_id and date are required");
    }

    const supabaseAdmin = getSupabaseAdmin();

    // 1. Get employee's profile (for company_id)
    const { data: profile, error: profileError } = await supabaseAdmin
      .from("profiles")
      .select("company_id")
      .eq("id", employee_id)
      .single();

    if (profileError || !profile) throw new Error("Employee not found");

    // 2. Get all non-cancelled sessions for this employee on this date
    const { data: sessions, error: sessionsError } = await supabaseAdmin
      .from("work_sessions")
      .select("*")
      .eq("employee_id", employee_id)
      .eq("session_date", date)
      .neq("status", "cancelled")
      .order("clock_in", { ascending: true });

    if (sessionsError) throw new Error(`Failed to fetch sessions: ${sessionsError.message}`);

    const validSessions = sessions || [];

    // 3. Aggregate session data
    const totalSessions = validSessions.length;
    const totalWorkMinutes = validSessions.reduce(
      (sum, s) => sum + (s.total_minutes || 0),
      0
    );
    const totalRegularMinutes = validSessions.reduce(
      (sum, s) => sum + (s.regular_minutes || 0),
      0
    );
    const totalOvertimeMinutes = validSessions.reduce(
      (sum, s) => sum + (s.overtime_minutes || 0),
      0
    );

    // 4. Get schedule to determine expected hours
    const { data: schedules } = await supabaseAdmin
      .from("employee_schedules")
      .select("*, shift_template:shift_templates(*)")
      .eq("employee_id", employee_id)
      .lte("effective_from", date)
      .or(`effective_to.is.null,effective_to.gte.${date}`)
      .order("effective_from", { ascending: false })
      .limit(1);

    let expectedWorkMinutes = 0;
    let scheduleStartTime: string | null = null;

    if (schedules && schedules.length > 0) {
      const schedule = schedules[0];
      const template = schedule.shift_template;

      const startTime = template?.start_time || schedule.custom_start_time;
      const endTime = template?.end_time || schedule.custom_end_time;
      const workDays = template?.work_days || schedule.custom_work_days || [1, 2, 3, 4, 5];

      // Check if this date is a work day
      const dateObj = new Date(date + "T00:00:00");
      const dayOfWeek = dateObj.getDay(); // 0=Sun
      const isoDay = dayOfWeek === 0 ? 7 : dayOfWeek; // Convert to ISO: 1=Mon, 7=Sun

      if (workDays.includes(isoDay) && startTime && endTime) {
        const [startH, startM] = startTime.split(":").map(Number);
        const [endH, endM] = endTime.split(":").map(Number);
        expectedWorkMinutes = (endH * 60 + endM) - (startH * 60 + startM);
        if (expectedWorkMinutes < 0) expectedWorkMinutes += 1440;

        // Subtract break duration from expected minutes
        const breakMinutes = template?.break_duration_minutes ?? schedule.custom_break_duration_minutes ?? 0;
        expectedWorkMinutes -= breakMinutes;

        scheduleStartTime = startTime;
      }
    }

    // 5. Check lateness
    let isLate = false;
    let lateMinutes = 0;

    if (scheduleStartTime && validSessions.length > 0) {
      const firstSession = validSessions[0];
      const clockInDate = new Date(firstSession.clock_in);
      const [schedH, schedM] = scheduleStartTime.split(":").map(Number);

      // Construct schedule start as a Date on the session date
      const schedStart = new Date(date + "T00:00:00");
      schedStart.setHours(schedH, schedM, 0, 0);

      if (clockInDate > schedStart) {
        isLate = true;
        lateMinutes = Math.round(
          (clockInDate.getTime() - schedStart.getTime()) / 60000
        );
      }
    }

    // 6. Determine status
    let status = "complete";
    if (totalSessions === 0) {
      status = "absent";
    }
    if (validSessions.some((s) => s.status === "active")) {
      status = "incomplete";
    }

    // 7. Check if on leave
    let isLeave = false;
    const { data: leaveRecords } = await supabaseAdmin
      .from("leave_records")
      .select("id")
      .eq("employee_id", employee_id)
      .eq("status", "active")
      .lte("start_date", date)
      .gte("end_date", date)
      .limit(1);

    if (leaveRecords && leaveRecords.length > 0) {
      isLeave = true;
      status = "leave";
      // Employee is not expected to work on leave days
      expectedWorkMinutes = 0;
    }

    const isAbsent = status === "absent" && !isLeave;

    // Calculate deficit minutes
    const deficitMinutes = Math.max(0, expectedWorkMinutes - totalWorkMinutes);

    // Determine work_day_type
    let workDayType = passedWorkDayType || "regular";
    let isHoliday = passedIsHoliday || false;

    // If not passed from calculate-session, determine it ourselves
    if (!passedWorkDayType && profile.company_id) {
      const { data: holidayCheck } = await supabaseAdmin
        .from("company_holidays")
        .select("id")
        .eq("company_id", profile.company_id)
        .eq("holiday_date", date)
        .limit(1);

      if (holidayCheck && holidayCheck.length > 0) {
        workDayType = "holiday";
        isHoliday = true;
      } else {
        // Check recurring
        const { data: recurringCheck } = await supabaseAdmin
          .from("company_holidays")
          .select("holiday_date")
          .eq("company_id", profile.company_id)
          .eq("is_recurring", true);

        if (recurringCheck) {
          const dateMonthDay = date.substring(5);
          for (const rh of recurringCheck) {
            if ((rh.holiday_date as string).substring(5) === dateMonthDay) {
              workDayType = "holiday";
              isHoliday = true;
              break;
            }
          }
        }

        if (!isHoliday && expectedWorkMinutes === 0) {
          workDayType = "weekend";
        }
      }
    }

    // Preserve existing special day type (only toggle-special-day / toggle-boss-call changes it)
    let isBossCall = false;
    let effectiveWorkMinutes = totalWorkMinutes;
    let specialDayTypeId: string | null = null;

    const { data: existingSummary } = await supabaseAdmin
      .from("daily_summaries")
      .select("is_boss_call, effective_work_minutes, special_day_type_id")
      .eq("employee_id", employee_id)
      .eq("summary_date", date)
      .single();

    if (existingSummary && existingSummary.special_day_type_id) {
      specialDayTypeId = existingSummary.special_day_type_id;

      // Fetch the special day type definition
      const { data: dayType } = await supabaseAdmin
        .from("special_day_types")
        .select("*")
        .eq("id", specialDayTypeId)
        .single();

      if (dayType) {
        isBossCall = dayType.code === "boss_call";

        if (dayType.calculation_mode === "fixed_hours") {
          effectiveWorkMinutes = Math.round(
            dayType.base_minutes + dayType.extra_minutes * parseFloat(dayType.extra_multiplier)
          );
        } else {
          // rounding mode
          const mult = parseFloat(dayType.multiplier) || 1.5;
          const halfDay = Math.round((expectedWorkMinutes || 480) / 2);
          const fullDay = expectedWorkMinutes || 480;

          let roundedMinutes: number;
          if (totalWorkMinutes <= 0) {
            roundedMinutes = halfDay;
          } else if (totalWorkMinutes < halfDay) {
            roundedMinutes = halfDay;
          } else if (totalWorkMinutes <= fullDay) {
            roundedMinutes = fullDay;
          } else {
            roundedMinutes = totalWorkMinutes;
          }
          effectiveWorkMinutes = Math.round(roundedMinutes * mult);
        }
      }
    } else if (existingSummary && existingSummary.is_boss_call) {
      // Legacy fallback: is_boss_call = true but no special_day_type_id
      isBossCall = true;

      const { data: workSettings } = await supabaseAdmin
        .from("company_work_settings")
        .select("boss_call_multiplier")
        .eq("company_id", profile.company_id)
        .single();

      const bossCallMultiplier = workSettings
        ? parseFloat(workSettings.boss_call_multiplier)
        : 1.5;

      const halfDay = Math.round((expectedWorkMinutes || 480) / 2);
      const fullDay = expectedWorkMinutes || 480;

      let roundedMinutes: number;
      if (totalWorkMinutes <= 0) {
        roundedMinutes = halfDay;
      } else if (totalWorkMinutes < halfDay) {
        roundedMinutes = halfDay;
      } else if (totalWorkMinutes <= fullDay) {
        roundedMinutes = fullDay;
      } else {
        roundedMinutes = totalWorkMinutes;
      }

      effectiveWorkMinutes = Math.round(roundedMinutes * bossCallMultiplier);
    }

    if (isHoliday && status === "absent") {
      status = "holiday";
    }

    // 8. Upsert daily summary
    const { data: summary, error: upsertError } = await supabaseAdmin
      .from("daily_summaries")
      .upsert(
        {
          employee_id,
          company_id: profile.company_id,
          summary_date: date,
          total_sessions: totalSessions,
          total_work_minutes: totalWorkMinutes,
          total_regular_minutes: totalRegularMinutes,
          total_overtime_minutes: totalOvertimeMinutes,
          expected_work_minutes: expectedWorkMinutes,
          is_late: isLate,
          late_minutes: lateMinutes,
          is_absent: isAbsent,
          is_leave: isLeave,
          deficit_minutes: deficitMinutes,
          is_holiday: isHoliday,
          is_boss_call: isBossCall,
          special_day_type_id: specialDayTypeId,
          effective_work_minutes: effectiveWorkMinutes,
          work_day_type: workDayType,
          status,
        },
        {
          onConflict: "employee_id,summary_date",
        }
      )
      .select()
      .single();

    if (upsertError) throw new Error(`Failed to upsert daily summary: ${upsertError.message}`);

    return new Response(
      JSON.stringify({ summary }),
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
