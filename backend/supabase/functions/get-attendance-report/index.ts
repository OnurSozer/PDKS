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

    const url = new URL(req.url);
    const startDate = url.searchParams.get("start_date");
    const endDate = url.searchParams.get("end_date");
    const employeeId = url.searchParams.get("employee_id");

    if (!startDate || !endDate) {
      throw new Error("start_date and end_date query parameters are required");
    }

    // Build query for daily summaries
    let summaryQuery = supabase
      .from("daily_summaries")
      .select("*")
      .gte("summary_date", startDate)
      .lte("summary_date", endDate)
      .order("summary_date", { ascending: true });

    // RLS handles company scoping for operators
    if (employeeId) {
      summaryQuery = summaryQuery.eq("employee_id", employeeId);
    }

    const { data: summaries, error: summariesError } = await summaryQuery;
    if (summariesError) throw new Error(`Failed to fetch summaries: ${summariesError.message}`);

    // Fetch employees for the company (for name display)
    let employeesQuery = supabase
      .from("profiles")
      .select("id, first_name, last_name, email, role")
      .eq("is_active", true)
      .in("role", ["employee", "chef"]);

    if (employeeId) {
      employeesQuery = employeesQuery.eq("id", employeeId);
    }

    const { data: employees, error: employeesError } = await employeesQuery;
    if (employeesError) throw new Error(`Failed to fetch employees: ${employeesError.message}`);

    return new Response(
      JSON.stringify({
        summaries: summaries || [],
        employees: employees || [],
      }),
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
