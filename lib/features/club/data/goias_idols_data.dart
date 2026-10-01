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
          'Sebastião Macalé Caciano Cassimiro. Zagueiro de duas passagens '
          'pelo Goiás, das gerações mais antigas homenageadas pelo clube.',
      position: 'Zagueiro',
      period: '1965-1968, 1973-1980',
    ),
    ClubIdol(
      name: 'Lincoln',
      tier: 1,
      evidenceExplicitIdol: true,
      description:
          'Lincoln de Freitas Neves. Centroavante do Goiás na década de '
          '1970.',
      position: 'Centroavante',
      period: '1973-1977',
    ),
    ClubIdol(
      name: 'Paghetti',
      tier: 1,
      evidenceExplicitIdol: true,
      description:
          'Ari Paghetti. Atacante da década de 1970; o Goiás registra 36 '
          'gols dele com a camisa esmeraldina.',
      position: 'Atacante',
      period: 'Anos 1970',
    ),
    ClubIdol(
      name: 'Tuíra',
      tier: 1,
      evidenceExplicitIdol: true,
      description:
          'Valtuir Laureano Marques. Atacante, destaque do Goiás na década '
          'de 1970.',
      position: 'Atacante',
      period: 'Anos 1970',
    ),
    ClubIdol(
      name: 'Matinha',
      tier: 1,
      evidenceExplicitIdol: true,
      description:
          'José Raimundo da Silva. Volante, destaque do Goiás na década de '
          '1970, com passagem pelo clube até 1982.',
      position: 'Volante',
      period: 'Anos 1970-1982',
    ),
    ClubIdol(
      name: 'Amauri',
      tier: 1,
      evidenceExplicitIdol: false,
      description:
          'José Amauri Soares dos Santos. Goleiro da década de 1970, '
          'lembrado por uma sequência de seis partidas consecutivas sem '
          'sofrer gol.',
      // Período fica de fora: as fontes divergem sobre o início e o fim
      // exatos da passagem (ogol: 1972-1981).
      position: 'Goleiro',
    ),
    ClubIdol(
      name: 'Luvanor',
      tier: 1,
      evidenceExplicitIdol: true,
      description:
          'Luvanor Donizete Borges. Meia revelado pelo Goiás, com duas '
          'passagens pelo clube; lembrado pelo Goiás entre os jogadores que '
          'decidiram jogos e construíram momentos históricos.',
      position: 'Meia',
      period: '1977-1983, 1990-1991',
    ),
    // ------------------------------------------------------------ anos 1980
    ClubIdol(
      name: 'Carlos Alberto Santos',
      tier: 1,
      evidenceExplicitIdol: false,
      description:
          'Carlos Alberto Souza dos Santos. Volante do Goiás na primeira '
          'metade dos anos 1980.',
      position: 'Volante',
      period: '1981-1986',
    ),
    ClubIdol(
      name: 'Zé Teodoro',
      tier: 1,
      evidenceExplicitIdol: false,
      description:
          'José Teodoro Bonfim Queiroz. Lateral-direito com duas passagens '
          'pelo Goiás, nos anos 1980 e 1990.',
      position: 'Lateral-direito',
      period: '1982-1985, 1994-1995',
    ),
    ClubIdol(
      name: 'Edson Mug',
      tier: 1,
      evidenceExplicitIdol: true,
      description:
          'Goleiro eleito o "Goleiro do Fantástico" em 1983 e 1984.',
      // Dados pessoais e período ainda divergem entre fontes — nada além do
      // prêmio citado pelo clube.
      position: 'Goleiro',
    ),
    ClubIdol(
      name: 'Cacau',
      tier: 1,
      evidenceExplicitIdol: true,
      description:
          'Cláudio Rabello de Castro. Meia revelado pelo Goiás, com '
          'trajetória no clube entre os anos 1980 e o início dos anos 1990.',
      position: 'Meia',
      period: 'Anos 1980-1993',
    ),
    ClubIdol(
      name: 'Uidemar',
      tier: 1,
      evidenceExplicitIdol: true,
      description:
          'Uidemar Pessoa de Oliveira. Volante revelado pelo Goiás nos anos '
          '1980, lembrado pelo clube entre os jogadores de relevância '
          'nacional que vestiram a camisa esmeraldina.',
      position: 'Volante',
      period: 'Anos 1980',
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
          'Túlio Humberto Pereira Costa. Centroavante, lembrado pelo Goiás '
          'entre os jogadores de relevância nacional que vestiram a camisa '
          'esmeraldina.',
      position: 'Centroavante',
      period: '1988-1992',
      photoAsset: '$_guess/tulio_maravilha.png',
    ),
    // ------------------------------------------------------------ anos 1990
    ClubIdol(
      name: 'Kléber Guerra',
      tier: 1,
      evidenceExplicitIdol: true,
      description:
          'Kléber Guerra Marques. Goleiro formado no Goiás, representante '
          'dos anos 1990 na homenagem do clube aos seus ídolos.',
      position: 'Goleiro',
      period: 'Anos 1990',
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
          'Elpídio Barbosa Conceição. Atacante revelado pelo Goiás, com 38 '
          'gols em 101 jogos; um dos nomes que ajudaram a consolidar o clube '
          'no cenário nacional.',
      position: 'Atacante',
      period: '1994-2000',
      photoAsset: '$_guess/dill.png',
    ),
    ClubIdol(
      name: 'Alex Dias',
      tier: 1,
      evidenceExplicitIdol: true,
      description:
          'Alex Dias de Almeida. Atacante lembrado pelo Goiás entre os '
          'jogadores que decidiram jogos e construíram momentos históricos.',
      position: 'Atacante',
      period: '1995-1999',
      photoAsset: '$_guess/alex_dias.png',
    ),
    ClubIdol(
      name: 'Fernandão',
      tier: 1,
      evidenceExplicitIdol: true,
      description:
          'Fernando Lúcio da Costa. Formado desde as categorias de base do '
          'clube, marcou 108 gols em 271 jogos pelo Goiás. Campeão da Série '
          'B de 1999, do pentacampeonato goiano (1996-2000) e das Copas '
          'Centro-Oeste de 2000 e 2001.',
      position: 'Atacante',
      period: '1995-2001, 2009-2010',
      photoAsset: '$_guess/fernandao.png',
    ),
    ClubIdol(
      name: 'Sílvio Criciúma',
      tier: 1,
      evidenceExplicitIdol: true,
      description:
          'Sílvio Nicoladelli. Zagueiro lembrado pelo Goiás entre os '
          'jogadores de relevância nacional que vestiram a camisa '
          'esmeraldina.',
      position: 'Zagueiro',
      period: 'Anos 1990',
    ),
    ClubIdol(
      name: 'Aloísio Chulapa',
      tier: 1,
      evidenceExplicitIdol: true,
      description:
          'Aloísio José da Silva. Centroavante, um dos nomes que ajudaram a '
          'consolidar o Goiás no cenário nacional.',
      position: 'Centroavante',
      period: '1997-1999',
    ),
    ClubIdol(
      name: 'Araújo',
      tier: 1,
      evidenceExplicitIdol: true,
      description:
          'Clemerson de Araújo Soares. Maior artilheiro da história do '
          'Goiás, com 145 gols em 391 jogos. Campeão da Série B de 1999 e '
          'peça da geração dominante do fim dos anos 1990 e início dos 2000.',
      position: 'Atacante',
      period: '1997-2003, 2013-2014',
    ),
    ClubIdol(
      name: 'Josué',
      tier: 1,
      evidenceExplicitIdol: true,
      description:
          'Josué Anunciado de Oliveira. Volante revelado pelo Goiás, '
          'lembrado pelo clube entre os jogadores de relevância nacional que '
          'vestiram a camisa esmeraldina.',
      position: 'Volante',
      period: '1997-2004',
    ),
    ClubIdol(
      name: 'Harlei',
      tier: 1,
      evidenceExplicitIdol: true,
      description:
          'Goleiro recordista de partidas pelo Goiás, com 831 jogos. Campeão '
          'da Série B em 1999 e 2012, de sete Campeonatos Goianos e de três '
          'Copas Centro-Oeste; disputou a Libertadores de 2006 e foi '
          'vice-campeão da Sul-Americana de 2010.',
      position: 'Goleiro',
      period: '1999-2014',
      photoAsset: '$_guess/harlei.png',
    ),
    // ------------------------------------------------------------ anos 2000
    ClubIdol(
      name: 'Dimba',
      tier: 1,
      evidenceExplicitIdol: true,
      description:
          'Editácio Vieira de Andrade. Centroavante, um dos nomes que '
          'ajudaram a consolidar o Goiás no cenário nacional.',
      position: 'Centroavante',
      period: '2003',
    ),
    ClubIdol(
      name: 'Paulo Baier',
      tier: 1,
      evidenceExplicitIdol: true,
      description:
          'Paulo César Baier. Meia de duas passagens pelo Goiás, lembrado '
          'pelo clube entre os jogadores de relevância nacional que vestiram '
          'a camisa esmeraldina.',
      position: 'Meia',
      period: '2004-2005, 2007-2008',
    ),
    ClubIdol(
      name: 'Jadílson',
      tier: 1,
      evidenceExplicitIdol: true,
      description:
          'José Jadilson dos Santos Silva. Lateral-esquerdo de duas '
          'passagens pelo Goiás.',
      position: 'Lateral-esquerdo',
      period: '2004-2006, 2010',
      photoAsset: '$_guess/jadilson.png',
    ),
    ClubIdol(
      name: 'Vítor',
      tier: 1,
      evidenceExplicitIdol: true,
      description:
          'Cícero Vítor dos Santos Júnior. Lateral-direito de duas passagens '
          'pelo Goiás.',
      position: 'Lateral-direito',
      period: '2005-2010, 2012-2014',
      photoAsset: '$_guess/vitor.png',
    ),
    ClubIdol(
      name: 'Ernando',
      tier: 1,
      evidenceExplicitIdol: true,
      description:
          'Ernando Rodrigues Lopes. Zagueiro com 371 jogos e 12 gols pelo '
          'Goiás; um dos nomes que ajudaram a consolidar o clube no cenário '
          'nacional.',
      position: 'Zagueiro',
      period: '2005-2013',
      photoAsset: '$_guess/ernando.png',
    ),
    ClubIdol(
      name: 'Amaral',
      tier: 1,
      evidenceExplicitIdol: true,
      description:
          'Willian José de Souza. Volante, capitão e um dos jogadores mais '
          'identificados com o clube; campeão da Série B de 2012 e de '
          'vários Campeonatos Goianos.',
      position: 'Volante',
      period: '2005-2014',
    ),
    ClubIdol(
      name: 'Rafael Tolói',
      tier: 1,
      evidenceExplicitIdol: true,
      description:
          'Zagueiro formado pelo Goiás; campeão goiano e vice-campeão da '
          'Sul-Americana de 2010.',
      position: 'Zagueiro',
      period: '2008-2012',
      photoAsset: '$_guess/rafael_toloi.png',
    ),
    ClubIdol(
      name: 'Iarley',
      tier: 1,
      evidenceExplicitIdol: true,
      description:
          'Pedro Iarley Lima Dantas. Atacante de duas passagens pelo Goiás; '
          'marcou o gol que confirmou o título da Série B de 2012.',
      position: 'Atacante',
      period: '2008-2009, 2011-2012',
    ),
    // ------------------------------------------------------------ anos 2010
    ClubIdol(
      name: 'Rafael Moura',
      tier: 1,
      evidenceExplicitIdol: true,
      description:
          'Rafael Martiniano de Miranda Moura. Centroavante de duas '
          'passagens, com 49 gols em 120 jogos pelo Goiás.',
      position: 'Centroavante',
      period: '2010, 2019-2020',
      photoAsset: '$_guess/rafael_moura.png',
    ),
    ClubIdol(
      name: 'Walter',
      tier: 1,
      evidenceExplicitIdol: true,
      description:
          'Walter Henrique da Silva. Centroavante de duas passagens; na '
          'primeira (2012-2013), marcou 45 gols em 82 jogos.',
      position: 'Centroavante',
      period: '2012-2013, 2016-2017',
      photoAsset: '$_guess/walter.png',
    ),
    ClubIdol(
      name: 'Michael',
      tier: 1,
      evidenceExplicitIdol: true,
      description:
          'Michael Richard Delgado de Oliveira. Atacante com 24 gols em 129 '
          'jogos; campeão goiano e do acesso à Série A em 2018 e destaque '
          'nacional em 2019.',
      position: 'Atacante',
      period: '2017-2019',
      photoAsset: '$_guess/michael.png',
    ),
    // ----------------------------------------------------------------- atual
    ClubIdol(
      name: 'Tadeu',
      tier: 1,
      evidenceExplicitIdol: false,
      description:
          'Tadeu Antônio Ferreira. Goleiro no clube desde 2019, completou '
          '400 jogos pelo Goiás em 28/08/2026. Campeão da Copa Verde de 2023 '
          'e do Campeonato Goiano de 2026.',
      position: 'Goleiro',
      period: 'Desde 2019',
      photoAsset: 'lib/assets/squad/goias/tadeu.jpg',
    ),
  ];
}
