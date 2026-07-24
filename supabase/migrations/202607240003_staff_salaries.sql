alter type public.app_role add value if not exists 'staff';
create table if not exists public.staff (
 id uuid primary key default gen_random_uuid(), user_id uuid unique references auth.users(id) on delete set null, full_name text not null, email text unique, phone text, job_title text, monthly_salary numeric(12,2) not null default 0 check(monthly_salary>=0), status text not null default 'active' check(status in ('active','inactive')), created_at timestamptz not null default now(), updated_at timestamptz not null default now()
);
create table if not exists public.staff_salaries (
 id uuid primary key default gen_random_uuid(), staff_id uuid not null references public.staff(id) on delete cascade, salary_month date not null, amount_due numeric(12,2) not null check(amount_due>=0), amount_paid numeric(12,2) not null default 0 check(amount_paid>=0 and amount_paid<=amount_due), paid_on date, notes text, created_at timestamptz not null default now(), updated_at timestamptz not null default now(), unique(staff_id,salary_month)
);
alter table public.classes add column if not exists staff_id uuid references public.staff(id) on delete set null;
create index if not exists staff_user_id_idx on public.staff(user_id); create index if not exists classes_staff_id_idx on public.classes(staff_id); create index if not exists staff_salaries_staff_id_idx on public.staff_salaries(staff_id); create index if not exists staff_salaries_month_idx on public.staff_salaries(salary_month);
alter table public.staff enable row level security; alter table public.staff_salaries enable row level security;
create policy "admins manage staff" on public.staff for all using (public.is_staff()) with check (public.is_staff());
create policy "admins manage salaries" on public.staff_salaries for all using (public.is_staff()) with check (public.is_staff());
create trigger staff_touch before update on public.staff for each row execute procedure public.touch_updated_at(); create trigger staff_salaries_touch before update on public.staff_salaries for each row execute procedure public.touch_updated_at();
