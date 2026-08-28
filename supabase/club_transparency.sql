-- Transparência do Goiás — tópicos (exercícios contábeis, editais,
-- estatuto, relatórios) e os documentos (PDF) dentro de cada um. Fonte:
-- goiasec.com.br/transparencia. Supabase é a fonte da verdade — adicionar
-- um novo demonstrativo mensal é só inserir uma linha aqui, sem build novo.
--
-- Nota: a maioria dos documentos mais antigos (2008–2024) mostra a MESMA
-- data dentro do mesmo tópico no site oficial — não é a data do documento
-- em si, é quando aquele bloco foi publicado/atualizado no CMS deles.
-- Importado como está, sem inventar datas mais precisas que não temos.

create table if not exists public.club_transparency_topics (
  id text primary key,
  title text not null,
  sort_order int not null default 0,
  updated_at timestamptz not null default now()
);

create table if not exists public.club_transparency_documents (
  id text primary key,
  topic_id text not null references public.club_transparency_topics(id) on delete cascade,
  title text not null,
  document_date date not null,
  pdf_url text not null,
  sort_order int not null default 0,
  updated_at timestamptz not null default now()
);

alter table public.club_transparency_topics enable row level security;
alter table public.club_transparency_documents enable row level security;

drop policy if exists "club_transparency_topics_read_all" on public.club_transparency_topics;
create policy "club_transparency_topics_read_all"
  on public.club_transparency_topics
  for select
  using (true);

drop policy if exists "club_transparency_documents_read_all" on public.club_transparency_documents;
create policy "club_transparency_documents_read_all"
  on public.club_transparency_documents
  for select
  using (true);

insert into public.club_transparency_topics (id, title, sort_order) values
  ('edital_de_convocacao', 'Edital de Convocação', 0),
  ('estatuto_social_vigente', 'Estatuto Social Vigente', 1),
  ('exercicio_2008', 'Exercício 2008', 2),
  ('exercicio_2009', 'Exercício 2009', 3),
  ('exercicio_2010', 'Exercício 2010', 4),
  ('exercicio_2011', 'Exercício 2011', 5),
  ('exercicio_2012', 'Exercício 2012', 6),
  ('exercicio_2013', 'Exercício 2013', 7),
  ('exercicio_2014', 'Exercício 2014', 8),
  ('exercicio_2015', 'Exercício 2015', 9),
  ('exercicio_2016', 'Exercício 2016', 10),
  ('exercicio_2017', 'Exercício 2017', 11),
  ('exercicio_2018', 'Exercício 2018', 12),
  ('exercicio_2019', 'Exercício 2019', 13),
  ('exercicio_2020', 'Exercício 2020', 14),
  ('exercicio_2021', 'Exercício 2021', 15),
  ('exercicio_2022', 'Exercício 2022', 16),
  ('exercicio_2023', 'Exercício 2023', 17),
  ('exercicio_2024', 'Exercício 2024', 18),
  ('exercicio_2025', 'Exercício 2025', 19),
  ('exercicio_2026', 'Exercício 2026', 20),
  ('relatorio_de_transparencia_e_igualdade_salarial', 'Relatório de Transparência e Igualdade Salarial', 21)
on conflict (id) do update set
  title = excluded.title,
  sort_order = excluded.sort_order;

insert into public.club_transparency_documents (id, topic_id, title, document_date, pdf_url, sort_order) values
  ('edital_de_convocacao_edital_de_convocacao_reuniao_do_conselho_deliberativo_01_11_', 'edital_de_convocacao', 'Edital de Convocação Reunião do Conselho Deliberativo - 01/11/2024', date '2023-12-04', 'https://static.goiasec.com.br/upload/transparencia/2023/12/Edital-de-Convocacao-Reuniao-do-Conselho-Deliberativo-01-11-2024.pdf', 0),
  ('edital_de_convocacao_edital_de_convocacao_reuniao_do_conselho_deliberativo_21_10_', 'edital_de_convocacao', 'Edital de Convocação Reunião do Conselho Deliberativo - 21/10/2024', date '2023-12-04', 'https://static.goiasec.com.br/upload/transparencia/2023/12/Edital-de-Convocacao-Reuniao-do-Conselho-Deliberativo-21-10-2024.pdf', 1),
  ('edital_de_convocacao_edital_de_convocacao_reuniao_do_conselho_deliberativo_16_09_', 'edital_de_convocacao', 'Edital de Convocação Reunião do Conselho Deliberativo - 16/09/2024', date '2023-12-04', 'https://static.goiasec.com.br/upload/transparencia/2023/12/Edital-de-Convocacao-Reuniao-do-Conselho-Deliberativo-09-2024.pdf', 2),
  ('edital_de_convocacao_edital_de_convocacao_reuniao_do_conselho_deliberativo_03_202', 'edital_de_convocacao', 'Edital de Convocação Reunião do Conselho Deliberativo - 03/2024 Terceira Publicação', date '2023-12-04', 'https://static.goiasec.com.br/upload/transparencia/2023/12/Edital-dia-08.03.24-1.pdf', 3),
  ('edital_de_convocacao_edital_de_convocacao_reuniao_do_conselho_deliberativo_03_202_2', 'edital_de_convocacao', 'Edital de Convocação Reunião do Conselho Deliberativo - 03/2024 Segunda Publicação', date '2023-12-04', 'https://static.goiasec.com.br/upload/transparencia/2023/12/Publicacao-em-07.03-1.pdf', 4),
  ('edital_de_convocacao_edital_de_convocacao_reuniao_do_conselho_deliberativo_03_202_3', 'edital_de_convocacao', 'Edital de Convocação Reunião do Conselho Deliberativo - 03/2024 Primeira Publicação', date '2023-12-04', 'https://static.goiasec.com.br/upload/transparencia/2024/03/EDITAL-DE-CONVOCACAO-REUNIAO-DO-CONSELHO-DELIBERATIVO-032024.pdf', 5),
  ('edital_de_convocacao_reuniao_do_conselho_deliberativo_dezembro_2023', 'edital_de_convocacao', 'Reunião do Conselho Deliberativo - Dezembro 2023', date '2023-12-04', 'https://static.goiasec.com.br/upload/transparencia/2023/12/PUBLICAC%CC%A7A%CC%83O-SITE.-EDITAL-DE-CONVOCACAO-ELEICAO-2023-GEC.pdf', 6),
  ('estatuto_social_vigente_estatuto_social_vigente', 'estatuto_social_vigente', 'Estatuto Social Vigente', date '2026-05-14', 'https://static.goiasec.com.br/upload/transparencia/ee73bbb47ad448e8be18cabdad846189.pdf', 0),
  ('exercicio_2008_demonstracoes_contabeis_2008_2007', 'exercicio_2008', 'Demonstrações Contábeis 2008-2007', date '2021-06-16', 'https://static.goiasec.com.br/upload/transparencia/2019/02/1002_08091139345016.pdf', 0),
  ('exercicio_2009_demonstracoes_contabeis_2009_2008', 'exercicio_2009', 'Demonstrações Contábeis 2009-2008', date '2021-06-16', 'https://static.goiasec.com.br/upload/transparencia/2019/02/1016_08091153262944.pdf', 0),
  ('exercicio_2009_resolucao_01_2009', 'exercicio_2009', 'Resolução 01-2009', date '2021-06-16', 'https://static.goiasec.com.br/upload/transparencia/2021/06/Resolucao-01.2009.pdf', 1),
  ('exercicio_2009_resolucao_02_2009', 'exercicio_2009', 'Resolução 02-2009', date '2021-06-16', 'https://static.goiasec.com.br/upload/transparencia/2021/06/Resolucao-02.2009.pdf', 2),
  ('exercicio_2009_resolucao_03_2009', 'exercicio_2009', 'Resolução 03-2009', date '2021-06-16', 'https://static.goiasec.com.br/upload/transparencia/2021/06/Resolucao-03.2009.pdf', 3),
  ('exercicio_2009_resolucao_04_2009', 'exercicio_2009', 'Resolução 04-2009', date '2021-06-16', 'https://static.goiasec.com.br/upload/transparencia/2021/06/Resolucao-04.2009.pdf', 4),
  ('exercicio_2009_resolucao_05_2009', 'exercicio_2009', 'Resolução 05-2009', date '2021-06-16', 'https://static.goiasec.com.br/upload/transparencia/2021/06/Resolucao-05.2009.pdf', 5),
  ('exercicio_2009_certidao_02_10_2009', 'exercicio_2009', 'Certidão 02.10.2009', date '2021-06-16', 'https://static.goiasec.com.br/upload/transparencia/2021/06/Certidao-02.10.2009.pdf', 6),
  ('exercicio_2010_demonstracoes_contabeis_2010_2009', 'exercicio_2010', 'Demonstrações Contábeis 2010-2009', date '2021-06-16', 'https://static.goiasec.com.br/upload/transparencia/2019/02/1017_08091153385247.pdf', 0),
  ('exercicio_2011_demonstracoes_contabeis_2011_2010', 'exercicio_2011', 'Demonstrações Contábeis 2011-2010', date '2021-06-16', 'https://static.goiasec.com.br/upload/transparencia/2019/02/1018_08091153528802.pdf', 0),
  ('exercicio_2012_demonstracoes_contabeis_2012_2011', 'exercicio_2012', 'Demonstrações Contábeis 2012-2011', date '2021-06-16', 'https://static.goiasec.com.br/upload/transparencia/2019/02/1019_08091154147173.pdf', 0),
  ('exercicio_2013_demonstracoes_contabeis_2013_2012', 'exercicio_2013', 'Demonstrações Contábeis 2013-2012', date '2021-06-16', 'https://static.goiasec.com.br/upload/transparencia/2019/02/2072_04300821367736.pdf', 0),
  ('exercicio_2014_demonstracoes_contabeis_2014_2013', 'exercicio_2014', 'Demonstrações Contábeis 2014-2013', date '2021-06-16', 'https://static.goiasec.com.br/upload/transparencia/2019/02/3376_05010847051501.pdf', 0),
  ('exercicio_2015_demonstracoes_contabeis_2015_2014', 'exercicio_2015', 'Demonstrações Contábeis 2015-2014', date '2021-06-16', 'https://static.goiasec.com.br/upload/transparencia/2019/02/4701_04300128152738.pdf', 0),
  ('exercicio_2016_demonstracoes_contabeis_2016_2015', 'exercicio_2016', 'Demonstrações Contábeis 2016-2015', date '2021-06-16', 'https://static.goiasec.com.br/upload/transparencia/2019/02/6072_04281022046811.pdf', 0),
  ('exercicio_2017_demonstracoes_contabeis_2017_2016', 'exercicio_2017', 'Demonstrações Contábeis 2017-2016', date '2021-06-16', 'https://static.goiasec.com.br/upload/transparencia/2019/02/7200_06110501149442.pdf', 0),
  ('exercicio_2018_demonstracoes_contabeis_2018_2017', 'exercicio_2018', 'Demonstrações Contábeis 2018-2017', date '2021-06-16', 'https://static.goiasec.com.br/upload/transparencia/2019/04/GEC-Demonstra%C3%A7%C3%B5es-Cont%C3%A1beis-2018-Sites.pdf', 0),
  ('exercicio_2018_ata_da_reuniao_conselho_fiscal_dezembro_2018', 'exercicio_2018', 'Ata da Reunião Conselho Fiscal - Dezembro 2018', date '2021-06-16', 'https://static.goiasec.com.br/upload/transparencia/2021/06/Ata-da-Reuniao-Conselho-Fiscal-Dezembro-2018.pdf', 1),
  ('exercicio_2019_demonstracoes_contabeis_2019_2018', 'exercicio_2019', 'Demonstrações Contábeis 2019-2018', date '2021-06-16', 'https://static.goiasec.com.br/upload/transparencia/2020/04/GEC-Demonstra%C3%A7%C3%B5es-Cont%C3%A1beis-2019-Assinado.pdf', 0),
  ('exercicio_2019_ata_da_reuniao_conselho_fiscal_maio_2019', 'exercicio_2019', 'Ata da Reunião Conselho Fiscal - Maio 2019', date '2021-06-16', 'https://static.goiasec.com.br/upload/transparencia/2021/06/Ata-da-Reuniao-Conselho-Fiscal-Maio-2019.pdf', 1),
  ('exercicio_2020_demonstracoes_contabeis_2020_2019', 'exercicio_2020', 'Demonstrações Contábeis 2020-2019', date '2021-06-16', 'https://static.goiasec.com.br/upload/transparencia/2021/05/GEC-Demonstra%C3%A7%C3%B5es-Cont%C3%A1beis-2020-Sites.pdf', 0),
  ('exercicio_2020_parecer_do_conselho_fiscal_exercicio_2020', 'exercicio_2020', 'Parecer do Conselho Fiscal - Exercício 2020', date '2021-06-16', 'https://static.goiasec.com.br/upload/transparencia/2022/03/Parecer-do-Conselho-Fiscal-Exercicio-2020.pdf', 1),
  ('exercicio_2020_ata_da_reuniao_conselho_fiscal_dezembro_2020', 'exercicio_2020', 'Ata da Reunião Conselho Fiscal - Dezembro 2020', date '2021-06-16', 'https://static.goiasec.com.br/upload/transparencia/2022/03/Ata-da-Reuniao-Conselho-Fiscal-Dezembro-2020.pdf', 2),
  ('exercicio_2021_demonstracoes_contabeis_2021_2020', 'exercicio_2021', 'Demonstrações Contábeis 2021-2020', date '2022-03-31', 'https://static.goiasec.com.br/upload/transparencia/2022/03/Demonstra%C3%A7%C3%B5es-Cont%C3%A1beis-Goi%C3%A1s-Esporte-Clube-31.12.2021.pdf', 0),
  ('exercicio_2021_parecer_do_conselho_fiscal_exercicio_2021', 'exercicio_2021', 'Parecer do Conselho Fiscal - Exercício 2021', date '2022-03-31', 'https://static.goiasec.com.br/upload/transparencia/2023/04/Parecer-do-Conselho-Fiscal-Exercicio-2021.pdf', 1),
  ('exercicio_2021_demonstrativo_contabil_janeiro_2021', 'exercicio_2021', 'Demonstrativo Contábil - Janeiro 2021', date '2022-03-31', 'https://static.goiasec.com.br/upload/transparencia/2022/03/01-Demonstrativo-Contabil-Janeiro-_2021.pdf', 2),
  ('exercicio_2021_demonstrativo_contabil_fevereiro_2021', 'exercicio_2021', 'Demonstrativo Contábil - Fevereiro 2021', date '2022-03-31', 'https://static.goiasec.com.br/upload/transparencia/2022/03/02-Demonstrativo-Contabil-Fevereiro-_2021.pdf', 3),
  ('exercicio_2021_demonstrativo_contabil_marco_2021', 'exercicio_2021', 'Demonstrativo Contábil - Março 2021', date '2022-03-31', 'https://static.goiasec.com.br/upload/transparencia/2022/03/03-Demonstrativo-Contabil-Marco-_2021.pdf', 4),
  ('exercicio_2021_demonstrativo_contabil_abril_2021', 'exercicio_2021', 'Demonstrativo Contábil - Abril 2021', date '2022-03-31', 'https://static.goiasec.com.br/upload/transparencia/2022/03/04-Demonstrativo-Contabil-Abril-_2021.pdf', 5),
  ('exercicio_2021_demonstrativo_contabil_maio_2021', 'exercicio_2021', 'Demonstrativo Contábil - Maio 2021', date '2022-03-31', 'https://static.goiasec.com.br/upload/transparencia/2022/03/05-Demonstrativo-Contabil-Maio-_2021.pdf', 6),
  ('exercicio_2021_demonstrativo_contabil_junho_2021', 'exercicio_2021', 'Demonstrativo Contábil - Junho 2021', date '2022-03-31', 'https://static.goiasec.com.br/upload/transparencia/2022/03/06-Demonstrativo-Contabil-Junho-_2021.pdf', 7),
  ('exercicio_2021_demonstrativo_contabil_julho_2021', 'exercicio_2021', 'Demonstrativo Contábil - Julho 2021', date '2022-03-31', 'https://static.goiasec.com.br/upload/transparencia/2022/03/07-Demonstrativo-Contabil-Julho-_2021.pdf', 8),
  ('exercicio_2021_demonstrativo_contabil_agosto_2021', 'exercicio_2021', 'Demonstrativo Contábil - Agosto 2021', date '2022-03-31', 'https://static.goiasec.com.br/upload/transparencia/2022/03/08-Demonstrativo-Contabil-Agosto-_2021.pdf', 9),
  ('exercicio_2021_demonstrativo_contabil_setembro_2021', 'exercicio_2021', 'Demonstrativo Contábil - Setembro 2021', date '2022-03-31', 'https://static.goiasec.com.br/upload/transparencia/2022/03/09-Demonstrativo-Contabil-Setembro-_2021.pdf', 10),
  ('exercicio_2021_demonstrativo_contabil_outubro_2021', 'exercicio_2021', 'Demonstrativo Contábil - Outubro 2021', date '2022-03-31', 'https://static.goiasec.com.br/upload/transparencia/2022/03/10-Demonstrativo-Contabil-Outubro-_2021.pdf', 11),
  ('exercicio_2021_demonstrativo_contabil_novembro_2021', 'exercicio_2021', 'Demonstrativo Contábil - Novembro 2021', date '2022-03-31', 'https://static.goiasec.com.br/upload/transparencia/2022/03/11-Demonstrativo-Contabil-Novembro-_2021.pdf', 12),
  ('exercicio_2021_demonstrativo_contabil_dezembro_2021', 'exercicio_2021', 'Demonstrativo Contábil - Dezembro 2021', date '2022-03-31', 'https://static.goiasec.com.br/upload/transparencia/2022/03/12-Demonstrativo-Contabil-Dezembro-_2021.pdf', 13),
  ('exercicio_2022_demonstracoes_contabeis_2022_2021', 'exercicio_2022', 'Demonstrações Contábeis 2022-2021', date '2023-04-30', 'https://static.goiasec.com.br/upload/transparencia/2023/04/1239gec_demonstracoes-contabeis_compressed.pdf', 0),
  ('exercicio_2022_parecer_do_conselho_fiscal_1o_trimestre_2022', 'exercicio_2022', 'Parecer do Conselho Fiscal 1º Trimestre 2022', date '2023-04-30', 'https://static.goiasec.com.br/upload/transparencia/2023/04/Parecer-do-Conselho-Fiscal-1o-Trimestre-2022.pdf', 1),
  ('exercicio_2022_parecer_do_conselho_fiscal_exercicio_2022', 'exercicio_2022', 'Parecer do Conselho Fiscal - Exercício 2022', date '2023-04-30', 'https://static.goiasec.com.br/upload/transparencia/2023/04/Parecer-do-Conselho-Fiscal-Exercicio-2022.pdf', 2),
  ('exercicio_2022_ata_da_reuniao_conselho_fiscal_marco_2022', 'exercicio_2022', 'Ata da Reunião Conselho Fiscal - Março 2022', date '2023-04-30', 'https://static.goiasec.com.br/upload/transparencia/2023/04/Ata-da-Reuniao-Conselho-Fiscal-Marco-2022.pdf', 3),
  ('exercicio_2022_ata_da_reuniao_extraordinaria_do_conselho_deliberativo_abril', 'exercicio_2022', 'Ata da Reunião Extraordinária do Conselho Deliberativo - Abril 2022', date '2023-04-30', 'https://static.goiasec.com.br/upload/transparencia/2023/04/Ata-da-Reuniao-Extraordinaria-do-Conselho-Deliberativo-Abril-2022.pdf', 4),
  ('exercicio_2022_ata_da_reuniao_extraordinaria_do_conselho_deliberativo_agost', 'exercicio_2022', 'Ata da Reunião Extraordinária do Conselho Deliberativo - Agosto 2022', date '2023-04-30', 'https://static.goiasec.com.br/upload/transparencia/2023/04/Ata-da-Reuniao-Extraordinaria-do-Conselho-Deliberativo-Agosto-2022.pdf', 5),
  ('exercicio_2022_demonstrativo_contabil_janeiro_2022', 'exercicio_2022', 'Demonstrativo Contábil - Janeiro 2022', date '2023-04-30', 'https://static.goiasec.com.br/upload/transparencia/2023/04/01-Demonstrativo-Contabil-Janeiro-_2022.pdf', 6),
  ('exercicio_2022_demonstrativo_contabil_fevereiro_2022', 'exercicio_2022', 'Demonstrativo Contábil - Fevereiro 2022', date '2023-04-30', 'https://static.goiasec.com.br/upload/transparencia/2023/04/02-Demonstrativo-Contabil-Fevereiro-_2022.pdf', 7),
  ('exercicio_2022_demonstrativo_contabil_marco_2022', 'exercicio_2022', 'Demonstrativo Contábil - Março 2022', date '2023-04-30', 'https://static.goiasec.com.br/upload/transparencia/2023/04/03-Demonstrativo-Contabil-Marco-_2022.pdf', 8),
  ('exercicio_2022_demonstrativo_contabil_abril_2022', 'exercicio_2022', 'Demonstrativo Contábil - Abril 2022', date '2023-04-30', 'https://static.goiasec.com.br/upload/transparencia/2023/04/04-Demonstrativo-Contabil-Abril-_2022.pdf', 9),
  ('exercicio_2022_demonstrativo_contabil_maio_2022', 'exercicio_2022', 'Demonstrativo Contábil - Maio 2022', date '2023-04-30', 'https://static.goiasec.com.br/upload/transparencia/2023/04/05-Demonstrativo-Contabil-Maio-_2022.pdf', 10),
  ('exercicio_2022_demonstrativo_contabil_junho_2022', 'exercicio_2022', 'Demonstrativo Contábil - Junho 2022', date '2023-04-30', 'https://static.goiasec.com.br/upload/transparencia/2023/04/06-Demonstrativo-Contabil-Junho-_2022.pdf', 11),
  ('exercicio_2022_demonstrativo_contabil_julho_2022', 'exercicio_2022', 'Demonstrativo Contábil - Julho 2022', date '2023-04-30', 'https://static.goiasec.com.br/upload/transparencia/2023/04/07-Demonstrativo-Contabil-Julho-_2022.pdf', 12),
  ('exercicio_2022_demonstrativo_contabil_agosto_2022', 'exercicio_2022', 'Demonstrativo Contábil - Agosto 2022', date '2023-04-30', 'https://static.goiasec.com.br/upload/transparencia/2023/04/08-Demonstrativo-Contabil-Agosto-_2022.pdf', 13),
  ('exercicio_2022_demonstrativo_contabil_setembro_2022', 'exercicio_2022', 'Demonstrativo Contábil - Setembro 2022', date '2023-04-30', 'https://static.goiasec.com.br/upload/transparencia/2023/04/07-Demonstrativo-Contabil-Setembro-_2022.pdf', 14),
  ('exercicio_2022_demonstrativo_contabil_outubro_2022', 'exercicio_2022', 'Demonstrativo Contábil - Outubro 2022', date '2023-04-30', 'https://static.goiasec.com.br/upload/transparencia/2023/04/10-Demonstrativo-Contabil-Outubro-_2022.pdf', 15),
  ('exercicio_2022_demonstrativo_contabil_novembro_2022', 'exercicio_2022', 'Demonstrativo Contábil - Novembro 2022', date '2023-04-30', 'https://static.goiasec.com.br/upload/transparencia/2023/04/11-Demonstrativo-Contabil-Novembro-_2022.pdf', 16),
  ('exercicio_2022_demonstrativo_contabil_dezembro_2022', 'exercicio_2022', 'Demonstrativo Contábil - Dezembro 2022', date '2023-04-30', 'https://static.goiasec.com.br/upload/transparencia/2023/04/12-Demonstrativo-Contabil-Dezembro-_2022.pdf', 17),
  ('exercicio_2023_demonstracoes_contabeis_2023_2022', 'exercicio_2023', 'Demonstrações Contábeis 2023-2022', date '2023-08-15', 'https://static.goiasec.com.br/upload/transparencia/2023/08/Demonstracoes-Contabeis-2023-2022.pdf', 0),
  ('exercicio_2023_parecer_conselho_fiscal_exercicio_2023', 'exercicio_2023', 'Parecer Conselho Fiscal - Exercício 2023', date '2023-08-15', 'https://static.goiasec.com.br/upload/transparencia/2023/08/Parecer-Conselho-Fiscal-Exercicio-2023.pdf', 1),
  ('exercicio_2023_ata_da_reuniao_extraordinaria_do_conselho_deliberativo_marco', 'exercicio_2023', 'Ata da Reunião Extraordinária do Conselho Deliberativo - Março 2023', date '2023-08-15', 'https://static.goiasec.com.br/upload/transparencia/2023/08/Ata-da-Reuniao-Extraordinaria-do-Conselho-Deliberativo-Marco-2023.pdf', 2),
  ('exercicio_2023_ata_da_reuniao_extraordinaria_do_conselho_deliberativo_abril', 'exercicio_2023', 'Ata da Reunião Extraordinária do Conselho Deliberativo - Abril 2023', date '2023-08-15', 'https://static.goiasec.com.br/upload/transparencia/2023/08/Ata-da-Reuniao-Extraordinaria-do-Conselho-Deliberativo-Abril-2023.pdf', 3),
  ('exercicio_2023_demonstrativo_contabil_janeiro_2023', 'exercicio_2023', 'Demonstrativo Contábil - Janeiro 2023', date '2023-08-15', 'https://static.goiasec.com.br/upload/transparencia/2023/08/01-Demonstrativo-Contabil-Janeiro-2023.pdf', 4),
  ('exercicio_2023_demonstrativo_contabil_fevereiro_2023', 'exercicio_2023', 'Demonstrativo Contábil - Fevereiro 2023', date '2023-08-15', 'https://static.goiasec.com.br/upload/transparencia/2023/08/02-Demonstrativo-Contabil-Fevereiro-2023.pdf', 5),
  ('exercicio_2023_demonstrativo_contabil_marco_2023', 'exercicio_2023', 'Demonstrativo Contábil - Março 2023', date '2023-08-15', 'https://static.goiasec.com.br/upload/transparencia/2023/08/03-Demonstrativo-Contabil-Marco-2023.pdf', 6),
  ('exercicio_2023_demonstrativo_contabil_abril_2023', 'exercicio_2023', 'Demonstrativo Contábil - Abril 2023', date '2023-08-15', 'https://static.goiasec.com.br/upload/transparencia/2023/08/04-Demonstrativo-Contabil-Abril-2023.pdf', 7),
  ('exercicio_2023_demonstrativo_contabil_maio_2023', 'exercicio_2023', 'Demonstrativo Contábil - Maio 2023', date '2023-08-15', 'https://static.goiasec.com.br/upload/transparencia/2023/08/05-Demonstrativo-Contabil-Maio-2023.pdf', 8),
  ('exercicio_2023_demonstrativo_contabil_junho_2023', 'exercicio_2023', 'Demonstrativo Contábil - Junho 2023', date '2023-08-15', 'https://static.goiasec.com.br/upload/transparencia/2023/08/06-Demonstrativo-Contabil-Junho-2023.pdf', 9),
  ('exercicio_2023_demonstrativo_contabil_julho_2023', 'exercicio_2023', 'Demonstrativo Contábil - Julho 2023', date '2023-08-15', 'https://static.goiasec.com.br/upload/transparencia/2023/08/Demonstrativo-Contabil-Julho-2023.pdf', 10),
  ('exercicio_2023_demonstrativo_contabil_agosto_2023', 'exercicio_2023', 'Demonstrativo Contábil - Agosto 2023', date '2023-08-15', 'https://static.goiasec.com.br/upload/transparencia/2023/08/Demonstrativo-Contabil-Agosto-2023.pdf', 11),
  ('exercicio_2023_demonstrativo_contabil_setembro_2023', 'exercicio_2023', 'Demonstrativo Contábil - Setembro 2023', date '2023-08-15', 'https://static.goiasec.com.br/upload/transparencia/2023/08/Demonstrativos_GEC_Setembro-_2023-1.pdf', 12),
  ('exercicio_2023_demonstrativo_contabil_outubro_2023', 'exercicio_2023', 'Demonstrativo Contábil - Outubro 2023', date '2023-08-15', 'https://static.goiasec.com.br/upload/transparencia/2023/08/Demonstrativos_GEC_Outubro-_2023.pdf', 13),
  ('exercicio_2023_demonstrativo_contabil_novembro_2023', 'exercicio_2023', 'Demonstrativo Contábil - Novembro 2023', date '2023-08-15', 'https://static.goiasec.com.br/upload/transparencia/2023/08/Demonstrativos_GEC_30.11.pdf', 14),
  ('exercicio_2023_demonstrativo_contabil_dezembro_2023', 'exercicio_2023', 'Demonstrativo Contábil - Dezembro 2023', date '2023-08-15', 'https://static.goiasec.com.br/upload/transparencia/2023/08/Demonstrativos_GEC_31.12.pdf', 15),
  ('exercicio_2023_portaria_no_06_2023', 'exercicio_2023', 'Portaria Nº 06/2023', date '2023-08-15', 'https://static.goiasec.com.br/upload/transparencia/2023/08/PORTARIA-06-2023.pdf', 16),
  ('exercicio_2024_relatorio_da_auditoria_2024', 'exercicio_2024', 'Relatório da Auditoria 2024', date '2024-03-08', 'https://static.goiasec.com.br/upload/transparencia/2024/03/3105-25-_Relatorio-dos-Auditores_Goias-Esporte-Clube_31.12.pdf', 0),
  ('exercicio_2024_demonstracoes_contabeis_2024_2023', 'exercicio_2024', 'Demonstrações Contábeis 2024-2023', date '2024-03-08', 'https://static.goiasec.com.br/upload/transparencia/2024/03/GOIAS-Esporte-Clube-Balanco-28-04-Ass.-Aroldo.pdf', 1),
  ('exercicio_2024_demonstrativo_contabil_dezembro_2024', 'exercicio_2024', 'Demonstrativo Contábil - Dezembro 2024', date '2024-03-08', 'https://static.goiasec.com.br/upload/transparencia/2024/03/Demonstrativo-Contabil-Dezembro-2024.pdf', 2),
  ('exercicio_2024_demonstrativo_contabil_novembro_2024', 'exercicio_2024', 'Demonstrativo Contábil - Novembro 2024', date '2024-03-08', 'https://static.goiasec.com.br/upload/transparencia/2024/03/Demonstrativos_GEC_Novembro-_2024-assinado.pdf', 3),
  ('exercicio_2024_demonstrativo_contabil_outubro_2024', 'exercicio_2024', 'Demonstrativo Contábil - Outubro 2024', date '2024-03-08', 'https://static.goiasec.com.br/upload/transparencia/2024/03/Demonstrativos_GEC_Outubro-_2024.pdf', 4),
  ('exercicio_2024_demonstrativo_contabil_setembro_2024', 'exercicio_2024', 'Demonstrativo Contábil - Setembro 2024', date '2024-03-08', 'https://static.goiasec.com.br/upload/transparencia/2024/03/Demonstrativos_GEC_Setembro_2024-PDF.pdf', 5),
  ('exercicio_2024_demonstrativo_contabil_agosto_2024', 'exercicio_2024', 'Demonstrativo Contábil - Agosto 2024', date '2024-03-08', 'https://static.goiasec.com.br/upload/transparencia/2024/03/Demonstrativo-Contabil-Agosto-2024.pdf', 6),
  ('exercicio_2024_demonstrativo_contabil_julho_2024', 'exercicio_2024', 'Demonstrativo Contábil - Julho 2024', date '2024-03-08', 'https://static.goiasec.com.br/upload/transparencia/2024/03/Demonstrativo-Contabil-Julho-2024.pdf', 7),
  ('exercicio_2024_demonstrativo_contabil_junho_2024', 'exercicio_2024', 'Demonstrativo Contábil - Junho 2024', date '2024-03-08', 'https://static.goiasec.com.br/upload/transparencia/2024/03/Demonstrativos_GEC_Junho_2024-PDF.pdf', 8),
  ('exercicio_2024_demonstrativo_contabil_maio_2024', 'exercicio_2024', 'Demonstrativo Contábil - Maio 2024', date '2024-03-08', 'https://static.goiasec.com.br/upload/transparencia/2024/03/Demonstrativos_GEC_Maio_2024-PDF.pdf', 9),
  ('exercicio_2024_demonstrativo_contabil_abril_2024', 'exercicio_2024', 'Demonstrativo Contábil - Abril 2024', date '2024-03-08', 'https://static.goiasec.com.br/upload/transparencia/2024/03/Demonstrativos_GEC_Abril_2024-PDF.pdf', 10),
  ('exercicio_2024_demonstrativo_contabil_marco_2024', 'exercicio_2024', 'Demonstrativo Contábil - Março 2024', date '2024-03-08', 'https://static.goiasec.com.br/upload/transparencia/2024/03/Demonstrativos_GEC_Marco_2024-PDF.pdf', 11),
  ('exercicio_2024_demonstrativo_contabil_fevereiro_2024', 'exercicio_2024', 'Demonstrativo Contábil - Fevereiro 2024', date '2024-03-08', 'https://static.goiasec.com.br/upload/transparencia/2024/03/Demonstrativos_GEC_Fevereiro-_2024-PDF.pdf', 12),
  ('exercicio_2024_demonstrativo_contabil_janeiro_2024', 'exercicio_2024', 'Demonstrativo Contábil - Janeiro 2024', date '2024-03-08', 'https://static.goiasec.com.br/upload/transparencia/2024/03/Demonstrativos_GEC_Janeiro-_2024-PDF.pdf', 13),
  ('exercicio_2024_resolucao_01_2024_conselho_deliberativo', 'exercicio_2024', 'Resolução 01-2024 - Conselho Deliberativo', date '2024-03-08', 'https://static.goiasec.com.br/upload/transparencia/2024/03/Resolucao-01.2024-Conselho-Deliberativo-Goias-EC-Regimento-Eleitoral-Assinado.pdf', 14),
  ('exercicio_2024_parecer_conselho_fiscal_exercicio_2024', 'exercicio_2024', 'Parecer Conselho Fiscal – Exercício 2024', date '2026-05-13', 'https://static.goiasec.com.br/upload/transparencia/dd3d73db9b684a0a89f5e59feafd877b.pdf', 15),
  ('exercicio_2025_demonstrativo_contabil_janeiro_2025', 'exercicio_2025', 'Demonstrativo Contábil - Janeiro 2025', date '2025-02-28', 'https://static.goiasec.com.br/upload/transparencia/2025/02/Demonstrativos_GEC_Janeiro_2025-v.05-031.pdf', 0),
  ('exercicio_2025_demonstrativo_contabil_fevereiro_2025', 'exercicio_2025', 'Demonstrativo Contábil - Fevereiro 2025', date '2025-02-28', 'https://static.goiasec.com.br/upload/transparencia/2025/02/Demonstrativos_GEC_Fevereiro_2025-1.pdf', 1),
  ('exercicio_2025_demonstrativo_contabil_marco_2025', 'exercicio_2025', 'Demonstrativo Contábil - Março 2025', date '2025-02-28', 'https://static.goiasec.com.br/upload/transparencia/2025/02/Demonstrativos_GEC_Marco_2025-V.final_.pdf', 2),
  ('exercicio_2025_demonstrativo_contabil_abril_2025', 'exercicio_2025', 'Demonstrativo Contábil - Abril 2025', date '2025-02-28', 'https://static.goiasec.com.br/upload/transparencia/2025/02/Demonstrativos-GEC-04-2025.pdf', 3),
  ('exercicio_2025_demonstrativo_contabil_maio_2025', 'exercicio_2025', 'Demonstrativo Contábil - Maio 2025', date '2025-02-28', 'https://static.goiasec.com.br/upload/transparencia/2025/02/Demonstrativos-GEC-05-2025.pdf', 4),
  ('exercicio_2025_demonstrativo_contabil_junho_2025', 'exercicio_2025', 'Demonstrativo Contábil - Junho 2025', date '2025-02-28', 'https://static.goiasec.com.br/upload/transparencia/2025/02/Demonstrativos-GEC-06-2025.pdf', 5),
  ('exercicio_2025_demonstrativo_contabil_julho_2025', 'exercicio_2025', 'Demonstrativo Contábil - Julho 2025', date '2025-08-13', 'https://static.goiasec.com.br/upload/transparencia/5141b50b365b4865ba049d360cff9fc6.pdf', 6),
  ('exercicio_2025_demonstrativo_contabil_agosto_2025', 'exercicio_2025', 'Demonstrativo Contábil - Agosto 2025', date '2025-09-11', 'https://static.goiasec.com.br/upload/transparencia/febd94ade8e44a6eb900a96ee710b67f.pdf', 7),
  ('exercicio_2025_demonstrativo_contabil_setembro_2025', 'exercicio_2025', 'Demonstrativo Contábil - Setembro 2025', date '2025-10-18', 'https://static.goiasec.com.br/upload/transparencia/88f86ed186204cac8c8d224faa56c052.pdf', 8),
  ('exercicio_2025_demonstrativo_contabil_outubro_2025', 'exercicio_2025', 'Demonstrativo Contábil - Outubro 2025', date '2025-11-14', 'https://static.goiasec.com.br/upload/transparencia/4bbf7f5105264b418e62f3a28c57757a.pdf', 9),
  ('exercicio_2025_demonstrativo_contabil_novembro_2025', 'exercicio_2025', 'Demonstrativo Contábil - Novembro 2025', date '2025-12-10', 'https://static.goiasec.com.br/upload/transparencia/a2fc5bfe5a384bca9b3dc7a4391e3ee3.pdf', 10),
  ('exercicio_2025_demonstrativo_contabil_dezembro_2025', 'exercicio_2025', 'Demonstrativo Contábil - Dezembro 2025', date '2026-01-22', 'https://static.goiasec.com.br/upload/transparencia/351e57347215427b8ac07f7ba578720f.pdf', 11),
  ('exercicio_2025_demonstracoes_contabeis_2025_2024', 'exercicio_2025', 'Demonstrações Contábeis 2025 - 2024', date '2026-04-29', 'https://static.goiasec.com.br/upload/transparencia/a99e7679802e4d2297c3b5b212ec41b3.pdf', 12),
  ('exercicio_2025_parecer_conselho_fiscal_exercicio_2025', 'exercicio_2025', 'Parecer Conselho Fiscal – Exercício 2025', date '2026-05-13', 'https://static.goiasec.com.br/upload/transparencia/a5b2f3acc4424003918ba52fef3ef4e9.pdf', 13),
  ('exercicio_2026_demonstrativo_contabil_janeiro_2026', 'exercicio_2026', 'Demonstrativo Contábil - Janeiro 2026', date '2026-02-27', 'https://static.goiasec.com.br/upload/transparencia/0f9aa3f8080f47039fb46af548c2141f.pdf', 0),
  ('exercicio_2026_demonstrativo_contabil_fevereiro_2026', 'exercicio_2026', 'Demonstrativo Contábil - Fevereiro 2026', date '2026-04-01', 'https://static.goiasec.com.br/upload/transparencia/bc0b6181c6774cd0bab964a48ef37446.pdf', 1),
  ('exercicio_2026_demonstrativo_contabil_marco_2026', 'exercicio_2026', 'Demonstrativo Contábil - Março 2026', date '2026-04-17', 'https://static.goiasec.com.br/upload/transparencia/6166fe45b7504ab0b08317ebf9a8dc1a.pdf', 2),
  ('exercicio_2026_demonstrativo_contabil_abril_2026', 'exercicio_2026', 'Demonstrativo Contábil - Abril 2026', date '2026-05-19', 'https://static.goiasec.com.br/upload/transparencia/6d54b1974fe24862ab51f6ef2adccfed.pdf', 3),
  ('exercicio_2026_demonstrativo_contabil_maio_2026', 'exercicio_2026', 'Demonstrativo Contábil - Maio 2026', date '2026-06-19', 'https://static.goiasec.com.br/upload/transparencia/da06884b828d46959b1cc91ac0e74101.pdf', 4),
  ('exercicio_2026_demonstrativo_contabil_junho_2026', 'exercicio_2026', 'Demonstrativo Contábil - Junho 2026', date '2026-07-13', 'https://static.goiasec.com.br/upload/transparencia/0c4bac9d39b64af6b05e2b1ebbfbf777.pdf', 5),
  ('exercicio_2026_demonstrativo_contabil_julho_2026', 'exercicio_2026', 'Demonstrativo Contábil - Julho 2026', date '2026-08-24', 'https://static.goiasec.com.br/upload/transparencia/1ca53e4216a74cb994a744d5b3d991e5.pdf', 6),
  ('relatorio_de_transparencia_e_igualdade_salarial_2o_semestre_2024', 'relatorio_de_transparencia_e_igualdade_salarial', '2º Semestre 2024', date '2024-03-29', 'https://static.goiasec.com.br/upload/transparencia/2024/03/Relatorio-de-Transparencia-Igualdade-Salarial.pdf', 0),
  ('relatorio_de_transparencia_e_igualdade_salarial_1o_semestre_2024', 'relatorio_de_transparencia_e_igualdade_salarial', '1º Semestre 2024', date '2024-03-29', 'https://static.goiasec.com.br/upload/transparencia/43d6a19e7d094bb5b03a845a627dc8cf.pdf', 1),
  ('relatorio_de_transparencia_e_igualdade_salarial_1o_semestre_2025', 'relatorio_de_transparencia_e_igualdade_salarial', '1º Semestre 2025', date '2025-10-01', 'https://static.goiasec.com.br/upload/transparencia/3795b7d53b98493abe728f53f5c984f9.pdf', 2),
  ('relatorio_de_transparencia_e_igualdade_salarial_2o_semestre_2025', 'relatorio_de_transparencia_e_igualdade_salarial', '2º Semestre 2025', date '2025-10-01', 'https://static.goiasec.com.br/upload/transparencia/1944d2958b8642b2a466c2dd98f2ad2c.pdf', 3),
  ('relatorio_de_transparencia_e_igualdade_salarial_1o_semestre_2026', 'relatorio_de_transparencia_e_igualdade_salarial', '1º Semestre 2026', date '2026-04-28', 'https://static.goiasec.com.br/upload/transparencia/ada763b0033c467b84bb5a2803fc2cf1.pdf', 4)
on conflict (id) do update set
  topic_id = excluded.topic_id,
  title = excluded.title,
  document_date = excluded.document_date,
  pdf_url = excluded.pdf_url,
  sort_order = excluded.sort_order;
