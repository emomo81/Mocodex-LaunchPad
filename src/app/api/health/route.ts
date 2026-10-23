import { NextResponse } from 'next/server';
import { isSupabaseConfigured, getSupabaseServerClient } from '@/lib/supabase/server';

export const dynamic = 'force-dynamic';

/**
 * Connectivity check for the deployment wiring.
 * Reports whether Supabase credentials are present and whether the anon client
 * can read the public catalog (RLS: categories are world-readable, apps only
 * when live). It never exposes credentials or non-public rows.
 */
export async function GET() {
  const base = {
    service: 'mocodex-launchpad',
    vercel: {
      environment: process.env.VERCEL_ENV ?? 'local',
      region: process.env.VERCEL_REGION ?? null,
      commit: process.env.VERCEL_GIT_COMMIT_SHA?.slice(0, 7) ?? null,
    },
    supabase: {
      configured: isSupabaseConfigured,
      reachable: false,
      categories: 0,
      live_apps: 0,
      error: null as string | null,
    },
  };

  if (!isSupabaseConfigured) {
    return NextResponse.json(
      { ...base, status: 'unconfigured' },
      { status: 200, headers: { 'Cache-Control': 'no-store' } },
    );
  }

  try {
    const supabase = getSupabaseServerClient();

    const [categories, apps] = await Promise.all([
      supabase.from('categories').select('id', { count: 'exact', head: true }),
      supabase.from('apps').select('id', { count: 'exact', head: true }).eq('status', 'live'),
    ]);

    const error = categories.error ?? apps.error;
    if (error) throw new Error(error.message);

    base.supabase.reachable = true;
    base.supabase.categories = categories.count ?? 0;
    base.supabase.live_apps = apps.count ?? 0;

    return NextResponse.json(
      { ...base, status: 'ok' },
      { status: 200, headers: { 'Cache-Control': 'no-store' } },
    );
  } catch (error) {
    base.supabase.error = error instanceof Error ? error.message : 'Unknown Supabase error';
    return NextResponse.json(
      { ...base, status: 'degraded' },
      { status: 503, headers: { 'Cache-Control': 'no-store' } },
    );
  }
}
