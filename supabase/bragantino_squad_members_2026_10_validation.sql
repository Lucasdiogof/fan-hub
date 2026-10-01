-- Validação do elenco atual do Bragantino (auditoria 2026-10-01).
-- Fonte: API oficial do clube (redbullbragantino.com, person-profiles do time
-- masculino profissional) para número, nascimento, nacionalidade, foto e
-- Instagram; altura e pé (a API oficial não publica) do ogol.com.br, com a
-- Wikipédia como corroboração, identidade confirmada pela data de nascimento.
-- Só campos que estavam NULL (cada UPDATE confere o valor antigo) e um atleta
-- novo do elenco oficial (Patrick, #28). Ficaram de fora, por divergência
-- entre fontes boas: altura de Gabriel Girotto, Pitta, Tiago Volpi,
-- Rodriguinho, Lucas Barbosa, Gustavo Neves e Agustín Sant'Anna; a de Cauê
-- não tem fonte. Nascimento do Eric Ramires mantido como o oficial
-- (2000-10-10; ogol/Wikipédia EN dizem 2000-08-10).
-- ATUALIZAÇÃO (mesmo dia): a pesquisa de pendências confirmou 2000-08-10 pela
-- CBF e 4 das alturas acima — ver bragantino_squad_members_2026_10_pendencias.sql,
-- que roda DEPOIS deste.
-- Ryan Augusto e Bruninho NÃO constam no elenco oficial hoje (decisão do
-- usuário se seguem ativos); os dados biográficos deles são da pessoa e
-- entram mesmo assim.
--
-- Rodar SÓ no projeto Supabase do BRAGANTINO (yrgyzkaaudyzmsqwzecj).
-- Idempotente.

do $$
begin
  if not exists (select 1 from public.clubs where id = '51683d2a-ea1d-57c6-8014-996146f242e7') then
    raise exception 'este não é o projeto Supabase do Bragantino -- PARE';
  end if;
end $$;

update public.squad_members set height_cm = 190, updated_at = now() where id = 'cleiton' and club_id = '51683d2a-ea1d-57c6-8014-996146f242e7' and height_cm is null; -- https://www.ogol.com.br/jogador/cleiton/504363 | https://pt.wikipedia.org/wiki/Cleiton_Schwengber
update public.squad_members set foot = 'Destro', updated_at = now() where id = 'cleiton' and club_id = '51683d2a-ea1d-57c6-8014-996146f242e7' and foot is null; -- https://www.ogol.com.br/jogador/cleiton/504363 | https://pt.wikipedia.org/wiki/Cleiton_Schwengber
update public.squad_members set height_cm = 185, updated_at = now() where id = 'guzman-rodriguez' and club_id = '51683d2a-ea1d-57c6-8014-996146f242e7' and height_cm is null; -- https://www.ogol.com.br/jogador/guzman-rodriguez/749380 | https://pt.wikipedia.org/wiki/Guzm%C3%A1n_Rodr%C3%ADguez
update public.squad_members set foot = 'Destro', updated_at = now() where id = 'guzman-rodriguez' and club_id = '51683d2a-ea1d-57c6-8014-996146f242e7' and foot is null; -- https://www.ogol.com.br/jogador/guzman-rodriguez/749380 | https://pt.wikipedia.org/wiki/Guzm%C3%A1n_Rodr%C3%ADguez
update public.squad_members set height_cm = 196, updated_at = now() where id = 'eduardo-santos' and club_id = '51683d2a-ea1d-57c6-8014-996146f242e7' and height_cm is null; -- https://www.ogol.com.br/jogador/eduardo-santos/547773 | https://pt.wikipedia.org/wiki/Eduardo_Santos
update public.squad_members set foot = 'Destro', updated_at = now() where id = 'eduardo-santos' and club_id = '51683d2a-ea1d-57c6-8014-996146f242e7' and foot is null; -- https://www.ogol.com.br/jogador/eduardo-santos/547773
update public.squad_members set height_cm = 195, updated_at = now() where id = 'alix-vinicius' and club_id = '51683d2a-ea1d-57c6-8014-996146f242e7' and height_cm is null; -- https://www.ogol.com.br/jogador/alix-vinicius/720559
update public.squad_members set foot = 'Destro', updated_at = now() where id = 'alix-vinicius' and club_id = '51683d2a-ea1d-57c6-8014-996146f242e7' and foot is null; -- https://www.ogol.com.br/jogador/alix-vinicius/720559
update public.squad_members set height_cm = 178, updated_at = now() where id = 'fabinho' and club_id = '51683d2a-ea1d-57c6-8014-996146f242e7' and height_cm is null; -- https://www.ogol.com.br/jogador/fabinho/609279 | https://pt.wikipedia.org/wiki/Fabinho_%28futebolista%2C_2002%29
update public.squad_members set foot = 'Destro', updated_at = now() where id = 'fabinho' and club_id = '51683d2a-ea1d-57c6-8014-996146f242e7' and foot is null; -- https://www.ogol.com.br/jogador/fabinho/609279 | https://pt.wikipedia.org/wiki/Fabinho_%28futebolista%2C_2002%29
update public.squad_members set foot = 'Destro', updated_at = now() where id = 'gabriel' and club_id = '51683d2a-ea1d-57c6-8014-996146f242e7' and foot is null; -- https://www.ogol.com.br/jogador/gabriel/239330 | https://pt.wikipedia.org/wiki/Gabriel_Girotto_Franco
update public.squad_members set foot = 'Destro', updated_at = now() where id = 'pitta' and club_id = '51683d2a-ea1d-57c6-8014-996146f242e7' and foot is null; -- https://www.ogol.com.br/jogador/isidro-pitta/629950 | https://pt.wikipedia.org/wiki/Isidro_Pitta
update public.squad_members set height_cm = 183, updated_at = now() where id = 'vanderlan-barbosa' and club_id = '51683d2a-ea1d-57c6-8014-996146f242e7' and height_cm is null; -- https://www.ogol.com.br/jogador/vanderlan/717251 | https://pt.wikipedia.org/wiki/Vanderlan
update public.squad_members set foot = 'Canhoto', updated_at = now() where id = 'vanderlan-barbosa' and club_id = '51683d2a-ea1d-57c6-8014-996146f242e7' and foot is null; -- https://www.ogol.com.br/jogador/vanderlan/717251 | https://pt.wikipedia.org/wiki/Vanderlan
update public.squad_members set height_cm = 189, updated_at = now() where id = 'gustavo-marques' and club_id = '51683d2a-ea1d-57c6-8014-996146f242e7' and height_cm is null; -- https://www.ogol.com.br/jogador/gustavo-marques/632463 | https://pt.wikipedia.org/wiki/Gustavo_Marques
update public.squad_members set foot = 'Destro', updated_at = now() where id = 'gustavo-marques' and club_id = '51683d2a-ea1d-57c6-8014-996146f242e7' and foot is null; -- https://www.ogol.com.br/jogador/gustavo-marques/632463
update public.squad_members set foot = 'Destro', updated_at = now() where id = 'tiago-volpi' and club_id = '51683d2a-ea1d-57c6-8014-996146f242e7' and foot is null; -- https://www.ogol.com.br/jogador/tiago-volpi/138651 | https://pt.wikipedia.org/wiki/Tiago_Volpi
update public.squad_members set foot = 'Destro', updated_at = now() where id = 'rodriguinho' and club_id = '51683d2a-ea1d-57c6-8014-996146f242e7' and foot is null; -- https://www.ogol.com.br/jogador/rodriguinho/743295 | https://pt.wikipedia.org/wiki/Rodriguinho_%28futebolista%2C_2004%29
update public.squad_members set foot = 'Canhoto', updated_at = now() where id = 'lucas-barbosa' and club_id = '51683d2a-ea1d-57c6-8014-996146f242e7' and foot is null; -- https://www.ogol.com.br/jogador/lucas-barbosa/693761
update public.squad_members set foot = 'Destro', updated_at = now() where id = 'gustavo-neves' and club_id = '51683d2a-ea1d-57c6-8014-996146f242e7' and foot is null; -- https://www.ogol.com.br/jogador/gustavinho/790548
update public.squad_members set foot = 'Destro', updated_at = now() where id = 'agustin-santanna' and club_id = '51683d2a-ea1d-57c6-8014-996146f242e7' and foot is null; -- https://www.ogol.com.br/jogador/agustin-sant-anna/483111
update public.squad_members set height_cm = 176, updated_at = now() where id = 'juninho-capixaba' and club_id = '51683d2a-ea1d-57c6-8014-996146f242e7' and height_cm is null; -- https://www.ogol.com.br/jogador/juninho-capixaba/487501 | https://pt.wikipedia.org/wiki/Juninho_Capixaba
update public.squad_members set foot = 'Canhoto', updated_at = now() where id = 'juninho-capixaba' and club_id = '51683d2a-ea1d-57c6-8014-996146f242e7' and foot is null; -- https://www.ogol.com.br/jogador/juninho-capixaba/487501 | https://pt.wikipedia.org/wiki/Juninho_Capixaba
update public.squad_members set height_cm = 178, updated_at = now() where id = 'andres-hurtado' and club_id = '51683d2a-ea1d-57c6-8014-996146f242e7' and height_cm is null; -- https://www.ogol.com.br/jogador/andres-hurtado/839238 | https://pt.wikipedia.org/wiki/Andr%C3%A9s_Hurtado
update public.squad_members set foot = 'Destro', updated_at = now() where id = 'andres-hurtado' and club_id = '51683d2a-ea1d-57c6-8014-996146f242e7' and foot is null; -- https://www.ogol.com.br/jogador/andres-hurtado/839238 | https://pt.wikipedia.org/wiki/Andr%C3%A9s_Hurtado
update public.squad_members set height_cm = 183, updated_at = now() where id = 'matheus-fernandes' and club_id = '51683d2a-ea1d-57c6-8014-996146f242e7' and height_cm is null; -- https://www.ogol.com.br/jogador/matheus-fernandes/480994 | https://pt.wikipedia.org/wiki/Matheus_Fernandes_%28futebolista%29
update public.squad_members set foot = 'Destro', updated_at = now() where id = 'matheus-fernandes' and club_id = '51683d2a-ea1d-57c6-8014-996146f242e7' and foot is null; -- https://www.ogol.com.br/jogador/matheus-fernandes/480994 | https://pt.wikipedia.org/wiki/Matheus_Fernandes_%28futebolista%29
update public.squad_members set height_cm = 190, updated_at = now() where id = 'fabricio' and club_id = '51683d2a-ea1d-57c6-8014-996146f242e7' and height_cm is null; -- https://www.ogol.com.br/jogador/fabricio/547242
update public.squad_members set foot = 'Destro', updated_at = now() where id = 'fabricio' and club_id = '51683d2a-ea1d-57c6-8014-996146f242e7' and foot is null; -- https://www.ogol.com.br/jogador/fabricio/547242
update public.squad_members set foot = 'Canhoto', updated_at = now() where id = 'caue' and club_id = '51683d2a-ea1d-57c6-8014-996146f242e7' and foot is null; -- https://www.ogol.com.br/jogador/caue-nascimento/973222
update public.squad_members set height_cm = 190, updated_at = now() where id = 'gustavo-reis' and club_id = '51683d2a-ea1d-57c6-8014-996146f242e7' and height_cm is null; -- https://www.ogol.com.br/jogador/gustavo-reis/843054
update public.squad_members set foot = 'Destro', updated_at = now() where id = 'gustavo-reis' and club_id = '51683d2a-ea1d-57c6-8014-996146f242e7' and foot is null; -- https://www.ogol.com.br/jogador/gustavo-reis/843054
update public.squad_members set height_cm = 182, updated_at = now() where id = 'wallace-yan' and club_id = '51683d2a-ea1d-57c6-8014-996146f242e7' and height_cm is null; -- https://www.ogol.com.br/jogador/wallace-yan/893570 | https://pt.wikipedia.org/wiki/Wallace_Yan
update public.squad_members set foot = 'Destro', updated_at = now() where id = 'wallace-yan' and club_id = '51683d2a-ea1d-57c6-8014-996146f242e7' and foot is null; -- https://www.ogol.com.br/jogador/wallace-yan/893570 | https://pt.wikipedia.org/wiki/Wallace_Yan
update public.squad_members set foot = 'Destro', updated_at = now() where id = 'eric-ramires' and club_id = '51683d2a-ea1d-57c6-8014-996146f242e7' and foot is null; -- https://www.ogol.com.br/jogador/eric-ramires/620649
update public.squad_members set foot = 'Destro', updated_at = now() where id = 'eduardo-sasha' and club_id = '51683d2a-ea1d-57c6-8014-996146f242e7' and foot is null; -- https://www.ogol.com.br/jogador/eduardo-sasha/134110 | https://pt.wikipedia.org/wiki/Eduardo_Sasha
update public.squad_members set height_cm = 175, updated_at = now() where id = 'nacho-sosa' and club_id = '51683d2a-ea1d-57c6-8014-996146f242e7' and height_cm is null; -- https://www.ogol.com.br/jogador/ignacio-sosa/860878 | https://en.wikipedia.org/wiki/Ignacio_Sosa
update public.squad_members set foot = 'Canhoto', updated_at = now() where id = 'herrera' and club_id = '51683d2a-ea1d-57c6-8014-996146f242e7' and foot is null; -- https://www.ogol.com.br/jogador/jose-herrera/988103
update public.squad_members set foot = 'Canhoto', updated_at = now() where id = 'marcelinho' and club_id = '51683d2a-ea1d-57c6-8014-996146f242e7' and foot is null; -- https://www.ogol.com.br/jogador/marcelinho/891328
update public.squad_members set height_cm = 179, updated_at = now() where id = 'ryan-augusto' and club_id = '51683d2a-ea1d-57c6-8014-996146f242e7' and height_cm is null; -- https://www.ogol.com.br/jogador/ryan-augusto/1183688 | https://en.wikipedia.org/wiki/Ryan_Augusto
update public.squad_members set foot = 'Destro', updated_at = now() where id = 'ryan-augusto' and club_id = '51683d2a-ea1d-57c6-8014-996146f242e7' and foot is null; -- https://www.ogol.com.br/jogador/ryan-augusto/1183688
update public.squad_members set foot = 'Destro', updated_at = now() where id = 'bruno-goncalves' and club_id = '51683d2a-ea1d-57c6-8014-996146f242e7' and foot is null; -- https://www.ogol.com.br/jogador/bruninho/691446
update public.squad_members set shirt_number = 47, updated_at = now() where id = 'wallace-yan' and club_id = '51683d2a-ea1d-57c6-8014-996146f242e7' and shirt_number is null; -- https://www.redbullbragantino.com/v3/api/graphql/v1/v3/feed/pt-BR?filter[type]=person-profiles&filter[relationships.tags]=rrn:content:tags:849fbae7-0fd7-45b7-b125-15e15fab9a15:en-INT&sort=athleteNumber&page[limit]=100&rb3Schema=v1:cardList&rb3Locale=br-pt
update public.squad_members set birth_date = '2005-02-08', updated_at = now() where id = 'wallace-yan' and club_id = '51683d2a-ea1d-57c6-8014-996146f242e7' and birth_date is null; -- https://www.redbullbragantino.com/v3/api/graphql/v1/v3/feed/pt-BR?filter[type]=person-profiles&filter[uriSlug]=wallace-yan&page[limit]=1&rb3Locale=br-pt&rb3Schema=v1:structuredData
update public.squad_members set nationality = 'Brasil', updated_at = now() where id = 'wallace-yan' and club_id = '51683d2a-ea1d-57c6-8014-996146f242e7' and nationality is null; -- https://www.redbullbragantino.com/v3/api/graphql/v1/v3/feed/pt-BR?filter[type]=person-profiles&filter[uriSlug]=wallace-yan&page[limit]=1&rb3Locale=br-pt&rb3Schema=v1:structuredData
update public.squad_members set photo_url = 'https://img.redbullbragantino.com/images/f_auto,q_auto,w_400/2026/9/8/qh0vzuljenyiurz1ysa2/wallace-yan', updated_at = now() where id = 'wallace-yan' and club_id = '51683d2a-ea1d-57c6-8014-996146f242e7' and photo_url is null; -- https://www.redbullbragantino.com/v3/api/graphql/v1/v3/feed/pt-BR?filter[type]=person-profiles&filter[relationships.tags]=rrn:content:tags:849fbae7-0fd7-45b7-b125-15e15fab9a15:en-INT&sort=athleteNumber&page[limit]=100&rb3Schema=v1:cardList&rb3Locale=br-pt
update public.squad_members set full_name = 'Wallace Yan de Souza Barreto', updated_at = now() where id = 'wallace-yan' and club_id = '51683d2a-ea1d-57c6-8014-996146f242e7' and full_name = 'Wallace Yan'; -- https://www.ogol.com.br/jogador/wallace-yan/893570
update public.squad_members set birth_date = '2007-09-04', updated_at = now() where id = 'ryan-augusto' and club_id = '51683d2a-ea1d-57c6-8014-996146f242e7' and birth_date is null; -- https://www.ogol.com.br/jogador/ryan-augusto/1183688 | https://en.wikipedia.org/wiki/Ryan_Augusto
update public.squad_members set nationality = 'Brasil', updated_at = now() where id = 'ryan-augusto' and club_id = '51683d2a-ea1d-57c6-8014-996146f242e7' and nationality is null; -- https://www.ogol.com.br/jogador/ryan-augusto/1183688
update public.squad_members set full_name = 'Ryan Augusto Tavares da Silva', updated_at = now() where id = 'ryan-augusto' and club_id = '51683d2a-ea1d-57c6-8014-996146f242e7' and full_name = 'Ryan Augusto'; -- https://www.ogol.com.br/jogador/ryan-augusto/1183688
update public.squad_members set full_name = 'Bruno Gonçalves de Jesus', updated_at = now() where id = 'bruno-goncalves' and club_id = '51683d2a-ea1d-57c6-8014-996146f242e7' and full_name = 'Bruno Gonçalves'; -- https://www.ogol.com.br/jogador/bruninho/691446
-- Patrick: no elenco oficial (#28), fora do banco. Nome completo e altura do ogol (= Wikipédia EN); pé só ogol.
insert into public.squad_members
  (id, club_id, name, full_name, shirt_number, position, position_group, birth_date, nationality, height_cm, foot, photo_url, instagram_url, club_history, sort_order)
values
  ('patrick', '51683d2a-ea1d-57c6-8014-996146f242e7', 'Patrick', 'Patrick Roberto da Silva Campos', 28, 'Volante', 'Volantes', '2004-03-19', 'Brasil', 187, 'Canhoto', 'https://img.redbullbragantino.com/images/f_auto,q_auto,w_400/2026/9/24/kkfomm7uidcwzquhut71/patrick', 'https://www.instagram.com/patrickj_04/', '[]'::jsonb, 92)
on conflict (id) do nothing;

