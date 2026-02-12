import { SupabaseClient } from "https://esm.sh/@supabase/supabase-js@2";
import { getSupabaseAdmin } from "./supabase-client.ts";

export interface AuthUser {
  id: string;
  role: string;
  company_id: string | null;
}

/**
 * Extracts and validates the authenticated user from the Supabase client.
 * Gets the auth user, then looks up role and company_id from the profiles table.
 */
export async function getAuthUser(
  supabase: SupabaseClient
): Promise<AuthUser> {
  const {
    data: { user },
    error,
  } = await supabase.auth.getUser();

  if (error || !user) {
    throw new Error("Unauthorized");
  }

  // Look up role and company_id from profiles table (using admin client to bypass RLS)
  const admin = getSupabaseAdmin();
  const { data: profile, error: profileError } = await admin
    .from("profiles")
    .select("role, company_id")
    .eq("id", user.id)
    .single();

  if (profileError || !profile) {
    throw new Error("User profile not found");
  }

  return {
    id: user.id,
    role: profile.role,
    company_id: profile.company_id || null,
  };
}

/**
 * Asserts that the user has one of the required roles.
 * Throws an error if the role check fails.
 */
export function requireRole(user: AuthUser, allowedRoles: string[]): void {
  if (!allowedRoles.includes(user.role)) {
    throw new Error(
      `Forbidden: requires one of [${allowedRoles.join(", ")}], got ${user.role}`
    );
  }
}
