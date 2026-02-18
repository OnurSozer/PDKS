import { serve } from "https://deno.land/std@0.177.0/http/server.ts";
import { corsHeaders } from "../_shared/cors.ts";
import { getSupabaseClient, getSupabaseAdmin } from "../_shared/supabase-client.ts";
import { getAuthUser, requireRole } from "../_shared/auth.ts";
import { logActivity } from "../_shared/activity-log.ts";

serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  try {
    const authHeader = req.headers.get("Authorization")!;
    const supabase = getSupabaseClient(authHeader);
    const user = await getAuthUser(supabase);
    requireRole(user, ["employee", "chef"]);

    // Check for existing open session
    const { data: openSessions, error: checkError } = await supabase
      .from("work_sessions")
      .select("id")
      .eq("employee_id", user.id)
      .eq("status", "active")
      .is("clock_out", null);

    if (checkError) throw new Error(`Failed to check open sessions: ${checkError.message}`);

    if (openSessions && openSessions.length > 0) {
      throw new Error("You already have an open session. Please clock out first.");
    }

    const now = new Date();
    // session_date = date of clock_in (always)
    const sessionDate = now.toISOString().split("T")[0];

    const { data: session, error: insertError } = await supabase
      .from("work_sessions")
      .insert({
        employee_id: user.id,
        company_id: user.company_id,
        clock_in: now.toISOString(),
        session_date: sessionDate,
        status: "active",
      })
      .select()
      .single();

    if (insertError) throw new Error(`Failed to create session: ${insertError.message}`);

    logActivity(getSupabaseAdmin(), {
      company_id: user.company_id,
      employee_id: user.id,
      performed_by: user.id,
      action_type: "clock_in",
      resource_type: "work_session",
      resource_id: session.id,
      details: { clock_in: now.toISOString(), session_date: sessionDate },
    });

    return new Response(
      JSON.stringify({ session }),
      {
        headers: { ...corsHeaders, "Content-Type": "application/json" },
        status: 201,
      }
    );
  } catch (error) {
    const msg = (error as Error).message;
    const status = msg === "Unauthorized" ? 401 : msg.startsWith("Forbidden") ? 403 : 400;
    return new Response(
      JSON.stringify({ error: msg }),
      {
        headers: { ...corsHeaders, "Content-Type": "application/json" },
        status,
      }
    );
  }
});
