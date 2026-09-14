-- ============================================================================
-- Diretoria do Bragantino — fecha o cadastro de Marquinho Chedid como
-- Presidente de Honra (distinto de André Rocha, CEO). Rode no SQL Editor do
-- projeto Supabase do BRAGANTINO (ref yrgyzkaaudyzmsqwzecj), nunca no do
-- Goiás — esta tabela não é compartilhada entre clubes (cada um tem a sua,
-- em projetos Supabase separados).
--
-- Fonte da decisão: CBF, documento oficial TJD/FPF, e presença em evento
-- recente com a Prefeitura de Bragança Paulista — decisão fechada pelo
-- usuário, não uma pesquisa nova.
-- ============================================================================

-- `display_name` é NOVO — nome curto/popular pra exibição na tela, sem
-- substituir `name` (que continua o nome completo/legal, fonte de verdade).
-- Nullable: todo o resto da diretoria continua mostrando só `name`.
alter table public.club_board_members
  add column if not exists display_name text;

update public.club_board_members
set
  name = 'Marco Antonio Nassif Abi Chedid',
  display_name = 'Marquinho Chedid',
  role = 'Presidente de Honra'
where id = 'marco_antonio_abi_chedid';

-- André Rocha já está corretamente cadastrado como CEO — preservado, nenhuma
-- mudança nesta linha.
