-- ============================================================
-- Shajarah (شجرة) — Family Tree App — Schema v3
-- Drop old tables first, then run this entire file.
-- ============================================================

create extension if not exists "uuid-ossp";

-- ============================================================
-- TABLES
-- ============================================================

create table public.families (
  id          uuid primary key default uuid_generate_v4(),
  name        text not null,
  name_ar     text,
  description text,
  created_by  uuid references auth.users(id) on delete set null,
  created_at  timestamptz not null default now()
);

-- user_profiles.linked_member_id is added after members table below.
create table public.user_profiles (
  id              uuid primary key references auth.users(id) on delete cascade,
  full_name       text,
  full_name_ar    text,
  role            text not null default 'viewer'
                    check (role in ('admin', 'editor', 'viewer')),
  family_id       uuid references public.families(id) on delete set null,
  created_at      timestamptz not null default now()
);

create table public.members (
  id                      uuid primary key default uuid_generate_v4(),
  family_id               uuid not null references public.families(id) on delete cascade,

  -- Paternal four-part name (always publicly visible)
  first_name              text not null,
  father_name             text not null,
  grandfather_name        text not null,
  family_name             text not null,

  -- Maternal four-part name (hidden until verified tree connection)
  mother_first_name       text,
  mother_father_name      text,
  mother_grandfather_name text,
  mother_family_name      text,

  -- Geographic scope (prevents name collisions across regions)
  city                    text not null,

  -- Standard passport fields
  gender                  text not null default 'male'
                            check (gender in ('male', 'female')),
  birth_date              date,
  death_date              date,
  place_of_birth          text,

  -- Privacy toggle: owner controls whether relatives see birth date
  show_birth_date         boolean not null default false,

  photo_url               text,
  notes                   text,

  created_by              uuid references auth.users(id) on delete set null,
  created_at              timestamptz not null default now()
);

-- Link an app user to their tree member (enables privacy checks)
alter table public.user_profiles
  add column linked_member_id uuid references public.members(id) on delete set null;

create table public.relationships (
  id                uuid primary key default uuid_generate_v4(),
  member_id         uuid not null references public.members(id) on delete cascade,
  related_member_id uuid not null references public.members(id) on delete cascade,
  relationship_type text not null
                      check (relationship_type in ('parent','child','spouse','sibling')),
  created_at        timestamptz not null default now(),
  unique (member_id, related_member_id, relationship_type)
);

-- ============================================================
-- SECURITY DEFINER HELPERS
-- ============================================================

create or replace function public.my_family_id()
returns uuid language sql security definer stable as $$
  select family_id from public.user_profiles where id = auth.uid() limit 1;
$$;

-- Creates a new family and sets the caller as admin.
create or replace function public.setup_profile(
  p_family_name  text,
  p_full_name    text,
  p_full_name_ar text default null
)
returns void language plpgsql security definer as $$
declare v_fid uuid;
begin
  insert into public.families (name, created_by)
  values (p_family_name, auth.uid()) returning id into v_fid;

  insert into public.user_profiles (id, full_name, full_name_ar, family_id, role)
  values (auth.uid(), p_full_name, p_full_name_ar, v_fid, 'admin')
  on conflict (id) do update
    set full_name = excluded.full_name, full_name_ar = excluded.full_name_ar,
        family_id = excluded.family_id, role = 'admin';
end; $$;

-- Joins an existing family by name.
create or replace function public.join_family_by_name(
  p_family_name  text,
  p_full_name    text,
  p_full_name_ar text default null
)
returns void language plpgsql security definer as $$
declare v_fid uuid;
begin
  select id into v_fid from public.families
  where lower(name) = lower(p_family_name) limit 1;
  if v_fid is null then
    raise exception 'Family "%" not found', p_family_name;
  end if;
  insert into public.user_profiles (id, full_name, full_name_ar, family_id, role)
  values (auth.uid(), p_full_name, p_full_name_ar, v_fid, 'viewer')
  on conflict (id) do update
    set full_name = excluded.full_name, full_name_ar = excluded.full_name_ar,
        family_id = excluded.family_id;
end; $$;

-- Changes a user's role (admin only).
create or replace function public.set_user_role(p_user_id uuid, p_role text)
returns void language plpgsql security definer as $$
declare v_role text; v_fam uuid; v_tfam uuid;
begin
  select role, family_id into v_role, v_fam from public.user_profiles where id = auth.uid();
  if v_role != 'admin' then raise exception 'Only admins can change roles'; end if;
  if p_user_id = auth.uid() then raise exception 'You cannot change your own role'; end if;
  select family_id into v_tfam from public.user_profiles where id = p_user_id;
  if v_tfam is distinct from v_fam then raise exception 'User not in your family'; end if;
  update public.user_profiles set role = p_role where id = p_user_id;
end; $$;

-- Removes a user from the family (admin only).
create or replace function public.remove_family_member_user(p_user_id uuid)
returns void language plpgsql security definer as $$
declare v_role text; v_fam uuid; v_tfam uuid;
begin
  select role, family_id into v_role, v_fam from public.user_profiles where id = auth.uid();
  if v_role != 'admin' then raise exception 'Only admins can remove users'; end if;
  if p_user_id = auth.uid() then raise exception 'You cannot remove yourself'; end if;
  select family_id into v_tfam from public.user_profiles where id = p_user_id;
  if v_tfam is distinct from v_fam then raise exception 'User not in your family'; end if;
  update public.user_profiles set family_id = null, role = 'viewer' where id = p_user_id;
end; $$;

-- Updates family settings (admin only).
create or replace function public.update_family(
  p_family_id uuid, p_name text,
  p_name_ar text default null, p_description text default null
)
returns void language plpgsql security definer as $$
declare v_role text; v_fam uuid;
begin
  select role, family_id into v_role, v_fam from public.user_profiles where id = auth.uid();
  if v_fam is distinct from p_family_id or v_role != 'admin' then
    raise exception 'Only family admins can update family settings';
  end if;
  update public.families set name = p_name, name_ar = p_name_ar, description = p_description
  where id = p_family_id;
end; $$;

-- ── Automatic relationship detection ────────────────────────────────────────

-- Scans all members in a family and creates relationships derived purely from
-- the four-part paternal name and the maternal name fields.
--
-- Rules:
--   Parent  : B.first = A.father AND B.father = A.grandfather
--             AND B.family = A.family AND B.city = A.city
--   Paternal sibling : same father + grandfather + family + city
--   Maternal sibling : same full mother four-part name
--
-- Returns the number of NEW relationship rows inserted.
create or replace function public.auto_detect_relationships(p_family_id uuid)
returns int
language plpgsql
security definer
as $$
declare
  v_new int := 0;
  v_tmp int;
begin
  -- A sees B as parent (B.first = A.father, B.father = A.grandfather)
  insert into public.relationships (member_id, related_member_id, relationship_type)
  select a.id, b.id, 'parent'
  from public.members a
  join public.members b
    on  lower(b.first_name)   = lower(a.father_name)
    and lower(b.father_name)  = lower(a.grandfather_name)
    and lower(b.family_name)  = lower(a.family_name)
    and lower(b.city)         = lower(a.city)
    and b.id != a.id
  where a.family_id = p_family_id
    and b.family_id = p_family_id
  on conflict (member_id, related_member_id, relationship_type) do nothing;
  get diagnostics v_tmp = row_count; v_new := v_new + v_tmp;

  -- Inverse: B sees A as child
  insert into public.relationships (member_id, related_member_id, relationship_type)
  select b.id, a.id, 'child'
  from public.members a
  join public.members b
    on  lower(b.first_name)   = lower(a.father_name)
    and lower(b.father_name)  = lower(a.grandfather_name)
    and lower(b.family_name)  = lower(a.family_name)
    and lower(b.city)         = lower(a.city)
    and b.id != a.id
  where a.family_id = p_family_id
    and b.family_id = p_family_id
  on conflict (member_id, related_member_id, relationship_type) do nothing;
  get diagnostics v_tmp = row_count; v_new := v_new + v_tmp;

  -- Paternal siblings: same father_name + grandfather_name + family_name + city
  insert into public.relationships (member_id, related_member_id, relationship_type)
  select a.id, b.id, 'sibling'
  from public.members a
  join public.members b
    on  lower(a.father_name)      = lower(b.father_name)
    and lower(a.grandfather_name) = lower(b.grandfather_name)
    and lower(a.family_name)      = lower(b.family_name)
    and lower(a.city)             = lower(b.city)
    and a.id != b.id
  where a.family_id = p_family_id
    and b.family_id = p_family_id
  on conflict (member_id, related_member_id, relationship_type) do nothing;
  get diagnostics v_tmp = row_count; v_new := v_new + v_tmp;

  -- Maternal siblings: same full mother four-part name
  insert into public.relationships (member_id, related_member_id, relationship_type)
  select a.id, b.id, 'sibling'
  from public.members a
  join public.members b
    on  a.mother_first_name is not null
    and b.mother_first_name is not null
    and lower(a.mother_first_name)       = lower(b.mother_first_name)
    and lower(a.mother_father_name)      = lower(b.mother_father_name)
    and lower(a.mother_grandfather_name) = lower(b.mother_grandfather_name)
    and lower(a.mother_family_name)      = lower(b.mother_family_name)
    and a.id != b.id
  where a.family_id = p_family_id
    and b.family_id = p_family_id
  on conflict (member_id, related_member_id, relationship_type) do nothing;
  get diagnostics v_tmp = row_count; v_new := v_new + v_tmp;

  return v_new;
end;
$$;

-- ── Smart auto-linking scans (used during add-member prompt flow) ─────────────

-- Finds members sharing the same paternal lineage in the same city (potential siblings).
create or replace function public.find_potential_siblings(
  p_family_id        uuid,
  p_father_name      text,
  p_grandfather_name text,
  p_family_name      text,
  p_city             text,
  p_exclude_id       uuid default null
)
returns table (
  id               uuid,
  first_name       text,
  father_name      text,
  grandfather_name text,
  family_name      text,
  gender           text
)
language sql security definer stable as $$
  select id, first_name, father_name, grandfather_name, family_name, gender
  from public.members
  where family_id = p_family_id
    and lower(father_name)       = lower(p_father_name)
    and lower(grandfather_name)  = lower(p_grandfather_name)
    and lower(family_name)       = lower(p_family_name)
    and lower(city)              = lower(p_city)
    and (p_exclude_id is null or id != p_exclude_id)
  limit 20;
$$;

-- Finds potential maternal relatives (maternal siblings or maternal uncles/aunts).
create or replace function public.find_maternal_relatives(
  p_family_id               uuid,
  p_mother_first_name       text,
  p_mother_father_name      text,
  p_mother_grandfather_name text,
  p_mother_family_name      text,
  p_city                    text,
  p_exclude_id              uuid default null
)
returns table (
  id               uuid,
  first_name       text,
  father_name      text,
  grandfather_name text,
  family_name      text,
  gender           text,
  match_type       text
)
language sql security definer stable as $$
  -- Shared mother → maternal siblings
  select id, first_name, father_name, grandfather_name, family_name, gender,
         'maternal_sibling'::text
  from public.members
  where family_id = p_family_id
    and lower(mother_first_name)        = lower(p_mother_first_name)
    and lower(mother_father_name)       = lower(p_mother_father_name)
    and lower(mother_grandfather_name)  = lower(p_mother_grandfather_name)
    and lower(mother_family_name)       = lower(p_mother_family_name)
    and lower(city)                     = lower(p_city)
    and (p_exclude_id is null or id != p_exclude_id)
  union all
  -- Paternal name matches mother's name → maternal uncle/aunt
  select id, first_name, father_name, grandfather_name, family_name, gender,
         'maternal_uncle_aunt'::text
  from public.members
  where family_id = p_family_id
    and lower(first_name)        = lower(p_mother_first_name)
    and lower(father_name)       = lower(p_mother_father_name)
    and lower(grandfather_name)  = lower(p_mother_grandfather_name)
    and lower(family_name)       = lower(p_mother_family_name)
    and lower(city)              = lower(p_city)
    and (p_exclude_id is null or id != p_exclude_id)
  limit 20;
$$;

-- ============================================================
-- ROW LEVEL SECURITY
-- ============================================================

alter table public.families      enable row level security;
alter table public.user_profiles enable row level security;
alter table public.members       enable row level security;
alter table public.relationships enable row level security;

-- families
create policy "families_select" on public.families
  for select using (id = public.my_family_id());
create policy "families_insert" on public.families
  for insert with check (auth.uid() is not null);
create policy "families_update" on public.families
  for update using (created_by = auth.uid());

-- user_profiles
create policy "profiles_select" on public.user_profiles
  for select using (id = auth.uid() or family_id = public.my_family_id());
create policy "profiles_insert" on public.user_profiles
  for insert with check (id = auth.uid());
create policy "profiles_update" on public.user_profiles
  for update using (id = auth.uid());

-- members
create policy "members_select" on public.members
  for select using (family_id = public.my_family_id());
create policy "members_insert" on public.members
  for insert with check (family_id = public.my_family_id());
create policy "members_update" on public.members
  for update using (family_id = public.my_family_id());
create policy "members_delete" on public.members
  for delete using (family_id = public.my_family_id());

-- relationships
create policy "relationships_select" on public.relationships
  for select using (
    member_id in (select id from public.members where family_id = public.my_family_id())
  );
create policy "relationships_insert" on public.relationships
  for insert with check (
    member_id in (select id from public.members where family_id = public.my_family_id())
  );
create policy "relationships_delete" on public.relationships
  for delete using (
    member_id in (select id from public.members where family_id = public.my_family_id())
  );

-- ============================================================
-- INDEXES
-- ============================================================

create index members_family_idx       on public.members(family_id);
create index members_paternal_idx     on public.members(lower(father_name), lower(grandfather_name), lower(family_name), lower(city));
create index members_maternal_idx     on public.members(lower(mother_first_name), lower(mother_father_name), lower(mother_family_name));
create index rels_member_idx          on public.relationships(member_id);
create index rels_related_idx         on public.relationships(related_member_id);
create index profiles_family_idx      on public.user_profiles(family_id);
create index profiles_linked_idx      on public.user_profiles(linked_member_id);

-- ============================================================
-- INCREMENTAL MIGRATION (existing database — skip if running fresh)
-- ============================================================
-- Run these if upgrading from v2:
--
-- alter table public.members
--   add column if not exists first_name       text,
--   add column if not exists father_name      text,
--   add column if not exists grandfather_name text,
--   add column if not exists family_name      text,
--   add column if not exists mother_first_name       text,
--   add column if not exists mother_father_name      text,
--   add column if not exists mother_grandfather_name text,
--   add column if not exists mother_family_name      text,
--   add column if not exists city             text,
--   add column if not exists show_birth_date  boolean not null default false;
--
-- alter table public.user_profiles
--   add column if not exists linked_member_id uuid references public.members(id) on delete set null;
--
-- Then re-run all create or replace function blocks above.
