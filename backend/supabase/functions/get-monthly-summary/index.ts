import { serve } from "https://deno.land/std@0.177.0/http/server.ts";
import { corsHeaders } from "../_shared/cors.ts";
import { getSupabaseClient, getSupabaseAdmin } from "../_shared/supabase-client.ts";
import { getAuthUser, requireRole } from "../_shared/auth.ts";

serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  try {
    const authHeader = req.headers.get("Authorization")!;
    const supabase = getSupabaseClient(authHeader);
    const user = await getAuthUser(supabase);
    requireRole(user, ["operator", "super_admin"]);

    const url = new URL(req.url);
    const month = url.searchParams.get("month"); // e.g. "2026-02"
    const employeeId = url.searchParams.get("employee_id");

    if (!month || !/^\d{4}-\d{2}$/.test(month)) {
      throw new Error("month parameter is required in YYYY-MM format");
    }

    const supabaseAdmin = getSupabaseAdmin();
    const companyId = user.company_id!;

    // Parse month bounds
    const [yearStr, monthStr] = month.split("-");
    const year = parseInt(yearStr);
    const monthNum = parseInt(monthStr);
    const firstDay = `${month}-01`;
    const lastDay = new Date(year, monthNum, 0).toISOString().split("T")[0];
    const daysInMonth = new Date(year, monthNum, 0).getDate();

    // Fetch company work settings
    const { data: workSettings } = await supabaseAdmin
      .from("company_work_settings")
      .select("*")
      .eq("company_id", companyId)
      .single();

    const overtimeMultiplier = workSettings ? parseFloat(workSettings.overtime_multiplier) : 1.5;
    const weekendMultiplier = workSettings ? parseFloat(workSettings.weekend_multiplier) : 1.5;
    const holidayMultiplier = workSettings ? parseFloat(workSettings.holiday_multiplier) : 2.0;
    const monthlyConstant = workSettings ? parseFloat(workSettings.monthly_work_days_constant) : 21.66;

    // Fetch company holidays for this month
    const { data: holidays } = await supabaseAdmin
      .from("company_holidays")
      .select("holiday_date")
      .eq("company_id", companyId)
      .gte("holiday_date", firstDay)
      .lte("holiday_date", lastDay);

    const holidayDates = new Set((holidays || []).map((h: any) => h.holiday_date));

    // Also check recurring holidays (match month-day regardless of year)
    const { data: recurringHolidays } = await supabaseAdmin
      .from("company_holidays")
      .select("holiday_date")
      .eq("company_id", companyId)
      .eq("is_recurring", true);

    if (recurringHolidays) {
      for (const rh of recurringHolidays) {
        const rhDate = rh.holiday_date as string; // "YYYY-MM-DD"
        const rhMonthDay = rhDate.substring(5); // "MM-DD"
        const thisYearDate = `${yearStr}-${rhMonthDay}`;
        if (thisYearDate >= firstDay && thisYearDate <= lastDay) {
          holidayDates.add(thisYearDate);
        }
      }
    }

    // Fetch employees
    let employeeQuery = supabaseAdmin
      .from("profiles")
      .select("id, first_name, last_name, email, role")
      .eq("company_id", companyId)
      .in("role", ["employee", "chef"])
      .eq("is_active", true)
      .order("first_name");

    if (employeeId) {
      employeeQuery = employeeQuery.eq("id", employeeId);
    }

    const { data: employees, error: empError } = await employeeQuery;
    if (empError) throw new Error(`Failed to fetch employees: ${empError.message}`);
    if (!employees || employees.length === 0) {
      return new Response(JSON.stringify({ summaries: [], month, settings: workSettings }), {
        headers: { ...corsHeaders, "Content-Type": "application/json" },
        status: 200,
      });
    }

    const employeeIds = employees.map((e: any) => e.id);

    // Fetch all schedules that overlap with this month for these employees
    const { data: allSchedules } = await supabaseAdmin
      .from("employee_schedules")
      .select("*, shift_template:shift_templates(*)")
      .in("employee_id", employeeIds)
      .lte("effective_from", lastDay)
      .or(`effective_to.is.null,effective_to.gte.${firstDay}`);

    // Fetch all daily summaries for the month
    const { data: allSummaries } = await supabaseAdmin
      .from("daily_summaries")
      .select("*")
      .in("employee_id", employeeIds)
      .gte("summary_date", firstDay)
      .lte("summary_date", lastDay);

    // Fetch all special day types for this company (including inactive for historical data)
    const { data: specialDayTypes } = await supabaseAdmin
      .from("special_day_types")
      .select("*")
      .eq("company_id", companyId);

    const specialDayTypeMap = new Map<string, any>();
    for (const sdt of specialDayTypes || []) {
      specialDayTypeMap.set(sdt.id, sdt);
    }

    // Fetch leave records for all employees in this month with leave type name
    const leaveTypeMap = new Map<string, string>();
    try {
      const { data: allLeaveRecords, error: leaveErr } = await supabaseAdmin
        .from("leave_records")
        .select("employee_id, start_date, end_date, leave_type_id, leave_types(name)")
        .in("employee_id", employeeIds)
        .eq("status", "active")
        .lte("start_date", lastDay)
        .gte("end_date", firstDay);

      if (!leaveErr && allLeaveRecords) {
        for (const lr of allLeaveRecords) {
          const typeName = (lr.leave_types as any)?.name || "";
          const lrStart = new Date(`${lr.start_date}T00:00:00`);
          const lrEnd = new Date(`${lr.end_date}T00:00:00`);
          const cursor = new Date(lrStart);
          while (cursor <= lrEnd) {
            const cursorStr = cursor.toISOString().split("T")[0];
            if (cursorStr >= firstDay && cursorStr <= lastDay) {
              leaveTypeMap.set(`${lr.employee_id}|${cursorStr}`, typeName);
            }
            cursor.setDate(cursor.getDate() + 1);
          }
        }
      }
    } catch (_) {
      // Non-critical — leave type names won't be shown but function still works
    }

    // Build per-employee summaries
    const results = [];

    for (const employee of employees) {
      const empSchedules = (allSchedules || []).filter(
        (s: any) => s.employee_id === employee.id
      );
      const empSummaries = (allSummaries || []).filter(
        (s: any) => s.employee_id === employee.id
      );

      // Build a map of date -> daily summary
      const summaryMap = new Map<string, any>();
      for (const s of empSummaries) {
        summaryMap.set(s.summary_date, s);
      }

      let totalWorkMinutes = 0;
      let totalExpectedMinutes = 0;
      let bossCallDays = 0;
      let bossCallMinutes = 0;
      let workDays = 0;
      let lateDays = 0;
      let absentDays = 0;
      let leaveDays = 0;
      let totalDeficit = 0;
      const dailyDetails = [];
      let weekendWorkMinutes = 0;
      let holidayWorkMinutes = 0;
      // Per special day type stats
      const specialDayStats: Record<string, { days: number; minutes: number; name: string; code: string }> = {};

      for (let day = 1; day <= daysInMonth; day++) {
        const dateStr = `${month}-${String(day).padStart(2, "0")}`;
        const dateObj = new Date(`${dateStr}T00:00:00`);
        const dayOfWeek = dateObj.getDay(); // 0=Sun
        const isoDay = dayOfWeek === 0 ? 7 : dayOfWeek; // 1=Mon, 7=Sun

        // Find the applicable schedule for this date
        const schedule = empSchedules
          .filter(
            (s: any) =>
              s.effective_from <= dateStr &&
              (!s.effective_to || s.effective_to >= dateStr)
          )
          .sort((a: any, b: any) => b.effective_from.localeCompare(a.effective_from))[0];

        let isWorkDay = false;
        let expectedMinutes = 0;

        if (schedule) {
          const template = schedule.shift_template;
          const workDaysArr = template?.work_days || schedule.custom_work_days || [1, 2, 3, 4, 5];
          const startTime = template?.start_time || schedule.custom_start_time;
          const endTime = template?.end_time || schedule.custom_end_time;

          if (workDaysArr.includes(isoDay) && startTime && endTime) {
            isWorkDay = true;
            const [startH, startM] = startTime.split(":").map(Number);
            const [endH, endM] = endTime.split(":").map(Number);
            expectedMinutes = (endH * 60 + endM) - (startH * 60 + startM);
            if (expectedMinutes < 0) expectedMinutes += 1440;

            // Subtract break duration from expected minutes
            const breakMinutes = template?.break_duration_minutes ?? schedule.custom_break_duration_minutes ?? 0;
            expectedMinutes -= breakMinutes;
          }
        }

        // Determine work day type
        let workDayType: "regular" | "weekend" | "holiday" = "regular";
        if (holidayDates.has(dateStr)) {
          workDayType = "holiday";
        } else if (!isWorkDay) {
          workDayType = "weekend";
        }

        const summary = summaryMap.get(dateStr);
        let contributed = 0;
        let effectiveMinutes = 0;
        let dayIsBossCall = false;
        let dayIsLate = false;
        let dayIsAbsent = false;
        let dayIsLeave = false;
        let dayDeficit = 0;
        let dayStatus = "";
        let daySpecialDayTypeId: string | null = null;
        let daySpecialDayTypeName: string | null = null;
        let daySpecialDayTypeCode: string | null = null;
        let hasSpecialDay = false;

        if (summary) {
          dayIsBossCall = summary.is_boss_call || false;
          dayIsLate = summary.is_late || false;
          dayIsAbsent = summary.is_absent || false;
          dayIsLeave = summary.is_leave || false;
          dayDeficit = summary.deficit_minutes || 0;

          // Employee is not expected to work on leave days
          if (dayIsLeave) {
            expectedMinutes = 0;
          }
          dayStatus = summary.status || "";
          effectiveMinutes = summary.effective_work_minutes || summary.total_work_minutes || 0;
          daySpecialDayTypeId = summary.special_day_type_id || null;

          // Resolve special day type info
          if (daySpecialDayTypeId && specialDayTypeMap.has(daySpecialDayTypeId)) {
            const sdt = specialDayTypeMap.get(daySpecialDayTypeId);
            daySpecialDayTypeName = sdt.name;
            daySpecialDayTypeCode = sdt.code;
            hasSpecialDay = true;
          }

          if (hasSpecialDay || dayIsBossCall) {
            // Special day: use effective_work_minutes (already has formula applied)
            contributed = effectiveMinutes;

            // Track per-type stats
            if (daySpecialDayTypeId) {
              if (!specialDayStats[daySpecialDayTypeId]) {
                const sdt = specialDayTypeMap.get(daySpecialDayTypeId);
                specialDayStats[daySpecialDayTypeId] = {
                  days: 0,
                  minutes: 0,
                  name: sdt?.name || "Unknown",
                  code: sdt?.code || "unknown",
                };
              }
              specialDayStats[daySpecialDayTypeId].days++;
              specialDayStats[daySpecialDayTypeId].minutes += effectiveMinutes;
            }

            // Backward compat counters
            if (dayIsBossCall || daySpecialDayTypeCode === "boss_call") {
              bossCallDays++;
              bossCallMinutes += effectiveMinutes;
            }
          } else {
            contributed = summary.total_work_minutes || 0;
          }

          if (dayIsLate) lateDays++;
          if (dayIsLeave) leaveDays++;
        } else if (isWorkDay) {
          // No summary = absent (never clocked in)
          dayIsAbsent = true;
          dayStatus = "absent";
          dayDeficit = expectedMinutes;
        }

        // Track weekend/holiday work minutes
        if (workDayType === "weekend" && contributed > 0) weekendWorkMinutes += contributed;
        if (workDayType === "holiday" && contributed > 0) holidayWorkMinutes += contributed;

        if (isWorkDay || (summary && (summary.total_work_minutes > 0 || hasSpecialDay || dayIsBossCall))) {
          workDays++;
          totalExpectedMinutes += expectedMinutes;
          totalWorkMinutes += contributed;
          totalDeficit += dayDeficit;
          if (dayIsAbsent && !dayIsLeave) absentDays++;
        }

        dailyDetails.push({
          date: dateStr,
          is_work_day: isWorkDay,
          work_day_type: workDayType,
          total_work_minutes: summary?.total_work_minutes || 0,
          expected_work_minutes: expectedMinutes,
          effective_work_minutes: effectiveMinutes,
          is_boss_call: dayIsBossCall,
          is_late: dayIsLate,
          is_absent: dayIsAbsent,
          is_leave: dayIsLeave,
          leave_type_name: dayIsLeave ? (leaveTypeMap.get(`${employee.id}|${dateStr}`) || null) : null,
          deficit_minutes: dayDeficit,
          status: dayStatus,
          special_day_type_id: daySpecialDayTypeId,
          special_day_type_name: daySpecialDayTypeName,
          special_day_type_code: daySpecialDayTypeCode,
        });
      }

      // Monthly formula calculation
      const netMinutes = totalWorkMinutes - totalExpectedMinutes;

      // Aggregate all special day minutes (these already include their multiplier)
      let totalSpecialDayDays = 0;
      let totalSpecialDayMinutes = 0;
      for (const stat of Object.values(specialDayStats)) {
        totalSpecialDayDays += stat.days;
        totalSpecialDayMinutes += stat.minutes;
      }

      // OT value: apply per-type multipliers
      // Weekend/holiday work is all surplus (expected=0 for those days).
      // Special day minutes already have their multiplier baked in.
      let overtimeValue = 0;
      if (netMinutes > 0) {
        const expectedPerDay = totalExpectedMinutes / Math.max(workDays, 1);
        const specialDaySurplus = totalSpecialDayMinutes - (totalSpecialDayDays * expectedPerDay);
        // Weekend/holiday work is all surplus; subtract from net to get regular surplus
        const regularSurplus = netMinutes - weekendWorkMinutes - holidayWorkMinutes - Math.max(0, specialDaySurplus);

        overtimeValue = 0;
        if (regularSurplus > 0) overtimeValue += regularSurplus * overtimeMultiplier;
        overtimeValue += weekendWorkMinutes * weekendMultiplier;
        overtimeValue += holidayWorkMinutes * holidayMultiplier;
        if (specialDaySurplus > 0) overtimeValue += specialDaySurplus; // already multiplied
      }

      const expectedDailyMinutes = totalExpectedMinutes / Math.max(workDays, 1);
      const overtimeDays = expectedDailyMinutes > 0 ? overtimeValue / expectedDailyMinutes : 0;
      const overtimePercentage = monthlyConstant > 0 ? (overtimeDays / monthlyConstant) * 100 : 0;

      results.push({
        employee_id: employee.id,
        employee_name: `${employee.first_name} ${employee.last_name}`,
        work_days: workDays,
        total_work_minutes: totalWorkMinutes,
        expected_work_minutes: totalExpectedMinutes,
        boss_call_days: bossCallDays,
        boss_call_minutes: bossCallMinutes,
        special_day_stats: specialDayStats,
        net_minutes: netMinutes,
        deficit_minutes: totalDeficit,
        overtime_value: Math.round(overtimeValue),
        overtime_days: Math.round(overtimeDays * 100) / 100,
        overtime_percentage: Math.round(overtimePercentage * 100) / 100,
        late_days: lateDays,
        absent_days: absentDays,
        leave_days: leaveDays,
        daily_details: dailyDetails,
      });
    }

    return new Response(
      JSON.stringify({
        summaries: results,
        month,
        settings: {
          overtime_multiplier: overtimeMultiplier,
          weekend_multiplier: weekendMultiplier,
          holiday_multiplier: holidayMultiplier,
          monthly_work_days_constant: monthlyConstant,
        },
      }),
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
