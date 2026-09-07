-- Transparência do Red Bull Bragantino — adiciona o Exercício 2025.
--
-- Fonte: pacote de conteúdo consolidado (docs/bragantino_data), que aponta
-- pra `fpf_financials_2025` no catálogo de fontes — domínio oficial da
-- Federação Paulista de Futebol (futebolpaulista.com.br), NÃO o domínio do
-- clube (que já se provou quebrado pros exercícios 2023/2024, ver
-- bragantino_club_transparency.sql). Verificado ao vivo em 2026-09-07:
-- HTTP 200, `content-type: application/pdf`, 4.7MB, `last-modified:
-- 2026-05-19` — usado como document_date por ser um dado real do próprio
-- arquivo, já que a fonte não trouxe uma data de assinatura explícita.
--
-- Números do relatório (net_revenue R$ 499.199.000, net_income
-- R$ 31.773.000) ficam só no PDF em si — o schema atual de
-- club_transparency_documents não tem campo pra valores numéricos, só
-- título/data/link, então não há coluna pra preencher com eles aqui.
--
-- Rodar no SQL editor do projeto Supabase do BRAGANTINO
-- (yrgyzkaaudyzmsqwzecj).

insert into public.club_transparency_topics (id, title, sort_order) values
  ('exercicio_2025', 'Exercício 2025', 2)
on conflict (id) do update set title = excluded.title, sort_order = excluded.sort_order;

insert into public.club_transparency_documents (id, topic_id, title, document_date, pdf_url, sort_order) values
  (
    'exercicio_2025_relatorio_auditores_independentes',
    'exercicio_2025',
    'Relatório dos auditores independentes 2025',
    '2026-05-19',
    'https://futebolpaulista.com.br/Repositorio/Institucional/2025/3333-26%20%20Relat%C3%B3rio%20dos%20auditores%20independentes%20RB%20Bragantino%202025.pdf',
    0
  )
on conflict (id) do update set
  title = excluded.title,
  document_date = excluded.document_date,
  pdf_url = excluded.pdf_url,
  sort_order = excluded.sort_order;
