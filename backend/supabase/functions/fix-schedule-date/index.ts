import { serve } from "https://deno.land/std@0.177.0/http/server.ts";
import { corsHeaders } from "../_shared/cors.ts";
import { getSupabaseAdmin } from "../_shared/supabase-client.ts";

/**
 * One-time fix: Update the effective_from date for employee schedules.
 * Then re-trigger batch-recalculate.
 */
serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  try {
    const supabaseAdmin = getSupabaseAdmin();
    const body = await req.json().catch(() => ({}));
    const newDate = body.effective_from || "2026-01-01";

    // Update all schedules with effective_from after 2026-02-01 to the new date
    const { data: updated, error } = await supabaseAdmin
      .from("employee_schedules")
      .update({ effective_from: newDate })
      .gt("effective_from", "2026-02-01")
      .select("id, employee_id, effective_from");

    if (error) throw new Error(`Failed to update: ${error.message}`);

    return new Response(
      JSON.stringify({
        message: `Updated ${(updated || []).length} schedule(s) to effective_from=${newDate}`,
        updated,
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
