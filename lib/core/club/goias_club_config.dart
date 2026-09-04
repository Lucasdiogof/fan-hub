import 'package:goias_app/core/club/club_assets.dart';
import 'package:goias_app/core/club/club_branding.dart';
import 'package:goias_app/core/club/club_capabilities.dart';
import 'package:goias_app/core/club/club_config.dart';
import 'package:goias_app/core/club/club_identity.dart';
import 'package:goias_app/core/club/club_integrations.dart';
import 'package:goias_app/core/club/club_product_naming.dart';
import 'package:goias_app/core/theme/app_assets.dart';
import 'package:goias_app/core/theme/app_colors.dart';

/// A ÚNICA entrada de `clubRegistry` nesta rodada (M1). Todo valor abaixo
/// é o mesmo já em produção hoje — isto é reempacotamento, nunca dado
/// novo. Zero mudança visual/funcional: `AppColors.light`/`.dark` e
/// `AppAssets.*` continuam sendo a fonte real, isto só as referencia.
const goiasClubConfig = ClubConfig(
  identity: ClubIdentity(
    code: 'goias',
    slug: 'goias',
    displayName: 'Goiás Esporte Clube',
    shortName: 'Goiás',
    fanDemonym: 'Esmeraldino',
    canonicalClubId: '4c16340d-300c-5ab2-903f-17519db9b146',
  ),
  branding: ClubBranding(light: AppColors.light, dark: AppColors.dark),
  assets: ClubAssets(
    crest: AppAssets.goiasCrest,
    crestBadge: AppAssets.goiasCrestBadge,
    crest3d: AppAssets.goiasCrest3d,
    loginBackground: AppAssets.loginBackground,
    stadium: AppAssets.stadium,
    matchHero: AppAssets.matchHero,
    tacticsBoardIllustration: AppAssets.tacticsBoardIllustration,
    arenaStadiumIcon: AppAssets.arenaStadiumIcon,
    arenaStadiumPhoto: AppAssets.arenaStadiumPhoto,
    storeBanner: AppAssets.storeBanner,
    splashVideo: 'lib/assets/videos/goias_splash.mp4',
  ),
  integrations: ClubIntegrations(
    oneFootballTeamId: 1863,
    oneFootballSlug: 'goias-1863',
    oneFootballCompetitionSlug: 'brasileirao-serie-b-superbet-119',
    workerBaseUrl: 'https://goias-app.lucasdiogo1234.workers.dev',
    // Projeto Supabase real do Goiás (yonozsdgyrhgqrvydbnr) — valores que
    // já eram o `defaultValue` hardcoded de `SupabaseConfig` (agora
    // resolvido por clube, não mais por dart-define com fallback pro
    // Goiás). Chave publishable, nunca segredo de servidor.
    supabaseUrl: 'https://yonozsdgyrhgqrvydbnr.supabase.co',
    supabasePublishableKey: 'sb_publishable_G7wFeRd5jcKNI0oek24-5g_x3lDJV8t',
    supabaseRedirectUrl: 'https://goias-app.lucasdiogo1234.workers.dev',
    orderPrefix: 'GOI',
    pickupAddress: ClubPickupAddress(
      storeName: 'Goiás Store',
      street: 'Av. 85, 3277',
      neighborhood: 'Setor Bela Vista',
      city: 'Goiânia',
      state: 'GO',
      zipCode: '74823-310',
    ),
    contactWhatsappNumber: '(62) 99472-2541',
    contactWhatsappUrl: 'https://wa.me/5562994722541',
    socialInstagramUrl: 'https://www.instagram.com/goiasoficial/',
    socialYoutubeUrl: 'https://www.youtube.com/@TVGoias',
    socialTiktokUrl: 'https://www.tiktok.com/@goiasec',
    socialFacebookUrl: 'https://www.facebook.com/goiasoficial/',
    socialXUrl: 'https://x.com/goiasoficial',
    officialSiteUrl: 'https://www.goiasec.com.br/',
  ),
  capabilities: ClubCapabilities(
    hasMembership: true,
    hasStore: true,
    hasTickets: true,
    hasCrowdLineup: true,
    hasPassport: true,
    hasNews: true,
    hasSocial: true,
    hasClubContent: true,
    hasMatches: true,
    enabledArenaGames: {
      'quiz',
      'lineup',
      'career_path',
      'guess_player',
      'player_identity',
      'tactical_identity',
    },
  ),
  productNames: ClubProductNaming(
    arenaName: 'Arena Esmeraldina',
    passportName: 'Passaporte Esmeraldino',
    storeName: 'Goiás Store',
    membershipProgramName: 'Sócio Esmeralda',
  ),
);
