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
        .from("overtime_rules")
        .select("*")
        .eq("company_id", user.company_id!)
        .order("priority", { ascending: false });

      if (error) throw new Error(`Failed to fetch overtime rules: ${error.message}`);

      return new Response(JSON.stringify({ rules: data }), {
        headers: { ...corsHeaders, "Content-Type": "application/json" },
        status: 200,
      });
    }

    const body = await req.json();

    if (method === "POST") {
      const { name, description, rule_type, threshold_minutes, multiplier, priority } = body;
      if (!name || !rule_type) {
        throw new Error("name and rule_type are required");
      }

      const { data, error } = await supabase
        .from("overtime_rules")
        .insert({
          company_id: user.company_id,
          name,
          description: description || null,
          rule_type,
          threshold_minutes: threshold_minutes || null,
          multiplier: multiplier || 1.5,
          priority: priority || 0,
        })
        .select()
        .single();

      if (error) throw new Error(`Failed to create overtime rule: ${error.message}`);

      return new Response(JSON.stringify({ rule: data }), {
        headers: { ...corsHeaders, "Content-Type": "application/json" },
        status: 201,
      });
    }

    if (method === "PUT") {
      const { id, ...updates } = body;
      if (!id) throw new Error("id is required");

      delete updates.company_id;
      delete updates.created_at;
      delete updates.updated_at;

      const { data, error } = await supabase
        .from("overtime_rules")
        .update(updates)
        .eq("id", id)
        .select()
        .single();

      if (error) throw new Error(`Failed to update overtime rule: ${error.message}`);

      return new Response(JSON.stringify({ rule: data }), {
        headers: { ...corsHeaders, "Content-Type": "application/json" },
        status: 200,
      });
    }

    if (method === "DELETE") {
      const { id } = body;
      if (!id) throw new Error("id is required");

      const { error } = await supabase
        .from("overtime_rules")
        .update({ is_active: false })
        .eq("id", id);

      if (error) throw new Error(`Failed to deactivate overtime rule: ${error.message}`);

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
