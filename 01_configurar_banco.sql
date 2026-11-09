-- NEAR Gestão em Psicologia — AMBIENTE DE TESTE, sem pacientes reais.
-- Execute UMA VEZ no SQL Editor de um projeto Supabase de teste separado.
-- Não altera tabelas do NEAR.LAB nem do sistema atual.
begin;
create schema if not exists near_test_private;
revoke all on schema near_test_private from public, anon;
grant usage on schema near_test_private to authenticated;

create table public.near_test_profiles (
 user_id uuid primary key references auth.users(id),
 name text not null check (length(name) between 1 and 150),
 role text not null check (role in ('admin','therapist')),
 active boolean not null default true
);
alter table public.near_test_profiles enable row level security;
-- Lookups internos: SECURITY DEFINER evita recursão na política de perfis.
-- Sem parâmetros, auth.uid() obrigatório; schema não exposto pela Data API.
create function near_test_private.is_admin() returns boolean
language sql stable security definer set search_path = '' as $$
 select auth.uid() is not null and exists (
 select 1 from public.near_test_profiles where user_id=auth.uid() and active and role='admin');
$$;
create function near_test_private.is_member() returns boolean
language sql stable security definer set search_path = '' as $$
 select auth.uid() is not null and exists (
 select 1 from public.near_test_profiles where user_id=auth.uid() and active);
$$;
revoke all on function near_test_private.is_admin() from public,anon;
revoke all on function near_test_private.is_member() from public,anon;
grant execute on function near_test_private.is_admin(),near_test_private.is_member() to authenticated;

create table public.near_test_patients (
 id uuid primary key default gen_random_uuid(), therapist_id uuid not null references public.near_test_profiles(user_id),
 name text not null check(length(name) between 1 and 200), birth date,
 phone text not null default '', email text not null default '',
 guardian text not null default '', guardian_document text not null default '',
 cep text not null default '', address text not null default '', number text not null default '',
 complement text not null default '', neighborhood text not null default '', city text not null default '', state text not null default '',
 sport text not null default '', status text not null default 'Ativo' check(status in ('Ativo','Pausado','Encerrado')),
 created_at timestamptz not null default now()
);
create index near_test_patient_therapist on public.near_test_patients(therapist_id);
create table public.near_test_plans (
 patient_id uuid not null references public.near_test_patients(id), month date not null check(extract(day from month)=1),
 session_count int not null check(session_count between 0 and 62), primary key(patient_id,month)
);
create table public.near_test_billing (
 patient_id uuid primary key references public.near_test_patients(id),
 billing_type text not null default 'CPF' check(billing_type in ('CPF','CNPJ')),
 payer text not null default '', payer_document text not null default '', payer_phone text not null default '',
 payer_email text not null default '', payer_cep text not null default '', payer_address text not null default '',
 bank text not null default '', payment_method text not null default '', receipt_required boolean not null default false
);
create table public.near_test_charges (
 patient_id uuid not null references public.near_test_patients(id),month date not null check(extract(day from month)=1),
 amount_cents int not null default 0 check(amount_cents>=0),
 paid_cents int not null default 0 check(paid_cents between 0 and amount_cents),primary key(patient_id,month)
);
create table public.near_test_appointments (
 id uuid primary key default gen_random_uuid(),patient_id uuid not null references public.near_test_patients(id),
 therapist_id uuid not null references public.near_test_profiles(user_id),starts_at timestamptz not null,
 duration int not null check(duration between 10 and 240),status text not null check(status in ('Agendado','Confirmado','Realizado','Falta','Cancelado')),
 series_id uuid,created_at timestamptz not null default now()
);
create index near_test_appointment_therapist_start on public.near_test_appointments(therapist_id,starts_at);
create table public.near_test_notes (
 id uuid primary key default gen_random_uuid(),patient_id uuid not null references public.near_test_patients(id),
 author_id uuid not null references public.near_test_profiles(user_id),date date not null,
 goal text not null default '',evolution text not null check(length(evolution)>0),next_steps text not null default ''
);
create index near_test_note_author on public.near_test_notes(author_id);
alter table public.near_test_patients enable row level security;
alter table public.near_test_plans enable row level security;
alter table public.near_test_billing enable row level security;
alter table public.near_test_charges enable row level security;
alter table public.near_test_appointments enable row level security;
alter table public.near_test_notes enable row level security;

create policy profiles_select on public.near_test_profiles for select to authenticated
 using(near_test_private.is_member() and (user_id=(select auth.uid()) or near_test_private.is_admin()));
-- Ninguém altera perfil/cargo pelo navegador. Atribuição feita no SQL Editor.
create policy patients_select on public.near_test_patients for select to authenticated
 using(near_test_private.is_member() and (therapist_id=(select auth.uid()) or near_test_private.is_admin()));
create policy patients_insert on public.near_test_patients for insert to authenticated
 with check(near_test_private.is_member() and (therapist_id=(select auth.uid()) or near_test_private.is_admin()));
create policy patients_update on public.near_test_patients for update to authenticated
 using(near_test_private.is_member() and (therapist_id=(select auth.uid()) or near_test_private.is_admin()))
 with check(near_test_private.is_member() and (therapist_id=(select auth.uid()) or near_test_private.is_admin()));
create policy plans_select on public.near_test_plans for select to authenticated using(near_test_private.is_member() and exists(select 1 from public.near_test_patients p where p.id=patient_id));
create policy plans_insert on public.near_test_plans for insert to authenticated with check(near_test_private.is_admin());
create policy plans_update on public.near_test_plans for update to authenticated using(near_test_private.is_admin()) with check(near_test_private.is_admin());
create policy billing_select on public.near_test_billing for select to authenticated using(near_test_private.is_admin());
create policy billing_insert on public.near_test_billing for insert to authenticated with check(near_test_private.is_admin());
create policy billing_update on public.near_test_billing for update to authenticated using(near_test_private.is_admin()) with check(near_test_private.is_admin());
create policy charges_select on public.near_test_charges for select to authenticated using(near_test_private.is_admin());
create policy charges_insert on public.near_test_charges for insert to authenticated with check(near_test_private.is_admin());
create policy charges_update on public.near_test_charges for update to authenticated using(near_test_private.is_admin()) with check(near_test_private.is_admin());
create policy appointments_select on public.near_test_appointments for select to authenticated
 using(near_test_private.is_member() and (therapist_id=(select auth.uid()) or near_test_private.is_admin()) and exists(select 1 from public.near_test_patients p where p.id=patient_id));
create policy appointments_insert on public.near_test_appointments for insert to authenticated
 with check(near_test_private.is_member() and (therapist_id=(select auth.uid()) or near_test_private.is_admin()) and exists(select 1 from public.near_test_patients p where p.id=patient_id and p.therapist_id=near_test_appointments.therapist_id));
create policy appointments_update on public.near_test_appointments for update to authenticated
 using(near_test_private.is_member() and (therapist_id=(select auth.uid()) or near_test_private.is_admin()))
 with check(near_test_private.is_member() and (therapist_id=(select auth.uid()) or near_test_private.is_admin()) and exists(select 1 from public.near_test_patients p where p.id=patient_id and p.therapist_id=near_test_appointments.therapist_id));
create policy notes_select on public.near_test_notes for select to authenticated using(near_test_private.is_member() and author_id=(select auth.uid()) and exists(select 1 from public.near_test_patients p where p.id=patient_id));
create policy notes_insert on public.near_test_notes for insert to authenticated with check(near_test_private.is_member() and author_id=(select auth.uid()) and exists(select 1 from public.near_test_patients p where p.id=patient_id));
create policy notes_update on public.near_test_notes for update to authenticated using(near_test_private.is_member() and author_id=(select auth.uid())) with check(near_test_private.is_member() and author_id=(select auth.uid()) and exists(select 1 from public.near_test_patients p where p.id=patient_id));

revoke all on public.near_test_profiles,public.near_test_patients,public.near_test_plans,public.near_test_billing,public.near_test_charges,public.near_test_appointments,public.near_test_notes from anon,authenticated,public;
grant select on public.near_test_profiles to authenticated;
grant select,insert,update on public.near_test_patients,public.near_test_plans,public.near_test_billing,public.near_test_charges,public.near_test_appointments,public.near_test_notes to authenticated;

-- Transação para criar a sequência ou editar uma sessão; obedece RLS.
create function public.near_test_save_appointments(p_patient uuid,p_start timestamptz,p_duration int,p_status text,p_id uuid default null,p_until date default null)
returns int language plpgsql security invoker set search_path='' as $$
declare t uuid; s uuid; n int:=1; i int; moment timestamptz; old public.near_test_appointments%rowtype;
begin
 if not near_test_private.is_member() then raise exception 'Acesso não autorizado';end if;
 select therapist_id into t from public.near_test_patients where id=p_patient;
 if t is null then raise exception 'Paciente não disponível';end if;
 if p_duration not between 10 and 240 or p_status not in ('Agendado','Confirmado','Realizado','Falta','Cancelado') then raise exception 'Atendimento inválido';end if;
 if p_id is not null then
  select * into old from public.near_test_appointments where id=p_id;
  if old.id is null then raise exception 'Atendimento não disponível';end if;
  s:=old.series_id;
 elsif p_until is not null then
  n:=((p_until-(p_start at time zone 'America/Sao_Paulo')::date)/7)+1;
  if p_until<(p_start at time zone 'America/Sao_Paulo')::date or n not between 1 and 53 then raise exception 'Escolha entre 1 e 53 semanas';end if;
  s:=gen_random_uuid();
 end if;
 perform pg_advisory_xact_lock(hashtext(t::text));
 for i in 0..n-1 loop
  moment:=p_start+i*interval '7 days';
  if p_status<>'Cancelado' and exists(select 1 from public.near_test_appointments a where a.therapist_id=t and a.status<>'Cancelado' and (p_id is null or a.id<>p_id) and a.starts_at<moment+make_interval(mins=>p_duration) and a.starts_at+make_interval(mins=>a.duration)>moment) then
   raise exception 'Conflito de horário. Nenhuma sessão desta operação foi salva';
  end if;
  if p_id is null then insert into public.near_test_appointments(patient_id,therapist_id,starts_at,duration,status,series_id) values(p_patient,t,moment,p_duration,p_status,s);
  else update public.near_test_appointments set patient_id=p_patient,therapist_id=t,starts_at=moment,duration=p_duration,status=p_status where id=p_id;end if;
 end loop;
 return n;
end;$$;
revoke all on function public.near_test_save_appointments(uuid,timestamptz,int,text,uuid,date) from public,anon;
grant execute on function public.near_test_save_appointments(uuid,timestamptz,int,text,uuid,date) to authenticated;
commit;

-- Salva cadastro e plano em uma única transação. SECURITY INVOKER mantém RLS.
begin;
create function public.near_test_save_patient(p_id uuid,p_data jsonb,p_billing jsonb default null,p_plan jsonb default null,p_charge jsonb default null)
returns uuid language plpgsql security invoker set search_path='' as $$
declare result uuid:=coalesce(p_id,gen_random_uuid()); t uuid;
begin
 if not near_test_private.is_member() then raise exception 'Acesso não autorizado';end if;
 if p_id is not null and not exists(select 1 from public.near_test_patients where id=p_id) then raise exception 'Cadastro não disponível';end if;
 if not near_test_private.is_admin() and (p_billing is not null or p_plan is not null or p_charge is not null) then raise exception 'Financeiro exclusivo do gestor';end if;
 t:=case when near_test_private.is_admin() then (p_data->>'therapist_id')::uuid else auth.uid() end;
 insert into public.near_test_patients(id,therapist_id,name,birth,phone,email,guardian,guardian_document,cep,address,number,complement,neighborhood,city,state,sport,status)
 values(result,t,p_data->>'name',nullif(p_data->>'birth','')::date,coalesce(p_data->>'phone',''),coalesce(p_data->>'email',''),coalesce(p_data->>'guardian',''),coalesce(p_data->>'guardian_document',''),coalesce(p_data->>'cep',''),coalesce(p_data->>'address',''),coalesce(p_data->>'number',''),coalesce(p_data->>'complement',''),coalesce(p_data->>'neighborhood',''),coalesce(p_data->>'city',''),coalesce(p_data->>'state',''),coalesce(p_data->>'sport',''),coalesce(p_data->>'status','Ativo'))
 on conflict(id) do update set therapist_id=excluded.therapist_id,name=excluded.name,birth=excluded.birth,phone=excluded.phone,email=excluded.email,guardian=excluded.guardian,guardian_document=excluded.guardian_document,cep=excluded.cep,address=excluded.address,number=excluded.number,complement=excluded.complement,neighborhood=excluded.neighborhood,city=excluded.city,state=excluded.state,sport=excluded.sport,status=excluded.status;
 if p_billing is not null then
 insert into public.near_test_billing(patient_id,billing_type,payer,payer_document,payer_phone,payer_email,payer_cep,payer_address,bank,payment_method,receipt_required)
 values(result,coalesce(p_billing->>'billing_type','CPF'),coalesce(p_billing->>'payer',''),coalesce(p_billing->>'payer_document',''),coalesce(p_billing->>'payer_phone',''),coalesce(p_billing->>'payer_email',''),coalesce(p_billing->>'payer_cep',''),coalesce(p_billing->>'payer_address',''),coalesce(p_billing->>'bank',''),coalesce(p_billing->>'payment_method',''),coalesce((p_billing->>'receipt_required')::boolean,false))
 on conflict(patient_id) do update set billing_type=excluded.billing_type,payer=excluded.payer,payer_document=excluded.payer_document,payer_phone=excluded.payer_phone,payer_email=excluded.payer_email,payer_cep=excluded.payer_cep,payer_address=excluded.payer_address,bank=excluded.bank,payment_method=excluded.payment_method,receipt_required=excluded.receipt_required;
 end if;
 if p_plan is not null then
 insert into public.near_test_plans(patient_id,month,session_count) values(result,(p_plan->>'month')::date,(p_plan->>'session_count')::int)
 on conflict(patient_id,month) do update set session_count=excluded.session_count;
 end if;
 if p_charge is not null then
 insert into public.near_test_charges(patient_id,month,amount_cents,paid_cents) values(result,(p_charge->>'month')::date,(p_charge->>'amount_cents')::int,0)
 on conflict(patient_id,month) do update set amount_cents=excluded.amount_cents;
 end if;
 return result;
end;$$;
revoke all on function public.near_test_save_patient(uuid,jsonb,jsonb,jsonb,jsonb) from public,anon;
grant execute on function public.near_test_save_patient(uuid,jsonb,jsonb,jsonb,jsonb) to authenticated;
commit;
