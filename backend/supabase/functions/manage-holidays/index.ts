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
      const url = new URL(req.url);
      const year = url.searchParams.get("year");

      let query = supabase
        .from("company_holidays")
        .select("*")
        .eq("company_id", user.company_id!)
        .order("holiday_date", { ascending: true });

      if (year) {
        query = query
          .gte("holiday_date", `${year}-01-01`)
          .lte("holiday_date", `${year}-12-31`);
      }

      const { data, error } = await query;
      if (error) throw new Error(`Failed to fetch holidays: ${error.message}`);

      return new Response(JSON.stringify({ holidays: data }), {
        headers: { ...corsHeaders, "Content-Type": "application/json" },
        status: 200,
      });
    }

    const body = await req.json();

    if (method === "POST") {
      const { name, holiday_date, is_recurring } = body;
      if (!name || !holiday_date) throw new Error("name and holiday_date are required");

      const { data, error } = await supabase
        .from("company_holidays")
        .insert({
          company_id: user.company_id,
          name,
          holiday_date,
          is_recurring: is_recurring || false,
        })
        .select()
        .single();

      if (error) throw new Error(`Failed to create holiday: ${error.message}`);

      return new Response(JSON.stringify({ holiday: data }), {
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
        .from("company_holidays")
        .update(updates)
        .eq("id", id)
        .select()
        .single();

      if (error) throw new Error(`Failed to update holiday: ${error.message}`);

      return new Response(JSON.stringify({ holiday: data }), {
        headers: { ...corsHeaders, "Content-Type": "application/json" },
        status: 200,
      });
    }

    if (method === "DELETE") {
      const { id } = body;
      if (!id) throw new Error("id is required");

      const { error } = await supabase
        .from("company_holidays")
        .delete()
        .eq("id", id);

      if (error) throw new Error(`Failed to delete holiday: ${error.message}`);

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
