import 'package:flutter/material.dart';
import 'package:goias_app/core/club/club_assets.dart';
import 'package:goias_app/core/club/club_branding.dart';
import 'package:goias_app/core/club/club_capabilities.dart';
import 'package:goias_app/core/club/club_config.dart';
import 'package:goias_app/core/club/club_identity.dart';
import 'package:goias_app/core/club/club_integrations.dart';
import 'package:goias_app/core/club/club_product_naming.dart';
import 'package:goias_app/core/club/commerce_mode.dart';
import 'package:goias_app/core/club/membership_program_config.dart';
import 'package:goias_app/core/theme/app_colors.dart';
import 'package:goias_app/features/membership/domain/entities/regulation_version.dart';
import 'synthetic_passport_content.dart';

/// Clube sintético/neutro pra testes de tenant-scope e isolamento de
/// identidade (M3.1 + M4.1) — nunca um time real, nunca cadastrado em
/// `clubRegistry`. Diferente de toda a primeira versão (M3.1), branding/
/// assets/integrations/productNames aqui são DELIBERADAMENTE distintos do
/// Goiás — não reaproveita mais nada — porque a auditoria M4 encontrou
/// múltiplos pontos que ainda liam `AppColors`/`AppAssets`/valores
/// hardcoded do Goiás em vez de `ClubConfig`; um clube sintético que
/// reaproveitasse os mesmos valores nunca provaria esse tipo de bug (os
/// dois "clubes" pareceriam iguais mesmo com o bypass presente).
///
/// `canonicalClubId` é um UUID qualquer, deliberadamente DIFERENTE do
/// Goiás — usado pra provar que uma query nunca vaza `club_id` de outro
/// clube por acidente.
final syntheticClubBConfig = ClubConfig(
  identity: ClubIdentity(
    code: 'club-b',
    slug: 'club-b',
    displayName: 'Clube Sintético B',
    shortName: 'Clube B',
    fanDemonym: 'Torcedor B',
    canonicalClubId: '00000000-0000-0000-0000-0000000000b1',
  ),
  branding: ClubBranding(
    light: AppColors(
      background: Color(0xFFF5F7FA),
      surface: Color(0xFFFFFFFF),
      surfaceRaised: Color(0xFFFFFFFF),
      primary: Color(0xFF0B3D91),
      onPrimary: Color(0xFFFFFFFF),
      secondary: Color(0xFFE3EAF6),
      brandDark: Color(0xFF0A2E6B),
      brandDeep: Color(0xFF071F49),
      cta: Color(0xFF1858C7),
      gold: Color(0xFFB08A2E),
      textPrimary: Color(0xFF111318),
      textSecondary: Color(0xFF5D6470),
      textHint: Color(0xFF9AA1AC),
      border: Color(0xFFDCE2EA),
      error: Color(0xFFB3261E),
      success: Color(0xFF1B7A3D),
    ),
    dark: AppColors(
      background: Color(0xFF080B14),
      surface: Color(0xFF10151F),
      surfaceRaised: Color(0xFF161C28),
      primary: Color(0xFF3D74D6),
      onPrimary: Color(0xFFFFFFFF),
      secondary: Color(0xFF16233A),
      brandDark: Color(0xFF0A2E6B),
      brandDeep: Color(0xFF071F49),
      cta: Color(0xFF4C86E0),
      gold: Color(0xFFC79C43),
      textPrimary: Color(0xFFF3F5F8),
      textSecondary: Color(0xFFAAB2BF),
      textHint: Color(0xFF6D7683),
      border: Color(0xFF232C3B),
      error: Color(0xFFE6837B),
      success: Color(0xFF3FA664),
    ),
  ),
  assets: ClubAssets(
    crest: 'test/assets/club_b/crest.svg',
    crestBadge: 'test/assets/club_b/crest_badge.png',
    crest3d: 'test/assets/club_b/crest_3d.jpg',
    loginBackground: 'test/assets/club_b/login_background.png',
    stadium: 'test/assets/club_b/stadium.png',
    matchHero: 'test/assets/club_b/match_hero.png',
    tacticsBoardIllustration: 'test/assets/club_b/tactics_board.png',
    arenaStadiumIcon: 'test/assets/club_b/arena_stadium.svg',
    arenaStadiumPhoto: 'test/assets/club_b/arena_stadium.png',
    storeBanner: 'test/assets/club_b/store_banner.png',
  ),
  integrations: ClubIntegrations(
    oneFootballTeamId: 999999,
    oneFootballSlug: 'club-b-999999',
    oneFootballCompetitionSlug: 'campeonato-sintetico-b',
    orderPrefix: 'CLB',
    pickupAddress: ClubPickupAddress(
      storeName: 'Club B Store',
      street: 'Rua Sintética, 1',
      neighborhood: 'Bairro B',
      city: 'Cidade B',
      state: 'BB',
      zipCode: '00000-000',
    ),
    contactWhatsappNumber: '(00) 90000-0000',
    contactWhatsappUrl: 'https://wa.me/5500900000000',
    // Sem redes sociais/site oficial de propósito — prova que uma
    // integração ausente vira "indisponível", nunca cai pro Goiás.
  ),
  // M4.2A — desligado tudo que hoje depende de CONTEÚDO hardcoded do Goiás
  // sem nenhum scoping por clube (não é sobre a tabela ter club_id ou não —
  // é sobre o próprio dado, sempre real e sempre do Goiás, embutido no
  // binário): Loja (catálogo estático, `store_products.json`), Sócio
  // (`MembershipPlansCatalog.plans`, nomes/preços reais fixos), Ingressos
  // (`TicketFixture`, setores/preços/portões reais do Goiás E.C.) e
  // Escalação da Torcida (`goiasSquad`, elenco real usado pra resolver o
  // resultado da votação) — os 2 últimos são achados NOVOS desta rodada
  // (M4.2A), não estavam na auditoria M4 round 1/M4.1, que só tinham
  // olhado pra tabelas com club_id, não pro catálogo estático por trás
  // delas. Passaporte já era `false`. `enabledArenaGames` continua com
  // 'quiz' porque o conteúdo do Arena É genuinamente club_id-scoped
  // (M3.1/M3.2, com `ClubScopedFallback` nunca cross-club).
  capabilities: ClubCapabilities(
    hasMembership: false,
    hasStore: false,
    hasTickets: false,
    hasCrowdLineup: false,
    hasPassport: false,
    hasNews: false,
    hasSocial: false,
    hasClubContent: false,
    hasPartners: false,
    hasMatches: false,
    enabledArenaGames: {'quiz'},
    storeCommerceMode: CommerceMode.demo,
    ticketCommerceMode: CommerceMode.demo,
    membershipCommerceMode: CommerceMode.demo,
  ),
  productNames: ClubProductNaming(
    arenaName: 'Arena B',
    passportName: 'Passaporte B',
    storeName: 'Club B Store',
    membershipProgramName: 'Sócio B',
  ),
  passportContent: syntheticPassportContent,
  // `hasMembership: false` acima — nunca lido por nenhum teste, plans/
  // regulamento vazios de propósito (mesmo espírito do resto deste
  // arquivo: sintético, nunca reaproveita dado do Goiás).
  membershipProgram: MembershipProgramConfig(
    plans: [],
    regulationVersion: RegulationVersion(
      id: 'synthetic-club-b',
      version: 'synthetic',
      effectiveAt: DateTime(2000),
      assetPath: 'test/assets/club_b/membership_regulation.md',
    ),
    regulationIntro: '',
    regulationSections: const [],
    sourceLabel: 'Clube sintético de teste.',
    sourceUpdatedAt: DateTime(2000),
  ),
);
