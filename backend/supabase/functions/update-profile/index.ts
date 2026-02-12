import { serve } from "https://deno.land/std@0.177.0/http/server.ts";
import { corsHeaders } from "../_shared/cors.ts";
import { getSupabaseClient } from "../_shared/supabase-client.ts";
import { getAuthUser } from "../_shared/auth.ts";

serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  try {
    const authHeader = req.headers.get("Authorization")!;
    const supabase = getSupabaseClient(authHeader);
    const user = await getAuthUser(supabase);

    const body = await req.json();
    const { profile_id, first_name, last_name, phone, start_date } = body;

    // Determine which profile to update
    let targetId = user.id;

    if (profile_id && profile_id !== user.id) {
      // Operator or super_admin updating someone else
      if (!["operator", "super_admin"].includes(user.role)) {
        throw new Error("Forbidden: only operators and super admins can update other profiles");
      }
      targetId = profile_id;
    }

    // Build update object (only include provided fields)
    const updates: Record<string, unknown> = {};
    if (first_name !== undefined) updates.first_name = first_name;
    if (last_name !== undefined) updates.last_name = last_name;
    if (phone !== undefined) updates.phone = phone;
    if (start_date !== undefined) updates.start_date = start_date;

    if (Object.keys(updates).length === 0) {
      throw new Error("No fields to update");
    }

    // RLS will enforce that operators can only update profiles in their company
    const { data, error } = await supabase
      .from("profiles")
      .update(updates)
      .eq("id", targetId)
      .select()
      .single();

    if (error) throw new Error(`Failed to update profile: ${error.message}`);

    return new Response(
      JSON.stringify({ profile: data }),
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
