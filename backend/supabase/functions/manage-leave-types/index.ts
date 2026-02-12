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
        .from("leave_types")
        .select("*")
        .eq("company_id", user.company_id!)
        .order("name");

      if (error) throw new Error(`Failed to fetch leave types: ${error.message}`);

      return new Response(JSON.stringify({ leave_types: data }), {
        headers: { ...corsHeaders, "Content-Type": "application/json" },
        status: 200,
      });
    }

    const body = await req.json();

    if (method === "POST") {
      const { name, default_days_per_year, is_paid } = body;
      if (!name) throw new Error("name is required");

      const { data, error } = await supabase
        .from("leave_types")
        .insert({
          company_id: user.company_id,
          name,
          default_days_per_year: default_days_per_year || null,
          is_paid: is_paid !== undefined ? is_paid : true,
        })
        .select()
        .single();

      if (error) throw new Error(`Failed to create leave type: ${error.message}`);

      return new Response(JSON.stringify({ leave_type: data }), {
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
        .from("leave_types")
        .update(updates)
        .eq("id", id)
        .select()
        .single();

      if (error) throw new Error(`Failed to update leave type: ${error.message}`);

      return new Response(JSON.stringify({ leave_type: data }), {
        headers: { ...corsHeaders, "Content-Type": "application/json" },
        status: 200,
      });
    }

    if (method === "DELETE") {
      const { id } = body;
      if (!id) throw new Error("id is required");

      const { error } = await supabase
        .from("leave_types")
        .update({ is_active: false })
        .eq("id", id);

      if (error) throw new Error(`Failed to deactivate leave type: ${error.message}`);

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
