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
      // List shift templates for the operator's company
      const { data, error } = await supabase
        .from("shift_templates")
        .select("*")
        .eq("company_id", user.company_id!)
        .order("created_at", { ascending: false });

      if (error) throw new Error(`Failed to fetch shift templates: ${error.message}`);

      return new Response(JSON.stringify({ templates: data }), {
        headers: { ...corsHeaders, "Content-Type": "application/json" },
        status: 200,
      });
    }

    const body = await req.json();

    if (method === "POST") {
      // Create a new shift template
      const { name, start_time, end_time, break_duration_minutes, work_days } = body;
      if (!name || !start_time || !end_time) {
        throw new Error("name, start_time, and end_time are required");
      }

      const { data, error } = await supabase
        .from("shift_templates")
        .insert({
          company_id: user.company_id,
          name,
          start_time,
          end_time,
          break_duration_minutes: break_duration_minutes || 0,
          work_days: work_days || [1, 2, 3, 4, 5],
        })
        .select()
        .single();

      if (error) throw new Error(`Failed to create shift template: ${error.message}`);

      return new Response(JSON.stringify({ template: data }), {
        headers: { ...corsHeaders, "Content-Type": "application/json" },
        status: 201,
      });
    }

    if (method === "PUT") {
      // Update a shift template
      const { id, ...updates } = body;
      if (!id) throw new Error("id is required");

      // Remove fields that shouldn't be updated directly
      delete updates.company_id;
      delete updates.created_at;
      delete updates.updated_at;

      const { data, error } = await supabase
        .from("shift_templates")
        .update(updates)
        .eq("id", id)
        .select()
        .single();

      if (error) throw new Error(`Failed to update shift template: ${error.message}`);

      return new Response(JSON.stringify({ template: data }), {
        headers: { ...corsHeaders, "Content-Type": "application/json" },
        status: 200,
      });
    }

    if (method === "DELETE") {
      const { id } = body;
      if (!id) throw new Error("id is required");

      // Soft delete by deactivating
      const { error } = await supabase
        .from("shift_templates")
        .update({ is_active: false })
        .eq("id", id);

      if (error) throw new Error(`Failed to deactivate shift template: ${error.message}`);

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
