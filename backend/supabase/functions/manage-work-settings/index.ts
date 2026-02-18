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
        .from("company_work_settings")
        .select("*")
        .eq("company_id", user.company_id!)
        .single();

      if (error && error.code !== "PGRST116") {
        throw new Error(`Failed to fetch work settings: ${error.message}`);
      }

      return new Response(JSON.stringify({ settings: data || null }), {
        headers: { ...corsHeaders, "Content-Type": "application/json" },
        status: 200,
      });
    }

    if (method === "POST" || method === "PUT") {
      const body = await req.json();
      const {
        monthly_work_days_constant,
        overtime_multiplier,
        weekend_multiplier,
        holiday_multiplier,
        boss_call_multiplier,
      } = body;

      const payload = {
        company_id: user.company_id!,
        monthly_work_days_constant: monthly_work_days_constant ?? 21.66,
        overtime_multiplier: overtime_multiplier ?? 1.5,
        weekend_multiplier: weekend_multiplier ?? 1.5,
        holiday_multiplier: holiday_multiplier ?? 2.0,
        boss_call_multiplier: boss_call_multiplier ?? 1.5,
      };

      const { data, error } = await supabase
        .from("company_work_settings")
        .upsert(payload, { onConflict: "company_id" })
        .select()
        .single();

      if (error) throw new Error(`Failed to save work settings: ${error.message}`);

      // Sync boss_call_multiplier to the special_day_types row with code='boss_call'
      if (boss_call_multiplier !== undefined) {
        await supabase
          .from("special_day_types")
          .update({ multiplier: boss_call_multiplier })
          .eq("company_id", user.company_id!)
          .eq("code", "boss_call");
      }

      return new Response(JSON.stringify({ settings: data }), {
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
