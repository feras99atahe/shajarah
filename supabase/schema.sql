-- ============================================================
-- Shajarah (شجرة) — Family Tree App — Supabase Schema
-- Run this in your Supabase SQL editor after creating a project
-- ============================================================

-- Enable UUID extension
create extension if not exists "uuid-ossp";

-- ============================================================
-- TABLES (create all first, then policies)
-- ============================================================

create table public.families (
  id          uuid primary key default uuid_generate_v4(),
  name        text not null,
  name_ar     text,
  description text,
  created_by  uuid references auth.users(id) on delete set null,
  created_at  timestamptz not null default now()
);

create table public.user_profiles (
  id          uuid primary key references auth.users(id) on delete cascade,
  phone       text unique,
  full_name   text,
  role        text not null default 'viewer'
                check (role in ('admin', 'editor', 'viewer')),
  family_id   uuid references public.families(id) on delete set null,
  created_at  timestamptz not null default now()
);

create table public.members (
  id          uuid primary key default uuid_generate_v4(),
  family_id   uuid not null references public.families(id) on delete cascade,
  full_name   text not null,
  full_name_ar text,
  gender      text not null default 'male'
                check (gender in ('male', 'female')),
  birth_date  date,
  death_date  date,
  birth_place text,
  phone       text,
  photo_url   text,
  notes       text,
  created_by  uuid references auth.users(id) on delete set null,
  created_at  timestamptz not null default now()
);

create table public.relationships (
  id                  uuid primary key default uuid_generate_v4(),
  member_id           uuid not null references public.members(id) on delete cascade,
  related_member_id   uuid not null references public.members(id) on delete cascade,
  relationship_type   text not null
                        check (relationship_type in ('parent', 'child', 'spouse', 'sibling')),
  created_at          timestamptz not null default now(),
  unique (member_id, related_member_id, relationship_type)
);

-- ============================================================
-- ROW LEVEL SECURITY
-- ============================================================

alter table public.families      enable row level security;
alter table public.user_profiles enable row level security;
alter table public.members       enable row level security;
alter table public.relationships enable row level security;

-- ---- families ----

create policy "families_select" on public.families
  for select using (
    id in (
      select family_id from public.user_profiles where id = auth.uid()
    )
  );

create policy "families_insert" on public.families
  for insert with check (auth.role() = 'authenticated');

create policy "families_update" on public.families
  for update using (created_by = auth.uid());

-- ---- user_profiles ----

create policy "profiles_select" on public.user_profiles
  for select using (
    id = auth.uid()
    or family_id in (
      select family_id from public.user_profiles where id = auth.uid()
    )
  );

create policy "profiles_insert" on public.user_profiles
  for insert with check (id = auth.uid());

create policy "profiles_update" on public.user_profiles
  for update using (id = auth.uid());

-- ---- members ----

create policy "members_select" on public.members
  for select using (
    family_id in (
      select family_id from public.user_profiles where id = auth.uid()
    )
  );

create policy "members_insert" on public.members
  for insert with check (
    family_id in (
      select family_id from public.user_profiles where id = auth.uid()
    )
  );

create policy "members_update" on public.members
  for update using (
    family_id in (
      select family_id from public.user_profiles where id = auth.uid()
    )
  );

create policy "members_delete" on public.members
  for delete using (
    family_id in (
      select family_id from public.user_profiles where id = auth.uid()
    )
  );

-- ---- relationships ----

create policy "relationships_select" on public.relationships
  for select using (
    member_id in (
      select id from public.members where family_id in (
        select family_id from public.user_profiles where id = auth.uid()
      )
    )
  );

create policy "relationships_insert" on public.relationships
  for insert with check (
    member_id in (
      select id from public.members where family_id in (
        select family_id from public.user_profiles where id = auth.uid()
      )
    )
  );

create policy "relationships_delete" on public.relationships
  for delete using (
    member_id in (
      select id from public.members where family_id in (
        select family_id from public.user_profiles where id = auth.uid()
      )
    )
  );

-- ============================================================
-- INDEXES
-- ============================================================

create index members_family_idx  on public.members(family_id);
create index rels_member_idx     on public.relationships(member_id);
create index rels_related_idx    on public.relationships(related_member_id);
create index profiles_family_idx on public.user_profiles(family_id);

-- ============================================================
-- STORAGE — run separately in Supabase Dashboard:
-- Storage → New bucket → name: "photos" → Public bucket: ON
-- ============================================================
