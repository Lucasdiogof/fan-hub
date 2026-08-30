-- ============================================================================
-- Marcador de baseline -- nao contem SQL executavel de proposito.
--
-- Ate 30/08/2026, todo o schema deste projeto (as ~23 tabelas/funcoes em
-- supabase/*.sql) foi aplicado manualmente colando cada arquivo no SQL
-- Editor do Supabase, sem historico de migration versionado. Recriar essa
-- historia inteira como migrations agora seria arriscado (rodar de novo
-- scripts antigos contra um banco que ja tem os dados de producao) sem
-- trazer beneficio real -- o estado atual do banco ja reflete tudo aquilo.
--
-- A partir desta migration, toda alteracao de schema/RPC/policy passa a
-- ser registrada como um arquivo novo em supabase/migrations/, nunca mais
-- como edicao direta de um dos scripts soltos em supabase/*.sql. Os
-- arquivos soltos continuam existindo como referencia historica de como
-- cada tabela nasceu, mas deixam de ser o lugar onde mudanca nova acontece.
--
-- Ver supabase/MIGRATIONS.md para o processo completo.
-- ============================================================================

select 1; -- no-op, so pra o arquivo nao ficar vazio.
