import { serve } from "https://deno.land/std@0.177.0/http/server.ts";
import { corsHeaders } from "../_shared/cors.ts";
import { getSupabaseClient } from "../_shared/supabase-client.ts";
import { getAuthUser, requireRole } from "../_shared/auth.ts";

serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  try {
    const authHeader = req.headers.get("Authorization")!;
    const supabase = getSupabaseClient(authHeader);
    const user = await getAuthUser(supabase);
    requireRole(user, ["employee", "chef"]);

    const { session_id, clock_out_time } = await req.json();
    if (!session_id || !clock_out_time) {
      throw new Error("session_id and clock_out_time are required");
    }

    // Fetch the session (RLS ensures employee can only see their own)
    const { data: session, error: fetchError } = await supabase
      .from("work_sessions")
      .select("*")
      .eq("id", session_id)
      .single();

    if (fetchError || !session) throw new Error("Session not found");

    if (session.employee_id !== user.id) {
      throw new Error("Forbidden: not your session");
    }

    if (session.status !== "active") {
      throw new Error("Session is not active");
    }

    // Validate clock_out_time is after clock_in
    const clockIn = new Date(session.clock_in);
    const clockOut = new Date(clock_out_time);

    if (clockOut <= clockIn) {
      throw new Error("Clock out time must be after clock in time");
    }

    // Update the session
    const { data: updatedSession, error: updateError } = await supabase
      .from("work_sessions")
      .update({
        clock_out: clock_out_time,
        clock_out_submitted_by: "employee",
      })
      .eq("id", session_id)
      .select()
      .single();

    if (updateError) throw new Error(`Failed to submit missed clock-out: ${updateError.message}`);

    // Trigger calculate-session
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

    // Re-fetch
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
