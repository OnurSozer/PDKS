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
    requireRole(user, ["super_admin"]);

    const { company, operator } = await req.json();

    if (!company?.name) {
      throw new Error("Company name is required");
    }
    if (!operator?.email || !operator?.password || !operator?.first_name || !operator?.last_name) {
      throw new Error("Operator email, password, first_name, and last_name are required");
    }

    const supabaseAdmin = getSupabaseAdmin();

    // 1. Create the company
    const { data: companyData, error: companyError } = await supabaseAdmin
      .from("companies")
      .insert({
        name: company.name,
        address: company.address || null,
        phone: company.phone || null,
        email: company.email || null,
      })
      .select()
      .single();

    if (companyError) throw new Error(`Failed to create company: ${companyError.message}`);

    // 2. Create the operator auth user
    const { data: authData, error: authError } = await supabaseAdmin.auth.admin.createUser({
      email: operator.email,
      password: operator.password,
      email_confirm: true,
    });

    if (authError) {
      // Rollback: delete the company
      await supabaseAdmin.from("companies").delete().eq("id", companyData.id);
      throw new Error(`Failed to create operator auth user: ${authError.message}`);
    }

    // 3. Create the operator profile
    const { data: profileData, error: profileError } = await supabaseAdmin
      .from("profiles")
      .insert({
        id: authData.user.id,
        company_id: companyData.id,
        role: "operator",
        first_name: operator.first_name,
        last_name: operator.last_name,
        email: operator.email,
        phone: operator.phone || null,
      })
      .select()
      .single();

    if (profileError) {
      // Rollback: delete the auth user and company
      await supabaseAdmin.auth.admin.deleteUser(authData.user.id);
      await supabaseAdmin.from("companies").delete().eq("id", companyData.id);
      throw new Error(`Failed to create operator profile: ${profileError.message}`);
    }

    // 4. Create default notification settings for the company
    await supabaseAdmin.from("notification_settings").insert({
      company_id: companyData.id,
    });

    return new Response(
      JSON.stringify({ company: companyData, operator: profileData }),
      {
        headers: { ...corsHeaders, "Content-Type": "application/json" },
        status: 201,
      }
    );
  } catch (error) {
    const status = (error as Error).message === "Unauthorized" ? 401 : 400;
    return new Response(
      JSON.stringify({ error: (error as Error).message }),
      {
        headers: { ...corsHeaders, "Content-Type": "application/json" },
        status,
      }
    );
  }
});
