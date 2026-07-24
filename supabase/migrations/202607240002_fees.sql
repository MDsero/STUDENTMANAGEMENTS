create table if not exists public.student_fees (
  id uuid primary key default gen_random_uuid(),
  student_id uuid not null references public.students(id) on delete cascade,
  fee_month date not null,
  amount_due numeric(12,2) not null check (amount_due >= 0),
  amount_paid numeric(12,2) not null default 0 check (amount_paid >= 0 and amount_paid <= amount_due),
  due_date date not null,
  notes text,
  updated_at timestamptz not null default now(), created_at timestamptz not null default now(),
  unique(student_id, fee_month)
);
create index if not exists student_fees_student_id_idx on public.student_fees(student_id);
create index if not exists student_fees_fee_month_idx on public.student_fees(fee_month);
create index if not exists student_fees_due_date_idx on public.student_fees(due_date);
alter table public.student_fees enable row level security;
create policy "staff manages fees" on public.student_fees for all using (public.is_staff()) with check (public.is_staff());
create policy "student views own fees" on public.student_fees for select using (student_id=public.current_student_id());
create trigger student_fees_touch before update on public.student_fees for each row execute procedure public.touch_updated_at();
create or replace function public.dashboard_metrics() returns jsonb language sql stable security invoker set search_path=public as $$
 select jsonb_build_object('students',(select count(*) from students where status='active'),'programs',(select count(*) from programs where is_active),'todayClasses',(select count(*) from classes where starts_at::date=current_date),'attendanceToday',(select count(*) from attendance where attendance_date=current_date and status='present'),'feesReceived',(select coalesce(sum(amount_paid),0) from student_fees where date_trunc('month',fee_month)=date_trunc('month',current_date)),'feesPending',(select coalesce(sum(amount_due-amount_paid),0) from student_fees where date_trunc('month',fee_month)=date_trunc('month',current_date))); $$;
grant execute on function public.dashboard_metrics() to authenticated;
