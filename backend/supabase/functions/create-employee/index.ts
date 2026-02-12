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
    requireRole(user, ["operator"]);

    const body = await req.json();
    const { email, password, first_name, last_name, phone, start_date, role, schedule, leave_balances, leave_entitlements } = body;

    if (!email || !password || !first_name || !last_name) {
      throw new Error("email, password, first_name, and last_name are required");
    }

    // Role must be employee or chef
    const employeeRole = role || "employee";
    if (!["employee", "chef"].includes(employeeRole)) {
      throw new Error("role must be 'employee' or 'chef'");
    }

    const supabaseAdmin = getSupabaseAdmin();

    // 1. Create the auth user
    const { data: authData, error: authError } = await supabaseAdmin.auth.admin.createUser({
      email,
      password,
      email_confirm: true,
    });

    if (authError) throw new Error(`Failed to create auth user: ${authError.message}`);

    // 2. Create the profile
    const { data: profileData, error: profileError } = await supabaseAdmin
      .from("profiles")
      .insert({
        id: authData.user.id,
        company_id: user.company_id,
        role: employeeRole,
        first_name,
        last_name,
        email,
        phone: phone || null,
        start_date: start_date || null,
      })
      .select()
      .single();

    if (profileError) {
      await supabaseAdmin.auth.admin.deleteUser(authData.user.id);
      throw new Error(`Failed to create profile: ${profileError.message}`);
    }

    // 3. Create schedule if provided
    let scheduleData = null;
    if (schedule) {
      const { data: sched, error: schedError } = await supabaseAdmin
        .from("employee_schedules")
        .insert({
          employee_id: authData.user.id,
          company_id: user.company_id,
          shift_template_id: schedule.shift_template_id || null,
          custom_start_time: schedule.custom_start_time || null,
          custom_end_time: schedule.custom_end_time || null,
          custom_break_duration_minutes: schedule.custom_break_duration_minutes || null,
          custom_work_days: schedule.custom_work_days || null,
          effective_from: schedule.effective_from || new Date().toISOString().split("T")[0],
        })
        .select()
        .single();

      if (schedError) {
        console.error("Failed to create schedule:", schedError.message);
      } else {
        scheduleData = sched;
      }
    }

    // 4. Create leave entitlements if provided
    if (Array.isArray(leave_entitlements) && leave_entitlements.length > 0) {
      const entRows = leave_entitlements.map((ent: { leave_type_id: string; days_per_year: number }) => ({
        employee_id: authData.user.id,
        company_id: user.company_id,
        leave_type_id: ent.leave_type_id,
        days_per_year: ent.days_per_year,
      }));

      const { error: entError } = await supabaseAdmin
        .from("employee_leave_entitlements")
        .insert(entRows);

      if (entError) {
        console.error("Failed to create leave entitlements:", entError.message);
      }
    }

    // 5. Create initial leave balances if provided
    if (Array.isArray(leave_balances) && leave_balances.length > 0) {
      const currentYear = new Date().getFullYear();
      const rows = leave_balances.map((lb: { leave_type_id: string; total_days: number }) => ({
        employee_id: authData.user.id,
        company_id: user.company_id,
        leave_type_id: lb.leave_type_id,
        year: currentYear,
        total_days: lb.total_days,
        used_days: 0,
      }));

      const { error: lbError } = await supabaseAdmin
        .from("leave_balances")
        .insert(rows);

      if (lbError) {
        console.error("Failed to create leave balances:", lbError.message);
      }
    }

    return new Response(
      JSON.stringify({ employee: profileData, schedule: scheduleData }),
      {
        headers: { ...corsHeaders, "Content-Type": "application/json" },
        status: 201,
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
