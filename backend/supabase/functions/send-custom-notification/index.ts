import { serve } from "https://deno.land/std@0.177.0/http/server.ts";
import { corsHeaders } from "../_shared/cors.ts";
import { getSupabaseAdmin, getSupabaseClient } from "../_shared/supabase-client.ts";
import { getAuthUser, requireRole } from "../_shared/auth.ts";

/**
 * Operator sends custom notification to all or selected employees in their company.
 *
 * Request body:
 * {
 *   title: string,
 *   body: string,
 *   employee_ids?: string[]   // if empty/null, sends to all active employees+chefs
 * }
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

    const { title, body, employee_ids } = await req.json();

    if (!title || !body) {
      throw new Error("title and body are required");
    }

    const supabaseAdmin = getSupabaseAdmin();

    // Determine recipients
    let userIds: string[];

    if (employee_ids && Array.isArray(employee_ids) && employee_ids.length > 0) {
      // Send to selected employees — verify they belong to the same company
      const { data: employees, error: empError } = await supabaseAdmin
        .from("profiles")
        .select("id")
        .eq("company_id", user.company_id!)
        .eq("is_active", true)
        .in("id", employee_ids);

      if (empError) throw new Error(`Failed to fetch employees: ${empError.message}`);
      userIds = (employees || []).map((e) => e.id);
    } else {
      // Send to all active employees+chefs in company
      const { data: employees, error: empError } = await supabaseAdmin
        .from("profiles")
        .select("id")
        .eq("company_id", user.company_id!)
        .eq("is_active", true)
        .in("role", ["employee", "chef"]);

      if (empError) throw new Error(`Failed to fetch employees: ${empError.message}`);
      userIds = (employees || []).map((e) => e.id);
    }

    console.log("Target user IDs:", JSON.stringify(userIds));

    if (userIds.length === 0) {
      return new Response(
        JSON.stringify({ sent: 0, message: "No employees to notify" }),
        {
          headers: { ...corsHeaders, "Content-Type": "application/json" },
          status: 200,
        }
      );
    }

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
          title,
          body,
          data: { type: "custom" },
        }),
      }
    );

    const notifText = await notifResponse.text();
    console.log("send-notification response:", notifText);
    let notifResult: { sent?: number; error?: string };
    try {
      notifResult = JSON.parse(notifText);
    } catch {
      console.error("Failed to parse send-notification response");
      notifResult = { sent: 0, error: notifText };
    }

    // Log the notification
    await supabaseAdmin.from("notification_logs").insert({
      company_id: user.company_id,
      sent_by: user.id,
      title,
      body,
      recipient_count: userIds.length,
      notification_type: "custom",
    });

    // Log to activity_logs
    await supabaseAdmin.from("activity_logs").insert({
      company_id: user.company_id,
      user_id: user.id,
      action_type: "notification_send",
      details: {
        title,
        recipient_count: userIds.length,
        sent: notifResult.sent || 0,
      },
    });

    return new Response(
      JSON.stringify({
        sent: notifResult.sent || 0,
        recipient_count: userIds.length,
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
