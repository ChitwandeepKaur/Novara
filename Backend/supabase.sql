-- Run once in your own Supabase project's SQL Editor.
-- No public or anonymous access. Each signed-in user can only access their own row.
begin;
create table if not exists public.novara_saves (
    user_id uuid primary key references auth.users(id) on delete cascade,
    state_json text not null check (octet_length(state_json) <= 20000000),
    fingerprint text not null check (length(fingerprint) = 64),
    version uuid not null default gen_random_uuid(),
    updated_at timestamptz not null default now()
);
alter table public.novara_saves enable row level security;
revoke all on public.novara_saves from anon, authenticated;
grant select, insert, update on public.novara_saves to authenticated;
drop policy if exists novara_read_own on public.novara_saves;
create policy novara_read_own on public.novara_saves for select to authenticated
    using ((select auth.uid()) = user_id);
drop policy if exists novara_insert_own on public.novara_saves;
create policy novara_insert_own on public.novara_saves for insert to authenticated
    with check ((select auth.uid()) = user_id);
drop policy if exists novara_update_own on public.novara_saves;
create policy novara_update_own on public.novara_saves for update to authenticated
    using ((select auth.uid()) = user_id) with check ((select auth.uid()) = user_id);
create or replace function public.novara_touch_save() returns trigger
language plpgsql set search_path = '' as $$
begin
    new.updated_at = now();
    return new;
end;
$$;
revoke all on function public.novara_touch_save() from public;
drop trigger if exists novara_touch_save on public.novara_saves;
create trigger novara_touch_save before update on public.novara_saves
    for each row execute function public.novara_touch_save();
commit;
