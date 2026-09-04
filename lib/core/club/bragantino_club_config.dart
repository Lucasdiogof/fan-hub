import 'package:flutter/material.dart';
import 'package:goias_app/core/club/club_assets.dart';
import 'package:goias_app/core/club/club_branding.dart';
import 'package:goias_app/core/club/club_capabilities.dart';
import 'package:goias_app/core/club/club_config.dart';
import 'package:goias_app/core/club/club_identity.dart';
import 'package:goias_app/core/club/club_integrations.dart';
import 'package:goias_app/core/club/club_product_naming.dart';
import 'package:goias_app/core/theme/app_colors.dart';

// ============================================================================
// Red Bull Bragantino — 2ª entrada REAL do clubRegistry (onboarding M4).
//
// MÍNIMO viável pra COMPILAR/rodar o flavor `bragantino` no Fan Hub. TODAS as
// capabilities começam FALSE e `enabledArenaGames` VAZIO — nenhuma feature do
// Bragantino tem dado/conteúdo real ainda. NUNCA usa dado/asset do Goiás como
// fallback.
//
// Os campos marcados PLACEHOLDER/TODO abaixo são DATA_GAP/ASSET_GAP reais que
// precisam de dado oficial antes de ligar qualquer capability — ver
// docs/multiclub/47_m4_bragantino_onboarding_design.md §8. São PLACEHOLDERS
// óbvios (nunca valores inventados apresentados como reais):
//   * canonicalClubId — precisa de uma linha REAL em public.clubs (0 db push
//     agora). Enquanto for este placeholder, toda query tenant-scoped do
//     Bragantino retorna vazio e toda RPC (que valida exists em clubs) falha
//     — esperado, o app só compila/roda com as telas gated off.
//   * branding — paleta NEUTRA de placeholder (nem verde do Goiás nem
//     vermelho oficial do Bragantino inventado). TODO: cores oficiais.
//   * assets — placeholders neutros em lib/assets/branding/bragantino/. TODO:
//     escudo/artes reais do Bragantino.
//   * integrations.oneFootball{TeamId,Slug,CompetitionSlug} — CONFIRMADOS
//     (não são mais placeholder), navegando onefootball.com/pt-br/time/
//     rb-bragantino-4734 e onefootball.com/pt-br/competicao/
//     brasileirao-betano-16 — ver comentários inline abaixo com a fonte.
//   * integrations.workerBaseUrl — DATA_GAP real: `null` até o Worker do
//     Bragantino ser deployado e validado (`hasMatches` continua `false`
//     até lá, ver ClubCapabilities).
// ============================================================================

// Paleta NEUTRA de placeholder — deliberadamente sem identidade (cinzas +
// azul neutro), pra deixar claro que NÃO é a cor real do Bragantino nem a do
// Goiás. TODO(M4-dados): substituir pelas cores oficiais.
const _placeholderLight = AppColors(
  background: Color(0xFFF4F5F7),
  surface: Color(0xFFFFFFFF),
  surfaceRaised: Color(0xFFECEFF1),
  primary: Color(0xFF37474F),
  onPrimary: Color(0xFFFFFFFF),
  secondary: Color(0xFFECEFF1),
  darkGreen: Color(0xFF263238),
  deepGreen: Color(0xFF1B2429),
  ctaGreen: Color(0xFF37474F),
  gold: Color(0xFFB0812E),
  textPrimary: Color(0xFF1F2429),
  textSecondary: Color(0xFF5B646B),
  textHint: Color(0xFF9AA2A8),
  border: Color(0xFFD9DEE2),
  error: Color(0xFFB00020),
  success: Color(0xFF2E7D32),
);

const _placeholderDark = AppColors(
  background: Color(0xFF12171B),
  surface: Color(0xFF1B2228),
  surfaceRaised: Color(0xFF232C33),
  primary: Color(0xFF90A4AE),
  onPrimary: Color(0xFF10161A),
  secondary: Color(0xFF263238),
  darkGreen: Color(0xFF0E1417),
  deepGreen: Color(0xFF0A0F12),
  ctaGreen: Color(0xFF90A4AE),
  gold: Color(0xFFD4A84B),
  textPrimary: Color(0xFFF2F4F5),
  textSecondary: Color(0xFFAEB6BC),
  textHint: Color(0xFF7C858B),
  border: Color(0xFF313A40),
  error: Color(0xFFCF6679),
  success: Color(0xFF81C784),
);

// Placeholders de asset — 2 arquivos neutros; nunca os do Goiás.
const _phRaster = 'lib/assets/branding/bragantino/placeholder.png';
const _phVector = 'lib/assets/branding/bragantino/placeholder.svg';

const bragantinoClubConfig = ClubConfig(
  identity: ClubIdentity(
    code: 'bragantino',
    slug: 'bragantino',
    displayName: 'Red Bull Bragantino',
    shortName: 'Bragantino',
    fanDemonym: 'Bragantino',
    // UUID REAL, já aplicado em public.clubs do projeto Bragantino
    // (yrgyzkaaudyzmsqwzecj) — uuidV5(CLUBS_UUID_NAMESPACE,
    // 'goias-app:multiclub:club:2'), canonizado em
    // tooling/multiclub/clubs_registry.json e confirmado ao vivo via
    // `select * from public.clubs` (ver docs/multiclub/53+). Não é mais
    // placeholder desde a convergência de schema de 2026-09-04.
    canonicalClubId: '51683d2a-ea1d-57c6-8014-996146f242e7',
  ),
  branding: ClubBranding(light: _placeholderLight, dark: _placeholderDark),
  assets: ClubAssets(
    crest: _phVector,
    crestBadge: _phRaster,
    crest3d: _phRaster,
    loginBackground: _phRaster,
    stadium: _phRaster,
    matchHero: _phRaster,
    tacticsBoardIllustration: _phRaster,
    arenaStadiumIcon: _phVector,
    arenaStadiumPhoto: _phRaster,
    storeBanner: _phRaster,
    // Sem vídeo oficial do Bragantino ainda — `null` explícito, nunca o
    // vídeo de outro clube. `SplashVideoPage` cai pra `StaticLogoSplash`
    // (mostra `crestBadge`, já é o placeholder neutro acima).
    splashVideo: null,
  ),
  integrations: ClubIntegrations(
    // Confirmado navegando onefootball.com/pt-br/time/rb-bragantino-4734
    // (também /en/team/rb-bragantino-4734) — nome oficial exibido "RB
    // Bragantino", id numérico 4734.
    oneFootballTeamId: 4734,
    oneFootballSlug: 'rb-bragantino-4734',
    // Confirmado navegando onefootball.com/pt-br/competicao/
    // brasileirao-betano-16 (e /tabela) — RB Bragantino aparece na
    // classificação (9º lugar no momento da consulta). Nome de exibição
    // "Brasileirão Betano" na própria página; usamos "Brasileirão Série A"
    // no app pelo mesmo motivo do Goiás usar "Brasileirão Série B" em vez
    // do nome com patrocinador (ver PRIMARY_COMPETITION_DISPLAY_NAME no
    // Worker) — consistente com `_competitionShortNames` em
    // `next_match_hero.dart`, que já normaliza pra esse padrão.
    oneFootballCompetitionSlug: 'brasileirao-betano-16',
    // Worker do Bragantino ainda não existe/não foi deployado — NUNCA usa
    // a URL do Worker do Goiás. `null` faz `ApiClient` falhar de forma
    // controlada (nunca cross-club) — ver `ClubIntegrations.workerBaseUrl`.
    workerBaseUrl: null,
    // Projeto Supabase REAL já existe (yrgyzkaaudyzmsqwzecj) e já tem o
    // schema canônico convergido (SCHEMA_DIFF=0 contra o Goiás). URL +
    // chave publishable/anon confirmadas pelo usuário em 2026-09-04 —
    // chave client-side oficial (nunca a anon key legacy, nunca service_
    // role/senha de banco). `Supabase.initialize`/Auth passam a apontar
    // de verdade pro projeto Bragantino quando o flavor `bragantino` roda.
    supabaseUrl: 'https://yrgyzkaaudyzmsqwzecj.supabase.co',
    supabasePublishableKey: 'sb_publishable_pa2JzbHgClEqRBAajsPjig_uvL5Ntcc',
    // Sem Worker/domínio próprio do Bragantino ainda (workerBaseUrl
    // continua null) -- redirectTo fica null nos fluxos de auth (reset de
    // senha etc.), Supabase usa a Site URL configurada no dashboard do
    // próprio projeto Bragantino como destino. Preencher quando o Worker
    // for deployado (mesmo racional de workerBaseUrl).
    supabaseRedirectUrl: null,
    orderPrefix: 'BRA',
    // Loja desligada (hasStore=false) — endereço nunca é exibido; placeholder.
    pickupAddress: ClubPickupAddress(
      storeName: 'Loja (indisponível)',
      street: '—',
      neighborhood: '—',
      city: '—',
      state: '—',
      zipCode: '—',
    ),
    // Sem redes/contato oficiais cadastrados ainda — null, nunca inventar.
    contactWhatsappNumber: null,
    contactWhatsappUrl: null,
    socialInstagramUrl: null,
    socialYoutubeUrl: null,
    socialTiktokUrl: null,
    socialFacebookUrl: null,
    socialXUrl: null,
    officialSiteUrl: null,
  ),
  // Tudo FALSE + Arena vazia até haver dado/conteúdo real do Bragantino.
  capabilities: ClubCapabilities(
    hasMembership: false,
    hasStore: false,
    hasTickets: false,
    hasCrowdLineup: false,
    hasPassport: false,
    hasNews: false,
    hasSocial: false,
    hasClubContent: false,
    // Worker do Bragantino ainda não existe/não foi testado — nunca usa o
    // Worker do Goiás nem temporariamente. Vira true só depois do deploy
    // + validação (ver ClubIntegrations.workerBaseUrl abaixo).
    hasMatches: false,
    enabledArenaGames: <String>{},
  ),
  productNames: ClubProductNaming(
    arenaName: 'Arena',
    passportName: 'Passaporte',
    storeName: 'Loja',
    membershipProgramName: 'Sócio',
  ),
);
