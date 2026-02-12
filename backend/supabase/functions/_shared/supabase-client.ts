import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

/**
 * Creates a Supabase admin client using the service_role key.
 * This client bypasses RLS and should only be used for admin operations
 * (creating auth users, batch queries, etc.).
 */
export function getSupabaseAdmin() {
  return createClient(
    Deno.env.get("SUPABASE_URL")!,
    Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!,
    {
      auth: {
        autoRefreshToken: false,
        persistSession: false,
      },
    }
  );
}

/**
 * Creates a Supabase client using the user's JWT.
 * This client respects RLS policies.
 */
export function getSupabaseClient(authHeader: string) {
  return createClient(
    Deno.env.get("SUPABASE_URL")!,
    Deno.env.get("SUPABASE_ANON_KEY")!,
    {
      global: { headers: { Authorization: authHeader } },
    }
  );
}
