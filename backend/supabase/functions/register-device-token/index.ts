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
    requireRole(user, ["employee", "chef"]);

    const { token, platform } = await req.json();
    if (!token || !platform) {
      throw new Error("token and platform are required");
    }

    if (!["android", "ios"].includes(platform)) {
      throw new Error("platform must be 'android' or 'ios'");
    }

    // Deactivate this token for any other user (device changed accounts)
    await supabase
      .from("device_tokens")
      .update({ is_active: false })
      .eq("token", token)
      .neq("user_id", user.id);

    // Upsert the device token (if same user+token exists, just update)
    const { error } = await supabase
      .from("device_tokens")
      .upsert(
        {
          user_id: user.id,
          token,
          platform,
          is_active: true,
        },
        { onConflict: "user_id,token" }
      );

    if (error) throw new Error(`Failed to register device token: ${error.message}`);

    return new Response(
      JSON.stringify({ success: true }),
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
