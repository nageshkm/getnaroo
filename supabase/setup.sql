-- getnaroo.com: database, storage and security rules.
-- Run once in the Supabase SQL editor. Safe to re-run.
-- Replace ADMIN_EMAIL_HERE with the organizer's email before running.

-- 1. Organizers (who can approve)
create table if not exists public.admins (email text primary key);
alter table public.admins enable row level security;
insert into public.admins (email) values (lower('ADMIN_EMAIL_HERE')) on conflict do nothing;

create or replace function public.is_admin() returns boolean
language sql stable security definer set search_path = public as $$
  select exists (select 1 from public.admins a where a.email = lower(auth.jwt() ->> 'email'));
$$;
grant execute on function public.is_admin() to anon, authenticated;

-- 2. Memories
create table if not exists public.memories (
  id          uuid primary key default gen_random_uuid(),
  created_at  timestamptz not null default now(),
  name        text not null check (char_length(name) between 1 and 80),
  relation    text not null check (relation in ('work','tennis','beer','life')),
  how_known   text check (char_length(how_known) <= 140),
  year_met    int  check (year_met between 1976 and 2026),
  moment      text check (char_length(moment) <= 2000),
  taught      text check (char_length(taught) <= 2000),
  wish        text check (char_length(wish) <= 1000),
  video_link  text check (char_length(video_link) <= 500 and video_link ~* '^https?://'),
  media       jsonb not null default '[]'::jsonb check (jsonb_typeof(media) = 'array' and jsonb_array_length(media) <= 6),
  approved    boolean not null default false,
  featured    boolean not null default false
);
alter table public.memories enable row level security;

drop policy if exists "anyone can submit" on public.memories;
create policy "anyone can submit" on public.memories
  for insert to anon, authenticated
  with check (approved = false and featured = false);

drop policy if exists "approved visible after reveal" on public.memories;
create policy "approved visible after reveal" on public.memories
  for select to anon, authenticated
  using (approved = true and now() >= timestamptz '2026-11-16 00:00:00+05:30');

drop policy if exists "organizers read all" on public.memories;
create policy "organizers read all" on public.memories
  for select to authenticated using (public.is_admin());

drop policy if exists "organizers update" on public.memories;
create policy "organizers update" on public.memories
  for update to authenticated using (public.is_admin()) with check (public.is_admin());

drop policy if exists "organizers delete" on public.memories;
create policy "organizers delete" on public.memories
  for delete to authenticated using (public.is_admin());

-- How many memories are waiting (shown on the locked wall; reveals nothing else).
create or replace function public.memory_count() returns int
language sql stable security definer set search_path = public as $$
  select count(*)::int from public.memories;
$$;
grant execute on function public.memory_count() to anon, authenticated;

-- 3. Storage for photos and videos (public read via unguessable paths, 50 MB cap)
insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values ('memories', 'memories', true, 52428800, array['image/*','video/*'])
on conflict (id) do update set public = true, file_size_limit = 52428800, allowed_mime_types = array['image/*','video/*'];

drop policy if exists "anyone can upload memories" on storage.objects;
create policy "anyone can upload memories" on storage.objects
  for insert to anon, authenticated
  with check (bucket_id = 'memories');

drop policy if exists "organizers manage memory files" on storage.objects;
create policy "organizers manage memory files" on storage.objects
  for delete to authenticated
  using (bucket_id = 'memories' and public.is_admin());

drop policy if exists "organizers read memory files" on storage.objects;
create policy "organizers read memory files" on storage.objects
  for select to authenticated
  using (bucket_id = 'memories' and public.is_admin());
