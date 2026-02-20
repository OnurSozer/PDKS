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
    requireRole(user, ["employee", "chef", "operator"]);

    const { session_id, clock_out_time } = await req.json();
    if (!session_id) throw new Error("session_id is required");

    // Fetch the session (RLS will enforce access control)
    const { data: session, error: fetchError } = await supabase
      .from("work_sessions")
      .select("*")
      .eq("id", session_id)
      .single();

    if (fetchError || !session) throw new Error("Session not found");

    if (session.status !== "active") {
      throw new Error("Session is not active");
    }

    if (session.clock_out) {
      throw new Error("Session already has a clock out time");
    }

    const now = new Date();
    const turkeyNowStr = now.toLocaleString("sv-SE", { timeZone: "Europe/Istanbul" });

    let turkeyNow: string;
    if (clock_out_time) {
      const custom = new Date(clock_out_time);
      if (isNaN(custom.getTime())) throw new Error("Invalid clock_out_time format");

      // Must not be in the future
      if (custom > now) throw new Error("Cannot select a future time");

      const customTurkey = custom.toLocaleString("sv-SE", { timeZone: "Europe/Istanbul" });

      // Must be after clock_in
      const clockInTime = new Date(session.clock_in);
      if (custom <= clockInTime) throw new Error("Clock-out time must be after clock-in time");

      turkeyNow = customTurkey;
    } else {
      turkeyNow = turkeyNowStr;
    }
    const submittedBy = user.role === "operator" ? "operator" : "employee";

    // Update the session with clock_out
    const { data: updatedSession, error: updateError } = await supabase
      .from("work_sessions")
      .update({
        clock_out: turkeyNow,
        clock_out_submitted_by: submittedBy,
      })
      .eq("id", session_id)
      .select()
      .single();

    if (updateError) throw new Error(`Failed to clock out: ${updateError.message}`);

    logActivity(getSupabaseAdmin(), {
      company_id: session.company_id,
      employee_id: session.employee_id,
      performed_by: user.id,
      action_type: "clock_out",
      resource_type: "work_session",
      resource_id: session_id,
      details: { clock_out: turkeyNow, submitted_by: submittedBy },
    });

    // Trigger calculate-session via internal call
    const calcResponse = await fetch(
      `${Deno.env.get("SUPABASE_URL")}/functions/v1/calculate-session`,
      {
        method: "POST",
        headers: {
          Authorization: `Bearer ${Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")}`,
          "Content-Type": "application/json",
        },
        body: JSON.stringify({ session_id }),
      }
    );

    if (!calcResponse.ok) {
      console.error("Failed to trigger calculate-session:", await calcResponse.text());
    }

    // Re-fetch the session after calculation
    const { data: finalSession } = await supabase
      .from("work_sessions")
      .select("*")
      .eq("id", session_id)
      .single();

    return new Response(
      JSON.stringify({ session: finalSession || updatedSession }),
      {
        headers: { ...corsHeaders, "Content-Type": "application/json" },
        status: 200,
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
