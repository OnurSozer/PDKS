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
    requireRole(user, ["operator", "super_admin"]);

    const { employee_ids, special_day_type_id, action } = await req.json();

    if (!employee_ids || !Array.isArray(employee_ids) || employee_ids.length === 0) {
      throw new Error("employee_ids array is required");
    }
    if (!special_day_type_id) {
      throw new Error("special_day_type_id is required");
    }

    if (action === "remove") {
      const { error } = await supabase
        .from("employee_special_day_types")
        .delete()
        .eq("special_day_type_id", special_day_type_id)
        .in("employee_id", employee_ids);

      if (error) throw new Error(`Failed to remove assignments: ${error.message}`);

      return new Response(JSON.stringify({ success: true, removed: employee_ids.length }), {
        headers: { ...corsHeaders, "Content-Type": "application/json" },
        status: 200,
      });
    }

    // Default: assign (upsert)
    const results = [];
    const errors = [];

    for (const empId of employee_ids) {
      const { data, error } = await supabase
        .from("employee_special_day_types")
        .upsert(
          {
            employee_id: empId,
            special_day_type_id,
            company_id: user.company_id,
          },
          { onConflict: "employee_id,special_day_type_id" }
        )
        .select()
        .single();

      if (error) {
        errors.push({ employee_id: empId, error: error.message });
      } else {
        results.push(data);
      }
    }

    return new Response(
      JSON.stringify({ assignments: results, errors }),
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
