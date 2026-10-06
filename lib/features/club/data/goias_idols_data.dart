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
/// PENDÊNCIA (auditoria específica da semântica de `career_players`):
/// `supabase/career_players.sql` ainda traz Dill com 133 gols (os Ídolos
/// usam 135, press kits oficiais de 2026) e Ernando com 330 jogos e 11 gols
/// (os Ídolos usam 405 jogos). Não alterado de propósito nesta rodada.
///
/// FOTOS: reaproveitam o acervo já usado no "Quem Vestiu o Manto"
/// (`goiasGuessPlayerPhotos`) e no Elenco (Tadeu), mesmo padrão do
/// Bragantino. Os demais ficam `null` (a tela mostra as iniciais) até o
/// usuário entregar as fotos em `lib/assets/branding/goias/idols/<id>.png`
/// — lembrar de declarar essa pasta no pubspec quando os arquivos chegarem.
class GoiasIdolsData {
  const GoiasIdolsData._();

  static const _guess = 'lib/assets/games/guess_player/goias';
  static const _idols = 'lib/assets/branding/goias/idols';

  static const List<ClubIdol> idols = [
    // ---------------------------------------------------- anos 1950–1970
    ClubIdol(
      name: 'Tião Segurado',
      tier: 1,
      photoAsset: '$_idols/tiao_segurado.jpg',
      evidenceExplicitIdol: true,
      description:
          'Um dos nomes das gerações mais antigas do Goiás lembrados pelo '
          'clube entre os seus ídolos.',
      period: '1953-1963',
      highlights: [
        'Artilheiro do Campeonato Goiano de 1956, com 22 gols — o primeiro do Goiás a terminar o estadual como artilheiro',
      ],
      // Auditoria 06/10/2026: PERÍODO DIVERGENTE (catálogo 1953-1963 x fonte histórica 1954-1961) — preservado como está até haver prova.
      // Pesquisa 2026-10: artilheiro 1956 = Goiás EC + RSSSF. Nome completo, posição, 112 jogos/84 gols: só Futebol de Goyaz (1 FONTE) — fora.
    ),
    ClubIdol(
      name: 'Macalé',
      tier: 1,
      photoAsset: '$_idols/macale.jpg',
      evidenceExplicitIdol: true,
      description:
          'Zagueiro de duas passagens pelo Goiás, das gerações mais antigas homenageadas pelo clube.',
      position: 'Zagueiro',
      period: '1965-1968, 1973-1980',
      fullName: 'Sebastião Macalé Caciano Cassimiro',
      titles: [
        'Campeonato Goiano 1966',
        'Campeonato Goiano 1975',
        'Campeonato Goiano 1976',
      ],
      highlights: [
        'Estreou em 1965, no jogo contra o Riachuelo que definiu a permanência do Goiás na Divisão Especial',
        'Eleito o melhor jogador do Goiás no Campeonato Goiano de 1966',
        'Participou das campanhas do Goiás no Campeonato Brasileiro de 1974, 1976 e 1978',
      ],
      story:
          'Macalé estreou profissionalmente em 1965, no confronto contra o '
          'Riachuelo que definiu a permanência do Goiás na Divisão Especial. Em '
          '1966 participou do primeiro título goiano da história do clube e foi '
          'eleito o melhor jogador do Goiás naquela campanha. Voltou ao clube em '
          '1973 e conquistou o estadual de 1975 e o de 1976.',
      // Pesquisa 2026-10: retrospectivas do Goiás EC (antigo site) — títulos e momentos CONFIRMADOS. Total de jogos: só o recorte de Brasileiro (118) — fora.
    ),
    ClubIdol(
      name: 'Lincoln',
      tier: 1,
      photoAsset: '$_idols/lincoln.jpg',
      evidenceExplicitIdol: true,
      description: 'Centroavante do Goiás na década de 1970.',
      position: 'Centroavante',
      period: '1973-1977',
      fullName: 'Lincoln de Freitas Neves',
      goals: 109,
      statsScope: 'Gols oficiais pelo Goiás',
      highlights: [
        'Três vezes artilheiro do Campeonato Goiano',
        'Cinco vezes o principal artilheiro do Goiás no Campeonato Brasileiro',
        'Marcou o primeiro gol do Goiás no Campeonato Brasileiro, em 1973',
        'Primeiro brasileiro a marcar no estádio Serra Dourada, em 1975',
        'Em levantamento oficial publicado pelo Goiás em 16/08/2021, aparecia como o 3º maior artilheiro da história do clube, com 109 gols',
      ],
      story:
          'Lincoln marcou 109 gols oficiais pelo Goiás. Foi três vezes artilheiro '
          'do Campeonato Goiano e cinco vezes o principal goleador esmeraldino no '
          'Campeonato Brasileiro. Marcou o primeiro gol do Goiás no Brasileiro, '
          'em 1973, e foi o primeiro brasileiro a fazer um gol no Serra Dourada, '
          'em 1975.',
      // Pesquisa 2026-10: Goiás EC (retrospectiva oficial) — 109 gols e marcos CONFIRMADOS. Jogos: sem fonte.
    ),
    ClubIdol(
      name: 'Paghetti',
      tier: 1,
      photoAsset: '$_idols/paghetti.jpg',
      evidenceExplicitIdol: true,
      description:
          'Atacante da década de 1970; o Goiás registra 36 gols dele com a camisa esmeraldina.',
      position: 'Atacante',
      fullName: 'Ari Paghetti',
      // Total de gols registrado pelo próprio clube (fontes secundárias
      // divergem; prioridade à oficial). Jogos sem fonte que feche.
      goals: 36,
      period: '1973-1976',
      titles: [
        'Campeonato Goiano 1975',
        'Copa Leonino Caiado 1973, 1974 e 1975 (todas invictas)',
      ],
      highlights: [
        'Fez três gols no empate por 4 a 4 com o Santos, no Pacaembu, em 06/02/1974, em jogo do Campeonato Brasileiro de 1973',
      ],
      story:
          'Ary Paghetti defendeu o Goiás de 1973 a 1976 e marcou 36 gols. Foi '
          'campeão goiano invicto em 1975 e tricampeão da Copa Leonino Caiado, em '
          '1973, 1974 e 1975, também de forma invicta. Um dos principais jogos da '
          'sua passagem foi o empate por 4 a 4 com o Santos, no Pacaembu, em 6 de '
          'fevereiro de 1974 (jogo do Campeonato Brasileiro de 1973), em que marcou '
          'três gols.',
      // Pesquisa 2026-10: Goiás EC — período, 36 gols e títulos CONFIRMADOS. 4x4 com o Santos: 06/02/1974 é a data do jogo e 1973 é a edição do Brasileiro — as duas versões do clube descrevem coisas diferentes. Jogos totais: sem fonte.
    ),
    ClubIdol(
      name: 'Tuíra',
      tier: 1,
      photoAsset: '$_idols/tuira.jpg',
      evidenceExplicitIdol: true,
      description: 'Atacante, destaque do Goiás na década de 1970.',
      // Posição VAZIA de propósito: as fontes divergem (meio-campista x atacante).
      period: '1969-1975',
      fullName: 'Valtuir Laureano Marques',
      highlights: [
        'Esteve no empate por 4 a 4 com o Santos, no Pacaembu',
        'Marcou em um dos primeiros confrontos entre Goiás e Goianésia',
      ],
      // Pesquisa 2026-10: momentos = Futebol de Goyaz + Goiás EC. Período 1969-1975 aplicado em 07/10/2026 (duas bases). POSIÇÃO (atacante x meia) em aberto — removida em 07/10/2026.
    ),
    ClubIdol(
      name: 'Matinha',
      tier: 1,
      photoAsset: '$_idols/matinha.jpg',
      evidenceExplicitIdol: true,
      description:
          'Volante, destaque do Goiás na década de 1970, com passagem pelo clube até 1982.',
      position: 'Volante',
      period: 'Anos 1970-1982',
      fullName: 'José Raimundo da Silva',
      highlights: [
        'Atuou na primeira campanha do Goiás no Campeonato Brasileiro, em 1973',
        'Fez 23 partidas no Campeonato Brasileiro de 1974',
        'Esteve no empate por 4 a 4 com o Santos, no Pacaembu',
      ],
      // Pesquisa 2026-10: Goiás EC. Período (1971-1982 + 1984 na fonte) NÃO alterado: divergente.
    ),
    ClubIdol(
      name: 'Amauri',
      tier: 1,
      photoAsset: '$_idols/amauri.jpg',
      evidenceExplicitIdol: false,
      description:
          'Goleiro da década de 1970, lembrado por uma sequência de seis partidas consecutivas sem sofrer gol.',
      // Período fica de fora: as fontes divergem sobre o início e o fim
      // exatos da passagem (ogol: 1972-1981).
      position: 'Goleiro',
      fullName: 'José Amauri Soares dos Santos',
      highlights: [
        '540 minutos sem sofrer gol, em seis partidas consecutivas, em 1973',
      ],
      // Pesquisa 2026-10: Goiás EC + ge. Período e títulos (Goianos 1975/76 = 1 FONTE) NÃO alterados.
      // Rodada 07/10/2026: 540 min (Goiás EC + ge) x 589 min (outra base, Brasileiro de
      // 1973) — mantido o número oficial. Período: ge/Sagres 1972-1981 x Futebol de
      // Goyaz 1973-1982 — segue DIVERGENTE.
    ),
    ClubIdol(
      name: 'Luvanor',
      tier: 1,
      photoAsset: '$_idols/luvanor.jpg',
      evidenceExplicitIdol: true,
      // Formação na base: futeboldegoyaz.com.br/jogadores/3109/jogador (ficha
      // com "Divulgação no site do Goias E.C."; estreou aos 16 anos) e
      // pt.wikipedia.org/wiki/Luvanor_Donizete_Borges (base desde 1973).
      description:
          'Meia formado nas categorias de base do Goiás, com duas passagens pelo clube; lembrado pelo Goiás entre os jogadores que decidiram jogos e construíram momentos históricos.',
      position: 'Meia',
      period: '1977-1983, 1990-1991',
      fullName: 'Luvanor Donizete Borges',
      titles: [
        'Campeonato Goiano 1981',
        'Campeonato Goiano 1990',
        'Campeonato Goiano 1991',
      ],
      highlights: [
        'Integrou o elenco da campanha do Goiás no Campeonato Brasileiro de 1983, uma das grandes campanhas nacionais do clube nos anos 1980',
        'Voltou ao Goiás em 1990 e esteve na campanha do vice-campeonato da Copa do Brasil',
      ],
      // Auditoria 06/10/2026: colocação do Brasileiro de 1983 DIVERGENTE (5º x 7º) — posição exata fora do texto. 17 gols = recorte Brasileiro + Copa do Brasil, NÃO total — fora.
      // Pesquisa 2026-10: Goiás EC (retrospectiva) — títulos e campanhas CONFIRMADOS. Totais de jogos/gols: sem fonte.
    ),
    // ------------------------------------------------------------ anos 1980
    ClubIdol(
      name: 'Carlos Alberto Santos',
      tier: 1,
      photoAsset: '$_idols/carlos_alberto_santos.jpg',
      evidenceExplicitIdol: false,
      description:
          'Volante do Goiás entre o fim dos anos 1970 e meados dos anos 1980.',
      position: 'Volante',
      period: '1979-1986',
      fullName: 'Carlos Alberto Souza dos Santos',
      titles: [
        'Campeonato Goiano 1981',
        'Campeonato Goiano 1983',
        'Campeonato Goiano 1986',
      ],
      highlights: [
        'Disputou 20 partidas pelo Goiás no Campeonato Brasileiro de 1985',
      ],
      // Pesquisa 2026-10: Goiás EC. Período 1979-1986 (revelado em 1979 + escalação do Brasileiro de 1979).
      // Jogos/gols VAZIOS de propósito: 94/2 (uma base) x 163/10 (painel do Futebol de Goyaz, que mistura clubes) — escopos divergentes.
    ),
    ClubIdol(
      name: 'Zé Teodoro',
      tier: 1,
      photoAsset: '$_idols/ze_teodoro.jpg',
      evidenceExplicitIdol: false,
      description:
          'Lateral-direito com duas passagens pelo Goiás, nos anos 1980 e 1990.',
      position: 'Lateral-direito',
      period: '1981-1985, 1994-1995',
      fullName: 'José Teodoro Bonfim Queiroz',
      titles: ['Campeonato Goiano 1994'],
      highlights: [
        'Integrou o elenco da campanha do Goiás no Campeonato Brasileiro de 1983, uma das grandes campanhas nacionais do clube nos anos 1980',
        'Acesso à Série A nacional em 1994',
      ],
      // Auditoria 06/10/2026: colocação do Goiás no Brasileiro de 1983 DIVERGENTE (5º no Goiás/ge x 7º em levantamento histórico) — posição exata fora do texto.
      // Pesquisa 2026-10: Goiás EC. Início em 1981: ge + material histórico do clube (aplicado em 07/10/2026).
    ),
    ClubIdol(
      name: 'Edson Mug',
      tier: 1,
      photoAsset: '$_idols/edson_mug.jpg',
      evidenceExplicitIdol: true,
      description: 'Goleiro eleito o "Goleiro do Fantástico" em 1983 e 1984.',
      // Período 1983-1984: CONFIRMADO na pesquisa 2026-10 (ge + Mais Goiás). Nome
      // completo ainda só em base secundária (1 FONTE) — fica de fora, assim como
      // jogos/gols/títulos.
      position: 'Goleiro',
      period: '1983-1984',
      highlights: ['Eleito o "Goleiro do Fantástico" em 1983 e 1984'],
    ),
    ClubIdol(
      name: 'Cacau',
      tier: 1,
      photoAsset: '$_idols/cacau.jpg',
      evidenceExplicitIdol: true,
      // Matéria oficial do Goiás (URL não registrada): revelado pelo Goiás,
      // atacante. (105 jogos/18 gols da matéria = recorte do Brasileiro; removidos.) Apoio: futeboldegoyaz.com.br/jogadores/2890/jogador
      // (atacante, Goiás 1981-85 e 1990-93). O ogol diz meia (ogol.com.br/player.php?id=128387).
      description:
          'Atacante revelado pelo Goiás, com trajetória no clube entre os anos 1980 e o início dos anos 1990.',
      position: 'Atacante',
      period: 'Anos 1980-1993',
      fullName: 'Cláudio Rabello de Castro',
      titles: ['Campeonato Goiano 1983'],
      highlights: [
        'Artilheiro do Campeonato Goiano de 1983, com 10 gols',
        'Artilheiro do Goiás no Campeonato Brasileiro de 1984, com 6 gols em 21 partidas',
      ],
      // Pesquisa 2026-10: os antigos 105 jogos/18 gols são o recorte do Campeonato BRASILEIRO (Goiás EC), não o total no clube — removidos. O 56 gols do ge é 1 FONTE — não importado (rodada 06/10/2026: sem segunda fonte; uma base secundária traz número bem menor, com escopo não verificado).
    ),
    ClubIdol(
      name: 'Uidemar',
      tier: 1,
      photoAsset: '$_idols/uidemar.jpg',
      evidenceExplicitIdol: true,
      // "Grande revelação do Goiás na década de 1980":
      // futeboldegoyaz.com.br/jogadores/154/jogador.
      description:
          'Volante revelado pelo Goiás nos anos 1980, lembrado pelo clube entre os jogadores de relevância nacional que vestiram a camisa esmeraldina.',
      position: 'Volante',
      fullName: 'Uidemar Pessoa de Oliveira',
      period: '1983-1989, 1995',
      titles: [
        'Campeonato Goiano 1983',
        'Campeonato Goiano 1986',
        'Campeonato Goiano 1987',
        'Campeonato Goiano 1989',
      ],
      highlights: [
        'Primeiro jogador formado pelo Goiás convocado para a Seleção Brasileira principal enquanto defendia o clube',
        'Marcou de falta na vitória por 4 a 0 sobre o Internacional, na Copa do Brasil de 1989',
      ],
      // Pesquisa 2026-10: Futebol de Goyaz + ge (período/títulos), Goiás EC (Seleção).
    ),
    ClubIdol(
      name: 'Marquinhos',
      tier: 1,
      photoAsset: '$_idols/marquinhos.jpg',
      evidenceExplicitIdol: false,
      // Marcos José Franklin Macena de Melo, lateral-esquerdo, Goiás 1997-2002
      // (identidade, período e Série B 1999: futeboldegoyaz.com.br/jogadores/3561/jogador).
      // O ge o cita como jogador de grande passagem da geração campeã (URL
      // não registrada). Sem total de jogos/gols: nenhuma fonte do clube que feche.
      description:
          'Lateral-esquerdo da geração campeã do Goiás entre 1997 e 2002.',
      position: 'Lateral-esquerdo',
      period: '1997-2002',
      fullName: 'Marcos José Franklin Macena de Melo',
      titles: [
        'Campeonato Brasileiro Série B 1999',
        'Campeonato Goiano 1997',
        'Campeonato Goiano 1998',
        'Campeonato Goiano 1999',
        'Campeonato Goiano 2000',
        'Copa Centro-Oeste 2000',
        'Copa Centro-Oeste 2001',
        'Copa Centro-Oeste 2002',
      ],
      highlights: ['Marcou na campanha decisiva da Série B de 1999'],
      // Rodada 07/10/2026: Goiano 2002 segue FORA — as escalações das duas finais (16 e
      // 23/06/2002, Bola na Área) não trazem o Marquinhos. Futebol de Goyaz: 165 jogos/17
      // gols são do painel padrão do site, não total oficial.
      // Jogos VAZIOS de propósito: 312 (material recente do Goiás) x 465 (ge/O Popular) — divergência grande demais.
      // Pesquisa 2026-10: Goiás EC. Rodada 06/10/2026: Copas Centro-Oeste 2000/01/02
      // (aparece nas finais/escalações; RSSSF registra gols dele em 2001 e 2002) e
      // Goianos 1997-2000 (Futebol de Goyaz + evidência de quatro títulos do
      // pentacampeonato). Goiano 2002: PENDENTE — a ficha do Futebol de Goyaz o
      // lista, mas falta prova nominal robusta da participação na campanha.
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
      goals: 93,
      statsScope: 'Press kit oficial do Goiás, 2026',
      titles: ['Campeonato Goiano 1989'],
      highlights: [
        'Artilheiro do Campeonato Brasileiro de 1989, com 11 gols',
        'Integrou a campanha do vice-campeonato da Copa do Brasil de 1990',
      ],
      // Auditoria 06/10/2026: gols DIVERGENTES — press kit oficial atual 93 x ge histórico 96. Mantido o do clube, com a fonte no statsScope; não escolher silenciosamente.
      // Pesquisa 2026-10: 93 gols = press kit oficial do Goiás 2026; título e artilharia = Goiás EC.
    ),
    // ------------------------------------------------------------ anos 1990
    ClubIdol(
      name: 'Kléber Guerra',
      tier: 1,
      photoAsset: '$_idols/kleber_guerra.jpg',
      evidenceExplicitIdol: true,
      // Formado na base (17 anos no clube, 9 como profissional):
      // futeboldegoyaz.com.br/noticias/265/noticia.
      description:
          'Goleiro formado no Goiás, representante dos anos 1990 na homenagem do clube aos seus ídolos.',
      position: 'Goleiro',
      period: 'Anos 1990',
      fullName: 'Kléber Guerra Marques',
      titles: [
        'Campeonato Goiano 1989',
        'Campeonato Goiano 1990',
        'Campeonato Goiano 1991',
        'Campeonato Goiano 1994',
        'Campeonato Goiano 1996',
        'Campeonato Goiano 1997',
        'Campeonato Goiano 1998',
      ],
      highlights: [
        'Formado nas categorias de base do Goiás desde 1981, chegou ao time profissional no fim da década de 1980',
        'Esteve na campanha do vice-campeonato da Copa do Brasil de 1990',
        'Participou do acesso do Goiás à Série A em 1994',
      ],
      // Pesquisa 2026-10: Goiás EC. Rodada 06/10/2026: os sete Goianos (1989, 1990,
      // 1991, 1994, 1996, 1997, 1998) vêm da fonte jornalística que lista os anos
      // + material biográfico concordante, conforme a pesquisa do usuário. Uma
      // checagem rápida desta rodada achou um resumo listando 1990, 1991, 1994,
      // 1996 e 1998 — REVISAR a fonte primária (URL) antes de publicar.
    ),
    ClubIdol(
      name: 'Lúcio Bala',
      tier: 1,
      photoAsset: '$_idols/lucio_bala.jpg',
      evidenceExplicitIdol: true,
      description: 'Meia-atacante do Goiás em meados dos anos 1990.',
      position: 'Meia-atacante',
      period: '1994-1996',
      fullName: 'Lucenilde Pereira da Silva',
      titles: ['Campeonato Goiano 1996'],
      highlights: [
        'Destaque e revelação do Goiás no Campeonato Brasileiro de 1996, em que o clube terminou em quarto lugar',
      ],
      // Nome completo (rodada 06/10/2026): Lucenilde Pereira da Silva — site do
      // Fortaleza, Galo Digital e, segundo a pesquisa do usuário, Folha de S.Paulo
      // de 1997; "Lúcio Pereira da Silva" (ge/Futebol de Goyaz) é só a forma curta.
      // Goiano 1996: Fortaleza oficial + Galo Digital (duas fontes). Obs.: uma
      // auditoria anterior tinha removido esse título por falta de fonte nominal;
      // reaplicado por decisão do usuário nesta rodada.
      // Pesquisa 2026-10: Goiás EC (revelação 1996).
    ),
    ClubIdol(
      name: 'Dill',
      tier: 1,
      evidenceExplicitIdol: true,
      // Sem "revelado pelo Goiás": o Futebol de Goyaz diz que sim
      // (futeboldegoyaz.com.br/jogadores/1655/jogador) e o Esporte Goiano também,
      // mas a Folha de 03/09/2000 (URL não registrada) diz que o primeiro clube
      // foi o Brasília, depois o Gama, e que chegou ao Goiás em 1994 — conflito,
      // vale a regra rígida de formação. Gols: 135 dos press kits oficiais do
      // Goiás de 2026 (URL não registrada); o card de 83 anos
      // (maisgoias.com.br, "memórias que nascem verde e branco") e a imprensa
      // traziam 133. Os 101 jogos do ogol (ogol.com.br/player.php?id=5137) são
      // recorte parcial, por isso não há total de jogos.
      description:
          'Chegou ao Goiás em 1994 e se tornou um dos grandes artilheiros da história do clube.',
      position: 'Atacante',
      period: '1994-2000',
      photoAsset: '$_guess/dill.png',
      fullName: 'Elpídio Barbosa Conceição',
      goals: 135,
      statsScope: 'Levantamento institucional do Goiás, atualizado em 2026',
      titles: ['Campeonato Brasileiro Série B 1999'],
      highlights: [
        'Artilheiro do Campeonato Goiano de 2000, com 29 gols',
        'Artilheiro do Campeonato Brasileiro de 2000, com 20 gols',
      ],
      // Pesquisa 2026-10: Goiás EC + Mais Goiás. Gols 135 x 133: resolvido pelo press kit oficial do Goiás de 2026 (a fonte institucional mais nova prevalece); o 133 vem de material anterior.
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
      highlights: [
        'Integrou o ataque do Goiás que chegou à semifinal do Campeonato Brasileiro de 1996',
        'Marcou 8 gols no Campeonato Brasileiro de 1996',
      ],
      // Goianos 1996-1999: ge (não conferido ano a ano) + Wikipédia — NÃO gravados. Período (retorno em 2004?) segue em aberto — NÃO alterado.
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
      story:
          'Fernandão chegou ao Goiás ainda nas escolinhas e categorias de base e '
          'estreou profissionalmente em 1995, aos 17 anos. Foi o único jogador a '
          'participar dos cinco títulos estaduais consecutivos entre 1996 e 2000 '
          'e integrou o elenco campeão da Série B de 1999. Depois de construir '
          'carreira fora do clube, retornou em 2009; ao todo, o Goiás registra '
          '271 jogos e 108 gols com a camisa esmeraldina.',
      // Pesquisa 2026-10: Goiás EC (retrospectiva oficial) — 271/108 e títulos CONFIRMADOS.
    ),
    ClubIdol(
      name: 'Sílvio Criciúma',
      tier: 1,
      photoAsset: '$_idols/silvio_criciuma.jpg',
      evidenceExplicitIdol: true,
      description:
          'Zagueiro lembrado pelo Goiás entre os jogadores de relevância nacional que vestiram a camisa esmeraldina.',
      position: 'Zagueiro',
      fullName: 'Sílvio Nicoladelli',
      period: '1996-2001',
      titles: [
        'Campeonato Brasileiro Série B 1999',
        'Quatro dos cinco títulos do pentacampeonato goiano (1996 a 2000)',
        'Copa Centro-Oeste 2000',
        'Copa Centro-Oeste 2001',
      ],
      highlights: [
        'Capitão do Goiás',
        'Disputou 29 partidas na Série B de 1999',
      ],
      story:
          'Sílvio Criciúma chegou ao Goiás em 1996 e permaneceu até 2001. Foi um '
          'dos líderes e capitão da equipe campeã brasileira da Série B de 1999, '
          'na qual disputou 29 partidas. Também participou de quatro títulos do '
          'pentacampeonato estadual e das conquistas regionais de 2000 e 2001.',
      // Pesquisa 2026-10: Goiás EC + ge. Total geral de jogos/gols: sem fonte.
    ),
    ClubIdol(
      name: 'Aloísio Chulapa',
      tier: 1,
      photoAsset: '$_idols/aloisio_chulapa.jpg',
      evidenceExplicitIdol: true,
      description:
          'Centroavante, um dos nomes que ajudaram a consolidar o Goiás no cenário nacional.',
      position: 'Centroavante',
      period: '1997-1999',
      fullName: 'Aloísio José da Silva',
      titles: [
        'Campeonato Goiano 1997',
        'Campeonato Goiano 1998',
        'Campeonato Goiano 1999',
      ],
      highlights: [
        'Artilheiro do Campeonato Goiano de 1997, com 27 gols',
        'Marcou três gols na final do Goiano de 1997 contra o Crac',
      ],
      // Goianos 1997-1999 e artilharia de 1997 (27 gols): aplicados em 07/10/2026 por decisão do usuário (ge + fonte contemporânea da artilharia). Jogos/gols VAZIOS de propósito: 71/23 (1 FONTE) x 58 gols (outra fonte) — escopos incompatíveis.
    ),
    ClubIdol(
      name: 'Araújo',
      tier: 1,
      photoAsset: '$_idols/araujo.jpg',
      evidenceExplicitIdol: true,
      description:
          'Maior artilheiro da história do Goiás e peça da geração dominante do fim dos anos 1990 e início dos 2000.',
      position: 'Atacante',
      period: '1997-2003, 2013-2014',
      fullName: 'Clemerson de Araújo Soares',
      // Maior artilheiro, 145 gols e 391 jogos (todos de 1997-2003 e 2013-2014).
      // Fonte oficial do Goiás (URL não registrada); a imprensa concorda no
      // 145: goal.com/br/listas/maiores-artilheiros-goias-historia/blta7bf3280d376c85f,
      // esportegoiano.com.br/confira-quais-sao-os-maiores-artilheiros-da-historia-do-goias/
      // e portaldabola.com.br/futebol/idolo-goias-araujo-retorno-futebol/ (391).
      // O 187 do Túlio é contagem pessoal dele, não número do clube.
      matches: 391,
      goals: 145,
      titles: ['Campeonato Brasileiro Série B 1999'],
      story:
          'Araújo foi formado no Goiás e construiu uma das maiores marcas '
          'ofensivas da história do clube, com 145 gols em 391 partidas. '
          'Participou do elenco campeão da Série B de 1999. Anos depois retornou '
          'ao clube e terminou o Campeonato Goiano de 2014 como artilheiro.',
      highlights: [
        'Maior artilheiro da história do Goiás',
        'Artilheiro do Campeonato Goiano de 2014',
      ],
      // Pesquisa 2026-10: Goiás EC — 391/145 e fatos CONFIRMADOS.
    ),
    ClubIdol(
      name: 'Josué',
      tier: 1,
      photoAsset: '$_idols/josue.jpg',
      evidenceExplicitIdol: true,
      description:
          // Fonte do formador: pt.wikipedia.org/wiki/Josué_Anunciado_de_Oliveira
          // ("Revelado pelo Clube Atlético do Porto, de Caruaru") — o texto
          // antigo dizia "revelado pelo Goiás" sem fonte.
          // Origem (rodada 07/10/2026): Galo Digital ("iniciou sua carreira no Porto
          // de Caruaru, até ser contratado pelo Goiás") e Lancepedia/O Tempo
          // ("Revelado pelo Atlético do Porto, de Caruaru") concordam — o "formado
          // no Goiás" da pesquisa anterior fica REFUTADO por duas fontes. Chegada ao
          // Goiás: 1997 (O Tempo) x 1996 (Galo Digital/Futebol de Goyaz) — o período
          // segue 1997-2004.
          'Volante revelado pelo Porto, de Caruaru, lembrado pelo Goiás entre os jogadores de relevância nacional que vestiram a camisa esmeraldina.',
      position: 'Volante',
      period: '1997-2004',
      fullName: 'Josué Anunciado de Oliveira',
      matches: 386,
      statsScope: 'Press kit oficial do Goiás, 2026',
      titles: ['Campeonato Brasileiro Série B 1999', 'Copa Centro-Oeste 2000'],
      highlights: [
        'Um dos destaques da campanha do título da Série B de 1999',
        'No press kit oficial do Goiás de 2026, aparecia em 4º lugar entre os jogadores com mais partidas pelo clube, com 386 jogos',
      ],
      story:
          'Josué disputou 386 jogos pelo Goiás, segundo o press kit oficial do '
          'clube de 2026. Foi um dos destaques da conquista da Série B de 1999. '
          'Permaneceu no time esmeraldino até se transferir para o São Paulo e '
          'depois construiu carreira na Seleção Brasileira e no futebol europeu.',
      // Pesquisa 2026-10: 386 jogos = press kit oficial 2026; Série B 1999 = Goiás EC. Gols: sem fonte (nada gravado).
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
        'Terceiro lugar no Campeonato Brasileiro de 2005, que garantiu ao Goiás a vaga inédita na Libertadores',
        'Disputou a Libertadores de 2006',
        'Vice-campeão da Copa Sul-Americana de 2010',
      ],
      story:
          'Harlei chegou ao Goiás em 1999 e conquistou espaço no time durante a '
          'campanha campeã da Série B daquela temporada. Ao longo de 15 anos '
          'tornou-se o recordista de partidas pelo clube, com 831 jogos, e '
          'conquistou 12 títulos. Também esteve no elenco da Libertadores de 2006 '
          'e na campanha vice-campeã da Copa Sul-Americana de 2010, antes de '
          'encerrar a carreira em 2014.',
      // Pesquisa 2026-10: Goiás EC — 831 jogos e 12 títulos CONFIRMADOS. Gols: não encontrado (null, não zero).
    ),
    // ------------------------------------------------------------ anos 2000
    ClubIdol(
      name: 'Dimba',
      tier: 1,
      photoAsset: '$_idols/dimba.jpg',
      evidenceExplicitIdol: true,
      description:
          'Centroavante, um dos nomes que ajudaram a consolidar o Goiás no cenário nacional.',
      position: 'Centroavante',
      period: '2002-2003',
      fullName: 'Editácio Vieira de Andrade',
      highlights: [
        'Artilheiro do Campeonato Brasileiro de 2003, com 31 gols',
        'O Goiás terminou o Campeonato Brasileiro de 2003 em 9º lugar',
      ],
      // Pesquisa 2026-10: Goiás EC + ge. Os 31 gols são do Brasileiro 2003, não total no clube. 9º lugar: tabelas finais contemporâneas (Folha, UOL) + histórico do ge; o "6º" de uma página narrativa do clube não é a classificação final. Jogos/gols totais: sem fonte.
    ),
    ClubIdol(
      name: 'Paulo Baier',
      tier: 1,
      photoAsset: '$_idols/paulo_baier.jpg',
      evidenceExplicitIdol: true,
      description:
          'Meia de duas passagens pelo Goiás, lembrado pelo clube entre os jogadores de relevância nacional que vestiram a camisa esmeraldina.',
      position: 'Meia',
      period: '2004-2005, 2007-2008',
      fullName: 'Paulo César Baier',
      goals: 78,
      statsScope: 'Gols pelo Goiás segundo o ge, o Futebol80 e o Goal',
      highlights: [
        'Bola de Prata do Campeonato Brasileiro de 2004',
        'Artilheiro do Campeonato Goiano de 2005, com 12 gols',
        'Esteve no time que terminou o Brasileiro de 2005 em terceiro lugar',
        'Marcou o milésimo gol do Goiás no Campeonato Brasileiro, em 2008',
        'Artilheiro do Goiás no Campeonato Brasileiro de 2007, com 13 gols',
        'Artilheiro do Goiás no Campeonato Brasileiro de 2008, com 14 gols',
        'Fez 7 gols em 10 jogos na Copa Sul-Americana',
      ],
      // 78 gols: ge + Futebol80 (levantamento gol a gol) + Goal convergem diretamente em 78 (aplicado em 07/10/2026);
      // o 75 de outra base fica como divergência minoritária. Jogos totais VAZIOS de propósito. Antes: Goiás EC. Notas: Rodada 06/10/2026: uma base com detalhe por temporada (2004 47/16,
      // 2005 43/21, 2007 38/17, 2008 49/21) soma 177 jogos/75 gols. Futebol80 totaliza 78
      // gols pelo Goiás contando amistosos no geral (228 na carreira, 2 amistosos) — o
      // escopo exato da diferença segue sem prova; jogos totais também NÃO gravados.
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
      titles: ['Campeonato Goiano 2006'],
      highlights: [
        'Bola de Prata do Campeonato Brasileiro de 2005',
        'Esteve no time que terminou o Brasileiro de 2005 em terceiro lugar',
        'Eleito o melhor jogador do Campeonato Goiano de 2006',
        'Disputou a primeira Libertadores da história do Goiás, em 2006',
      ],
      // Auditoria 06/10/2026: Goiano 2006 e melhor jogador do estadual CONFIRMADOS (ge, 2011). 169 jogos/9 gols do painel do Futebol de Goyaz NÃO são total do Goiás — fora.
      // Pesquisa 2026-10: São Paulo FC + Folha.
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
      titles: [
        'Campeonato Goiano 2006',
        'Campeonato Goiano 2009',
        'Campeonato Goiano 2012',
        'Campeonato Goiano 2013',
        'Campeonato Brasileiro Série B 2012',
      ],
      highlights: [
        'Chegou ao 300º jogo pelo Goiás em março de 2013 e marcou na própria partida',
        'Disputou a Libertadores de 2006 e marcou contra o Estudiantes',
      ],
      // Rodada 06/10/2026: Goianos 2006/2009/2012/2013 + Série B 2012 gravados — fonte
      // nominal que os atribui ao Vítor (decisão do usuário; uma auditoria anterior os
      // tinha removido por falta de prova individual). Conferir a URL primária.
      // Goiano 2012: matéria do ge daquele ano diz explicitamente que, ao retornar, o Vítor conquistou o terceiro título goiano (07/10/2026).
      // Pesquisa 2026-10: ge + FGF. Total final de jogos: não encontrado.
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
      // 405 jogos: press kit oficial do Goiás (URL não registrada); a imprensa
      // repete o número: ohoje.com/2026/08/28/goias-vence-sao-bernardo-e-tadeu-celebra-400-jogos-na-serrinha/
      // (Ernando em segundo, atrás do Harlei). Gols fora até haver fonte que
      // diga explicitamente quantos foram PELO Goiás (o 12 do ogol não fecha:
      // ogol.com.br/jogador/ernando/32225).
      matches: 405,
      titles: [
        'Campeonato Goiano 2009',
        'Campeonato Goiano 2012',
        'Campeonato Goiano 2013',
        'Campeonato Brasileiro Série B 2012',
      ],
      highlights: [
        'Formado nas categorias de base do Goiás',
        'Chegou ao 300º jogo pelo Goiás em 2012, com 8 gols marcados até ali',
        'Ultrapassou 400 partidas pelo clube',
      ],
      // Auditoria 06/10/2026: total final de gols NÃO ENCONTRADO (o 8 é marco datado de 2012).
      // Goianos 2009/2012/2013 + Série B 2012: fonte nominal de 2013 (aplicados).
      // Goiano 2006: DIVERGENTE — fontes posteriores listam quatro estaduais
      // (com 2006); a de 2013 lista três; ele NÃO aparece nas escalações das finais de
      // 2006 (Bola na Área). Não gravado. Rodada 07/10/2026: Ernando consta na escalação
      // da final de 2009 e na lista de 2012 (como reserva); o Futebol de Goyaz lista só o
      // Goiano 2013 — conflito com a fonte nominal de 2013 que lista 2009/12/13. Gols: o
      // 12 do Futebol de Goyaz/ogol é da carreira inteira, não do Goiás.
      // Pesquisa 2026-10: ge.
    ),
    ClubIdol(
      name: 'Amaral',
      tier: 1,
      photoAsset: '$_idols/amaral.png',
      evidenceExplicitIdol: true,
      description:
          'Volante, capitão e um dos jogadores mais identificados com o clube.',
      position: 'Volante',
      period: '2005-2014',
      fullName: 'Willian José de Souza',
      matches: 373,
      goals: 44,
      titles: [
        'Campeonato Goiano 2006',
        'Campeonato Goiano 2009',
        'Campeonato Goiano 2012',
        'Campeonato Goiano 2013',
        'Campeonato Brasileiro Série B 2012',
      ],
      highlights: [
        'Capitão do time',
        'Formado nas escolinhas e categorias de base do Goiás',
      ],
      story:
          'Amaral chegou ao Goiás ainda garoto e passou pelas escolinhas e '
          'categorias de base antes de chegar ao profissional. Em oito temporadas '
          'profissionais disputou 373 jogos e conquistou quatro Campeonatos '
          'Goianos e a Série B de 2012. Também se tornou capitão do time e '
          'permaneceu no clube até o fim de 2014. Ao todo, foram 373 jogos e '
          '44 gols.',
      // Pesquisa 2026-10: Goiás EC — 373 jogos e títulos CONFIRMADOS. 44 gols: Terra (15/12/2014) + ge — antes estava fora por ser 1 FONTE.
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
      titles: ['Campeonato Goiano 2009', 'Campeonato Goiano 2012'],
      highlights: [
        'Formado nas categorias de base do Goiás',
        'Vice-campeão da Copa Sul-Americana de 2010',
        'Eleito três vezes o melhor zagueiro do Campeonato Goiano',
      ],
      fullName: 'Rafael Tolói',
      matches: 177,
      goals: 22,
      // Pesquisa 2026-10: 177 jogos/22 gols = São Paulo FC + ge (duas fontes). Auditoria 06/10/2026: Goianos 2009 e 2012 CONFIRMADOS por duas fontes fortes.
    ),
    ClubIdol(
      name: 'Iarley',
      tier: 1,
      photoAsset: '$_idols/iarley.jpg',
      evidenceExplicitIdol: true,
      description:
          'Atacante de duas passagens pelo Goiás; marcou o gol que confirmou o título da Série B de 2012.',
      position: 'Atacante',
      period: '2008-2009, 2011-2012',
      fullName: 'Pedro Iarley Lima Dantas',
      titles: [
        'Campeonato Goiano 2009',
        'Campeonato Goiano 2012',
        'Campeonato Brasileiro Série B 2012',
      ],
      highlights: [
        'Marcou aos 38 minutos do segundo tempo o gol da vitória por 2 a 1 sobre o Joinville, em 24/11/2012, que confirmou o título da Série B',
      ],
      matches: 173,
      goals: 47,
      // 173 jogos/47 gols: ge + ogol (soma das quatro temporadas: 2008 31/12, 2009 60/18, 2011 23/7, 2012 59/10). Substitui o 154 antigo. Goianos 2009/2012: gravados na rodada 07/10/2026 — Iarley está nas escalações das finais de 2009 e 2012 (Bola na Área) e o ge registra dois estaduais.
      // Pesquisa 2026-10: ge + ogol (154 jogos). 43 gols (ogol) = 1 FONTE — não importado.
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
      highlights: [
        'Artilheiro da Copa Sul-Americana de 2010, com 8 gols em 10 jogos',
        'Marcou o gol sobre o Avaí que classificou o Goiás para a semifinal da Sul-Americana de 2010 e jogou a final contra o Independiente',
        'Fez 25 gols em 51 jogos na temporada de 2010',
        'Chegou ao 50º gol pelo Goiás em 25/01/2021, em seu 117º jogo pelo clube',
      ],
      // Pesquisa 2026-10: o Goiás registrou o 50º gol em 25/01/2021 (117 jogos), então o 49 antigo estava errado. Total FINAL de jogos/gols ainda não confirmado — vazio de propósito. Naquele 25/01/2021 as passagens somavam 52/25 + 27/12 + 38/13 = 117/50; ele ainda jogou depois (inclusive marcou em fev/2021). Não somar manualmente. Rodada 07/10/2026: o antigo 120/49 = 52/25 (2010) + 27/12 (2019) + 41/12 (2020, ano-calendário) — SEM os jogos de 2021; a Goal.com trazia 109 jogos/47 gols e o painel do Futebol de Goyaz 147/54 (escopo desconhecido) — nenhum serve como total final.
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
      matches: 97,
      goals: 48,
      statsScope: 'Somando as duas passagens (2012-2013 e 2016-2017)',
      titles: ['Campeonato Brasileiro Série B 2012', 'Campeonato Goiano 2013'],
      highlights: [
        'Na primeira passagem, o Goiás registra 81 jogos e 45 gols',
        'Fez 16 gols na campanha do título da Série B de 2012',
        'Fez 11 gols no Campeonato Goiano de 2013 e 13 no Campeonato Brasileiro de 2013',
        'Marcou 5 gols na Copa do Brasil na primeira passagem',
      ],
      // Auditoria 06/10/2026: 81 jogos/45 gols = fonte oficial do Goiás, SÓ 2012-2013 (o 82 antigo estava errado). 48 gols somando as duas passagens: ge (97 jogos/48 gols) + Esporte Goiano de 11/03/2022 (98 jogos/48 gols) — os GOLS fecham em duas fontes. Jogos: Esporte Goiano (2022) e outra base apontam 98, mas a declaração do próprio Walter na época (97 jogos/48 gols) e a divisão do ge (81/45 + 2016: 10/3 + 2017: 6/0 = 97/48) sustentam 97, sem outra partida antes da saída — rodada 06/10/2026, decisão do usuário.
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
      highlights: [
        'Acesso à Série A em 2018',
        'Destaque nacional em 2019, com 16 gols em 54 jogos na temporada',
      ],
      story:
          'Michael chegou ao Goiás em 2017 e foi peça importante da equipe campeã '
          'estadual e promovida à Série A em 2018. Em 2019 ganhou projeção '
          'nacional e recebeu o prêmio de revelação do Campeonato Brasileiro. '
          'Encerrou a passagem com 129 partidas e 24 gols antes da transferência '
          'para o Flamengo.',
      // Pesquisa 2026-10: ge + O Popular — 129/24 e Goiano 2018 CONFIRMADOS.
    ),
    // ----------------------------------------------------------------- atual
    ClubIdol(
      name: 'Tadeu',
      tier: 1,
      evidenceExplicitIdol: false,
      position: 'Goleiro',
      period: 'Desde 2019',
      photoAsset: 'lib/assets/squad/goias/tadeu.jpg',
      fullName: 'Tadeu Antônio Ferreira',
      // Segue em atividade: número sempre com data de referência.
      titles: ['Copa Verde 2023', 'Campeonato Goiano 2026'],
      description:
          'Goleiro no clube desde 2019, completou 400 jogos pelo Goiás em '
          '28/08/2026 e é o segundo jogador com mais partidas pelo clube.',
      matches: 406,
      goals: 13,
      statsAsOf: '2026-10-01',
      highlights: [
        'Estreou pelo Goiás em 28/04/2019, contra o Fluminense, e defendeu um pênalti na vitória por 1 a 0',
        'Chegou ao 400º jogo pelo clube em agosto de 2026',
        'Segundo jogador com mais partidas pela camisa do Goiás',
      ],
      // Pesquisa 2026-10: 406 jogos após Goiás x Novorizontino (01/10/2026), O Popular + imprensa local; 13 gols = ge + Mais Goiás.
    ),
  ];
}
