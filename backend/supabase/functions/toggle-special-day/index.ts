import { serve } from "https://deno.land/std@0.177.0/http/server.ts";
import { corsHeaders } from "../_shared/cors.ts";
import { getSupabaseClient, getSupabaseAdmin } from "../_shared/supabase-client.ts";
import { getAuthUser, requireRole } from "../_shared/auth.ts";

/**
 * Calculate effective work minutes based on special day type.
 * - rounding mode: round to half/full day then × multiplier
 * - fixed_hours mode: base_minutes + extra_minutes × extra_multiplier
 */
function calculateEffective(
  totalWorkMinutes: number,
  expectedWorkMinutes: number,
  dayType: {
    calculation_mode: string;
    multiplier: number;
    base_minutes: number;
    extra_minutes: number;
    extra_multiplier: number;
  }
): number {
  if (dayType.calculation_mode === "fixed_hours") {
    return Math.round(
      dayType.base_minutes + dayType.extra_minutes * dayType.extra_multiplier
    );
  }

  // rounding mode (boss call style)
  const mult = parseFloat(String(dayType.multiplier)) || 1.5;
  const halfDay = Math.round(expectedWorkMinutes / 2);

  let roundedMinutes: number;
  if (totalWorkMinutes <= 0) {
    roundedMinutes = halfDay;
  } else if (totalWorkMinutes < halfDay) {
    roundedMinutes = halfDay;
  } else if (totalWorkMinutes <= expectedWorkMinutes) {
    roundedMinutes = expectedWorkMinutes;
  } else {
    roundedMinutes = totalWorkMinutes;
  }

  return Math.round(roundedMinutes * mult);
}

serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  try {
    const authHeader = req.headers.get("Authorization")!;
    const supabase = getSupabaseClient(authHeader);
    const user = await getAuthUser(supabase);
    requireRole(user, ["operator", "super_admin"]);

    const { employee_id, date, special_day_type_id } = await req.json();
    if (!employee_id || !date) throw new Error("employee_id and date are required");

    const supabaseAdmin = getSupabaseAdmin();

    // Get the daily summary
    const { data: summary, error: fetchError } = await supabaseAdmin
      .from("daily_summaries")
      .select("*")
      .eq("employee_id", employee_id)
      .eq("summary_date", date)
      .single();

    if (fetchError || !summary) {
      throw new Error("Daily summary not found for this employee and date");
    }

    // If clearing the special day type
    if (!special_day_type_id) {
      const { data: updated, error: updateError } = await supabaseAdmin
        .from("daily_summaries")
        .update({
          special_day_type_id: null,
          is_boss_call: false,
          effective_work_minutes: summary.total_work_minutes,
        })
        .eq("id", summary.id)
        .select()
        .single();

      if (updateError) throw new Error(`Failed to update: ${updateError.message}`);

      return new Response(JSON.stringify({ summary: updated }), {
        headers: { ...corsHeaders, "Content-Type": "application/json" },
        status: 200,
      });
    }

    // Fetch the special day type definition
    const { data: dayType, error: typeError } = await supabaseAdmin
      .from("special_day_types")
      .select("*")
      .eq("id", special_day_type_id)
      .eq("is_active", true)
      .single();

    if (typeError || !dayType) {
      throw new Error("Special day type not found or inactive");
    }

    // Check eligibility: if not applies_to_all, employee must be assigned
    if (!dayType.applies_to_all) {
      const { data: assignment } = await supabaseAdmin
        .from("employee_special_day_types")
        .select("id")
        .eq("employee_id", employee_id)
        .eq("special_day_type_id", special_day_type_id)
        .single();

      if (!assignment) {
        throw new Error("Employee is not eligible for this special day type");
      }
    }

    // Calculate effective work minutes
    const effectiveWorkMinutes = calculateEffective(
      summary.total_work_minutes,
      summary.expected_work_minutes || 480,
      {
        calculation_mode: dayType.calculation_mode,
        multiplier: parseFloat(dayType.multiplier),
        base_minutes: dayType.base_minutes,
        extra_minutes: dayType.extra_minutes,
        extra_multiplier: parseFloat(dayType.extra_multiplier),
      }
    );

    // Backward compat: set is_boss_call if this is the boss_call type
    const isBossCall = dayType.code === "boss_call";

    const { data: updated, error: updateError } = await supabaseAdmin
      .from("daily_summaries")
      .update({
        special_day_type_id: dayType.id,
        is_boss_call: isBossCall,
        effective_work_minutes: effectiveWorkMinutes,
      })
      .eq("id", summary.id)
      .select()
      .single();

    if (updateError) throw new Error(`Failed to update: ${updateError.message}`);

    return new Response(JSON.stringify({ summary: updated }), {
      headers: { ...corsHeaders, "Content-Type": "application/json" },
      status: 200,
    });
  } catch (error) {
    const msg = (error as Error).message;
    const status = msg === "Unauthorized" ? 401 : msg.startsWith("Forbidden") ? 403 : 400;
    return new Response(JSON.stringify({ error: msg }), {
      headers: { ...corsHeaders, "Content-Type": "application/json" },
      status,
    });
  }
});
