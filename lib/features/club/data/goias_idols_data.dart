import 'package:goias_app/features/club/domain/entities/club_idol.dart';

/// Ídolos do Goiás — lista aprovada pelo usuário em 2026-10-01 (37 nomes,
/// sem Romerito, Rodrigo Tabata e Ricardo Goulart).
///
/// Fontes, na ordem de prioridade usada:
///   * card oficial "memórias que nascem verde e branco", publicado pelo
///     Goiás no aniversário de 83 anos (06/04/2026) e reproduzido pelo Mais
///     Goiás em 09/04/2026 — base dos PERÍODOS e da evidência de ídolo
///     (`evidenceExplicitIdol: true` só para os 32 nomes do card);
///   * números já conferidos em `career_players` (Adivinhe o Jogador) e na
///     camada canônica (`player_club_stats`);
///   * pesquisa trazida pelo usuário (títulos e marcos de Fernandão, Araújo,
///     Harlei, Rafael Tolói, Amaral, Michael, Tadeu, Paghetti, Amauri,
///     Iarley);
///   * ogol.com.br (nome completo e posição; período só para quem não está
///     no card).
///
/// Regras: número só entra com duas fontes concordando (ou fonte oficial);
/// quando as fontes divergem, o número fica de fora do texto (Rafael Tolói,
/// Amaral, Josué, Vítor, Jadílson, Paulo Baier, Túlio — ver o relatório).
/// Estatística de quem segue em atividade sempre com data (Tadeu).
///
/// Ordem cronológica pela chegada ao clube — nunca ranking.
///
/// FOTOS: reaproveitam o acervo já usado no "Quem Vestiu o Manto"
/// (`goiasGuessPlayerPhotos`) e no Elenco (Tadeu), mesmo padrão do
/// Bragantino. Os demais ficam `null` (a tela mostra as iniciais) até o
/// usuário entregar as fotos em `lib/assets/branding/goias/idols/<id>.png`
/// — lembrar de declarar essa pasta no pubspec quando os arquivos chegarem.
class GoiasIdolsData {
  const GoiasIdolsData._();

  static const _guess = 'lib/assets/games/guess_player/goias';

  static const List<ClubIdol> idols = [
    // ---------------------------------------------------- anos 1950–1970
    ClubIdol(
      name: 'Tão Segurado',
      tier: 1,
      evidenceExplicitIdol: true,
      description:
          'Um dos nomes das gerações mais antigas do Goiás lembrados pelo '
          'clube entre os seus ídolos.',
      period: '1953-1963',
    ),
    ClubIdol(
      name: 'Macalé',
      tier: 1,
      evidenceExplicitIdol: true,
      description:
          'Zagueiro de duas passagens pelo Goiás, das gerações mais antigas homenageadas pelo clube.',
      position: 'Zagueiro',
      period: '1965-1968, 1973-1980',
      fullName: 'Sebastião Macalé Caciano Cassimiro',
    ),
    ClubIdol(
      name: 'Lincoln',
      tier: 1,
      evidenceExplicitIdol: true,
      description: 'Centroavante do Goiás na década de 1970.',
      position: 'Centroavante',
      period: '1973-1977',
      fullName: 'Lincoln de Freitas Neves',
    ),
    ClubIdol(
      name: 'Paghetti',
      tier: 1,
      evidenceExplicitIdol: true,
      description:
          'Atacante da década de 1970; o Goiás registra 36 gols dele com a camisa esmeraldina.',
      position: 'Atacante',
      period: 'Anos 1970',
      fullName: 'Ari Paghetti',
      // Total de gols registrado pelo próprio clube (fontes secundárias
      // divergem; prioridade à oficial). Jogos sem fonte que feche.
      goals: 36,
    ),
    ClubIdol(
      name: 'Tuíra',
      tier: 1,
      evidenceExplicitIdol: true,
      description: 'Atacante, destaque do Goiás na década de 1970.',
      position: 'Atacante',
      period: 'Anos 1970',
      fullName: 'Valtuir Laureano Marques',
    ),
    ClubIdol(
      name: 'Matinha',
      tier: 1,
      evidenceExplicitIdol: true,
      description:
          'Volante, destaque do Goiás na década de 1970, com passagem pelo clube até 1982.',
      position: 'Volante',
      period: 'Anos 1970-1982',
      fullName: 'José Raimundo da Silva',
    ),
    ClubIdol(
      name: 'Amauri',
      tier: 1,
      evidenceExplicitIdol: false,
      description:
          'Goleiro da década de 1970, lembrado por uma sequência de seis partidas consecutivas sem sofrer gol.',
      // Período fica de fora: as fontes divergem sobre o início e o fim
      // exatos da passagem (ogol: 1972-1981).
      position: 'Goleiro',
      fullName: 'José Amauri Soares dos Santos',
      highlights: ['Seis partidas consecutivas sem sofrer gol'],
    ),
    ClubIdol(
      name: 'Luvanor',
      tier: 1,
      evidenceExplicitIdol: true,
      description:
          'Meia revelado pelo Goiás, com duas passagens pelo clube; lembrado pelo Goiás entre os jogadores que decidiram jogos e construíram momentos históricos.',
      position: 'Meia',
      period: '1977-1983, 1990-1991',
      fullName: 'Luvanor Donizete Borges',
    ),
    // ------------------------------------------------------------ anos 1980
    ClubIdol(
      name: 'Carlos Alberto Santos',
      tier: 1,
      evidenceExplicitIdol: false,
      description: 'Volante do Goiás na primeira metade dos anos 1980.',
      position: 'Volante',
      period: '1981-1986',
      fullName: 'Carlos Alberto Souza dos Santos',
    ),
    ClubIdol(
      name: 'Zé Teodoro',
      tier: 1,
      evidenceExplicitIdol: false,
      description:
          'Lateral-direito com duas passagens pelo Goiás, nos anos 1980 e 1990.',
      position: 'Lateral-direito',
      period: '1982-1985, 1994-1995',
      fullName: 'José Teodoro Bonfim Queiroz',
    ),
    ClubIdol(
      name: 'Edson Mug',
      tier: 1,
      evidenceExplicitIdol: true,
      description: 'Goleiro eleito o "Goleiro do Fantástico" em 1983 e 1984.',
      // Dados pessoais e período ainda divergem entre fontes — nada além do
      // prêmio citado pelo clube.
      position: 'Goleiro',
      highlights: ['Eleito o "Goleiro do Fantástico" em 1983 e 1984'],
    ),
    ClubIdol(
      name: 'Cacau',
      tier: 1,
      evidenceExplicitIdol: true,
      description:
          'Meia revelado pelo Goiás, com trajetória no clube entre os anos 1980 e o início dos anos 1990.',
      position: 'Meia',
      period: 'Anos 1980-1993',
      fullName: 'Cláudio Rabello de Castro',
    ),
    ClubIdol(
      name: 'Uidemar',
      tier: 1,
      evidenceExplicitIdol: true,
      description:
          'Volante revelado pelo Goiás nos anos 1980, lembrado pelo clube entre os jogadores de relevância nacional que vestiram a camisa esmeraldina.',
      position: 'Volante',
      period: 'Anos 1980',
      fullName: 'Uidemar Pessoa de Oliveira',
    ),
    ClubIdol(
      name: 'Marquinhos',
      tier: 1,
      evidenceExplicitIdol: false,
      // Identidade ainda não definida: há vários "Marquinhos" na história do
      // clube. Nada além do nome até o usuário confirmar qual é.
      description: '',
    ),
    ClubIdol(
      name: 'Túlio Maravilha',
      tier: 1,
      evidenceExplicitIdol: true,
      description:
          'Centroavante, lembrado pelo Goiás entre os jogadores de relevância nacional que vestiram a camisa esmeraldina.',
      position: 'Centroavante',
      period: '1988-1992',
      photoAsset: '$_guess/tulio_maravilha.png',
      fullName: 'Túlio Humberto Pereira Costa',
    ),
    // ------------------------------------------------------------ anos 1990
    ClubIdol(
      name: 'Kléber Guerra',
      tier: 1,
      evidenceExplicitIdol: true,
      description:
          'Goleiro formado no Goiás, representante dos anos 1990 na homenagem do clube aos seus ídolos.',
      position: 'Goleiro',
      period: 'Anos 1990',
      fullName: 'Kléber Guerra Marques',
    ),
    ClubIdol(
      name: 'Lúcio Bala',
      tier: 1,
      evidenceExplicitIdol: true,
      description: 'Meia-atacante do Goiás em meados dos anos 1990.',
      // Nome completo diverge entre bases — fica de fora.
      position: 'Meia-atacante',
      period: '1994-1996',
    ),
    ClubIdol(
      name: 'Dill',
      tier: 1,
      evidenceExplicitIdol: true,
      description:
          'Atacante revelado pelo Goiás; um dos nomes que ajudaram a consolidar o clube no cenário nacional.',
      position: 'Atacante',
      period: '1994-2000',
      photoAsset: '$_guess/dill.png',
      fullName: 'Elpídio Barbosa Conceição',
      matches: 101,
      goals: 38,
    ),
    ClubIdol(
      name: 'Alex Dias',
      tier: 1,
      evidenceExplicitIdol: true,
      description:
          'Atacante lembrado pelo Goiás entre os jogadores que decidiram jogos e construíram momentos históricos.',
      position: 'Atacante',
      period: '1995-1999',
      photoAsset: '$_guess/alex_dias.png',
      fullName: 'Alex Dias de Almeida',
    ),
    ClubIdol(
      name: 'Fernandão',
      tier: 1,
      evidenceExplicitIdol: true,
      description:
          'Formado desde as categorias de base do clube, foi campeão da Série B de 1999 e de cinco Goianos seguidos.',
      position: 'Atacante',
      period: '1995-2001, 2009-2010',
      photoAsset: '$_guess/fernandao.png',
      fullName: 'Fernando Lúcio da Costa',
      // Total oficial do Goiás — não distribuir entre as duas passagens.
      matches: 271,
      goals: 108,
      titles: [
        'Campeonato Brasileiro Série B 1999',
        'Pentacampeonato Goiano (1996 a 2000)',
        'Copa Centro-Oeste 2000',
        'Copa Centro-Oeste 2001',
      ],
      highlights: [
        'Formado desde as categorias de base e as escolinhas do clube',
      ],
    ),
    ClubIdol(
      name: 'Sílvio Criciúma',
      tier: 1,
      evidenceExplicitIdol: true,
      description:
          'Zagueiro lembrado pelo Goiás entre os jogadores de relevância nacional que vestiram a camisa esmeraldina.',
      position: 'Zagueiro',
      period: 'Anos 1990',
      fullName: 'Sílvio Nicoladelli',
    ),
    ClubIdol(
      name: 'Aloísio Chulapa',
      tier: 1,
      evidenceExplicitIdol: true,
      description:
          'Centroavante, um dos nomes que ajudaram a consolidar o Goiás no cenário nacional.',
      position: 'Centroavante',
      period: '1997-1999',
      fullName: 'Aloísio José da Silva',
    ),
    ClubIdol(
      name: 'Araújo',
      tier: 1,
      evidenceExplicitIdol: true,
      description:
          'Maior artilheiro da história do Goiás e peça da geração dominante do fim dos anos 1990 e início dos 2000.',
      position: 'Atacante',
      period: '1997-2003, 2013-2014',
      fullName: 'Clemerson de Araújo Soares',
      // Total histórico oficial do Goiás.
      matches: 391,
      goals: 145,
      titles: ['Campeonato Brasileiro Série B 1999'],
      highlights: ['Maior artilheiro da história do Goiás'],
    ),
    ClubIdol(
      name: 'Josué',
      tier: 1,
      evidenceExplicitIdol: true,
      description:
          'Volante revelado pelo Goiás, lembrado pelo clube entre os jogadores de relevância nacional que vestiram a camisa esmeraldina.',
      position: 'Volante',
      period: '1997-2004',
      fullName: 'Josué Anunciado de Oliveira',
    ),
    ClubIdol(
      name: 'Harlei',
      tier: 1,
      evidenceExplicitIdol: true,
      description:
          'Goleiro recordista de partidas pelo Goiás, símbolo de longevidade, liderança e identificação com o clube.',
      position: 'Goleiro',
      period: '1999-2014',
      photoAsset: '$_guess/harlei.png',
      fullName: 'Harlei de Menezes Silva',
      matches: 831,
      titles: [
        'Campeonato Brasileiro Série B 1999',
        'Campeonato Brasileiro Série B 2012',
        'Sete Campeonatos Goianos',
        'Três Copas Centro-Oeste',
      ],
      highlights: [
        'Disputou a Libertadores de 2006',
        'Vice-campeão da Copa Sul-Americana de 2010',
      ],
    ),
    // ------------------------------------------------------------ anos 2000
    ClubIdol(
      name: 'Dimba',
      tier: 1,
      evidenceExplicitIdol: true,
      description:
          'Centroavante, um dos nomes que ajudaram a consolidar o Goiás no cenário nacional.',
      position: 'Centroavante',
      period: '2003',
      fullName: 'Editácio Vieira de Andrade',
    ),
    ClubIdol(
      name: 'Paulo Baier',
      tier: 1,
      evidenceExplicitIdol: true,
      description:
          'Meia de duas passagens pelo Goiás, lembrado pelo clube entre os jogadores de relevância nacional que vestiram a camisa esmeraldina.',
      position: 'Meia',
      period: '2004-2005, 2007-2008',
      fullName: 'Paulo César Baier',
    ),
    ClubIdol(
      name: 'Jadílson',
      tier: 1,
      evidenceExplicitIdol: true,
      description: 'Lateral-esquerdo de duas passagens pelo Goiás.',
      position: 'Lateral-esquerdo',
      period: '2004-2006, 2010',
      photoAsset: '$_guess/jadilson.png',
      fullName: 'José Jadilson dos Santos Silva',
    ),
    ClubIdol(
      name: 'Vítor',
      tier: 1,
      evidenceExplicitIdol: true,
      description: 'Lateral-direito de duas passagens pelo Goiás.',
      position: 'Lateral-direito',
      period: '2005-2010, 2012-2014',
      photoAsset: '$_guess/vitor.png',
      fullName: 'Cícero Vítor dos Santos Júnior',
    ),
    ClubIdol(
      name: 'Ernando',
      tier: 1,
      evidenceExplicitIdol: true,
      description:
          'Zagueiro, um dos nomes que ajudaram a consolidar o Goiás no cenário nacional.',
      position: 'Zagueiro',
      period: '2005-2013',
      photoAsset: '$_guess/ernando.png',
      fullName: 'Ernando Rodrigues Lopes',
      matches: 371,
      goals: 12,
    ),
    ClubIdol(
      name: 'Amaral',
      tier: 1,
      evidenceExplicitIdol: true,
      description:
          'Volante, capitão e um dos jogadores mais identificados com o clube.',
      position: 'Volante',
      period: '2005-2014',
      fullName: 'Willian José de Souza',
      titles: ['Campeonato Brasileiro Série B 2012', 'Campeonatos Goianos'],
      highlights: ['Capitão do time'],
    ),
    ClubIdol(
      name: 'Rafael Tolói',
      tier: 1,
      evidenceExplicitIdol: true,
      description:
          'Zagueiro formado pelo Goiás; campeão goiano e vice-campeão da Sul-Americana de 2010.',
      position: 'Zagueiro',
      period: '2008-2012',
      photoAsset: '$_guess/rafael_toloi.png',
      titles: ['Campeonato Goiano'],
      highlights: [
        'Formado nas categorias de base do Goiás',
        'Vice-campeão da Copa Sul-Americana de 2010',
      ],
    ),
    ClubIdol(
      name: 'Iarley',
      tier: 1,
      evidenceExplicitIdol: true,
      description:
          'Atacante de duas passagens pelo Goiás; marcou o gol que confirmou o título da Série B de 2012.',
      position: 'Atacante',
      period: '2008-2009, 2011-2012',
      fullName: 'Pedro Iarley Lima Dantas',
      titles: ['Campeonato Brasileiro Série B 2012'],
      highlights: ['Marcou o gol que confirmou o título da Série B de 2012'],
    ),
    // ------------------------------------------------------------ anos 2010
    ClubIdol(
      name: 'Rafael Moura',
      tier: 1,
      evidenceExplicitIdol: true,
      description: 'Centroavante de duas passagens pelo Goiás.',
      position: 'Centroavante',
      period: '2010, 2019-2020',
      photoAsset: '$_guess/rafael_moura.png',
      fullName: 'Rafael Martiniano de Miranda Moura',
      matches: 120,
      goals: 49,
    ),
    ClubIdol(
      name: 'Walter',
      tier: 1,
      evidenceExplicitIdol: true,
      description:
          'Centroavante de duas passagens; artilheiro na primeira, em 2012-2013.',
      position: 'Centroavante',
      period: '2012-2013, 2016-2017',
      photoAsset: '$_guess/walter.png',
      fullName: 'Walter Henrique da Silva',
      matches: 82,
      goals: 45,
      statsScope: 'Primeira passagem (2012-2013)',
    ),
    ClubIdol(
      name: 'Michael',
      tier: 1,
      evidenceExplicitIdol: true,
      description:
          'Atacante campeão goiano e do acesso à Série A em 2018, destaque nacional em 2019.',
      position: 'Atacante',
      period: '2017-2019',
      photoAsset: '$_guess/michael.png',
      fullName: 'Michael Richard Delgado de Oliveira',
      matches: 129,
      goals: 24,
      titles: ['Campeonato Goiano 2018'],
      highlights: ['Acesso à Série A em 2018', 'Destaque nacional em 2019'],
    ),
    // ----------------------------------------------------------------- atual
    ClubIdol(
      name: 'Tadeu',
      tier: 1,
      evidenceExplicitIdol: false,
      description:
          'Goleiro no clube desde 2019, completou 400 jogos pelo Goiás em 28/08/2026.',
      position: 'Goleiro',
      period: 'Desde 2019',
      photoAsset: 'lib/assets/squad/goias/tadeu.jpg',
      fullName: 'Tadeu Antônio Ferreira',
      // Segue em atividade: número sempre com data de referência.
      matches: 400,
      statsAsOf: '2026-08-28',
      titles: ['Copa Verde 2023', 'Campeonato Goiano 2026'],
    ),
  ];
}
