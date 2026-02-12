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
    requireRole(user, ["operator"]);

    const { session_id, clock_in, clock_out, notes } = await req.json();
    if (!session_id) throw new Error("session_id is required");

    // Fetch the session (RLS ensures operator can only see their company's sessions)
    const { data: session, error: fetchError } = await supabase
      .from("work_sessions")
      .select("*")
      .eq("id", session_id)
      .single();

    if (fetchError || !session) throw new Error("Session not found");

    // Build update object
    const updates: Record<string, unknown> = {
      status: "edited",
      edited_by: user.id,
      edited_at: new Date().toISOString(),
    };

    if (clock_in) {
      updates.clock_in = clock_in;
      // session_date = date of clock_in
      updates.session_date = new Date(clock_in).toISOString().split("T")[0];
    }
    if (clock_out) {
      updates.clock_out = clock_out;
      updates.clock_out_submitted_by = "operator";
    }
    if (notes !== undefined) updates.notes = notes;

    // Validate times
    const finalClockIn = new Date(clock_in || session.clock_in);
    const finalClockOut = clock_out ? new Date(clock_out) : session.clock_out ? new Date(session.clock_out) : null;

    if (finalClockOut && finalClockOut <= finalClockIn) {
      throw new Error("Clock out time must be after clock in time");
    }

    const { data: updatedSession, error: updateError } = await supabase
      .from("work_sessions")
      .update(updates)
      .eq("id", session_id)
      .select()
      .single();

    if (updateError) throw new Error(`Failed to edit session: ${updateError.message}`);

    // If session has both clock_in and clock_out, trigger recalculation
    if (updatedSession.clock_out) {
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
