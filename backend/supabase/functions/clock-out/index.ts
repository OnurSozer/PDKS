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
    requireRole(user, ["employee", "chef", "operator"]);

    const { session_id } = await req.json();
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
    const submittedBy = user.role === "operator" ? "operator" : "employee";

    // Update the session with clock_out
    const { data: updatedSession, error: updateError } = await supabase
      .from("work_sessions")
      .update({
        clock_out: now.toISOString(),
        clock_out_submitted_by: submittedBy,
      })
      .eq("id", session_id)
      .select()
      .single();

    if (updateError) throw new Error(`Failed to clock out: ${updateError.message}`);

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
