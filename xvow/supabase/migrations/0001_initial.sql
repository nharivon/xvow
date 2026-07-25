create extension if not exists "pgcrypto";

create or replace function public.set_updated_at()
returns trigger
language plpgsql
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

create table if not exists public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  full_name text not null default '',
  email text not null default '',
  push_enabled boolean not null default true,
  discipline integer not null default 100,
  project_health integer not null default 100,
  current_streak integer not null default 0,
  total_xp integer not null default 0,
  total_penalties integer not null default 0,
  total_savings integer not null default 0,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.app_snapshots (
  user_id uuid primary key references auth.users(id) on delete cascade,
  payload jsonb not null default '{}'::jsonb,
  updated_at timestamptz not null default now()
);

create table if not exists public.objectives (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  title text not null,
  description text not null default '',
  motivation text not null default '',
  target_weeks integer not null default 5,
  completed_weeks integer not null default 0,
  failed_weeks integer not null default 0,
  health integer not null default 100,
  is_completed boolean not null default false,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.planned_vows (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  objective_id uuid not null references public.objectives(id) on delete cascade,
  week_index smallint not null,
  title text not null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (objective_id, week_index)
);

create table if not exists public.weekly_cycles (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  launched_at timestamptz not null default now(),
  completed_at timestamptz,
  locked_until timestamptz not null default (now() + interval '7 days'),
  status text not null default 'active' check (status in ('active', 'locked', 'completed')),
  is_success boolean,
  penalty_paid integer not null default 0,
  xp_gained integer not null default 0,
  streak_reset boolean not null default false,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.weekly_vows (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  weekly_cycle_id uuid not null references public.weekly_cycles(id) on delete cascade,
  objective_id uuid not null references public.objectives(id) on delete cascade,
  planned_vow_id uuid not null references public.planned_vows(id) on delete restrict,
  title text not null,
  check_in_count integer not null default 0,
  is_completed boolean not null default false,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (weekly_cycle_id, planned_vow_id)
);

create table if not exists public.check_ins (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  weekly_vow_id uuid not null references public.weekly_vows(id) on delete cascade,
  checked_on date not null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (weekly_vow_id, checked_on)
);

create table if not exists public.notification_tokens (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  token text not null,
  platform text not null default 'mobile',
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (user_id, token)
);

create index if not exists idx_notification_tokens_user_id on public.notification_tokens(user_id);
create index if not exists idx_objectives_user_id on public.objectives(user_id);
create index if not exists idx_planned_vows_objective_id on public.planned_vows(objective_id);
create index if not exists idx_planned_vows_user_id on public.planned_vows(user_id);
create index if not exists idx_weekly_cycles_user_id on public.weekly_cycles(user_id);
create index if not exists idx_weekly_vows_cycle_id on public.weekly_vows(weekly_cycle_id);
create index if not exists idx_weekly_vows_user_id on public.weekly_vows(user_id);
create index if not exists idx_check_ins_vow_id on public.check_ins(weekly_vow_id);
create index if not exists idx_check_ins_user_id on public.check_ins(user_id);

alter table public.profiles enable row level security;
alter table public.app_snapshots enable row level security;
alter table public.objectives enable row level security;
alter table public.planned_vows enable row level security;
alter table public.weekly_cycles enable row level security;
alter table public.weekly_vows enable row level security;
alter table public.check_ins enable row level security;
alter table public.notification_tokens enable row level security;

create policy "profiles_select_own" on public.profiles
for select
using (auth.uid() = id);

create policy "profiles_insert_own" on public.profiles
for insert
with check (auth.uid() = id);

create policy "profiles_update_own" on public.profiles
for update
using (auth.uid() = id)
with check (auth.uid() = id);

create policy "objectives_select_own" on public.objectives
for select
using (auth.uid() = user_id);

create policy "objectives_insert_own" on public.objectives
for insert
with check (auth.uid() = user_id);

create policy "objectives_update_own" on public.objectives
for update
using (auth.uid() = user_id)
with check (auth.uid() = user_id);

create policy "objectives_delete_own" on public.objectives
for delete
using (auth.uid() = user_id);

create policy "planned_vows_select_own" on public.planned_vows
for select
using (auth.uid() = user_id);

create policy "planned_vows_insert_own" on public.planned_vows
for insert
with check (auth.uid() = user_id);

create policy "planned_vows_update_own" on public.planned_vows
for update
using (auth.uid() = user_id)
with check (auth.uid() = user_id);

create policy "planned_vows_delete_own" on public.planned_vows
for delete
using (auth.uid() = user_id);

create policy "weekly_cycles_select_own" on public.weekly_cycles
for select
using (auth.uid() = user_id);

create policy "weekly_cycles_insert_own" on public.weekly_cycles
for insert
with check (auth.uid() = user_id);

create policy "weekly_cycles_update_own" on public.weekly_cycles
for update
using (auth.uid() = user_id)
with check (auth.uid() = user_id);

create policy "weekly_cycles_delete_own" on public.weekly_cycles
for delete
using (auth.uid() = user_id);

create policy "weekly_vows_select_own" on public.weekly_vows
for select
using (auth.uid() = user_id);

create policy "weekly_vows_insert_own" on public.weekly_vows
for insert
with check (auth.uid() = user_id);

create policy "weekly_vows_update_own" on public.weekly_vows
for update
using (auth.uid() = user_id)
with check (auth.uid() = user_id);

create policy "weekly_vows_delete_own" on public.weekly_vows
for delete
using (auth.uid() = user_id);

create policy "check_ins_select_own" on public.check_ins
for select
using (auth.uid() = user_id);

create policy "check_ins_insert_own" on public.check_ins
for insert
with check (auth.uid() = user_id);

create policy "check_ins_update_own" on public.check_ins
for update
using (auth.uid() = user_id)
with check (auth.uid() = user_id);

create policy "check_ins_delete_own" on public.check_ins
for delete
using (auth.uid() = user_id);

create policy "snapshots_select_own" on public.app_snapshots
for select
using (auth.uid() = user_id);

create policy "snapshots_insert_own" on public.app_snapshots
for insert
with check (auth.uid() = user_id);

create policy "snapshots_update_own" on public.app_snapshots
for update
using (auth.uid() = user_id)
with check (auth.uid() = user_id);

create policy "snapshots_delete_own" on public.app_snapshots
for delete
using (auth.uid() = user_id);

create policy "tokens_select_own" on public.notification_tokens
for select
using (auth.uid() = user_id);

create policy "tokens_insert_own" on public.notification_tokens
for insert
with check (auth.uid() = user_id);

create policy "tokens_update_own" on public.notification_tokens
for update
using (auth.uid() = user_id)
with check (auth.uid() = user_id);

create policy "tokens_delete_own" on public.notification_tokens
for delete
using (auth.uid() = user_id);

create trigger set_profiles_updated_at
before update on public.profiles
for each row
execute function public.set_updated_at();

create trigger set_objectives_updated_at
before update on public.objectives
for each row
execute function public.set_updated_at();

create trigger set_planned_vows_updated_at
before update on public.planned_vows
for each row
execute function public.set_updated_at();

create trigger set_weekly_cycles_updated_at
before update on public.weekly_cycles
for each row
execute function public.set_updated_at();

create trigger set_weekly_vows_updated_at
before update on public.weekly_vows
for each row
execute function public.set_updated_at();

create trigger set_check_ins_updated_at
before update on public.check_ins
for each row
execute function public.set_updated_at();

create trigger set_snapshots_updated_at
before update on public.app_snapshots
for each row
execute function public.set_updated_at();

create trigger set_tokens_updated_at
before update on public.notification_tokens
for each row
execute function public.set_updated_at();
