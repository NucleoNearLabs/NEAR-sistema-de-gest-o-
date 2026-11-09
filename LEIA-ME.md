# NEAR Gestão em Psicologia — teste com Supabase e GitHub Pages

Este pacote é uma versão independente de teste. Não contém pacientes reais, senhas, contas prontas ou conexão com o banco do sistema atual. Começa com agenda e cadastros vazios. Use nomes e documentos fictícios durante a validação.

## O que está incluído

- Login individual por e-mail e senha pelo Supabase Auth. Não exige conta ChatGPT.
- Gestor: cadastros da equipe, planejamento mensal, cobrança por CPF/CNPJ e financeiro.
- Terapeuta: apenas os pacientes vinculados à própria conta, sua agenda e registros de sessão.
- Registros de sessão visíveis somente ao profissional autor, inclusive quando o gestor consulta o sistema.
- Cadastro com responsável, telefone, e-mail, CEP, endereço e modalidade.
- Número de sessões e valor do pacote por mês; recebimento parcial ou total.
- Agenda semanal com criação, edição e cancelamento de sessões.
- Repetição semanal até uma data final, limitada a 53 semanas. A edição é individual; editar todas as próximas ocorrências não está incluído neste modelo.
- Cadastro de um paciente novo dentro do formulário de agendamento, mantendo os dados já preenchidos da sessão.
- Permissões no banco (RLS), não somente nos menus. Uma conta sem perfil ativo não lê os dados.
- Encerramento local da sessão após 30 minutos sem interação. A sessão fica no armazenamento da aba, não há senha gravada nos arquivos.

Este pacote não inclui o contrato personalizado do outro sistema, assinatura eletrônica, cobrança automática, anexos, trilha completa de auditoria, MFA no aplicativo ou uma rotina de backup. Não migra nem modifica o sistema hospedado atual. Não deve ser usado como único prontuário.

## 1. Criar um projeto Supabase separado para teste

1. Entre em https://supabase.com/dashboard e crie um projeto de teste, por exemplo `near-gestao-teste`.
2. Guarde a senha do banco em um gerenciador de senhas; ela NÃO vai nos arquivos do GitHub e não é a senha de login dos profissionais.
3. Abra **SQL Editor**, crie uma consulta e cole todo o conteúdo de **01_configurar_banco.sql**. Execute uma vez.
4. O SQL cria somente tabelas com prefixo `near_test_` e funções próprias. Use um projeto novo, separado do NEAR.LAB, para isolar o teste. Se repetir a execução e receber “already exists”, não apague tabelas: a estrutura já foi criada.
5. Mantenha a Data API habilitada com o schema `public` exposto. NÃO adicione `near_test_private` aos schemas expostos. O SQL concede somente os privilégios necessários e ativa RLS.

## 2. Criar as contas com login e senha

1. Abra **Authentication → Users → Add user → Create new user**.
2. Crie tua conta com teu e-mail e uma senha forte individual.
3. Crie a conta da Eduarda com o e-mail dela e uma senha própria. Para o teste, use a opção de confirmar o e-mail automaticamente, se disponível. Se preferir confirmação por e-mail, conclua-a antes do primeiro login.
4. Em configurações do Auth, mantenha o login por e-mail/senha habilitado e desative o cadastro público de novos usuários. O aplicativo não oferece formulário de cadastro público.
5. Abra **02_vincular_usuarios.sql**. Substitua `SEU_EMAIL_AQUI` e `EMAIL_DA_EDUARDA_AQUI` pelos mesmos e-mails usados em Authentication. Não escreva senhas nesse arquivo.
6. Cole e execute esse SQL no editor. A consulta final deve mostrar as duas contas. Tu estarás como `admin`; Eduarda como `therapist`, sem financeiro. Se os dois precisarem de financeiro, altere o cargo dela para `admin` no SQL Editor, conscientemente.
7. Para adicionar outro profissional, crie a conta em Auth e acrescente outra linha ao bloco `values` do arquivo 02, com o e-mail, o nome e o cargo `therapist`.

Nenhuma conta é promovida a gestor automaticamente. Os perfis só são criados/alterados pelo administrador do projeto no SQL Editor. Uma conta criada em Auth, mas sem perfil ativo, fica sem acesso.

## 3. Conectar o site ao banco

1. Copie a **Project URL** pelo diálogo **Connect** ou pelas configurações de API do projeto.
2. Copie a **Publishable key**, que começa com `sb_publishable_`, em **Settings → API Keys**. Em projeto antigo, o app também aceita a chave legada `anon`.
3. Edite **config.js** no computador:

```js
window.NEAR_CONFIG = {
  supabaseUrl: 'https://CODIGO_DO_SEU_PROJETO.supabase.co',
  supabasePublishableKey: 'sb_publishable_SUA_CHAVE_PUBLICA'
};
```

Use somente URL e chave pública. NÃO use `sb_secret_`, `service_role`, senha do banco, senha de usuário nem token pessoal. A chave pública pode estar no código, mas a segurança depende das políticas RLS do arquivo 01. O aplicativo bloqueia chaves secretas reconhecíveis, mas nunca confie nisso para publicar segredos.

Se uma chave secreta for colocada no repositório por engano, apenas removê-la do arquivo não basta: revogue/troque a chave no Supabase e revise o histórico do GitHub.

## 4. Colocar no GitHub Pages

1. Descompacte o ZIP. Entre na pasta `near-github-teste`.
2. Crie um repositório exclusivo para o teste no GitHub. Se teu plano não oferecer Pages para repositórios privados, o código deste modelo pode ficar público: ele não deve conter nenhum dado pessoal ou segredo.
3. Envie o CONTEÚDO da pasta para a raiz do repositório, preservando a pasta `vendor`. Não envie somente o ZIP e não deixe `index.html` dentro de uma segunda pasta.
4. Na raiz devem aparecer: `index.html`, `style.css`, `app.js`, `config.js`, `vendor/`, os SQLs e este manual. `.nojekyll` pode ser enviado pelo Git ou pela opção de adicionar arquivos ocultos; o modelo não depende dele para funcionar.
5. Abra **Settings → Pages → Build and deployment**. Em **Source**, selecione **Deploy from a branch**. Escolha `main` e `/(root)`, depois salve.
6. Aguarde a publicação e abra a URL mostrada pelo próprio GitHub. Normalmente tem a forma `https://SEU_USUARIO.github.io/NOME_DO_REPOSITORIO/`.
7. No Supabase, em **Authentication → URL Configuration**, defina essa URL completa como **Site URL**. Se utilizar confirmação ou recuperação por e-mail no futuro, cadastre também as URLs de retorno autorizadas e implemente o fluxo correspondente; este modelo usa login direto por senha, sem recuperação automática.
8. Entre com o e-mail e a senha criados no Supabase. Não existe senha padrão no pacote.

O site no GitHub Pages mostra a interface de login. Os cadastros e sessões ficam no Supabase e só são consultados com a sessão e as permissões do usuário. Nunca coloque uma exportação do banco, planilhas de pacientes ou prontuários no repositório.

## 5. Primeiro teste recomendado

1. Entre como gestor.
2. Cadastre `Paciente Fictício A`, atribuindo o cadastro à Eduarda. Use telefone, documento e endereço inventados.
3. Selecione o mês atual e informe quatro sessões e um pacote de teste de R$ 400,00.
4. Crie um agendamento e escolha **Repetir semanalmente**, com uma data final. O valor mensal é informado separadamente: repetir sessões não gera cobranças.
5. Registre um recebimento parcial no Financeiro.
6. Saia e entre como Eduarda, preferencialmente em outro navegador para comparar contas.
7. Confira se o paciente dela aparece e se o Financeiro não aparece. Abra o cadastro: valores e dados do pagador não devem estar disponíveis.
8. Cadastre outro paciente fictício atribuído ao gestor. A Eduarda não deve enxergá-lo.
9. Salve um registro de sessão como Eduarda. Ao entrar como gestor, esse registro não deve aparecer, pois pertence à autora.
10. Reagende uma sessão da sequência e confirme que as outras datas não mudaram. Tente um horário sobreposto para conferir o bloqueio; a operação deve falhar sem salvar parte da sequência.
11. Atualize a página e faça login em outro dispositivo para confirmar que os dados persistem no Supabase.

## Revogar um acesso

No SQL Editor, usando o UUID correto em Authentication → Users:

```sql
update public.near_test_profiles
set active = false
where user_id = 'UUID_DO_USUARIO';
```

As políticas consultam o perfil ativo a cada operação de dados. A pessoa pode continuar com um token de login válido por algum tempo, mas perde o acesso aos registros. Dados já exibidos na tela podem continuar visíveis até a página ser atualizada; não é possível recolher cópias já vistas. Não exclua o usuário como única forma de revogar o acesso.

## Dificuldades comuns

- **“Primeiro preencha config.js”**: substitua os placeholders e publique novamente.
- **“Invalid login credentials”**: confira o e-mail, a senha e a confirmação da conta em Authentication → Users. A senha do banco é diferente da senha de login.
- **“Conta sem acesso”**: execute o arquivo 02 com o e-mail exatamente igual ao da conta e confirme `active = true`.
- **“relation does not exist” / função não encontrada**: execute o arquivo 01 inteiro. Confira se não há erro no SQL Editor.
- **“permission denied”**: confira Data API/schema público e o resultado das consultas em 03_conferir_configuracao.sql. Não desative RLS para tentar resolver.
- **Conta entra, mas não vê pacientes**: o gestor deve atribuir os cadastros ao UUID correto do profissional. O primeiro uso começa vazio.
- **O GitHub mostra um 404**: confira se `index.html` está na raiz da branch publicada e aguarde a execução de Pages.
- **Mudanças não aparecem**: atualize com Ctrl+F5 e confira a publicação mais recente.
- **“Conflito de horário”**: escolha outro horário ou cancele a sessão antiga. A função usa uma transação para não salvar somente parte de uma série.
- **Valor do pacote menor que o recebido**: ajuste o recebimento antes de reduzir o pacote. O banco rejeita saldos negativos.

## Validação e limites

O SQL foi executado em PostgreSQL local compatível (PGlite), com testes de RLS para gestor, terapeuta, conta sem perfil e conta desativada. Foram verificados isolamento financeiro, proibição de alterar cargos pelo cliente, registros privados, repetição semanal, edição individual e rollback de conflitos. O JavaScript foi checado sintaticamente.

O login e o comportamento na tua instância Supabase e na tua URL GitHub precisam ser conferidos após preencher config.js e executar os SQLs. Não foi criado ou alterado nenhum projeto Supabase real por este pacote.

Antes de dados reais: conferir acesso com contas reais separadas, testar exportação e restauração de backup, revisar a necessidade de MFA e logs, os documentos e os requisitos profissionais e de privacidade aplicáveis. O modelo não representa certificação de segurança ou conformidade.

## Referências oficiais

- Auth por senha: https://supabase.com/docs/reference/javascript/auth-signinwithpassword
- RLS: https://supabase.com/docs/guides/database/postgres/row-level-security
- Chaves públicas e secretas: https://supabase.com/docs/guides/getting-started/api-keys
- Backups: https://supabase.com/docs/guides/platform/backups
- GitHub Pages: https://docs.github.com/en/pages/getting-started-with-github-pages/creating-a-github-pages-site
