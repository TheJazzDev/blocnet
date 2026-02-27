import { createClient, type SupabaseClient } from "@supabase/supabase-js";

let _client: SupabaseClient | null = null;

export function getSupabaseClient(): SupabaseClient {
  if (_client) return _client;

  const supabaseUrl = process.env.NEXT_PUBLIC_SUPABASE_URL;
  const supabaseAnonKey = process.env.NEXT_PUBLIC_PUBLISHABLE_KEY;

  if (!supabaseUrl || !supabaseAnonKey) {
    throw new Error(
      "Missing NEXT_PUBLIC_SUPABASE_URL or NEXT_PUBLIC_PUBLISHABLE_KEY. " +
        "Create console/.env.local from console/.env.local.example."
    );
  }

  _client = createClient(supabaseUrl, supabaseAnonKey, {
    auth: {
      // Admin auth authority is httpOnly cookies + server refresh paths.
      persistSession: false,
      autoRefreshToken: false,
      detectSessionInUrl: false,
    },
  });
  return _client;
}

/** Convenience re-export for components that need the client directly. */
export const supabase = {
  get auth() {
    return getSupabaseClient().auth;
  },
};
