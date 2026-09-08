// Gera supabase/bragantino_career_players.sql a partir dos dados
// pesquisados (Wikipedia/EN+PT, ogol, imprensa) pra corrigir o dataset raso
// do pacote docs/bragantino_data/new_data/adivinhe_jogador_30_carreiras_v1
// .json (só nomes de clube, sem período/múltiplas passagens/ordem).
//
// READY = período+clube confirmado por fonte, sem conflito real.
// PARTIAL = pelo menos uma passagem confirmada com período; o resto da
// carreira (não confirmado) fica de fora — nunca inventa ano.
// BLOCKED = risco de homônimo/fonte insuficiente — NÃO entra no SQL.
import { writeFileSync } from 'node:fs';

const CLUB_ID = '51683d2a-ea1d-57c6-8014-996146f242e7';

// clubCareer: [{period, team, appearances, goals, loan, isBraga}]
const players = [
  {
    id: 'marcelo_martelotte',
    answer: 'Marcelo Martelotte',
    acceptedAnswers: ['Marcelo Martelotte', 'Martelotte'],
    position: 'Goleiro',
    status: 'READY',
    clubCareer: [
      { period: '1987–1988', team: 'Taubaté' },
      { period: '1989–1996', team: 'Bragantino', isBraga: true },
      { period: '1993', team: 'Santa Cruz', loan: true },
      { period: '1997–1998', team: 'Santos' },
      { period: '2000', team: 'Sport' },
      { period: '2002', team: 'Taubaté' },
    ],
  },
  {
    id: 'nivaldo_penafiel',
    answer: 'Nivaldo',
    acceptedAnswers: ['Nivaldo', 'Nivaldo Penafiel'],
    position: 'Goleiro',
    status: 'PARTIAL',
    note: 'Carreira depois do Palmeiras (1991) não confirmada por fonte — não incluída.',
    clubCareer: [
      { period: '1988', team: 'Noroeste' },
      { period: '1990', team: 'Bragantino', isBraga: true },
      { period: '1991', team: 'Palmeiras' },
    ],
  },
  {
    id: 'gil_baiano',
    answer: 'Gil Baiano',
    acceptedAnswers: ['Gil Baiano', 'José Gildásio Pereira de Matos'],
    position: 'Lateral-direito',
    status: 'READY',
    clubCareer: [
      { period: '1987–1988', team: 'Guarani' },
      { period: '1988–1993', team: 'Bragantino', appearances: 62, isBraga: true },
      { period: '1993–1994', team: 'Palmeiras', appearances: 7 },
      { period: '1994', team: 'Vitória', appearances: 19 },
      { period: '1995–1996', team: 'Paraná', appearances: 20 },
      { period: '1996–1997', team: 'Sporting CP' },
      { period: '1998', team: 'Ituano' },
      { period: '1998', team: 'Paraná', appearances: 9 },
      { period: '1999', team: 'Bragantino', isBraga: true },
      { period: '2000', team: 'Comercial-SP' },
      { period: '2000', team: 'Paraná', appearances: 4 },
      { period: '2001', team: 'XV de Piracicaba' },
      { period: '2002', team: 'Bragantino', isBraga: true },
    ],
  },
  {
    id: 'biro_biro_ribeiro',
    answer: 'Biro-Biro',
    acceptedAnswers: ['Biro-Biro', 'Gilberto Ribeiro de Carvalho'],
    position: 'Lateral-esquerdo',
    status: 'READY',
    note: 'Sequência corrigida via Wikipédia PT — pacote original listava clubes (Ituano/Palmeiras/Santo André/Paysandu) sem fonte encontrada.',
    clubCareer: [
      { period: '1982–1984', team: 'Santos' },
      { period: '1985–1992', team: 'Bragantino', isBraga: true },
      { period: '1992', team: 'Sport' },
      { period: '1993', team: 'Corinthians', appearances: 8, goals: 0 },
      { period: '1993', team: 'Sport' },
      { period: '1996', team: 'Bragantino', isBraga: true },
      { period: '1996–1997', team: 'XV de Piracicaba' },
    ],
  },
  {
    id: 'junior_paulista',
    answer: 'Júnior Paulista',
    acceptedAnswers: ['Júnior Paulista', 'Antônio Carlos Ribeiro Júnior'],
    position: 'Zagueiro',
    status: 'PARTIAL',
    note: 'Anos exatos de saída do Bragantino e das passagens seguintes (Atlético-MG/América-MG/Bahia/Fortaleza) não confirmados.',
    clubCareer: [
      { period: '1988', team: 'Bragantino', isBraga: true },
    ],
  },
  {
    id: 'nei_bragantino',
    answer: 'Nei',
    acceptedAnswers: ['Nei'],
    position: 'Zagueiro',
    status: 'PARTIAL',
    note: 'Só o período confirmado no Bragantino (1990–1991, capitão). Clubes antes/depois do pacote original não confirmados — fonte inclusive sugere carreira posterior ao Bragantino, contrariando a ordem do pacote.',
    clubCareer: [{ period: '1990–1991', team: 'Bragantino', isBraga: true }],
  },
  {
    id: 'pintado',
    answer: 'Pintado',
    acceptedAnswers: ['Pintado', 'Luís Carlos de Oliveira Preto'],
    position: 'Zagueiro',
    status: 'PARTIAL',
    note: 'Carreira real tem 2 passagens pelo São Paulo e empréstimo ao Taubaté não presentes no pacote original; anos exatos de Cruz Azul/Santos/tail não confirmados o suficiente.',
    clubCareer: [
      { period: '1984', team: 'São Paulo' },
      { period: '1986', team: 'Taubaté', loan: true },
      { period: '1987', team: 'São Paulo' },
      { period: '1988–1990', team: 'Bragantino', loan: true, isBraga: true },
    ],
  },
  {
    id: 'mauro_silva',
    answer: 'Mauro Silva',
    acceptedAnswers: ['Mauro Silva', 'Mauro da Silva Gomes'],
    position: 'Volante',
    status: 'READY',
    clubCareer: [
      { period: '1986–1989', team: 'Guarani' },
      { period: '1989–1992', team: 'Bragantino', isBraga: true },
      { period: '1992–2005', team: 'Deportivo La Coruña', appearances: 458 },
    ],
  },
  {
    id: 'ivair',
    answer: 'Ivair',
    acceptedAnswers: ['Ivair'],
    position: 'Volante',
    status: 'PARTIAL',
    note: 'Só o período confirmado no Bragantino (1988–1991). Clubes antes/depois do pacote original (União Bandeirante, Goytacaz, Athletico-PR, XV de Piracicaba, Mogi Mirim, Ponte Preta) não confirmados.',
    clubCareer: [{ period: '1988–1991', team: 'Bragantino', isBraga: true }],
  },
  {
    id: 'luis_muller',
    answer: 'Luís Müller',
    acceptedAnswers: ['Luís Müller', 'Müller', 'Miguel Luís Müller'],
    position: 'Meia',
    status: 'PARTIAL',
    note: 'Carreira anterior ao Bragantino (São Paulo, Criciúma, São José, Guarani, São Bento, Portuguesa, Portuguesa Santista, Ponte Preta) e posterior ao Gamba Osaka (Kyoto Sanga, Remo, Santos, Juventude, Sport) do pacote original não confirmadas com período.',
    clubCareer: [
      { period: '1990', team: 'Bragantino', isBraga: true },
      { period: '1992–1993', team: 'Gamba Osaka' },
    ],
  },
  {
    id: 'valmir_francisco',
    answer: 'Valmir',
    acceptedAnswers: ['Valmir', 'Valmir Francisco da Silva'],
    position: 'Meia',
    status: 'READY',
    clubCareer: [
      { period: '1982–1987', team: 'Ponte Preta' },
      { period: '1985–1986; 1992', team: 'Paysandu' },
      { period: '1988–1991', team: 'Bragantino', isBraga: true },
    ],
  },
  {
    id: 'joao_santos',
    answer: 'João Santos',
    acceptedAnswers: ['João Santos', 'João dos Santos Ferreira'],
    position: 'Meia',
    status: 'PARTIAL',
    note: 'Clubes depois do Bragantino do pacote original (Remo, Paraná, Santos, Internacional, Coritiba, União São João, Matonense) não confirmados.',
    clubCareer: [
      { period: '1989–1991', team: 'Bragantino', isBraga: true },
    ],
  },
  {
    id: 'mazinho_oliveira',
    answer: 'Mazinho',
    acceptedAnswers: ['Mazinho', 'Waldemar Aureliano de Oliveira Filho'],
    position: 'Atacante',
    status: 'READY',
    note: 'Pacote original não trazia a volta ao Bragantino em 2001 (confirmada por fonte) nem Athletico-PR entre Santos e Bragantino.',
    clubCareer: [
      { period: '1983–1988', team: 'Santos' },
      { period: '1988–1990', team: 'Athletico-PR' },
      { period: '1990–1991', team: 'Bragantino', goals: 10, isBraga: true },
      { period: '1991–1995', team: 'Bayern de Munique', appearances: 56 },
      { period: '1995–1999', team: 'Kashima Antlers', appearances: 100, goals: 52 },
      { period: '2001', team: 'Bragantino', isBraga: true },
    ],
  },
  {
    id: 'mario_maguila',
    answer: 'Mário',
    acceptedAnswers: ['Mário', 'Mário Maguila', 'Mário Carlos Moraes Soares'],
    position: 'Atacante',
    status: 'READY',
    note: 'Pacote original tratava o Bragantino como 1 passagem só — na verdade são 2.',
    clubCareer: [
      { period: '1987–1989', team: 'Guarani' },
      { period: '1989–1990', team: 'Bragantino', isBraga: true },
      { period: '1991', team: 'Celta de Vigo', appearances: 10, goals: 2 },
      { period: '1991', team: 'Bragantino', isBraga: true },
      { period: '1991–1992', team: 'Dunakanyar-Vác' },
      { period: '1993', team: 'Náutico' },
      { period: '1994–1995', team: 'Juventude', appearances: 39, goals: 28 },
    ],
  },
  {
    id: 'silvio_mariola',
    answer: 'Sílvio',
    acceptedAnswers: ['Sílvio', 'Sílvio Mariola', 'Sílvio César Ferreira da Costa'],
    position: 'Atacante',
    status: 'READY',
    note: 'Clubes após 1997 (Braga-POR, Bahia, São Caetano, São José, Gama, CRB, Tripoli-LIB, Coruripe) do pacote original não confirmados com período — não incluídos.',
    clubCareer: [
      { period: '1990–1994', team: 'Bragantino', isBraga: true },
      { period: '1994–1995', team: 'Logroñés' },
      { period: '1995', team: 'Paraná' },
      { period: '1996', team: 'Grêmio' },
      { period: '1996', team: 'Guarani' },
      { period: '1996', team: 'Goiás' },
      { period: '1997', team: 'Internacional' },
    ],
  },
  {
    id: 'tiba_guedes',
    answer: 'Tiba',
    acceptedAnswers: ['Tiba', 'Arione Ferreira Guedes'],
    position: 'Atacante',
    status: 'READY',
    note: 'Clubes finais do pacote original (São José, Paysandu, Juventude) não confirmados com período — não incluídos.',
    clubCareer: [
      { period: '1988–1991', team: 'Vasco' },
      { period: '1989–1990', team: 'Bragantino', loan: true, isBraga: true },
      { period: '1993', team: 'Paraná', loan: true },
      { period: '1994–1996', team: 'Portuguesa' },
      { period: '1996–1997', team: 'Corinthians', appearances: 13, goals: 6 },
      { period: '1998', team: 'Ituano' },
      { period: '1998', team: 'Portuguesa' },
    ],
  },
  {
    id: 'franklin_bittencourt',
    answer: 'Franklin',
    acceptedAnswers: ['Franklin', 'Franklin Bittencourt', 'Franklin Spencer Miguel Bittencourt'],
    position: 'Atacante',
    status: 'READY',
    clubCareer: [
      { period: '1989–1990', team: 'Fluminense' },
      { period: '1991', team: 'Bragantino', appearances: 2, goals: 1, isBraga: true },
      { period: '1992–1998', team: 'VfB Leipzig', appearances: 105, goals: 20 },
      { period: '1998–2003', team: 'Energie Cottbus', appearances: 84, goals: 22 },
    ],
  },
  {
    id: 'leo_ortiz',
    answer: 'Léo Ortiz',
    acceptedAnswers: ['Léo Ortiz'],
    position: 'Zagueiro',
    status: 'READY',
    clubCareer: [
      { period: '2012–2017', team: 'Internacional' },
      { period: '2018', team: 'Sport', loan: true },
      { period: '2019–2023', team: 'Red Bull Bragantino', appearances: 198, goals: 14, isBraga: true },
      { period: '2024–atual', team: 'Flamengo' },
    ],
  },
  {
    id: 'artur_victor',
    answer: 'Artur',
    acceptedAnswers: ['Artur', 'Artur Victor Guimarães'],
    position: 'Ponta-direita',
    status: 'READY',
    clubCareer: [
      { period: '2016–2019', team: 'Palmeiras' },
      { period: '2019', team: 'Bahia', loan: true },
      { period: '2020–2023', team: 'Red Bull Bragantino', appearances: 170, goals: 38, isBraga: true },
      { period: '2024–atual', team: 'Zenit' },
    ],
  },
  {
    id: 'aderlan_silva',
    answer: 'Aderlan',
    acceptedAnswers: ['Aderlan', 'Aderlan de Lima Silva'],
    position: 'Lateral-direito',
    status: 'READY',
    note: 'Carreira antes do Red Bull Bragantino (Campinense/Treze/Itapipoca/Corinthians-AL/CSA/Santa Rita/Coimbra/Luverdense/América-MG/Red Bull Brasil) sem período exato por clube confirmado — resumida.',
    clubCareer: [
      { period: '2009', team: 'Campinense' },
      { period: '2019–2023', team: 'Red Bull Bragantino', appearances: 218, goals: 6, isBraga: true },
      { period: '2024', team: 'Santos' },
      { period: '2025', team: 'Sport' },
    ],
  },
  {
    id: 'fabricio_bruno',
    answer: 'Fabrício Bruno',
    acceptedAnswers: ['Fabrício Bruno', 'Fabrício Bruno Soares de Faria'],
    position: 'Zagueiro',
    status: 'READY',
    clubCareer: [
      { period: '2016–2019', team: 'Cruzeiro', appearances: 30 },
      { period: '2017–2018', team: 'Chapecoense', loan: true, appearances: 46, goals: 2 },
      { period: '2020–2022', team: 'Red Bull Bragantino', appearances: 65, goals: 1, isBraga: true },
      { period: '2022–2024', team: 'Flamengo', appearances: 103, goals: 6 },
      { period: '2025–atual', team: 'Cruzeiro' },
    ],
  },
  {
    id: 'helinho',
    answer: 'Helinho',
    acceptedAnswers: ['Helinho', 'Hélio Júnior Nunes de Castro'],
    position: 'Ponta',
    status: 'READY',
    clubCareer: [
      { period: '2018–2021', team: 'São Paulo', appearances: 31, goals: 2 },
      { period: '2020–2021', team: 'Red Bull Bragantino', loan: true, appearances: 50, goals: 10, isBraga: true },
      { period: '2022–2024', team: 'Red Bull Bragantino', appearances: 65, goals: 13, isBraga: true },
      { period: '2024–atual', team: 'Toluca', appearances: 53, goals: 14 },
    ],
  },
  {
    id: 'luan_candido',
    answer: 'Luan Cândido',
    acceptedAnswers: ['Luan Cândido', 'Luan Cândido de Almeida'],
    position: 'Lateral-esquerdo',
    status: 'READY',
    clubCareer: [
      { period: '2019–2020', team: 'RB Leipzig' },
      { period: '2020–2025', team: 'Red Bull Bragantino', appearances: 200, goals: 21, isBraga: true },
      { period: '2025', team: 'Grêmio', loan: true },
      { period: '2025', team: 'Sport', loan: true },
      { period: '2025–2026', team: 'Vitória', loan: true },
    ],
  },
  {
    id: 'lucas_evangelista',
    answer: 'Lucas Evangelista',
    acceptedAnswers: ['Lucas Evangelista', 'Lucas Evangelista Santana de Oliveira'],
    position: 'Meio-campo',
    status: 'READY',
    note: 'Estoril/Vitória de Guimarães do pacote original não confirmados diretamente nesta rodada — omitidos.',
    clubCareer: [
      { period: '2013–2014', team: 'São Paulo' },
      { period: '2014–2016', team: 'Udinese' },
      { period: '2016', team: 'Panathinaikos', loan: true },
      { period: '2018', team: 'Nantes' },
      { period: '2020', team: 'Red Bull Bragantino', loan: true, isBraga: true },
      { period: '2021–2025', team: 'Red Bull Bragantino', isBraga: true },
      { period: '2025–atual', team: 'Palmeiras' },
    ],
  },
  {
    id: 'juninho_capixaba',
    answer: 'Juninho Capixaba',
    acceptedAnswers: ['Juninho Capixaba', 'Luis Antônio da Rocha Júnior'],
    position: 'Lateral-esquerdo',
    status: 'READY',
    clubCareer: [
      { period: '2015–2017', team: 'Bahia', appearances: 26 },
      { period: '2018–2019', team: 'Corinthians', appearances: 9 },
      { period: '2018–2019', team: 'Grêmio', loan: true, appearances: 16, goals: 5 },
      { period: '2019–2022', team: 'Grêmio', appearances: 15 },
      { period: '2020–2021', team: 'Bahia', loan: true, appearances: 56 },
      { period: '2022', team: 'Fortaleza', loan: true, appearances: 34, goals: 3 },
      { period: '2023–atual', team: 'Red Bull Bragantino', appearances: 132, goals: 9, isBraga: true },
    ],
  },
  {
    id: 'eduardo_sasha',
    answer: 'Eduardo Sasha',
    acceptedAnswers: ['Eduardo Sasha', 'Sasha', 'Eduardo Colcenti Antunes'],
    position: 'Atacante',
    status: 'READY',
    clubCareer: [
      { period: '2010–2012', team: 'Internacional' },
      { period: '2012–2013', team: 'Goiás', loan: true },
      { period: '2014–2017', team: 'Internacional' },
      { period: '2018–2019', team: 'Santos' },
      { period: '2020–2023', team: 'Atlético-MG' },
      { period: '2023–atual', team: 'Red Bull Bragantino', isBraga: true },
    ],
  },
  {
    id: 'claudinho',
    answer: 'Claudinho',
    acceptedAnswers: ['Claudinho', 'Cláudio Luiz Rodrigues Parise Leonel'],
    position: 'Meia',
    status: 'READY',
    note: 'Pacote original não trazia a passagem por empréstimo de 2016 no Bragantino, separada da passagem principal de 2019-2021.',
    clubCareer: [
      { period: '2015–2017', team: 'Corinthians' },
      { period: '2016', team: 'Bragantino', loan: true, isBraga: true },
      { period: '2017', team: 'Santo André', loan: true },
      { period: '2018', team: 'Red Bull Brasil', loan: true },
      { period: '2018', team: 'Oeste', loan: true },
      { period: '2017–2019', team: 'Ponte Preta' },
      { period: '2019–2021', team: 'Red Bull Bragantino', appearances: 99, goals: 32, isBraga: true },
      { period: '2021–2025', team: 'Zenit', appearances: 93, goals: 17 },
      { period: '2025–atual', team: 'Al-Sadd', appearances: 18, goals: 3 },
    ],
  },
];

function jsonbClubCareer(entries) {
  const mapped = entries.map((e) => ({
    period: e.period,
    team: e.team,
    appearances: e.appearances ?? null,
    goals: e.goals ?? null,
    loan: e.loan ?? false,
    is_goias: e.isBraga ?? false,
  }));
  return JSON.stringify(mapped).replace(/'/g, "''");
}

function sqlStringArray(arr) {
  return JSON.stringify(arr).replace(/'/g, "''");
}

const ready = players.filter((p) => p.status !== 'BLOCKED');
const rows = ready.map((p, i) => {
  const acceptedAnswers = sqlStringArray(p.acceptedAnswers);
  const clubCareer = jsonbClubCareer(p.clubCareer);
  return `('${p.id}', '${CLUB_ID}', '${p.answer.replace(/'/g, "''")}', '${acceptedAnswers}'::jsonb, '${p.position}', '${clubCareer}'::jsonb, ${i + 1})`;
});

const header = `-- Adivinhe o Jogador — carreiras do Bragantino, reconstruídas a partir do
-- pacote docs/bragantino_data/new_data/adivinhe_jogador_30_carreiras_v1.json
-- (que só tinha nome de clube, sem período nenhum) + pesquisa própria
-- (Wikipedia PT/EN, ogol, imprensa), 2026-09-08.
--
-- ${ready.filter((p) => p.status === 'READY').length} READY (período+clube confirmado por fonte) + ${ready.filter((p) => p.status === 'PARTIAL').length} PARTIAL
-- (pelo menos a passagem pelo Bragantino confirmada; o resto da carreira
-- some quando não achei fonte com período — nunca inventado). 3 ficaram de
-- fora (Carlos Augusto, Souza, Robert): fonte insuficiente ou risco real de
-- homônimo (nomes comuns, vários jogadores com o mesmo nome na época).
--
-- \`is_goias\` no jsonb é só o flag de destaque visual da linha (nome
-- herdado da tabela compartilhada com o Goiás, ver
-- \`lib/features/arena/games/career_path/career_models.dart\`) — aqui
-- marca a(s) passagem(ns) pelo BRAGANTINO, nunca pelo Goiás.
--
-- Rodar no SQL editor do projeto Supabase do BRAGANTINO
-- (yrgyzkaaudyzmsqwzecj).

insert into public.career_players (id, club_id, answer, accepted_answers, position, club_career, sort_order) values
`;

const footer = `
on conflict (id) do update set
  club_id = excluded.club_id, answer = excluded.answer, accepted_answers = excluded.accepted_answers,
  position = excluded.position, club_career = excluded.club_career, sort_order = excluded.sort_order;
`;

writeFileSync(
  '../../supabase/bragantino_career_players.sql',
  header + rows.join(',\n') + footer,
);

console.log('READY:', ready.filter((p) => p.status === 'READY').length);
console.log('PARTIAL:', ready.filter((p) => p.status === 'PARTIAL').length);
console.log('BLOCKED (fora do SQL):', players.length - ready.length);
console.log('total no SQL:', ready.length);
