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
    requireRole(user, ["employee", "chef"]);

    const body = await req.json();
    const { action } = body;

    if (action === "create") {
      return await handleCreate(body, user, supabase);
    } else if (action === "update") {
      return await handleUpdate(body, user, supabase);
    } else if (action === "delete") {
      return await handleDelete(body, user, supabase);
    } else {
      throw new Error("Invalid action. Must be 'create', 'update', or 'delete'.");
    }
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

async function handleCreate(
  body: any,
  user: { id: string; company_id: string | null },
  supabase: any
) {
  const { session_date, clock_in, clock_out } = body;

  if (!session_date || !clock_in || !clock_out) {
    throw new Error("session_date, clock_in, and clock_out are required");
  }

  if (!user.company_id) {
    throw new Error("User has no company assigned");
  }

  const clockInDate = new Date(clock_in);
  const clockOutDate = new Date(clock_out);

  if (clockOutDate <= clockInDate) {
    throw new Error("clock_out must be after clock_in");
  }

  const supabaseAdmin = getSupabaseAdmin();

  // Insert session via service_role (bypasses RLS)
  const { data: session, error: insertError } = await supabaseAdmin
    .from("work_sessions")
    .insert({
      employee_id: user.id,
      company_id: user.company_id,
      session_date,
      clock_in,
      clock_out,
      clock_out_submitted_by: "employee",
      status: "completed",
    })
    .select()
    .single();

  if (insertError) throw new Error(`Failed to create session: ${insertError.message}`);

  // Trigger calculate-session (computes regular/overtime, chains to recalculate-daily-summary)
  const calcResponse = await fetch(
    `${Deno.env.get("SUPABASE_URL")}/functions/v1/calculate-session`,
    {
      method: "POST",
      headers: {
        Authorization: `Bearer ${Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")}`,
        "Content-Type": "application/json",
      },
      body: JSON.stringify({ session_id: session.id }),
    }
  );

  if (!calcResponse.ok) {
    console.error("Failed to trigger calculate-session:", await calcResponse.text());
  }

  // Re-fetch the session after calculation
  const { data: finalSession } = await supabaseAdmin
    .from("work_sessions")
    .select("*")
    .eq("id", session.id)
    .single();

  return new Response(
    JSON.stringify({ session: finalSession || session }),
    {
      headers: { ...corsHeaders, "Content-Type": "application/json" },
      status: 200,
    }
  );
}

async function handleUpdate(
  body: any,
  user: { id: string; company_id: string | null },
  supabase: any
) {
  const { session_id, clock_in, clock_out } = body;

  if (!session_id) {
    throw new Error("session_id is required");
  }

  if (!clock_in || !clock_out) {
    throw new Error("clock_in and clock_out are required");
  }

  const clockInDate = new Date(clock_in);
  const clockOutDate = new Date(clock_out);

  if (clockOutDate <= clockInDate) {
    throw new Error("clock_out must be after clock_in");
  }

  // Fetch session via user client (RLS enforces ownership)
  const { data: session, error: fetchError } = await supabase
    .from("work_sessions")
    .select("*")
    .eq("id", session_id)
    .single();

  if (fetchError || !session) throw new Error("Session not found");

  if (session.employee_id !== user.id) {
    throw new Error("Forbidden: you can only edit your own sessions");
  }

  if (!["completed", "edited"].includes(session.status)) {
    throw new Error("Session cannot be edited (status: " + session.status + ")");
  }

  const supabaseAdmin = getSupabaseAdmin();

  const { error: updateError } = await supabaseAdmin
    .from("work_sessions")
    .update({
      clock_in,
      clock_out,
      status: "edited",
    })
    .eq("id", session_id);

  if (updateError) throw new Error(`Failed to update session: ${updateError.message}`);

  // Trigger calculate-session (recomputes regular/overtime, chains to recalculate-daily-summary)
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

  // Re-fetch after calculation
  const { data: finalSession } = await supabaseAdmin
    .from("work_sessions")
    .select("*")
    .eq("id", session_id)
    .single();

  return new Response(
    JSON.stringify({ session: finalSession || session }),
    {
      headers: { ...corsHeaders, "Content-Type": "application/json" },
      status: 200,
    }
  );
}

async function handleDelete(
  body: any,
  user: { id: string; company_id: string | null },
  supabase: any
) {
  const { session_id } = body;

  if (!session_id) {
    throw new Error("session_id is required");
  }

  // Fetch session via user client (RLS enforces ownership)
  const { data: session, error: fetchError } = await supabase
    .from("work_sessions")
    .select("*")
    .eq("id", session_id)
    .single();

  if (fetchError || !session) throw new Error("Session not found");

  // Verify ownership
  if (session.employee_id !== user.id) {
    throw new Error("Forbidden: you can only delete your own sessions");
  }

  // Allow cancelling active, completed, or edited sessions
  if (!["active", "completed", "edited"].includes(session.status)) {
    throw new Error("Session cannot be deleted (status: " + session.status + ")");
  }

  const supabaseAdmin = getSupabaseAdmin();

  // Cancel via service_role (bypasses RLS UPDATE restriction)
  const { error: updateError } = await supabaseAdmin
    .from("work_sessions")
    .update({ status: "cancelled" })
    .eq("id", session_id);

  if (updateError) throw new Error(`Failed to cancel session: ${updateError.message}`);

  // Trigger recalculate-daily-summary (recomputes the day without cancelled session)
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
      }),
    }
  );

  if (!summaryResponse.ok) {
    console.error("Failed to trigger recalculate-daily-summary:", await summaryResponse.text());
  }

  return new Response(
    JSON.stringify({ success: true }),
    {
      headers: { ...corsHeaders, "Content-Type": "application/json" },
      status: 200,
    }
  );
}
