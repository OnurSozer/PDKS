import { serve } from "https://deno.land/std@0.177.0/http/server.ts";
import { corsHeaders } from "../_shared/cors.ts";
import { getSupabaseAdmin } from "../_shared/supabase-client.ts";
import { sendBatchNotification } from "../_shared/fcm.ts";

/**
 * Internal helper: send push notification to specified users via FCM.
 * Called by other Edge Functions using service_role key.
 *
 * Request body:
 * {
 *   user_ids: string[],
 *   title: string,
 *   body: string,
 *   data?: Record<string, string>
 * }
 */
serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  try {
    const { user_ids, title, body, data } = await req.json();

    if (!user_ids || !Array.isArray(user_ids) || user_ids.length === 0) {
      throw new Error("user_ids array is required");
    }
    if (!title || !body) {
      throw new Error("title and body are required");
    }

    const supabaseAdmin = getSupabaseAdmin();

    // Get device tokens for the specified users
    const { data: tokenRecords, error: tokenError } = await supabaseAdmin
      .from("device_tokens")
      .select("token")
      .in("user_id", user_ids)
      .eq("is_active", true);

    if (tokenError) throw new Error(`Failed to fetch device tokens: ${tokenError.message}`);

    if (!tokenRecords || tokenRecords.length === 0) {
      return new Response(
        JSON.stringify({ sent: 0, failed: 0, message: "No active device tokens found" }),
        {
          headers: { ...corsHeaders, "Content-Type": "application/json" },
          status: 200,
        }
      );
    }

    const tokens = tokenRecords.map((t) => t.token);

    // Send notifications via FCM
    const result = await sendBatchNotification(
      tokens,
      { title, body },
      data
    );

    // Deactivate unregistered tokens
    if (result.unregistered_tokens.length > 0) {
      await supabaseAdmin
        .from("device_tokens")
        .update({ is_active: false })
        .in("token", result.unregistered_tokens);
    }

    return new Response(
      JSON.stringify(result),
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
