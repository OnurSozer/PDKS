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

    const { employee_ids, overtime_rule_id } = await req.json();

    if (!employee_ids || !Array.isArray(employee_ids) || employee_ids.length === 0) {
      throw new Error("employee_ids array is required");
    }
    if (!overtime_rule_id) {
      throw new Error("overtime_rule_id is required");
    }

    const results = [];
    const errors = [];

    for (const empId of employee_ids) {
      const { data, error } = await supabase
        .from("employee_overtime_rules")
        .upsert(
          {
            employee_id: empId,
            overtime_rule_id,
            company_id: user.company_id,
          },
          { onConflict: "employee_id,overtime_rule_id" }
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
