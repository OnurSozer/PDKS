import { serve } from "https://deno.land/std@0.177.0/http/server.ts";
import { corsHeaders } from "../_shared/cors.ts";
import { getSupabaseAdmin } from "../_shared/supabase-client.ts";

/**
 * Cron job: Check for open sessions and send push notifications
 * to remind employees to clock out.
 *
 * Uses `forgot_clockout_time` from notification_settings as the trigger time.
 * If the current time is past the reminder time and an employee has an open
 * session, they get a notification.
 *
 * Called by pg_cron every 15 minutes using service_role key.
 */
serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  try {
    const supabaseAdmin = getSupabaseAdmin();
    // Use Turkey time (UTC+3) since reminder times are set in local time
    const now = new Date();
    const turkeyNow = new Date(now.toLocaleString("en-US", { timeZone: "Europe/Istanbul" }));
    const nowHHMM = `${String(turkeyNow.getHours()).padStart(2, "0")}:${String(turkeyNow.getMinutes()).padStart(2, "0")}`;
    console.log(`Current Turkey time: ${nowHHMM}`);

    // Get all companies with forgot-clockout enabled
    const { data: companies, error: companiesError } = await supabaseAdmin
      .from("notification_settings")
      .select("company_id, forgot_clockout_time")
      .eq("forgot_clockout_enabled", true);

    if (companiesError) throw new Error(`Failed to fetch companies: ${companiesError.message}`);

    let checkedCompanies = 0;
    let notificationsSent = 0;

    for (const company of companies || []) {
      checkedCompanies++;
      const rawTime = company.forgot_clockout_time;

      // Skip if no reminder time is set
      if (!rawTime) continue;

      // Normalize to HH:MM (DB may return "15:30:00")
      const reminderTime = rawTime.substring(0, 5);
      console.log(`Company ${company.company_id}: reminder=${reminderTime}, now=${nowHHMM}`);

      // Only send if current time is past the reminder time
      if (nowHHMM < reminderTime) continue;

      // Find all open sessions for this company that haven't been reminded yet
      const { data: openSessions, error: sessionsError } = await supabaseAdmin
        .from("work_sessions")
        .select("id, employee_id, clock_in")
        .eq("company_id", company.company_id)
        .eq("status", "active")
        .is("clock_out", null)
        .eq("reminder_sent", false);

      if (sessionsError || !openSessions || openSessions.length === 0) continue;

      // Filter out stale sessions (older than 24 hours)
      const validSessions = openSessions.filter((session) => {
        const clockInDate = new Date(session.clock_in);
        const hoursSinceClockIn = (now.getTime() - clockInDate.getTime()) / (1000 * 60 * 60);
        return hoursSinceClockIn <= 24;
      });

      if (validSessions.length === 0) continue;

      const employeeIds = validSessions.map((s) => s.employee_id);

      // Send notification to all employees with open sessions at once
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
              user_ids: employeeIds,
              title: "Açık oturumunuz var",
              body: "Çıkış yapmayı unuttunuz mu?",
              data: { type: "forgot_clockout" },
            }),
          }
        );
        notificationsSent += employeeIds.length;

        // Mark these sessions as reminded so we don't send again
        const sessionIds = validSessions.map((s) => s.id);
        await supabaseAdmin
          .from("work_sessions")
          .update({ reminder_sent: true })
          .in("id", sessionIds);
      } catch (e) {
        console.error(`Failed to send notifications for company ${company.company_id}:`, e);
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
