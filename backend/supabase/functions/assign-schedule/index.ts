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
    requireRole(user, ["operator"]);

    const supabaseAdmin = getSupabaseAdmin();

    const body = await req.json();
    const {
      // Create action
      employee_ids,
      shift_template_id,
      custom_start_time,
      custom_end_time,
      custom_break_duration_minutes,
      custom_work_days,
      effective_from,
      effective_to,
      // Update action
      action,
      schedule_id,
    } = body;

    // ─── Update existing schedule ──────────────────────────────────────
    if (action === "update" && schedule_id) {
      const updateFields: Record<string, any> = {};
      if (effective_from !== undefined) updateFields.effective_from = effective_from;
      if (effective_to !== undefined) updateFields.effective_to = effective_to || null;
      if (shift_template_id !== undefined) updateFields.shift_template_id = shift_template_id || null;

      if (Object.keys(updateFields).length === 0) {
        throw new Error("No fields to update");
      }

      const { data, error } = await supabaseAdmin
        .from("employee_schedules")
        .update(updateFields)
        .eq("id", schedule_id)
        .eq("company_id", user.company_id)
        .select("*, shift_template:shift_templates(*)")
        .single();

      if (error) throw new Error(`Failed to update schedule: ${error.message}`);

      return new Response(
        JSON.stringify({ schedule: data }),
        {
          headers: { ...corsHeaders, "Content-Type": "application/json" },
          status: 200,
        }
      );
    }

    // ─── Create new schedule(s) ────────────────────────────────────────
    if (!employee_ids || !Array.isArray(employee_ids) || employee_ids.length === 0) {
      throw new Error("employee_ids array is required");
    }

    if (!shift_template_id && !custom_start_time) {
      throw new Error("Either shift_template_id or custom schedule times are required");
    }

    const newEffectiveFrom = effective_from || new Date().toISOString().split("T")[0];

    const results = [];
    const errors = [];

    for (const empId of employee_ids) {
      const { data, error } = await supabaseAdmin
        .from("employee_schedules")
        .insert({
          employee_id: empId,
          company_id: user.company_id,
          shift_template_id: shift_template_id || null,
          custom_start_time: custom_start_time || null,
          custom_end_time: custom_end_time || null,
          custom_break_duration_minutes: custom_break_duration_minutes || null,
          custom_work_days: custom_work_days || null,
          effective_from: newEffectiveFrom,
          effective_to: effective_to || null,
        })
        .select("*, shift_template:shift_templates(*)")
        .single();

      if (error) {
        errors.push({ employee_id: empId, error: error.message });
      } else {
        results.push(data);
      }
    }

    return new Response(
      JSON.stringify({ schedules: results, errors }),
      {
        headers: { ...corsHeaders, "Content-Type": "application/json" },
        status: errors.length > 0 ? 207 : 201,
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
