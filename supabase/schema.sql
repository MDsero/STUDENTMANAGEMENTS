-- RRAcademy canonical schema. Run in this order: schema.sql, storage.sql, seed.sql.
create extension if not exists pgcrypto;

create type public.app_role as enum ('super_admin','admin','staff','student');
create type public.attendance_status as enum ('present','absent','late','excused');

create table public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  email text not null unique,
  full_name text not null default '',
  role public.app_role not null default 'student',
  avatar_path text,
  created_at timestamptz not null default now(), updated_at timestamptz not null default now()
);
create table public.programs (
  id uuid primary key default gen_random_uuid(), name text not null unique, description text not null default '',
  poster_path text, is_active boolean not null default true, created_at timestamptz not null default now()
);
create table public.students (
  id uuid primary key default gen_random_uuid(), user_id uuid unique references auth.users(id) on delete set null,
  student_number text not null unique, full_name text not null, email text unique, phone text, guardian_name text,
  status text not null default 'active' check (status in ('active','inactive','graduated')), profile_path text,
  created_at timestamptz not null default now(), updated_at timestamptz not null default now()
);
create table public.classes (
  id uuid primary key default gen_random_uuid(), program_id uuid references public.programs(id) on delete set null,
  title text not null, instructor text, staff_id uuid, room text, starts_at timestamptz not null, ends_at timestamptz not null,
  capacity integer not null default 30 check (capacity > 0), created_at timestamptz not null default now(),
  check (ends_at > starts_at)
);
create table public.staff (
 id uuid primary key default gen_random_uuid(), user_id uuid unique references auth.users(id) on delete set null, full_name text not null, email text unique, phone text, job_title text, monthly_salary numeric(12,2) not null default 0 check(monthly_salary>=0), status text not null default 'active' check(status in ('active','inactive')), created_at timestamptz not null default now(), updated_at timestamptz not null default now()
);
alter table public.classes add constraint classes_staff_id_fkey foreign key(staff_id) references public.staff(id) on delete set null;
create table public.staff_salaries (
 id uuid primary key default gen_random_uuid(), staff_id uuid not null references public.staff(id) on delete cascade, salary_month date not null, amount_due numeric(12,2) not null check(amount_due>=0), amount_paid numeric(12,2) not null default 0 check(amount_paid>=0 and amount_paid<=amount_due), paid_on date, notes text, created_at timestamptz not null default now(), updated_at timestamptz not null default now(), unique(staff_id,salary_month)
);
create table public.student_programs (
  student_id uuid not null references public.students(id) on delete cascade,
  program_id uuid not null references public.programs(id) on delete cascade, assigned_at timestamptz not null default now(),
  primary key (student_id, program_id)
);
create table public.class_enrollments (
  student_id uuid not null references public.students(id) on delete cascade,
  class_id uuid not null references public.classes(id) on delete cascade, enrolled_at timestamptz not null default now(),
  primary key (student_id, class_id)
);
create table public.attendance (
  id uuid primary key default gen_random_uuid(), student_id uuid not null references public.students(id) on delete cascade,
  class_id uuid not null references public.classes(id) on delete cascade, attendance_date date not null,
  status public.attendance_status not null, notes text, marked_by uuid references auth.users(id), created_at timestamptz not null default now(),
  unique(student_id,class_id,attendance_date)
);
create table public.announcements (
  id uuid primary key default gen_random_uuid(), title text not null, body text not null, image_path text,
  published boolean not null default false, published_at timestamptz, author_id uuid references auth.users(id), created_at timestamptz not null default now(), updated_at timestamptz not null default now()
);
create table public.notifications (
  id uuid primary key default gen_random_uuid(), user_id uuid not null references auth.users(id) on delete cascade,
  title text not null, body text not null, data jsonb not null default '{}'::jsonb, read_at timestamptz, created_at timestamptz not null default now()
);
create table public.audit_logs (
  id bigint generated always as identity primary key, actor_id uuid references auth.users(id), action text not null,
  entity text not null, entity_id text, changes jsonb, created_at timestamptz not null default now()
);

create index students_user_id_idx on public.students(user_id); create index students_email_idx on public.students(email);
create index classes_program_id_idx on public.classes(program_id); create index attendance_student_id_idx on public.attendance(student_id);
create index classes_staff_id_idx on public.classes(staff_id); create index staff_user_id_idx on public.staff(user_id); create index staff_salaries_staff_id_idx on public.staff_salaries(staff_id); create index staff_salaries_month_idx on public.staff_salaries(salary_month);
create index attendance_class_id_idx on public.attendance(class_id); create index attendance_date_idx on public.attendance(attendance_date);
create index programs_created_at_idx on public.programs(created_at); create index announcements_created_at_idx on public.announcements(created_at);
create index notifications_user_created_idx on public.notifications(user_id,created_at desc);
create table public.student_fees (
 id uuid primary key default gen_random_uuid(), student_id uuid not null references public.students(id) on delete cascade, fee_month date not null, amount_due numeric(12,2) not null check(amount_due>=0), amount_paid numeric(12,2) not null default 0 check(amount_paid>=0 and amount_paid<=amount_due), due_date date not null, notes text, updated_at timestamptz not null default now(), created_at timestamptz not null default now(), unique(student_id,fee_month)
);
create index student_fees_student_id_idx on public.student_fees(student_id); create index student_fees_fee_month_idx on public.student_fees(fee_month); create index student_fees_due_date_idx on public.student_fees(due_date);

create or replace function public.is_staff() returns boolean language sql stable security definer set search_path=public as $$
  select exists(select 1 from public.profiles where id=auth.uid() and role in ('super_admin','admin'));
$$;
create or replace function public.current_student_id() returns uuid language sql stable security definer set search_path=public as $$
  select id from public.students where user_id=auth.uid();
$$;
create or replace function public.touch_updated_at() returns trigger language plpgsql as $$ begin new.updated_at=now(); return new; end; $$;
create trigger profiles_touch before update on public.profiles for each row execute procedure public.touch_updated_at();
create trigger students_touch before update on public.students for each row execute procedure public.touch_updated_at();
create trigger announcements_touch before update on public.announcements for each row execute procedure public.touch_updated_at();
create or replace function public.handle_new_user() returns trigger language plpgsql security definer set search_path=public as $$
begin insert into public.profiles(id,email,full_name) values(new.id,coalesce(new.email,''),coalesce(new.raw_user_meta_data->>'full_name','')); return new; end; $$;
create trigger on_auth_user_created after insert on auth.users for each row execute procedure public.handle_new_user();

alter table public.profiles enable row level security; alter table public.students enable row level security; alter table public.programs enable row level security; alter table public.staff enable row level security; alter table public.staff_salaries enable row level security;
alter table public.classes enable row level security; alter table public.student_programs enable row level security; alter table public.class_enrollments enable row level security;
alter table public.attendance enable row level security; alter table public.announcements enable row level security; alter table public.notifications enable row level security; alter table public.audit_logs enable row level security;
alter table public.student_fees enable row level security;
create policy "profile own or staff" on public.profiles for select using (id=auth.uid() or public.is_staff());
create policy "staff profile write" on public.profiles for update using (public.is_staff()) with check (public.is_staff());
create policy "staff manages students" on public.students for all using (public.is_staff()) with check (public.is_staff());
create policy "student views self" on public.students for select using (user_id=auth.uid());
create policy "programs visible" on public.programs for select using (is_active or public.is_staff()); create policy "staff manages programs" on public.programs for all using (public.is_staff()) with check (public.is_staff());
create policy "classes visible to enrolled" on public.classes for select using (public.is_staff() or exists(select 1 from public.class_enrollments e where e.class_id=id and e.student_id=public.current_student_id())); create policy "staff manages classes" on public.classes for all using (public.is_staff()) with check (public.is_staff());
create policy "enrollments visible" on public.class_enrollments for select using (public.is_staff() or student_id=public.current_student_id()); create policy "staff manages enrollments" on public.class_enrollments for all using (public.is_staff()) with check (public.is_staff());
create policy "student programs visible" on public.student_programs for select using (public.is_staff() or student_id=public.current_student_id()); create policy "staff manages student programs" on public.student_programs for all using (public.is_staff()) with check (public.is_staff());
create policy "attendance visible" on public.attendance for select using (public.is_staff() or student_id=public.current_student_id()); create policy "staff manages attendance" on public.attendance for all using (public.is_staff()) with check (public.is_staff());
create policy "published announcements visible" on public.announcements for select using (published or public.is_staff()); create policy "staff manages announcements" on public.announcements for all using (public.is_staff()) with check (public.is_staff());
create policy "own notifications" on public.notifications for select using (user_id=auth.uid()); create policy "mark own notification read" on public.notifications for update using (user_id=auth.uid()) with check (user_id=auth.uid()); create policy "staff creates notifications" on public.notifications for insert with check (public.is_staff());
create policy "staff reads audit" on public.audit_logs for select using (public.is_staff());
create policy "admins manage staff" on public.staff for all using (public.is_staff()) with check (public.is_staff()); create policy "admins manage salaries" on public.staff_salaries for all using (public.is_staff()) with check (public.is_staff());
create policy "staff manages fees" on public.student_fees for all using (public.is_staff()) with check (public.is_staff()); create policy "student views own fees" on public.student_fees for select using (student_id=public.current_student_id());

create or replace view public.attendance_summary with (security_invoker=true) as select student_id, count(*) total, count(*) filter(where status='present') present, round(100.0*count(*) filter(where status='present')/nullif(count(*),0),1) percentage from public.attendance group by student_id;
create or replace function public.dashboard_metrics() returns jsonb language sql stable security invoker set search_path=public as $$
 select jsonb_build_object('students',(select count(*) from students where status='active'),'programs',(select count(*) from programs where is_active),'todayClasses',(select count(*) from classes where starts_at::date=current_date),'attendanceToday',(select count(*) from attendance where attendance_date=current_date and status='present'),'feesReceived',(select coalesce(sum(amount_paid),0) from student_fees where date_trunc('month',fee_month)=date_trunc('month',current_date)),'feesPending',(select coalesce(sum(amount_due-amount_paid),0) from student_fees where date_trunc('month',fee_month)=date_trunc('month',current_date))); $$;
grant execute on function public.dashboard_metrics() to authenticated;
alter publication supabase_realtime add table public.announcements, public.attendance, public.classes, public.notifications;
