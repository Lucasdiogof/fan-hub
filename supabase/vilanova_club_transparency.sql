-- Transparência do Vila Nova (club_transparency_topics/documents).
-- GERADO por `node tooling/vilanova_content/generate_seed_sql.mjs` a partir de
-- docs/vila_nova_data/data/transparency.json — não edite à mão.
--
-- Rode no projeto Supabase do VILA NOVA — NUNCA no do Goiás nem no do
-- Bragantino (a trava abaixo para se não for). Idempotente.
--
-- document_date = last-modified do próprio PDF (o pacote só traz o ano).

do $$
begin
  if not exists (select 1 from public.clubs where id = '3a6b1e27-8441-533d-b6b8-99fdcfdf1c3e' and slug = 'vilanova')
     or exists (select 1 from public.clubs where slug <> 'vilanova') then
    raise exception 'este nao e o projeto Supabase do Vila Nova -- PARE';
  end if;
end $$;

insert into public.club_transparency_topics (id, title, sort_order) values
  ('vn_demonstracoes_contabeis', 'Demonstrações contábeis', 0),
  ('vn_estatuto', 'Estatuto', 1)
on conflict (id) do update set title = excluded.title, sort_order = excluded.sort_order;

insert into public.club_transparency_documents (id, topic_id, title, document_date, pdf_url, sort_order) values
  ('vn_demonstracoes_contabeis_demonstracoes_contabeis_2025', 'vn_demonstracoes_contabeis', 'Demonstrações Contábeis 2025', '2026-04-23', 'https://www.vilanovafc.com.br/files/demonstracoes-contabeis-2025-912670.pdf', 0),
  ('vn_demonstracoes_contabeis_demonstracoes_contabeis_2024', 'vn_demonstracoes_contabeis', 'Demonstrações Contábeis 2024', '2025-04-30', 'https://www.vilanovafc.com.br/files/demonstracoes-contabeis-2024-716240.pdf', 1),
  ('vn_demonstracoes_contabeis_demonstracoes_contabeis_2023', 'vn_demonstracoes_contabeis', 'Demonstrações Contábeis 2023', '2024-05-01', 'https://www.vilanovafc.com.br/files/demonstracoes-contabeis-2023-045380.pdf', 2),
  ('vn_demonstracoes_contabeis_demonstracoes_contabeis_2022', 'vn_demonstracoes_contabeis', 'Demonstrações Contábeis 2022', '2023-04-28', 'https://www.vilanovafc.com.br/files/demonstracoes-contabeis-2022-457690.pdf', 3),
  ('vn_estatuto_estatuto_social_vila_nova_futebol_clube_2025', 'vn_estatuto', 'Estatuto Social Vila Nova Futebol Clube 2025', '2025-11-07', 'https://www.vilanovafc.com.br/files/estatuto-social-vila-nova-futebol-clube-2025-297680.pdf', 0)
on conflict (id) do update set topic_id = excluded.topic_id, title = excluded.title, document_date = excluded.document_date, pdf_url = excluded.pdf_url, sort_order = excluded.sort_order;
