import { serve } from "https://deno.land/std@0.177.0/http/server.ts";
import { corsHeaders } from "../_shared/cors.ts";
import { getSupabaseAdmin, getSupabaseClient } from "../_shared/supabase-client.ts";
import { getAuthUser, requireRole } from "../_shared/auth.ts";

/**
 * Operator-only endpoint to update an employee's leave entitlements.
 * Accepts: { employee_id, entitlements: [{ leave_type_id, days_per_year }] }
 * Upserts into employee_leave_entitlements.
 */
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
    const { employee_id, entitlements } = body;

    if (!employee_id || !Array.isArray(entitlements)) {
      throw new Error("employee_id and entitlements array are required");
    }

    const supabaseAdmin = getSupabaseAdmin();

    // Verify employee belongs to operator's company
    const { data: employee, error: empError } = await supabaseAdmin
      .from("profiles")
      .select("id, company_id")
      .eq("id", employee_id)
      .single();

    if (empError || !employee) {
      throw new Error("Employee not found");
    }

    if (employee.company_id !== user.company_id) {
      throw new Error("Forbidden: employee belongs to a different company");
    }

    // Upsert entitlements
    const rows = entitlements.map((ent: { leave_type_id: string; days_per_year: number }) => ({
      employee_id,
      leave_type_id: ent.leave_type_id,
      company_id: user.company_id,
      days_per_year: ent.days_per_year,
    }));

    const { data: result, error: upsertError } = await supabaseAdmin
      .from("employee_leave_entitlements")
      .upsert(rows, { onConflict: "employee_id,leave_type_id" })
      .select();

    if (upsertError) {
      throw new Error(`Failed to upsert entitlements: ${upsertError.message}`);
    }

    return new Response(
      JSON.stringify({ entitlements: result }),
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
