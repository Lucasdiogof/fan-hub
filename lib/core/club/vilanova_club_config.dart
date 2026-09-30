import 'package:flutter/material.dart';
import 'package:goias_app/core/club/club_assets.dart';
import 'package:goias_app/core/club/club_branding.dart';
import 'package:goias_app/core/club/club_capabilities.dart';
import 'package:goias_app/core/club/club_config.dart';
import 'package:goias_app/core/club/club_identity.dart';
import 'package:goias_app/core/club/club_institutional_content.dart';
import 'package:goias_app/core/club/club_integrations.dart';
import 'package:goias_app/core/club/club_product_naming.dart';
import 'package:goias_app/core/club/commerce_mode.dart';
import 'package:goias_app/core/club/membership_program_config.dart';
import 'package:goias_app/core/theme/app_colors.dart';
import 'package:goias_app/features/club/data/vilanova_history_data.dart';
import 'package:goias_app/features/club/data/vilanova_idols_data.dart';
import 'package:goias_app/features/club/data/vilanova_timeline_data.dart';
import 'package:goias_app/features/club/data/vilanova_titles_data.dart';
import 'package:goias_app/features/membership/domain/entities/regulation_version.dart';
import 'package:goias_app/features/passport/data/vilanova_passport_content.dart';

// ============================================================================
// Vila Nova Futebol Clube — 3ª entrada REAL do clubRegistry (F1).
//
// Fonte de todo dado aqui: `docs/vila_nova_data/` (pacote de pesquisa,
// estado em `HANDOFF_ESTADO.md`). NUNCA usa dado/asset do Goiás (rival local)
// nem do Bragantino como fallback.
//
// Capabilities ligam fase a fase, só depois do dado validado: F3 ligou
// `hasClubContent`; faltam F4 diretoria/elenco, F5 Arena, F6 Passaporte, F7
// Sócio/Loja/Ingressos, F8 Jogos/Notícias/Redes.
//
// DATA_GAPs reais (null de propósito, nunca inventados):
//   * supabaseUrl/supabasePublishableKey preenchidos em 2026-09-29 (projeto
//     vkybbrfvmexevakknlsi, criado pelo usuário). Schema/seeds do runbook
//     (docs/multiclub/60_vilanova_seeds_runbook.md) ainda não aplicados —
//     o flavor sobe mas o banco está vazio até isso rodar.
//   * supabaseRedirectUrl — Worker do Vila é a F8, ainda não existe; fica
//     null até lá (nunca aponta pra uma URL que não resolve).
//   * workerBaseUrl — Worker do Vila é a F8.
// ============================================================================

// Cor oficial única do clube, do manual de identidade visual (pág. 9):
// C0 M93 Y73 K0 / RGB 195,61,65 / #C33D41 / PANTONE 18-1563 TPG. O resto
// da paleta é derivado dela (vinhos escurecidos), já que o manual não define
// cor secundária — só vermelho e branco.
const _vilaNovaLight = AppColors(
  background: Color(0xFFF7F7F8),
  surface: Color(0xFFFFFFFF),
  surfaceRaised: Color(0xFFFFFFFF),
  primary: Color(0xFFC33D41),
  onPrimary: Color(0xFFFFFFFF),
  // Vermelho oficial bem diluído, pra chips/superfícies selecionadas.
  secondary: Color(0xFFF8ECEC),
  // Vinhos derivados do vermelho oficial, pra heroes/gradientes/banners.
  brandDark: Color(0xFF7A2226),
  brandDeep: Color(0xFF4A1013),
  cta: Color(0xFFC33D41),
  // O manual não tem dourado; usado só como destaque semântico de troféu.
  gold: Color(0xFFE0A526),
  textPrimary: Color(0xFF111318),
  textSecondary: Color(0xFF5D636D),
  textHint: Color(0xFF969CA5),
  border: Color(0xFFE1E4E8),
  // Erro mais escuro que o vermelho de marca pra ser distinguível por
  // contexto (mesmo problema do Bragantino: marca vermelha).
  error: Color(0xFFA4161A),
  success: Color(0xFF198754),
);

const _vilaNovaDark = AppColors(
  // Preto levemente quente.
  background: Color(0xFF0F0A0B),
  surface: Color(0xFF1A1314),
  surfaceRaised: Color(0xFF241A1B),
  // Um tom acima do oficial pra funcionar sobre fundo escuro sem perder o
  // contraste do texto branco (4,7:1).
  primary: Color(0xFFCF4046),
  onPrimary: Color(0xFFFFFFFF),
  secondary: Color(0xFF3A2022),
  brandDark: Color(0xFF7A2226),
  brandDeep: Color(0xFF4A1013),
  cta: Color(0xFFD9484E),
  gold: Color(0xFFF2B84B),
  textPrimary: Color(0xFFF5F6F8),
  textSecondary: Color(0xFFB5AEAF),
  textHint: Color(0xFF7D7475),
  border: Color(0xFF3A2E2F),
  error: Color(0xFFFF6B6B),
  success: Color(0xFF3FBF75),
);

// Assets de marca gerados do vetor oficial por
// `tooling/vilanova_brand/build_brand_assets.py` (nada redesenhado).
const _dir = 'lib/assets/branding/vilanova';
// Placeholders neutros (cinza), nunca os de outro clube — trocar quando
// houver arte real (estádio, lousa tática, loja).
const _phRaster = '$_dir/placeholder.png';
const _phVector = '$_dir/placeholder.svg';

final vilaNovaClubConfig = ClubConfig(
  identity: const ClubIdentity(
    code: 'vilanova',
    slug: 'vilanova',
    displayName: 'Vila Nova Futebol Clube',
    shortName: 'Vila Nova',
    fanDemonym: 'Colorado',
    // `tooling/multiclub/clubs_registry.json` (goias-app:multiclub:club:3).
    canonicalClubId: '3a6b1e27-8441-533d-b6b8-99fdcfdf1c3e',
    foundingYear: 1943,
  ),
  branding: const ClubBranding(light: _vilaNovaLight, dark: _vilaNovaDark),
  assets: const ClubAssets(
    // Escudo branco vazado (pág. 3 do vetor oficial) — o selo do cadastro é
    // tingido de branco, então precisa das formas brancas sobre transparente.
    crest: '$_dir/crest_seal.svg',
    crestBadge: '$_dir/crest_badge.png',
    crest3d: '$_dir/crest_badge.png',
    // Provisório no espírito do Bragantino: gradiente vinho + escudo
    // oficial, composto programaticamente (não é arte de designer).
    loginBackground: '$_dir/login_background.png',
    stadium: null,
    matchHero: null,
    tacticsBoardIllustration: _phRaster,
    arenaStadiumIcon: _phVector,
    arenaStadiumPhoto: _phRaster,
    storeBanner: _phRaster,
  ),
  integrations: const ClubIntegrations(
    // Projeto Supabase do Vila, criado pelo usuário em 2026-09-29. A
    // publishable key não é segredo (mesmo padrão do Goiás/Bragantino,
    // já commitados em texto puro); nunca a service_role/senha de banco.
    supabaseUrl: 'https://vkybbrfvmexevakknlsi.supabase.co',
    supabasePublishableKey: 'sb_publishable_Jk2mNyr_WXwNw-h1ge9cbA_0pc0T__E',
    // Confirmados em onefootball.com/pt-br/time/vila-nova-2865 (2026-09-29):
    // o Vila disputa a mesma Série B do Goiás em 2026.
    oneFootballTeamId: 2865,
    oneFootballSlug: 'vila-nova-2865',
    oneFootballCompetitionSlug: 'brasileirao-serie-b-superbet-119',
    orderPrefix: 'VIL',
    pickupAddress: null,
    socialInstagramUrl: 'https://www.instagram.com/vilanovafc/',
    socialTiktokUrl: 'https://www.tiktok.com/@vilanovafc',
    socialFacebookUrl: 'https://www.facebook.com/vilanovafc/',
    socialXUrl: 'https://twitter.com/VilaNovaFC',
    officialSiteUrl: 'https://www.vilanovafc.com.br/',
  ),
  capabilities: const ClubCapabilities(
    hasMembership: false,
    hasStore: false,
    hasTickets: false,
    hasCrowdLineup: false,
    hasPassport: false,
    hasNews: false,
    hasSocial: false,
    // F3: história, linha do tempo, títulos e ídolos estáticos (pacote
    // v1.2). Diretoria/transparência (Supabase) entram na F4.
    hasClubContent: true,
    // Lista de patrocinadores incompleta no pacote (máster não confirmado) —
    // fica desligado até a lista fechar e passar por decisão editorial.
    hasPartners: false,
    hasMatches: false,
    enabledArenaGames: {},
    storeCommerceMode: CommerceMode.demo,
    ticketCommerceMode: CommerceMode.demo,
    membershipCommerceMode: CommerceMode.demo,
  ),
  productNames: const ClubProductNaming(
    // Arena/Passaporte: sugestões do pacote de pesquisa. Loja e Sócio: nomes
    // OFICIAIS do clube (Nação Colorada / Sócio Tigrão).
    arenaName: 'Arena do Tigre',
    passportName: 'Passaporte Colorado',
    storeName: 'Nação Colorada',
    membershipProgramName: 'Sócio Tigrão',
  ),
  passportContent: VilaNovaPassportContent.content,
  // `hasMembership: false` — programa vazio até a F7 (planos/regulamento do
  // Sócio Tigrão ainda em REVIEW no pacote). O asset de regulamento abaixo
  // ainda NÃO existe e nunca é lido enquanto a capability estiver desligada.
  membershipProgram: MembershipProgramConfig(
    plans: const [],
    regulationVersion: RegulationVersion(
      id: 'socio-tigrao-pendente',
      version: 'pendente',
      effectiveAt: DateTime(2026, 9, 29),
      assetPath: 'lib/assets/legal/vilanova_membership_regulation.md',
    ),
    regulationIntro: '',
    regulationSections: const [],
    sourceLabel: 'Programa Sócio Tigrão ainda não integrado ao app.',
    sourceUpdatedAt: DateTime(2026, 9, 29),
  ),
  institutionalContent: const ClubInstitutionalContent(
    history: VilaNovaHistoryData.sections,
    timeline: VilaNovaTimelineData.events,
    titles: VilaNovaTitlesData.groups,
    historicalCampaigns: VilaNovaTitlesData.historicalCampaigns,
    idols: VilaNovaIdolsData.idols,
  ),
);
