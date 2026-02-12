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

    const body = await req.json();
    const {
      employee_ids,
      shift_template_id,
      custom_start_time,
      custom_end_time,
      custom_break_duration_minutes,
      custom_work_days,
      effective_from,
      effective_to,
    } = body;

    if (!employee_ids || !Array.isArray(employee_ids) || employee_ids.length === 0) {
      throw new Error("employee_ids array is required");
    }

    if (!shift_template_id && !custom_start_time) {
      throw new Error("Either shift_template_id or custom schedule times are required");
    }

    const results = [];
    const errors = [];

    for (const empId of employee_ids) {
      // End any currently active schedule for this employee
      const { error: endError } = await supabase
        .from("employee_schedules")
        .update({
          effective_to: effective_from || new Date().toISOString().split("T")[0],
        })
        .eq("employee_id", empId)
        .is("effective_to", null);

      if (endError) {
        errors.push({ employee_id: empId, error: endError.message });
        continue;
      }

      // Create new schedule
      const { data, error } = await supabase
        .from("employee_schedules")
        .insert({
          employee_id: empId,
          company_id: user.company_id,
          shift_template_id: shift_template_id || null,
          custom_start_time: custom_start_time || null,
          custom_end_time: custom_end_time || null,
          custom_break_duration_minutes: custom_break_duration_minutes || null,
          custom_work_days: custom_work_days || null,
          effective_from: effective_from || new Date().toISOString().split("T")[0],
          effective_to: effective_to || null,
        })
        .select()
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
