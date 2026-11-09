-- Primeiro crie as contas em Authentication > Users > Add user > Create new user.
-- Depois substitua os DOIS e-mails abaixo e execute no SQL Editor.
-- As senhas são cadastradas no Supabase Auth, NUNCA neste SQL ou no GitHub.
-- Eduarda está como terapeuta (sem financeiro). Troque para admin apenas se desejar.
-- Não use a mesma conta para duas pessoas.
with wanted(email,name,role) as (values
 ('SEU_EMAIL_AQUI','Julio','admin'),
 ('EMAIL_DA_EDUARDA_AQUI','Eduarda','therapist')
)
insert into public.near_test_profiles(user_id,name,role,active)
select u.id,w.name,w.role,true from wanted w join auth.users u on lower(u.email)=lower(w.email)
on conflict(user_id) do update set name=excluded.name,role=excluded.role,active=true;
-- Devem aparecer as duas contas. Se faltar alguém, confira o e-mail e se a conta existe.
select p.name,p.role,p.active,u.email from public.near_test_profiles p join auth.users u on u.id=p.user_id order by p.name;
