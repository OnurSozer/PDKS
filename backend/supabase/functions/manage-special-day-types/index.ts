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

    const method = req.method;

    if (method === "GET") {
      const { data, error } = await supabase
        .from("special_day_types")
        .select("*")
        .eq("company_id", user.company_id!)
        .eq("is_active", true)
        .order("display_order")
        .order("name");

      if (error) throw new Error(`Failed to fetch special day types: ${error.message}`);

      return new Response(JSON.stringify({ special_day_types: data }), {
        headers: { ...corsHeaders, "Content-Type": "application/json" },
        status: 200,
      });
    }

    const body = await req.json();

    if (method === "POST") {
      const { name, code, calculation_mode, multiplier, base_minutes, extra_minutes, extra_multiplier, applies_to_all, display_order } = body;
      if (!name) throw new Error("name is required");
      if (!code) throw new Error("code is required");

      const { data, error } = await supabase
        .from("special_day_types")
        .insert({
          company_id: user.company_id,
          name,
          code,
          calculation_mode: calculation_mode || "rounding",
          multiplier: multiplier ?? 1.5,
          base_minutes: base_minutes ?? 0,
          extra_minutes: extra_minutes ?? 0,
          extra_multiplier: extra_multiplier ?? 1.5,
          applies_to_all: applies_to_all !== undefined ? applies_to_all : true,
          display_order: display_order ?? 0,
        })
        .select()
        .single();

      if (error) throw new Error(`Failed to create special day type: ${error.message}`);

      return new Response(JSON.stringify({ special_day_type: data }), {
        headers: { ...corsHeaders, "Content-Type": "application/json" },
        status: 201,
      });
    }

    if (method === "PUT") {
      const { id, ...updates } = body;
      if (!id) throw new Error("id is required");

      delete updates.company_id;
      delete updates.created_at;

      const { data, error } = await supabase
        .from("special_day_types")
        .update(updates)
        .eq("id", id)
        .select()
        .single();

      if (error) throw new Error(`Failed to update special day type: ${error.message}`);

      return new Response(JSON.stringify({ special_day_type: data }), {
        headers: { ...corsHeaders, "Content-Type": "application/json" },
        status: 200,
      });
    }

    if (method === "DELETE") {
      const { id } = body;
      if (!id) throw new Error("id is required");

      // Soft-delete the type
      const { error } = await supabase
        .from("special_day_types")
        .update({ is_active: false })
        .eq("id", id);

      if (error) throw new Error(`Failed to deactivate special day type: ${error.message}`);

      // Clean up employee assignments for this type
      await supabase
        .from("employee_special_day_types")
        .delete()
        .eq("special_day_type_id", id);

      return new Response(JSON.stringify({ success: true }), {
        headers: { ...corsHeaders, "Content-Type": "application/json" },
        status: 200,
      });
    }

    throw new Error(`Unsupported method: ${method}`);
  } catch (error) {
    const msg = (error as Error).message;
    const status = msg === "Unauthorized" ? 401 : msg.startsWith("Forbidden") ? 403 : 400;
    return new Response(JSON.stringify({ error: msg }), {
      headers: { ...corsHeaders, "Content-Type": "application/json" },
      status,
    });
  }
});
