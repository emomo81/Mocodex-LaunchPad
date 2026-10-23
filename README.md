# Mocodex LaunchPad

An interactive storefront prototype for discovering independent apps, with demo admin screens. Built with Next.js App Router, TypeScript, and CSS.

## Run locally

```bash
npm install
npm run dev
```

Open http://localhost:3000. Run `npm run build` to validate production compilation.

## What works in this prototype

- Browse featured and new apps, filter by category and platform, search, and sort.
- Open app details with version, platforms, creator, and rating information.
- Preview the a local-only admin dashboard, listing form, and sample queue in the prototype code (not linked from the public site).

**This is not a production app store.** Catalog entries and metrics are illustrative in-memory data. A draft created in the form exists only until refresh. Download buttons do not issue files; admin actions do not approve real submissions. No login, payment, file upload, virus scan, review, or signed URL endpoint is connected. This is intentional: no unscanned executable should be downloadable.

`supabase/migrations/20261022000000_initial_schema.sql` is a database starting point with RLS enabled and public read policies limited to live catalog data. It is not connected to the UI. Before launch, implement verified admin auth, admin-only publishing policies, privileged moderation with audit records, private R2 uploads and signed downloads, scanner callbacks and approval gates, reviews restricted to verified downloaders, rate limits, legal pages, and operational monitoring. In particular, keep builds and their storage paths inaccessible to public clients.

## Current setup status

| Service | State |
| --- | --- |
| Vercel | Project `mocodex-launchpad` created in `emomo81's projects`, linked to `emomo81/Mocodex-LaunchPad`, production branch `main`. First deployment built from `arena/2f78110e-mocodex-launchpad` and is `READY`. |
| Supabase | Not provisioned. A new project was refused because the org is at its free-project limit (5 projects: `icchr`, `exam-platform` active; `Confidence School Marks`, `stock-management` paused). No env vars are set, so `/api/health` reports `unconfigured` and the storefront stays on demo data. |

To finish Supabase later: free a slot (delete/pause a project, or upgrade the org), create the project, then run the migration and set the two env vars (locally and in Vercel).

## Supabase

The database lives in Supabase (Postgres 17 + RLS). `supabase/migrations/20261022000000_initial_schema.sql` is the source of truth; the UI still renders demo data, so a missing Supabase configuration never breaks the storefront.

1. Copy `.env.example` to `.env.local` and fill in the Project URL and the **anon/publishable** key (Project settings → API). Never put the service-role key in a `NEXT_PUBLIC_*` variable.
2. Apply the schema. Either paste the migration into the SQL editor, or use the CLI:
   ```bash
   supabase link --project-ref <project-ref>
   supabase db push
   ```
3. Verify the wiring with `GET /api/health`. It reports `unconfigured`, `ok` (with public catalog counts, read through RLS), or `degraded` (with the Supabase error).

Server code uses `src/lib/supabase/server.ts` (anon key + RLS, `server-only` guarded); browser code uses `src/lib/supabase/client.ts`, which returns `null` when env vars are absent.

## Vercel

The project `mocodex-launchpad` is linked to this GitHub repository (production branch `main`); branch pushes produce preview deployments.

- Environment variables (Production + Preview): `NEXT_PUBLIC_SUPABASE_URL`, `NEXT_PUBLIC_SUPABASE_ANON_KEY`.
- No custom build settings are required — Next.js is auto-detected and `npm run build` is the build command.
- Preview deployments sit behind Vercel's deployment protection; the production domain is public.

## Publishing policy

Mocodex admin is the only publisher. There is no creator self-service upload or publish flow. Outside developers may be considered for inclusion, but the admin must enter their listing, upload and scan builds, and approve releases. Before connecting this prototype to a backend, enforce admin-only create/update access server-side (not just by hiding UI controls).

The public storefront intentionally has **no admin navigation**. The demo admin screens are not protected by authentication and must not be treated as a secure admin area. Before any real publishing, put them behind a separate server-verified admin route and enforce admin authorization in the backend.
