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

    const url = new URL(req.url);
    const employeeId = url.searchParams.get("employee_id") || user.id;
    const year = parseInt(url.searchParams.get("year") || new Date().getFullYear().toString());

    // Employees/chefs can only view their own balance
    if ((user.role === "employee" || user.role === "chef") && employeeId !== user.id) {
      throw new Error("Forbidden: can only view your own leave balance");
    }

    // Fetch balances with leave type details
    const { data: balances, error } = await supabase
      .from("leave_balances")
      .select("*, leave_type:leave_types(*)")
      .eq("employee_id", employeeId)
      .eq("year", year);

    if (error) throw new Error(`Failed to fetch leave balances: ${error.message}`);

    return new Response(
      JSON.stringify({ balances: balances || [] }),
      {
        headers: { ...corsHeaders, "Content-Type": "application/json" },
        status: 200,
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
