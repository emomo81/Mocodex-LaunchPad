-- Foundation only. Do not enable build downloads until private storage, malware scanning,
-- signed URL issuance, and admin-only publishing and privileged moderation endpoints are implemented.
create extension if not exists pgcrypto;
create type public.app_status as enum ('draft','pending','live','rejected','hidden');
create type public.build_platform as enum ('android','windows','mac','linux','web');
create type public.scan_state as enum ('pending','clean','flagged','error');
create type public.report_state as enum ('open','resolved','dismissed');

create table public.users (
 id uuid primary key references auth.users(id) on delete cascade,
 name text not null default '', avatar_url text, bio text,
 role text not null default 'member' check (role in ('member','creator','admin')),
 created_at timestamptz not null default now()
);
create table public.categories (
 id bigint generated always as identity primary key,
 slug text not null unique, name text not null unique
);
insert into public.categories(slug,name) values
 ('productivity','Productivity'),('education','Education'),('games','Games'),
 ('dev-tools','Dev Tools'),('health','Health'),('business','Business');
create table public.apps (
 id uuid primary key default gen_random_uuid(), creator_id uuid not null references public.users(id),
 slug text not null unique, name text not null, tagline text not null, description text not null,
 category_id bigint not null references public.categories(id), icon_url text,
 status public.app_status not null default 'draft', tags text[] not null default '{}',
 avg_rating numeric(3,2) not null default 0, rating_count integer not null default 0,
 download_count integer not null default 0, featured boolean not null default false,
 created_at timestamptz not null default now()
);
create table public.versions (
 id uuid primary key default gen_random_uuid(), app_id uuid not null references public.apps(id) on delete cascade,
 version_number text not null, changelog text not null, released_at timestamptz,
 status public.app_status not null default 'draft', unique(app_id,version_number)
);
create table public.builds (
 id uuid primary key default gen_random_uuid(), version_id uuid not null references public.versions(id) on delete cascade,
 platform public.build_platform not null, file_path text not null, file_size bigint not null default 0
 check (file_size between 0 and 524288000), sha256 text check (sha256 ~ '^[a-f0-9]{64}$'),
 scan_status public.scan_state not null default 'pending', scan_checked_at timestamptz,
 unique(version_id,platform)
);
create table public.screenshots (
 id uuid primary key default gen_random_uuid(), app_id uuid not null references public.apps(id) on delete cascade,
 image_url text not null, sort_order integer not null default 0
);
create table public.reviews (
 id uuid primary key default gen_random_uuid(), app_id uuid not null references public.apps(id) on delete cascade,
 user_id uuid not null references public.users(id), version_id uuid references public.versions(id),
 rating smallint not null check (rating between 1 and 5), body text not null,
 helpful_count integer not null default 0, creator_reply text,
 status text not null default 'visible' check (status in ('visible','hidden')),
 created_at timestamptz not null default now(), updated_at timestamptz not null default now(),
 unique(app_id,user_id)
);
create table public.review_history (
 id bigint generated always as identity primary key, review_id uuid not null references public.reviews(id) on delete cascade,
 old_rating smallint not null, old_body text not null, edited_at timestamptz not null default now()
);
create table public.review_votes (
 review_id uuid not null references public.reviews(id) on delete cascade,
 user_id uuid not null references public.users(id) on delete cascade,
 primary key(review_id,user_id)
);
create table public.downloads (
 id uuid primary key default gen_random_uuid(), build_id uuid not null references public.builds(id),
 user_id uuid references public.users(id), ip_hash text, created_at timestamptz not null default now(),
 check (user_id is not null or ip_hash is not null)
);
create unique index downloads_member_once on public.downloads(build_id,user_id) where user_id is not null;
create unique index downloads_visitor_once on public.downloads(build_id,ip_hash) where user_id is null;
create index downloads_trending on public.downloads(created_at,build_id);
create table public.reports (
 id uuid primary key default gen_random_uuid(), reporter_id uuid not null references public.users(id),
 target_type text not null check (target_type in ('app','review','user')),
 target_id uuid not null, reason text not null, status public.report_state not null default 'open',
 created_at timestamptz not null default now()
);
create table public.feedback (
 id uuid primary key default gen_random_uuid(), app_id uuid not null references public.apps(id),
 user_id uuid not null references public.users(id), kind text not null check (kind in ('bug','idea')),
 body text not null, created_at timestamptz not null default now()
);
create table public.admin_audit (
 id bigint generated always as identity primary key, actor_id uuid not null references public.users(id),
 action text not null, target_type text not null, target_id uuid not null,
 reason text, created_at timestamptz not null default now()
);

create function public.refresh_app_rating() returns trigger language plpgsql security definer set search_path = '' as $$
begin
 update public.apps set avg_rating = coalesce((select round(avg(rating)::numeric,2) from public.reviews where app_id = coalesce(new.app_id,old.app_id) and status = 'visible'),0),
 rating_count = (select count(*) from public.reviews where app_id = coalesce(new.app_id,old.app_id) and status = 'visible')
 where id = coalesce(new.app_id,old.app_id);
 return null;
end $$;
create trigger refresh_rating after insert or update or delete on public.reviews
 for each row execute function public.refresh_app_rating();
create function public.refresh_app_downloads() returns trigger language plpgsql security definer set search_path = '' as $$
begin
 update public.apps set download_count = (
  select count(*) from public.downloads d join public.builds b on b.id = d.build_id
  join public.versions v on v.id = b.version_id where v.app_id =
  (select v2.app_id from public.builds b2 join public.versions v2 on v2.id=b2.version_id where b2.id=new.build_id)
 ) where id = (select v.app_id from public.builds b join public.versions v on v.id=b.version_id where b.id=new.build_id);
 return null;
end $$;
create trigger refresh_downloads after insert on public.downloads
 for each row execute function public.refresh_app_downloads();

-- Read-only public catalog. Only the Mocodex admin may publish. All writes require trusted server-side operations and
-- explicit policies to be added after auth, verification, scanning and rate limits.
alter table public.users enable row level security;
alter table public.categories enable row level security;
alter table public.apps enable row level security;
alter table public.versions enable row level security;
alter table public.builds enable row level security;
alter table public.screenshots enable row level security;
alter table public.reviews enable row level security;
alter table public.review_history enable row level security;
alter table public.review_votes enable row level security;
alter table public.downloads enable row level security;
alter table public.reports enable row level security;
alter table public.feedback enable row level security;
alter table public.admin_audit enable row level security;
create policy categories_read on public.categories for select using (true);
create policy live_apps_read on public.apps for select using (status = 'live');
create policy live_versions_read on public.versions for select using (status = 'live' and exists
 (select 1 from public.apps where id = app_id and status = 'live'));
-- Never expose builds.file_path through public RLS: only a server-side signed URL endpoint may read it.
create policy live_screenshots_read on public.screenshots for select using (exists
 (select 1 from public.apps where id = app_id and status = 'live'));
create policy visible_reviews_read on public.reviews for select using (status = 'visible' and exists
 (select 1 from public.apps where id = app_id and status = 'live'));
create policy public_creators_read on public.users for select using (exists
 (select 1 from public.apps where creator_id = id and status = 'live'));
