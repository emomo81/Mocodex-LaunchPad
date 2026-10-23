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

## Publishing policy

Mocodex admin is the only publisher. There is no creator self-service upload or publish flow. Outside developers may be considered for inclusion, but the admin must enter their listing, upload and scan builds, and approve releases. Before connecting this prototype to a backend, enforce admin-only create/update access server-side (not just by hiding UI controls).

The public storefront intentionally has **no admin navigation**. The demo admin screens are not protected by authentication and must not be treated as a secure admin area. Before any real publishing, put them behind a separate server-verified admin route and enforce admin authorization in the backend.
