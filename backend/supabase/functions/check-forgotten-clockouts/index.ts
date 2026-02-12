import { serve } from "https://deno.land/std@0.177.0/http/server.ts";
import { corsHeaders } from "../_shared/cors.ts";
import { getSupabaseAdmin } from "../_shared/supabase-client.ts";

/**
 * Cron job: Check for open sessions past shift end + offset and send
 * push notifications to remind employees to clock out.
 *
 * Called by pg_cron every 15 minutes between 17:00-23:00 using service_role key.
 */
serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  try {
    const supabaseAdmin = getSupabaseAdmin();
    const now = new Date();

    // Get all companies with forgot-clockout enabled
    const { data: companies, error: companiesError } = await supabaseAdmin
      .from("notification_settings")
      .select("company_id, forgot_clockout_offset_minutes")
      .eq("forgot_clockout_enabled", true);

    if (companiesError) throw new Error(`Failed to fetch companies: ${companiesError.message}`);

    let checkedCompanies = 0;
    let notificationsSent = 0;

    for (const company of companies || []) {
      checkedCompanies++;
      const offsetMinutes = company.forgot_clockout_offset_minutes || 30;

      // Find all open sessions for this company
      const { data: openSessions, error: sessionsError } = await supabaseAdmin
        .from("work_sessions")
        .select("id, employee_id, clock_in, session_date")
        .eq("company_id", company.company_id)
        .eq("status", "active")
        .is("clock_out", null);

      if (sessionsError || !openSessions || openSessions.length === 0) continue;

      for (const session of openSessions) {
        // Get the employee's schedule to find shift end time
        const { data: schedules } = await supabaseAdmin
          .from("employee_schedules")
          .select("*, shift_template:shift_templates(*)")
          .eq("employee_id", session.employee_id)
          .lte("effective_from", session.session_date)
          .or(`effective_to.is.null,effective_to.gte.${session.session_date}`)
          .order("effective_from", { ascending: false })
          .limit(1);

        if (!schedules || schedules.length === 0) continue;

        const schedule = schedules[0];
        const template = schedule.shift_template;
        const endTime = template?.end_time || schedule.custom_end_time;

        if (!endTime) continue;

        // Calculate the notification trigger time (shift_end + offset)
        const [endH, endM] = endTime.split(":").map(Number);
        const shiftEnd = new Date(session.session_date + "T00:00:00");
        shiftEnd.setHours(endH, endM, 0, 0);
        shiftEnd.setMinutes(shiftEnd.getMinutes() + offsetMinutes);

        // Only send if we're past the trigger time
        if (now < shiftEnd) continue;

        // Check if clock_in was today or yesterday (handle overnight)
        const clockInDate = new Date(session.clock_in);
        const hoursSinceClockIn = (now.getTime() - clockInDate.getTime()) / (1000 * 60 * 60);

        // Don't notify for sessions older than 24 hours (stale)
        if (hoursSinceClockIn > 24) continue;

        // Send notification
        try {
          await fetch(
            `${Deno.env.get("SUPABASE_URL")}/functions/v1/send-notification`,
            {
              method: "POST",
              headers: {
                Authorization: `Bearer ${Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")}`,
                "Content-Type": "application/json",
              },
              body: JSON.stringify({
                user_ids: [session.employee_id],
                title: "Acik oturumunuz var / Open Session",
                body: "Cikis yapmayi unuttunuz mu? / Did you forget to clock out?",
                data: {
                  type: "forgot_clockout",
                  session_id: session.id,
                },
              }),
            }
          );
          notificationsSent++;
        } catch (e) {
          console.error(`Failed to send notification for session ${session.id}:`, e);
        }
      }
    }

    return new Response(
      JSON.stringify({
        checked_companies: checkedCompanies,
        notifications_sent: notificationsSent,
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
