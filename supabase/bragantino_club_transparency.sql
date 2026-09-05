-- Transparência do Red Bull Bragantino — demonstrações financeiras
-- auditadas (BDO RCS Auditores Independentes), achadas pelo usuário no
-- domínio oficial do clube. Tópicos por exercício mantidos mesmo sem
-- documento clicável ainda — ver DOCUMENT_URL_GAP abaixo.
--
-- DOCUMENT_URL_GAP (2026-09-05): as duas URLs oficiais encontradas
--   https://www.redbullbragantino.com.br/balanco/Red_Bull_Bragantino_futebol_LTDA_BDO_RCS_Auditores_Independentes_SS-Sao_Paulo_31_de_Janeiro_de_2024.pdf
--   https://www.redbullbragantino.com.br/balanco/Red_Bull_Bragantino_%28BDO_RCS_Auditores_independentes_SS_S%C3%A3o_Paulo_11_de_Fevereiro_de_2025%29.pdf
-- redirecionam pra home do site (`/br-pt`) em todos os domínios testados
-- (.com.br, www.com.br, www.com) — o site do Bragantino passou por um
-- redesign (nova SPA "consumer-app") e a rota estática /balanco/*.pdf
-- parou de responder. Confirmado que os documentos são REAIS (Wayback
-- Machine tem as duas URLs arquivadas com status 200 em 2025), não é
-- dado inventado — só a rota atual do site não serve mais o arquivo.
-- Documentos NÃO inseridos de propósito (nenhum link clicável que jogue
-- o usuário pra home) — só os tópicos, pra entrar sem redesenhar nada
-- assim que a URL nova/funcional for encontrada:
--   Exercício 2023 -> "Demonstrações Financeiras 2023-2022" (assinado
--     pelo auditor em 31/jan/2024)
--   Exercício 2024 -> "Demonstrações Financeiras 2024-2023" (assinado
--     pelo auditor em 11/fev/2025)
--
-- Rodar no SQL editor do projeto Supabase do BRAGANTINO
-- (yrgyzkaaudyzmsqwzecj).

insert into public.club_transparency_topics (id, title, sort_order) values
  ('exercicio_2023', 'Exercício 2023', 0),
  ('exercicio_2024', 'Exercício 2024', 1)
on conflict (id) do update set title = excluded.title, sort_order = excluded.sort_order;

-- Documentos removidos até existir uma pdf_url que abra o arquivo de
-- verdade (ver DOCUMENT_URL_GAP acima) — rodar isto se os 2 documents de
-- uma tentativa anterior ainda estiverem na tabela:
delete from public.club_transparency_documents
  where id in (
    'exercicio_2023_demonstracoes_financeiras_2023_2022',
    'exercicio_2024_demonstracoes_financeiras_2024_2023'
  );
