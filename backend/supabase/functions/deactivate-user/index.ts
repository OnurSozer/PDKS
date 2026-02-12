import { serve } from "https://deno.land/std@0.177.0/http/server.ts";
import { corsHeaders } from "../_shared/cors.ts";
import { getSupabaseAdmin, getSupabaseClient } from "../_shared/supabase-client.ts";
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

    const { user_id } = await req.json();
    if (!user_id) throw new Error("user_id is required");

    // Prevent self-deactivation
    if (user_id === user.id) {
      throw new Error("Cannot deactivate your own account");
    }

    const supabaseAdmin = getSupabaseAdmin();

    // If operator, verify the target user belongs to their company
    if (user.role === "operator") {
      const { data: targetProfile, error: targetError } = await supabaseAdmin
        .from("profiles")
        .select("company_id, role")
        .eq("id", user_id)
        .single();

      if (targetError || !targetProfile) {
        throw new Error("User not found");
      }

      if (targetProfile.company_id !== user.company_id) {
        throw new Error("Forbidden: user belongs to a different company");
      }

      // Operators cannot deactivate other operators or super_admins
      if (["operator", "super_admin"].includes(targetProfile.role)) {
        throw new Error("Forbidden: cannot deactivate this user role");
      }
    }

    // Soft-delete: set is_active = false on profile
    const { data: profileData, error: profileError } = await supabaseAdmin
      .from("profiles")
      .update({ is_active: false })
      .eq("id", user_id)
      .select()
      .single();

    if (profileError) throw new Error(`Failed to deactivate user: ${profileError.message}`);

    // Also ban the auth user so they can't log in
    const { error: banError } = await supabaseAdmin.auth.admin.updateUserById(user_id, {
      ban_duration: "876000h", // ~100 years
    });

    if (banError) {
      console.error("Failed to ban auth user:", banError.message);
    }

    return new Response(
      JSON.stringify({ profile: profileData }),
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
