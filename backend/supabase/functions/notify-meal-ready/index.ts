import { serve } from "https://deno.land/std@0.177.0/http/server.ts";
import { corsHeaders } from "../_shared/cors.ts";
import { getSupabaseAdmin, getSupabaseClient } from "../_shared/supabase-client.ts";
import { getAuthUser, requireRole } from "../_shared/auth.ts";

/**
 * Chef sends "Meal is Ready" notification to all active employees in the company.
 */
serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  try {
    const authHeader = req.headers.get("Authorization")!;
    const supabase = getSupabaseClient(authHeader);
    const user = await getAuthUser(supabase);
    requireRole(user, ["chef"]);

    const supabaseAdmin = getSupabaseAdmin();

    // Get all active employees/chefs in the same company (excluding the chef sending)
    const { data: employees, error: empError } = await supabaseAdmin
      .from("profiles")
      .select("id")
      .eq("company_id", user.company_id!)
      .eq("is_active", true)
      .in("role", ["employee", "chef"])
      .neq("id", user.id);

    if (empError) throw new Error(`Failed to fetch employees: ${empError.message}`);

    if (!employees || employees.length === 0) {
      return new Response(
        JSON.stringify({ notified_count: 0, message: "No employees to notify" }),
        {
          headers: { ...corsHeaders, "Content-Type": "application/json" },
          status: 200,
        }
      );
    }

    const userIds = employees.map((e) => e.id);

    // Get the chef's name for the notification body
    const { data: chefProfile } = await supabaseAdmin
      .from("profiles")
      .select("first_name")
      .eq("id", user.id)
      .single();

    const chefName = chefProfile?.first_name || "Chef";

    // Send notification via internal send-notification function
    const notifResponse = await fetch(
      `${Deno.env.get("SUPABASE_URL")}/functions/v1/send-notification`,
      {
        method: "POST",
        headers: {
          Authorization: `Bearer ${Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")}`,
          "Content-Type": "application/json",
        },
        body: JSON.stringify({
          user_ids: userIds,
          title: "🍽️ YEMEK HAZIR! 🍽️",
          body: `${chefName} yemegin hazir oldugunu bildirdi. / ${chefName} announced the meal is ready.`,
          data: { type: "meal_ready" },
        }),
      }
    );

    const notifResult = await notifResponse.json();

    return new Response(
      JSON.stringify({
        notified_count: notifResult.sent || 0,
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
