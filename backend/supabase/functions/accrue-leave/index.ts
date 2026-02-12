import { serve } from "https://deno.land/std@0.177.0/http/server.ts";
import { corsHeaders } from "../_shared/cors.ts";
import { getSupabaseAdmin } from "../_shared/supabase-client.ts";

/**
 * Cron job: runs 1st of each month to accrue leave days.
 * Invoked with service_role key (--no-verify-jwt).
 *
 * Logic:
 * - Monthly mode: add days_per_year/12 to current year balance (create if missing)
 * - Yearly mode (Jan only): create new year balance = carry_over + days_per_year
 * - Monthly mode (Jan): handle carry-over first, then add first month's accrual
 * - Skip employees created in the current month (they got initial balance at creation)
 */
serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  try {
    const supabaseAdmin = getSupabaseAdmin();
    const now = new Date();
    const currentYear = now.getFullYear();
    const currentMonth = now.getMonth() + 1; // 1-12
    const isJanuary = currentMonth === 1;
    const previousYear = currentYear - 1;

    // First day of current month for filtering new employees
    const firstOfMonth = `${currentYear}-${String(currentMonth).padStart(2, "0")}-01`;

    // Get all companies with their accrual mode
    const { data: companies, error: compError } = await supabaseAdmin
      .from("companies")
      .select("id")
      .eq("is_active", true);

    if (compError) throw new Error(`Failed to fetch companies: ${compError.message}`);

    let totalAccrued = 0;
    let totalCarryOvers = 0;

    for (const company of companies || []) {
      // Get accrual mode from notification_settings
      const { data: settings } = await supabaseAdmin
        .from("notification_settings")
        .select("leave_accrual_mode")
        .eq("company_id", company.id)
        .single();

      const accrualMode = settings?.leave_accrual_mode || "monthly";

      // Yearly mode + not January => skip this company
      if (accrualMode === "yearly" && !isJanuary) {
        continue;
      }

      // Get active employees with entitlements, excluding those created this month
      const { data: entitlements, error: entError } = await supabaseAdmin
        .from("employee_leave_entitlements")
        .select("employee_id, leave_type_id, days_per_year, company_id")
        .eq("company_id", company.id);

      if (entError) {
        console.error(`Failed to fetch entitlements for company ${company.id}:`, entError.message);
        continue;
      }

      if (!entitlements || entitlements.length === 0) continue;

      // Get active employees, filter out those created this month
      const employeeIds = [...new Set(entitlements.map((e) => e.employee_id))];
      const { data: activeEmployees, error: empError } = await supabaseAdmin
        .from("profiles")
        .select("id, created_at")
        .in("id", employeeIds)
        .eq("is_active", true);

      if (empError) {
        console.error(`Failed to fetch employees for company ${company.id}:`, empError.message);
        continue;
      }

      // Filter out employees created in the current month
      const eligibleEmployees = (activeEmployees || []).filter((emp) => {
        const createdDate = new Date(emp.created_at);
        return !(
          createdDate.getFullYear() === currentYear &&
          createdDate.getMonth() + 1 === currentMonth
        );
      });

      const eligibleIds = new Set(eligibleEmployees.map((e) => e.id));

      for (const ent of entitlements) {
        if (!eligibleIds.has(ent.employee_id)) continue;

        // --- JANUARY: Handle carry-over ---
        if (isJanuary) {
          // Get previous year balance for carry-over calculation
          const { data: prevBalance } = await supabaseAdmin
            .from("leave_balances")
            .select("total_days, used_days")
            .eq("employee_id", ent.employee_id)
            .eq("leave_type_id", ent.leave_type_id)
            .eq("year", previousYear)
            .single();

          const carryOver = prevBalance
            ? Math.max(0, Number(prevBalance.total_days) - Number(prevBalance.used_days))
            : 0;

          // Check if current year balance already exists
          const { data: existingBalance } = await supabaseAdmin
            .from("leave_balances")
            .select("id, total_days")
            .eq("employee_id", ent.employee_id)
            .eq("leave_type_id", ent.leave_type_id)
            .eq("year", currentYear)
            .single();

          if (accrualMode === "yearly") {
            // Yearly mode: set total_days = carry_over + full entitlement
            const newTotal = carryOver + Number(ent.days_per_year);

            if (existingBalance) {
              await supabaseAdmin
                .from("leave_balances")
                .update({ total_days: newTotal })
                .eq("id", existingBalance.id);
            } else {
              await supabaseAdmin.from("leave_balances").insert({
                employee_id: ent.employee_id,
                leave_type_id: ent.leave_type_id,
                company_id: ent.company_id,
                year: currentYear,
                total_days: newTotal,
                used_days: 0,
              });
            }

            if (carryOver > 0) totalCarryOvers++;
            totalAccrued++;
          } else {
            // Monthly mode, January: carry-over + first month's accrual
            const monthlyAccrual = Number(ent.days_per_year) / 12;
            const newTotal = carryOver + monthlyAccrual;

            if (existingBalance) {
              // Add monthly accrual + carry-over to existing balance
              await supabaseAdmin
                .from("leave_balances")
                .update({
                  total_days: Number(existingBalance.total_days) + carryOver + monthlyAccrual,
                })
                .eq("id", existingBalance.id);
            } else {
              await supabaseAdmin.from("leave_balances").insert({
                employee_id: ent.employee_id,
                leave_type_id: ent.leave_type_id,
                company_id: ent.company_id,
                year: currentYear,
                total_days: newTotal,
                used_days: 0,
              });
            }

            if (carryOver > 0) totalCarryOvers++;
            totalAccrued++;
          }
        } else {
          // --- NON-JANUARY MONTHS (monthly mode only) ---
          const monthlyAccrual = Number(ent.days_per_year) / 12;

          // Get or create current year balance
          const { data: existingBalance } = await supabaseAdmin
            .from("leave_balances")
            .select("id, total_days")
            .eq("employee_id", ent.employee_id)
            .eq("leave_type_id", ent.leave_type_id)
            .eq("year", currentYear)
            .single();

          if (existingBalance) {
            await supabaseAdmin
              .from("leave_balances")
              .update({
                total_days: Number(existingBalance.total_days) + monthlyAccrual,
              })
              .eq("id", existingBalance.id);
          } else {
            await supabaseAdmin.from("leave_balances").insert({
              employee_id: ent.employee_id,
              leave_type_id: ent.leave_type_id,
              company_id: ent.company_id,
              year: currentYear,
              total_days: monthlyAccrual,
              used_days: 0,
            });
          }

          totalAccrued++;
        }
      }
    }

    return new Response(
      JSON.stringify({
        success: true,
        accrued: totalAccrued,
        carry_overs: totalCarryOvers,
        month: currentMonth,
        year: currentYear,
      }),
      {
        headers: { ...corsHeaders, "Content-Type": "application/json" },
        status: 200,
      }
    );
  } catch (error) {
    const msg = (error as Error).message;
    console.error("accrue-leave error:", msg);
    return new Response(
      JSON.stringify({ error: msg }),
      {
        headers: { ...corsHeaders, "Content-Type": "application/json" },
        status: 400,
      }
    );
  }
});
