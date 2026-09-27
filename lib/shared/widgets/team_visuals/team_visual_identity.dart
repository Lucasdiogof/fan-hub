import 'package:flutter/material.dart';
import 'package:goias_app/core/club/club_config.dart';
import 'package:goias_app/features/match/domain/entities/team.dart';

/// Identidade visual estilizada de um time pro [StyledTeamBadge] — sigla +
/// cor(es), nunca o escudo oficial. Camada NOVA, paralela ao escudo
/// oficial/`_fallbackPalette` de [TeamDto] (que continuam existindo intactos
/// pra rollback — ver `club_badge.dart`).
class TeamVisualIdentity {
  const TeamVisualIdentity({
    required this.acronym,
    required this.primaryColor,
    this.secondaryColor,
  });

  /// Sigla curta (3-4 letras), maiúscula, exibida no centro do badge.
  final String acronym;

  /// Cor predominante do time — preenchimento principal do escudo (deve
  /// cobrir a maior parte do shield, ~70-100%).
  final Color primaryColor;

  /// Segunda cor do time, só quando ela REALMENTE ajuda a reconhecer o
  /// clube (faixa/detalhe pequeno, ~20-30% do shield) — nunca uma área
  /// grande. `null` = shield 100% `primaryColor`, sem faixa nenhuma.
  ///
  /// NUNCA branco puro aqui: quando a segunda cor oficial do time é branca,
  /// a escolha é sempre uma das três — deixar `null` (só a primary), usar
  /// uma variação mais clara/escura da primary, ou aceitar que o branco
  /// aparece só no texto da sigla/numa borda fina (nunca preenchendo uma
  /// área grande do shield) — branco grande lia como "placeholder
  /// genérico", não como identidade de time (ver `docs/` da revisão
  /// 2026-09-22 de cores).
  final Color? secondaryColor;
}

/// Resolve a identidade visual estilizada de um [Team]:
/// 1. Se for o clube ativo (Goiás/Bragantino), usa a cor oficial já
///    configurada em [ClubConfig.branding] — nunca duplica a cor à parte,
///    pra nunca divergir se a marca mudar.
/// 2. Senão, procura o nome normalizado na tabela curada [_knownTeams]
///    (times reais do Brasileirão Série A/B com cor e sigla verdadeiras).
/// 3. Sem match, cai no MESMO fallback que já existia antes desta feature —
///    `team.shortName` + `team.color` (paleta determinística por id, ver
///    `team_dto.dart`) — garante que todo time, mapeado ou não, sai com o
///    mesmo estilo de escudo (só a precisão da cor/sigla muda). Fallback
///    determinístico é SÓ pra time realmente desconhecido — todo clube
///    listado na tabela curada usa a cor curada, nunca a paleta genérica.
TeamVisualIdentity resolveTeamVisualIdentity({
  required Team team,
  required ClubConfig clubConfig,
}) {
  if (team.matchesClub(clubConfig)) {
    return resolveActiveClubVisualIdentity(
      clubConfig,
      fallbackAcronym: team.shortName,
    );
  }

  final match = _knownTeams[_normalizeTeamName(team.name)];
  if (match != null) return match;

  return TeamVisualIdentity(acronym: team.shortName, primaryColor: team.color);
}

/// Mesma resolução do branch "clube ativo" acima, mas sem exigir um [Team]
/// — usada por `ClubBadge.activeClub()`/`StyledTeamBadge.forActiveClub`,
/// que hoje nunca tiveram um `Team` de verdade (só `ClubConfig`).
///
/// `secondaryColor` é sempre `null` aqui de propósito (revisão 2026-09-22):
/// nunca inventa uma segunda cor pro clube ativo — pro Goiás em especial,
/// a regra explícita é shield 100% `#004C1B`, sem faixa/rodapé branco
/// nenhum. Se um clube ativo futuro tiver uma segunda cor real que valha a
/// pena representar, isso deve vir de um campo próprio em `ClubConfig`, não
/// ser inferido aqui.
TeamVisualIdentity resolveActiveClubVisualIdentity(
  ClubConfig clubConfig, {
  String? fallbackAcronym,
}) {
  final acronym =
      _activeClubAcronyms[clubConfig.identity.code] ??
      fallbackAcronym ??
      clubConfig.identity.shortName
          .substring(0, clubConfig.identity.shortName.length.clamp(0, 3))
          .toUpperCase();
  return TeamVisualIdentity(
    acronym: acronym,
    primaryColor: clubConfig.branding.light.primary,
  );
}

/// Sigla oficial de cada clube ATIVO suportado pelo app — `ClubIdentity` não
/// tem campo de sigla (só `code`/`slug`/`displayName`/`shortName`), então
/// mapeamos aqui em vez de inventar um campo novo em `ClubIdentity` só pra
/// isso. Time ativo futuro sem entrada aqui cai em `team.shortName`
/// (derivado), nunca quebra o build.
const _activeClubAcronyms = {'goias': 'GOI', 'bragantino': 'RBB'};

const _c = Color.new;

/// Tabela curada de identidade visual dos clubes mais comuns do futebol
/// brasileiro (Série A + Série B, e alguns tradicionais de acesso/Copa do
/// Brasil) — cores/siglas REAIS, nunca a paleta genérica determinística.
/// Revisada em 2026-09-22 (auditoria de cor time a time, screenshot de
/// referência) com uma regra fixa: branco NUNCA é uma área grande do
/// shield — só texto/borda fina. Quando a 2ª cor oficial de um time é
/// branca, a tabela usa `secondaryColor: null` (só a primary, shield
/// inteiro) ou uma variação mais escura da própria primary — nunca
/// `Colors.white` como `secondaryColor`.
///
/// Chave: nome normalizado (ver [_normalizeTeamName]) — aceita a forma mais
/// comum retornada pela API e variações plausíveis (com/sem UF, abreviado).
/// Time do Brasileiro que não estiver aqui simplesmente cai no fallback
/// (`team.shortName` + `team.color`) — a tabela não precisa ser exaustiva,
/// só cobrir os confrontos mais frequentes dos clubes ativos.
final Map<String, TeamVisualIdentity> _knownTeams = {
  for (final entry in _rawKnownTeams)
    for (final alias in entry.$1)
      _normalizeTeamName(alias): TeamVisualIdentity(
        acronym: entry.$2,
        primaryColor: entry.$3,
        secondaryColor: entry.$4,
      ),
};

final _rawKnownTeams = <(List<String>, String, Color, Color?)>[
  // --- Clube ativo, também curado (pra quando aparece como ADVERSÁRIO no
  // outro flavor do app, ex.: Goiás no build do Bragantino) ---
  (['Goiás', 'Goiás Esporte Clube', 'Goiás EC'], 'GOI', _c(0xFF004C1B), null),
  (
    ['Red Bull Bragantino', 'Bragantino', 'RB Bragantino'],
    'RBB',
    _c(0xFFD2003C),
    null,
  ),

  // --- Série B (regra explícita do pedido 2026-09-22) ---
  (['Vila Nova', 'Vila Nova-GO'], 'VIL', _c(0xFFE30613), _c(0xFF8F0010)),
  (['Fortaleza', 'Fortaleza EC'], 'FOR', _c(0xFF005CA9), _c(0xFFE30613)),
  (
    ['Grêmio Novorizontino', 'Novorizontino'],
    'NOV',
    _c(0xFFF6C500),
    _c(0xFF111111),
  ),
  (['Juventude', 'EC Juventude'], 'JUV', _c(0xFF00843D), _c(0xFF005E2D)),
  (['Criciúma', 'Criciúma EC'], 'CRI', _c(0xFFF4C300), _c(0xFF111111)),
  (
    ['Atlético Goianiense', 'Atlético-GO', 'Atlético GO'],
    'ACG',
    _c(0xFFE21D2D),
    _c(0xFF111111),
  ),
  (['CRB', 'Clube de Regatas Brasil'], 'CRB', _c(0xFFD7193F), _c(0xFFA30D2A)),
  (
    ['Operário', 'Operário-PR', 'Operário Ferroviário'],
    'OPE',
    _c(0xFF111111),
    _c(0xFF333333),
  ),
  (
    ['Sport', 'Sport Recife', 'Sport Club do Recife'],
    'SPO',
    _c(0xFFC8102E),
    _c(0xFF111111),
  ),
  (['Cuiabá', 'Cuiabá EC'], 'CUI', _c(0xFFF7C800), _c(0xFF178A43)),
  (['São Bernardo', 'São Bernardo FC'], 'SBE', _c(0xFFF4C300), _c(0xFF111111)),
  (
    ['Athletic Club', 'Athletic', 'Athletic Club MG'],
    'ACS',
    _c(0xFF111111),
    _c(0xFF353535),
  ),
  (
    ['Náutico', 'Clube Náutico Capibaribe'],
    'NAU',
    _c(0xFFD71920),
    _c(0xFFA50E16),
  ),
  (['Ceará', 'Ceará SC'], 'CEA', _c(0xFF111111), _c(0xFF303030)),
  (
    ['Botafogo-SP', 'Botafogo Ribeirão Preto'],
    'BSP',
    _c(0xFF111111),
    _c(0xFFD71920),
  ),
  (['Avaí', 'Avaí FC'], 'AVA', _c(0xFF006CB7), _c(0xFF004A80)),
  (['Londrina', 'Londrina EC'], 'LON', _c(0xFF00529B), _c(0xFF003E75)),
  (
    ['América-MG', 'América Mineiro', 'América MG'],
    'AME',
    _c(0xFF009639),
    _c(0xFF006B2B),
  ),
  (['Ponte Preta', 'AA Ponte Preta'], 'PON', _c(0xFF111111), _c(0xFF303030)),

  // --- Série A e outros tradicionais (auditados na mesma revisão: sem
  // branco grande — time preto/branco ou verde/branco vira SÓ a primary,
  // `secondaryColor: null`) ---
  (['Internacional', 'SC Internacional'], 'INT', _c(0xFFE3242B), null),
  (['Remo', 'Clube do Remo'], 'REM', _c(0xFF0072BC), _c(0xFF8B1D2C)),
  (['Vitória', 'EC Vitória'], 'VIT', _c(0xFFCC092F), Colors.black),
  (['Botafogo', 'Botafogo FR'], 'BOT', Colors.black, null),
  (['Cruzeiro', 'Cruzeiro EC'], 'CRU', _c(0xFF003399), null),
  (['Santos', 'Santos FC'], 'SAN', Colors.black, null),
  (
    ['Athletico Paranaense', 'Athletico-PR', 'Atlético-PR', 'CAP'],
    'CAP',
    _c(0xFFCC092F),
    Colors.black,
  ),
  (['Fluminense', 'Fluminense FC'], 'FLU', _c(0xFF9B1B30), _c(0xFF006747)),
  (['Palmeiras', 'SE Palmeiras'], 'PAL', _c(0xFF006437), null),
  (['Mirassol', 'Mirassol FC'], 'MIR', _c(0xFFFFD400), _c(0xFF1B5E20)),
  (['Corinthians', 'SC Corinthians Paulista'], 'COR', Colors.black, null),
  (['Grêmio', 'Grêmio FBPA'], 'GRE', _c(0xFF0D80C4), Colors.black),
  (['Vasco da Gama', 'Vasco', 'CR Vasco da Gama'], 'VAS', Colors.black, null),
  (['São Paulo', 'São Paulo FC'], 'SAO', _c(0xFFE0261C), Colors.black),
  (['Flamengo', 'CR Flamengo'], 'FLA', _c(0xFFE30613), Colors.black),
  (
    [
      'Atlético Mineiro',
      'Atlético-MG',
      'Atlético MG',
      'Clube Atlético Mineiro',
    ],
    'CAM',
    Colors.black,
    null,
  ),
  (['Coritiba', 'Coritiba FC'], 'CFC', _c(0xFF00873E), Colors.black),
  (['Bahia', 'EC Bahia'], 'BAH', _c(0xFF0038A8), _c(0xFFE30613)),
  (['Chapecoense', 'Associação Chapecoense'], 'CHA', _c(0xFF00944D), null),
  (['Figueirense', 'Figueirense FC'], 'FIG', Colors.black, null),
  (['Paysandu', 'Paysandu SC'], 'PAY', _c(0xFF002D62), null),
  (['CSA'], 'CSA', _c(0xFFCC092F), Colors.black),
  (['Guarani', 'Guarani FC'], 'GUA', _c(0xFF00693E), null),
  (['Amazonas', 'Amazonas FC'], 'AMZ', _c(0xFF007A3D), null),
  (['ABC', 'ABC FC'], 'ABC', _c(0xFFCC092F), Colors.black),
  (['Ferroviária', 'AA Ferroviária'], 'FER', _c(0xFF0038A8), null),
  (['Tombense', 'Tombense FC'], 'TOM', Colors.black, null),
  (['Confiança', 'AS Confiança'], 'CON', _c(0xFFCC092F), Colors.black),
  (['Volta Redonda', 'Volta Redonda FC'], 'VOL', Colors.black, null),
];

/// Minúsculo, sem acento, sem pontuação — pra "Atlético-GO", "Atlético GO"
/// e "atletico go" caírem na mesma chave.
String _normalizeTeamName(String input) {
  const accented = 'áàâãäéèêëíìîïóòôõöúùûüçÁÀÂÃÄÉÈÊËÍÌÎÏÓÒÔÕÖÚÙÛÜÇ';
  const plain = 'aaaaaeeeeiiiiooooouuuucAAAAAEEEEIIIIOOOOOUUUUC';
  final buffer = StringBuffer();
  for (final char in input.split('')) {
    final idx = accented.indexOf(char);
    buffer.write(idx == -1 ? char : plain[idx]);
  }
  return buffer
      .toString()
      .toLowerCase()
      .replaceAll(RegExp(r'[^a-z0-9]+'), ' ')
      .trim();
}
