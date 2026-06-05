-- ============================================================
-- Shajarah (شجرة) — Family Tree — Schema (clean rebuild)
-- Olive design · four-part names · smart auto-linking · privacy
-- Run in the Supabase SQL editor. To reset: see DROP block at the very bottom.
-- ============================================================

create extension if not exists "uuid-ossp";

-- ── Tables ──────────────────────────────────────────────────────────────────

create table public.families (
  id          uuid primary key default uuid_generate_v4(),
  name        text not null,
  name_ar     text,
  description text,
  created_by  uuid references auth.users(id) on delete set null,
  created_at  timestamptz not null default now()
);

create table public.user_profiles (
  id           uuid primary key references auth.users(id) on delete cascade,
  full_name    text,
  role         text not null default 'viewer' check (role in ('admin','editor','viewer')),
  family_id    uuid references public.families(id) on delete set null,
  created_at   timestamptz not null default now()
);

create table public.members (
  id                      uuid primary key default uuid_generate_v4(),
  family_id               uuid not null references public.families(id) on delete cascade,
  -- paternal name (public). family_name = اللقب/العائلة, clan_name = القبيلة
  first_name              text not null,
  father_name             text not null,
  grandfather_name        text not null,
  family_name             text not null,
  clan_name               text,
  -- maternal four-part name (private — revealed only to verified relatives)
  mother_first_name       text,
  mother_father_name      text,
  mother_grandfather_name text,
  mother_family_name      text,
  -- scope + passport fields
  city                    text not null,
  gender                  text not null default 'male' check (gender in ('male','female')),
  birth_date              date,
  death_date              date,
  place_of_birth          text,
  show_birth_date         boolean not null default false,
  photo_url               text,
  notes                   text,
  created_by              uuid references auth.users(id) on delete set null,
  created_at              timestamptz not null default now()
);

-- link an app account to its tree member (drives privacy checks)
alter table public.user_profiles
  add column linked_member_id uuid references public.members(id) on delete set null;

create table public.relationships (
  id                uuid primary key default uuid_generate_v4(),
  member_id         uuid not null references public.members(id) on delete cascade,
  related_member_id uuid not null references public.members(id) on delete cascade,
  relationship_type text not null check (relationship_type in ('parent','child','spouse','sibling')),
  created_at        timestamptz not null default now(),
  unique (member_id, related_member_id, relationship_type)
);

-- A signed-up user requesting to "claim" an existing tree member as themselves.
-- Requires admin approval (real-world identity check).
create table public.member_claims (
  id         uuid primary key default uuid_generate_v4(),
  member_id  uuid not null references public.members(id) on delete cascade,
  user_id    uuid not null references auth.users(id) on delete cascade,
  status     text not null default 'pending' check (status in ('pending','approved','rejected')),
  created_at timestamptz not null default now(),
  unique (member_id, user_id)
);

-- ── Helpers (SECURITY DEFINER) ──────────────────────────────────────────────

create or replace function public.my_family_id()
returns uuid language sql security definer stable as $$
  select family_id from public.user_profiles where id = auth.uid() limit 1;
$$;

create or replace function public.setup_profile(
  p_family_name text, p_full_name text)
returns void language plpgsql security definer as $$
declare v_fid uuid;
begin
  insert into public.families (name, created_by) values (p_family_name, auth.uid())
  returning id into v_fid;
  insert into public.user_profiles (id, full_name, family_id, role)
  values (auth.uid(), p_full_name, v_fid, 'admin')
  on conflict (id) do update set full_name = excluded.full_name,
    family_id = excluded.family_id, role = 'admin';
end; $$;

create or replace function public.join_family_by_name(
  p_family_name text, p_full_name text)
returns void language plpgsql security definer as $$
declare v_fid uuid;
begin
  select id into v_fid from public.families where lower(name) = lower(p_family_name) limit 1;
  if v_fid is null then raise exception 'Family "%" not found', p_family_name; end if;
  insert into public.user_profiles (id, full_name, family_id, role)
  values (auth.uid(), p_full_name, v_fid, 'viewer')
  on conflict (id) do update set full_name = excluded.full_name, family_id = excluded.family_id;
end; $$;

create or replace function public.set_user_role(p_user_id uuid, p_role text)
returns void language plpgsql security definer as $$
declare v_role text; v_fam uuid; v_tfam uuid;
begin
  select role, family_id into v_role, v_fam from public.user_profiles where id = auth.uid();
  if v_role != 'admin' then raise exception 'Only admins can change roles'; end if;
  if p_user_id = auth.uid() then raise exception 'Cannot change your own role'; end if;
  select family_id into v_tfam from public.user_profiles where id = p_user_id;
  if v_tfam is distinct from v_fam then raise exception 'User not in your family'; end if;
  update public.user_profiles set role = p_role where id = p_user_id;
end; $$;

create or replace function public.remove_family_member_user(p_user_id uuid)
returns void language plpgsql security definer as $$
declare v_role text; v_fam uuid; v_tfam uuid;
begin
  select role, family_id into v_role, v_fam from public.user_profiles where id = auth.uid();
  if v_role != 'admin' then raise exception 'Only admins can remove users'; end if;
  if p_user_id = auth.uid() then raise exception 'Cannot remove yourself'; end if;
  select family_id into v_tfam from public.user_profiles where id = p_user_id;
  if v_tfam is distinct from v_fam then raise exception 'User not in your family'; end if;
  update public.user_profiles set family_id = null, role = 'viewer' where id = p_user_id;
end; $$;

create or replace function public.update_family(
  p_family_id uuid, p_name text, p_name_ar text default null, p_description text default null)
returns void language plpgsql security definer as $$
declare v_role text; v_fam uuid;
begin
  select role, family_id into v_role, v_fam from public.user_profiles where id = auth.uid();
  if v_fam is distinct from p_family_id or v_role != 'admin' then
    raise exception 'Only family admins can update settings'; end if;
  update public.families set name = p_name, name_ar = p_name_ar, description = p_description
  where id = p_family_id;
end; $$;

-- Derives parent/child and sibling relationships from the name fields.
create or replace function public.auto_detect_relationships(p_family_id uuid)
returns int language plpgsql security definer as $$
declare v_new int := 0; v_tmp int;
begin
  -- A → parent (B.first = A.father, B.father = A.grandfather, same family+city)
  insert into public.relationships (member_id, related_member_id, relationship_type)
  select a.id, b.id, 'parent' from public.members a join public.members b
    on lower(b.first_name)=lower(a.father_name) and lower(b.father_name)=lower(a.grandfather_name)
   and lower(b.family_name)=lower(a.family_name) and lower(b.city)=lower(a.city)
   and (a.clan_name is null or b.clan_name is null or lower(a.clan_name)=lower(b.clan_name)) and a.id<>b.id
  where a.family_id=p_family_id and b.family_id=p_family_id
  on conflict do nothing;
  get diagnostics v_tmp = row_count; v_new := v_new + v_tmp;

  insert into public.relationships (member_id, related_member_id, relationship_type)
  select b.id, a.id, 'child' from public.members a join public.members b
    on lower(b.first_name)=lower(a.father_name) and lower(b.father_name)=lower(a.grandfather_name)
   and lower(b.family_name)=lower(a.family_name) and lower(b.city)=lower(a.city)
   and (a.clan_name is null or b.clan_name is null or lower(a.clan_name)=lower(b.clan_name)) and a.id<>b.id
  where a.family_id=p_family_id and b.family_id=p_family_id
  on conflict do nothing;
  get diagnostics v_tmp = row_count; v_new := v_new + v_tmp;

  -- paternal siblings (same father+grandfather+family+city)
  insert into public.relationships (member_id, related_member_id, relationship_type)
  select a.id, b.id, 'sibling' from public.members a join public.members b
    on lower(a.father_name)=lower(b.father_name) and lower(a.grandfather_name)=lower(b.grandfather_name)
   and lower(a.family_name)=lower(b.family_name) and lower(a.city)=lower(b.city)
   and (a.clan_name is null or b.clan_name is null or lower(a.clan_name)=lower(b.clan_name)) and a.id<>b.id
  where a.family_id=p_family_id and b.family_id=p_family_id
  on conflict do nothing;
  get diagnostics v_tmp = row_count; v_new := v_new + v_tmp;

  -- maternal siblings (same full mother name)
  insert into public.relationships (member_id, related_member_id, relationship_type)
  select a.id, b.id, 'sibling' from public.members a join public.members b
    on a.mother_first_name is not null and b.mother_first_name is not null
   and lower(a.mother_first_name)=lower(b.mother_first_name)
   and lower(a.mother_father_name)=lower(b.mother_father_name)
   and lower(a.mother_grandfather_name)=lower(b.mother_grandfather_name)
   and lower(a.mother_family_name)=lower(b.mother_family_name) and a.id<>b.id
  where a.family_id=p_family_id and b.family_id=p_family_id
  on conflict do nothing;
  get diagnostics v_tmp = row_count; v_new := v_new + v_tmp;

  return v_new;
end; $$;

-- Cross-family directory search by city + clan + family name. SECURITY DEFINER
-- so it can look beyond the caller's own family. Returns PUBLIC fields only
-- (paternal name + city + clan) — never maternal/private data.
create or replace function public.search_members_global(
  p_city text default null, p_clan text default null, p_family_name text default null)
returns table (
  id uuid, family_id uuid, first_name text, father_name text,
  grandfather_name text, family_name text, clan_name text, city text, gender text)
language sql security definer stable as $$
  select id, family_id, first_name, father_name, grandfather_name,
         family_name, clan_name, city, gender
  from public.members
  where (p_city        is null or p_city        = '' or lower(city)        = lower(p_city))
    and (p_clan        is null or p_clan        = '' or lower(clan_name)   = lower(p_clan))
    and (p_family_name is null or p_family_name = '' or lower(family_name) = lower(p_family_name))
    and coalesce(p_city, p_clan, p_family_name, '') <> ''
  order by family_name, first_name
  limit 50;
$$;

-- ── Claim flow (claim an existing member as yourself; admin approves) ────────

-- Finds existing members matching the caller's exact four-part name + city,
-- so onboarding can offer "is this you?" instead of creating a duplicate.
create or replace function public.find_member_for_claim(
  p_first text, p_father text, p_grand text, p_family text, p_city text)
returns table (
  id uuid, family_id uuid, family_label text, first_name text, father_name text,
  grandfather_name text, family_name text, clan_name text, city text, gender text, claimed boolean)
language sql security definer stable as $$
  select m.id, m.family_id, f.name, m.first_name, m.father_name, m.grandfather_name,
         m.family_name, m.clan_name, m.city, m.gender,
         exists(select 1 from public.user_profiles up where up.linked_member_id = m.id)
  from public.members m join public.families f on f.id = m.family_id
  where lower(m.first_name)=lower(p_first) and lower(m.father_name)=lower(p_father)
    and lower(m.grandfather_name)=lower(p_grand) and lower(m.family_name)=lower(p_family)
    and lower(m.city)=lower(p_city)
  limit 10;
$$;

-- Caller requests to claim a member. Requires they have no family yet, and the
-- member isn't already claimed. Creates a pending claim for admin approval.
create or replace function public.request_claim(p_member_id uuid)
returns uuid language plpgsql security definer as $$
declare v_claim uuid; v_fam uuid;
begin
  select family_id into v_fam from public.user_profiles where id = auth.uid();
  if v_fam is not null then raise exception 'You already belong to a family'; end if;
  if exists(select 1 from public.user_profiles where linked_member_id = p_member_id) then
    raise exception 'This member is already claimed'; end if;
  insert into public.member_claims (member_id, user_id) values (p_member_id, auth.uid())
  on conflict (member_id, user_id) do update set status = 'pending', created_at = now()
  returning id into v_claim;
  return v_claim;
end; $$;

-- The caller's latest claim status (for the pending-approval screen).
create or replace function public.my_claim_status()
returns table (status text, member_label text, family_label text)
language sql security definer stable as $$
  select c.status,
         m.first_name||' '||m.father_name||' '||m.grandfather_name||' '||m.family_name,
         f.name
  from public.member_claims c
  join public.members m on m.id = c.member_id
  join public.families f on f.id = m.family_id
  where c.user_id = auth.uid()
  order by c.created_at desc limit 1;
$$;

-- Pending claims awaiting the calling admin's approval (for their family).
create or replace function public.pending_claims()
returns table (
  claim_id uuid, member_id uuid, member_label text, claimant_email text, created_at timestamptz)
language sql security definer stable as $$
  select c.id, m.id,
         m.first_name||' '||m.father_name||' '||m.grandfather_name||' '||m.family_name,
         u.email, c.created_at
  from public.member_claims c
  join public.members m on m.id = c.member_id
  join auth.users u on u.id = c.user_id
  where c.status = 'pending'
    and m.family_id = public.my_family_id()
    and (select role from public.user_profiles where id = auth.uid()) = 'admin'
  order by c.created_at;
$$;

create or replace function public.approve_claim(p_claim_id uuid)
returns void language plpgsql security definer as $$
declare v_member uuid; v_user uuid; v_fam uuid; v_caller_role text; v_caller_fam uuid;
begin
  select member_id, user_id into v_member, v_user from public.member_claims where id = p_claim_id;
  if v_member is null then raise exception 'Claim not found'; end if;
  select family_id into v_fam from public.members where id = v_member;
  select role, family_id into v_caller_role, v_caller_fam from public.user_profiles where id = auth.uid();
  if v_caller_role != 'admin' or v_caller_fam is distinct from v_fam then
    raise exception 'Only the family admin can approve this claim'; end if;
  update public.member_claims set status = 'approved' where id = p_claim_id;
  insert into public.user_profiles (id, family_id, linked_member_id, role)
  values (v_user, v_fam, v_member, 'viewer')
  on conflict (id) do update set family_id = v_fam, linked_member_id = v_member;
end; $$;

create or replace function public.reject_claim(p_claim_id uuid)
returns void language plpgsql security definer as $$
declare v_fam uuid; v_caller_role text; v_caller_fam uuid;
begin
  select m.family_id into v_fam from public.member_claims c
    join public.members m on m.id = c.member_id where c.id = p_claim_id;
  select role, family_id into v_caller_role, v_caller_fam from public.user_profiles where id = auth.uid();
  if v_caller_role != 'admin' or v_caller_fam is distinct from v_fam then
    raise exception 'Only the family admin can reject this claim'; end if;
  update public.member_claims set status = 'rejected' where id = p_claim_id;
end; $$;

-- ── Row Level Security ──────────────────────────────────────────────────────

alter table public.families      enable row level security;
alter table public.user_profiles enable row level security;
alter table public.members       enable row level security;
alter table public.relationships enable row level security;

create policy families_select on public.families for select using (id = public.my_family_id());
create policy families_insert on public.families for insert with check (auth.uid() is not null);
create policy families_update on public.families for update using (created_by = auth.uid());

create policy profiles_select on public.user_profiles for select
  using (id = auth.uid() or family_id = public.my_family_id());
create policy profiles_insert on public.user_profiles for insert with check (id = auth.uid());
create policy profiles_update on public.user_profiles for update using (id = auth.uid());

create policy members_select on public.members for select using (family_id = public.my_family_id());
create policy members_insert on public.members for insert with check (family_id = public.my_family_id());
create policy members_update on public.members for update using (family_id = public.my_family_id());
create policy members_delete on public.members for delete using (family_id = public.my_family_id());

create policy rels_select on public.relationships for select
  using (member_id in (select id from public.members where family_id = public.my_family_id()));
create policy rels_insert on public.relationships for insert
  with check (member_id in (select id from public.members where family_id = public.my_family_id()));
create policy rels_delete on public.relationships for delete
  using (member_id in (select id from public.members where family_id = public.my_family_id()));

alter table public.member_claims enable row level security;
-- Callers manage their own claim rows; admins act via SECURITY DEFINER functions.
create policy claims_select on public.member_claims for select using (user_id = auth.uid());
create policy claims_insert on public.member_claims for insert with check (user_id = auth.uid());

-- ── Indexes ─────────────────────────────────────────────────────────────────

create index members_family_idx   on public.members(family_id);
create index members_paternal_idx on public.members(lower(father_name), lower(grandfather_name), lower(family_name), lower(city));
create index members_maternal_idx on public.members(lower(mother_first_name), lower(mother_father_name), lower(mother_family_name));
create index members_global_idx   on public.members(lower(city), lower(clan_name), lower(family_name));
create index rels_member_idx      on public.relationships(member_id);
create index rels_related_idx     on public.relationships(related_member_id);
create index profiles_family_idx  on public.user_profiles(family_id);
create index profiles_linked_idx  on public.user_profiles(linked_member_id);

-- ============================================================
-- STORAGE — run once to enable profile photos
-- ============================================================
-- 1) Dashboard → Storage → New bucket → name "avatars" → Public bucket → Save.
--    (or run:)  insert into storage.buckets (id, name, public) values ('avatars','avatars',true);
-- 2) Allow authenticated uploads:
--    create policy "avatars upload" on storage.objects for insert to authenticated
--      with check (bucket_id = 'avatars');
--    create policy "avatars read" on storage.objects for select using (bucket_id = 'avatars');

-- ============================================================
-- RESET (run first if rebuilding over an existing database)
-- ============================================================
-- drop table if exists public.member_claims  cascade;
-- drop table if exists public.relationships  cascade;
-- drop table if exists public.user_profiles  cascade;
-- drop table if exists public.members        cascade;
-- drop table if exists public.families        cascade;
-- drop function if exists public.my_family_id, public.setup_profile,
--   public.join_family_by_name, public.set_user_role, public.remove_family_member_user,
--   public.update_family, public.auto_detect_relationships, public.search_members_global,
--   public.find_member_for_claim, public.request_claim, public.my_claim_status,
--   public.pending_claims, public.approve_claim, public.reject_claim cascade;
