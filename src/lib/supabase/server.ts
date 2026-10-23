import 'server-only';

import { createClient, type SupabaseClient } from '@supabase/supabase-js';
import { isSupabaseConfigured, requireSupabaseEnv } from './env';

/**
 * Server-side Supabase client using the public anon key.
 * Row Level Security is enforced exactly as for a signed-out visitor, so this
 * can only read live catalog rows. Server-only secrets must not be added here.
 */
export function getSupabaseServerClient(): SupabaseClient {
  const { url, anonKey } = requireSupabaseEnv();
  return createClient(url, anonKey, {
    auth: { persistSession: false, autoRefreshToken: false },
    global: { headers: { 'X-Client-Info': 'mocodex-launchpad/server' } },
  });
}

export { isSupabaseConfigured };
