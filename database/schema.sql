-- TD future backend schema draft for Supabase PostgreSQL.
-- Review before applying. OAuth and storage are not configured by this script.
create table if not exists public.td_profiles (
  user_id uuid primary key references auth.users(id) on delete cascade,
  display_name text not null check (char_length(display_name) between 1 and 40),
  created_at timestamptz not null default now()
);
create table if not exists public.td_meetings (
  id uuid primary key default gen_random_uuid(),
  owner_id uuid not null references auth.users(id) on delete cascade,
  category text not null check (category in ('와인 페어링','전통주 페어링','싱글몰트 페어링')),
  title text not null check (char_length(title) between 1 and 120),
  venue text not null check (char_length(venue) between 1 and 200),
  starts_at timestamptz not null,
  status text not null default 'pending' check (status in ('pending','approved','rejected')),
  created_at timestamptz not null default now()
);
create table if not exists public.td_posts (
  id uuid primary key default gen_random_uuid(),
  author_id uuid not null references auth.users(id) on delete cascade,
  category text not null check (category in ('와인 페어링','전통주 페어링','싱글몰트 페어링','모임 후기')),
  title text not null check (char_length(title) between 1 and 120),
  body text not null check (char_length(body) between 1 and 5000),
  created_at timestamptz not null default now()
);
alter table public.td_profiles enable row level security;
alter table public.td_meetings enable row level security;
alter table public.td_posts enable row level security;
create policy "profiles select authenticated" on public.td_profiles for select to authenticated using (true);
create policy "profiles insert own" on public.td_profiles for insert to authenticated with check ((select auth.uid()) = user_id);
create policy "profiles update own" on public.td_profiles for update to authenticated using ((select auth.uid()) = user_id) with check ((select auth.uid()) = user_id);
create policy "meetings read approved or own" on public.td_meetings for select to authenticated using (status='approved' or owner_id=(select auth.uid()));
create policy "meetings create pending own" on public.td_meetings for insert to authenticated with check (owner_id=(select auth.uid()) and status='pending');
-- No direct meeting update policy: prevents users from approving their own meetings.
-- Approval must happen via a separately authenticated, audited admin backend.
create policy "posts read authenticated" on public.td_posts for select to authenticated using (true);
create policy "posts insert own" on public.td_posts for insert to authenticated with check (author_id=(select auth.uid()));
create policy "posts update own" on public.td_posts for update to authenticated using (author_id=(select auth.uid())) with check (author_id=(select auth.uid()));
create policy "posts delete own" on public.td_posts for delete to authenticated using (author_id=(select auth.uid()));
