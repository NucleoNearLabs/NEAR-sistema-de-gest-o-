-- Somente leitura. Execute depois de configurar as tabelas e os perfis.
select tablename,rowsecurity from pg_tables
where schemaname='public' and tablename like 'near_test_%' order by tablename;
-- Todas as tabelas devem apresentar rowsecurity = true.
select tablename,policyname,cmd,roles from pg_policies
where schemaname='public' and tablename like 'near_test_%' order by tablename,policyname;
select table_name,grantee,privilege_type from information_schema.role_table_grants
where table_schema='public' and table_name like 'near_test_%' and grantee in ('anon','authenticated') order by table_name,grantee,privilege_type;
-- anon não deve ter acesso às tabelas. Perfis devem ter somente SELECT para authenticated.
select p.name,p.role,p.active,u.email from public.near_test_profiles p join auth.users u on u.id=p.user_id order by p.name;
