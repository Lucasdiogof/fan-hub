-- ============================================================================
-- Rollout Gate — configuração server-side de versão mínima do app.
-- NÃO aplicada ainda (arquivo local, aguardando revisão). Aditiva, 0 DROP,
-- 0 mudança em tabela existente.
--
-- Objetivo desta etapa: dar ao CLIENTE (Flutter) uma fonte server-side pra
-- decidir "minha versão está obsoleta?" antes de deixar o usuário navegar.
-- Isso é release control, NÃO enforcement de escrita — o servidor (RLS/RPC)
-- continua incapaz de saber a versão de quem chama PostgREST direto (nenhum
-- header de versão é enviado hoje; ver docs/multiclub/36_etapa_rollout_gate_report.md
-- §19-21). Um app antigo que já rodou, sem essa tela, ignora esta tabela
-- por completo — ela só protege instalações NOVAS o suficiente pra
-- consultá-la. `LEGACY_APP_WRITES_BLOCKED` continua false até essa lacuna
-- ser fechada por outro mecanismo (fora do escopo desta etapa).
--
-- Tenant-aware desde o início (club_id + platform), como toda tabela nova
-- do projeto — nunca "minimum_goias_version". Nenhum 2º clube cadastrado.
--
-- RLS: SELECT público (`USING (true)`, mesmo padrão de `quiz_questions` —
-- precisa ser legível ANTES do login, no boot). 0 policy de escrita: só
-- service_role/dashboard grava (nunca o app).
-- ============================================================================

create table public.app_release_requirements (
  id uuid primary key default gen_random_uuid(),
  club_id uuid not null references public.clubs(id),
  platform text not null check (platform in ('android', 'ios', 'web')),
  minimum_version text not null,
  minimum_build int not null,
  latest_version text,
  latest_build int,
  force_update boolean not null default false,
  message text,
  store_url text,
  updated_at timestamptz not null default now(),
  unique (club_id, platform)
);

alter table public.app_release_requirements enable row level security;

create policy "read app release requirements"
  on public.app_release_requirements
  for select
  using (true);

-- Seed inerte: aponta pra exatamente a versão já publicada localmente
-- (pubspec.yaml `1.0.0+1`) com force_update=false — mesmo se este seed
-- rodar em produção amanhã, ele não bloqueia ninguém, porque "mínimo
-- exigido" == "o que já está rodando". Alterar isso é decisão de release,
-- não desta migration.
insert into public.app_release_requirements
  (club_id, platform, minimum_version, minimum_build, force_update)
select id, platform, '1.0.0', 1, false
from public.clubs
cross join (values ('android'), ('ios'), ('web')) as p(platform)
where slug = 'goias';
