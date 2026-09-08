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
import 'package:goias_app/core/theme/app_colors.dart';
import 'package:goias_app/features/club/data/bragantino_history_data.dart';
import 'package:goias_app/features/club/data/bragantino_idols_data.dart';
import 'package:goias_app/features/club/data/bragantino_songs_data.dart';
import 'package:goias_app/features/club/data/bragantino_timeline_data.dart';
import 'package:goias_app/features/club/data/bragantino_titles_data.dart';
import 'package:goias_app/features/partners/data/bragantino_partners_data.dart';
import 'package:goias_app/features/passport/data/bragantino_passport_content.dart';

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
//   * branding — paleta V1 oficial real (vermelho/azul-marinho/amarelo do
//     escudo), cedida pelo usuário em 2026-09-06. Não é mais placeholder.
//   * assets — `crestBadge` já é o escudo oficial real (cedido pelo usuário
//     em 2026-09-06). `loginBackground` é um gradiente+escudo provisório
//     (composto, não desenhado por designer). Resto (crest vetorial,
//     crest3d, fotos de estádio, loja) continua placeholder neutro — TODO:
//     artes reais.
//   * integrations.oneFootball{TeamId,Slug,CompetitionSlug} — CONFIRMADOS
//     (não são mais placeholder), navegando onefootball.com/pt-br/time/
//     rb-bragantino-4734 e onefootball.com/pt-br/competicao/
//     brasileirao-betano-16 — ver comentários inline abaixo com a fonte.
//   * integrations.workerBaseUrl — DATA_GAP real: `null` até o Worker do
//     Bragantino ser deployado e validado (`hasMatches` continua `false`
//     até lá, ver ClubCapabilities).
// ============================================================================

// Paleta V1 oficial do Bragantino, cedida pelo usuário em 2026-09-06 — cores
// reais do escudo (vermelho/azul-marinho/amarelo), não mais placeholder.
const _bragantinoLight = AppColors(
  // Quase branco neutro — o Braga deve parecer muito mais branco que
  // vermelho no tema claro.
  background: Color(0xFFF7F7F8),
  surface: Color(0xFFFFFFFF),
  surfaceRaised: Color(0xFFFFFFFF),
  // Vermelho principal do escudo.
  primary: Color(0xFFD2003C),
  onPrimary: Color(0xFFFFFFFF),
  // Azul do escudo numa versão extremamente suave, pra chips/superfícies
  // selecionadas/áreas secundárias.
  secondary: Color(0xFFEDF1F6),
  // Azul-marinho oficial como cor profunda da identidade.
  brandDark: Color(0xFF001D46),
  // Variação ainda mais profunda pra heroes/gradientes/banners.
  brandDeep: Color(0xFF000D22),
  // No light o vermelho oficial já tem contraste muito bom com branco.
  cta: Color(0xFFD2003C),
  // Amarelo do escudo/Red Bull — troféus, destaques, pequenos accents.
  gold: Color(0xFFFFCC00),
  textPrimary: Color(0xFF111318),
  textSecondary: Color(0xFF5D636D),
  textHint: Color(0xFF969CA5),
  border: Color(0xFFE1E4E8),
  // Erro continua semanticamente vermelho, mas mais escuro que o vermelho
  // de marca pra ser distinguível por contexto.
  error: Color(0xFFB42318),
  // Verde fica exclusivamente semântico — não faz parte da identidade.
  success: Color(0xFF198754),
);

const _bragantinoDark = AppColors(
  // Preto levemente azulado.
  background: Color(0xFF080B10),
  surface: Color(0xFF10151C),
  surfaceRaised: Color(0xFF171E27),
  // Um pouco mais luminoso que o vermelho de marca pra funcionar melhor
  // sobre superfícies escuras.
  primary: Color(0xFFE0194D),
  onPrimary: Color(0xFFFFFFFF),
  // Navy discreto pra cards/chips selecionados.
  secondary: Color(0xFF172235),
  brandDark: Color(0xFF001D46),
  brandDeep: Color(0xFF000D22),
  // CTA ligeiramente mais vívido que primary.
  cta: Color(0xFFE52A5C),
  gold: Color(0xFFFFCC00),
  textPrimary: Color(0xFFF5F6F8),
  textSecondary: Color(0xFFAEB4BD),
  textHint: Color(0xFF747C87),
  border: Color(0xFF29323D),
  error: Color(0xFFFF6B6B),
  success: Color(0xFF3FBF75),
);

// Placeholders de asset — 2 arquivos neutros; nunca os do Goiás.
const _phRaster = 'lib/assets/branding/bragantino/placeholder.png';
const _phVector = 'lib/assets/branding/bragantino/placeholder.svg';

// Escudo oficial real, cedido pelo usuário em 2026-09-06 — só o raster
// (PNG). Ver `_crestSealReal` abaixo pra versão "vetorial" provisória
// (mesmo PNG embrulhado em SVG) usada em `crest`.
const _crestBadgeReal = 'lib/assets/branding/bragantino/crest_badge.png';

// Fundo provisório do login — gradiente com as cores oficiais (brandDark/
// brandDeep) + escudo real, composto programaticamente só pra tirar o
// placeholder neutro dessa tela. Ainda não é arte definitiva (hero
// desenhado por um designer, como o do Goiás).
const _loginBackgroundReal =
    'lib/assets/branding/bragantino/login_background.png';

// Versão "vetorial" provisória do escudo — sem traço vetorial de verdade
// ainda, então é o mesmo PNG oficial (`crest_badge.png`) embrulhado num SVG
// (`<image>` com o PNG em base64) só pra parar de usar o placeholder.svg
// (genérico) no selo tingido de branco do cadastro (`_CrestSeal` em
// auth_scaffold.dart, `ColorFilter.mode(Colors.white, srcIn)` — como o PNG
// já tem alfa real recortando o brasão, vira uma silhueta branca limpa,
// igual ao tratamento que o Goiás já tem com o SVG de verdade dele).
const _crestSealReal = 'lib/assets/branding/bragantino/crest_seal.svg';

/// Fotos pro Quem Vestiu o Manto — as 10 do elenco atual são as MESMAS
/// URLs do CDN oficial (`img.redbullbragantino.com`) já usadas em
/// `bragantino_squad_members.sql`, chaveadas pelo mesmo `id` de
/// `squad_members`; as 36 históricas (entregues em 2026-09-08, de 40
/// pedidas — faltam `cesar_haydar`/`ligger`/`edimar`/`gonzalo_fornari`)
/// são assets locais em `lib/assets/games/guess_player/bragantino/`,
/// chaveadas pelo slug do nome do jogador (mesma convenção de
/// `goiasGuessPlayerPhotos`, nunca uma chave nova/paralela). Sem entrada
/// aqui, `GuessPlayerRepository` resolve `imageUrl` como `null`, nunca um
/// placeholder genérico.
const _bragantinoGuessPlayerPhotos = {
  'tiago-volpi':
      'https://img.redbullbragantino.com/images/f_auto,q_auto,w_400/2026/3/13/jedmn2u3wlf6t5ypatw4/tiago-volpi',
  'andres-hurtado':
      'https://img.redbullbragantino.com/images/f_auto,q_auto,w_400/2026/3/13/gpgsjiqrtc7jpzewhkyb/andres-hurtado',
  'alix-vinicius':
      'https://img.redbullbragantino.com/images/f_auto,q_auto,w_400/2026/3/13/znm8zwxnjyhio147m4ew/alix',
  'gustavo-marques':
      'https://img.redbullbragantino.com/images/f_auto,q_auto,w_400/2026/3/13/igzcyqrbhmeftf5jdfea/gustavo-marques',
  'juninho-capixaba':
      'https://img.redbullbragantino.com/images/f_auto,q_auto,w_400/2026/3/13/qcknkekf5tdbpqoog7a3/juninho-capixaba',
  'fabinho':
      'https://img.redbullbragantino.com/images/f_auto,q_auto,w_400/2026/3/13/woqwrwsmzfhng3al0fla/fabinho-silva',
  'rodriguinho':
      'https://img.redbullbragantino.com/images/f_auto,q_auto,w_400/2026/3/13/pl8nxfp0taccry13ltbz/rodrigo-huendra',
  'lucas-barbosa':
      'https://img.redbullbragantino.com/images/f_auto,q_auto,w_400/2026/3/13/xqq5qy3b4zcnmgx1nzmy/lucas-barbosa',
  'henry-mosquera':
      'https://img.redbullbragantino.com/images/f_auto,q_auto,w_400/2026/3/13/zqtva3yctr01nfzobltl/henry-mosquera',
  'vinicinho-pereira':
      'https://img.redbullbragantino.com/images/f_auto,q_auto,w_400/2026/3/13/okbny04aehkxfeibt2sd/vinicius-pereira',
  // Históricas (36 de 40, entregues 2026-09-08) — assets locais.
  'aderlan': 'lib/assets/games/guess_player/bragantino/aderlan.png',
  'alerrandro': 'lib/assets/games/guess_player/bragantino/alerrandro.png',
  'artur': 'lib/assets/games/guess_player/bragantino/artur.png',
  'bruninho': 'lib/assets/games/guess_player/bragantino/bruninho.png',
  'bruno_tubarao': 'lib/assets/games/guess_player/bragantino/bruno_tubarao.jpg',
  'chrigor': 'lib/assets/games/guess_player/bragantino/chrigor.png',
  'claudinho': 'lib/assets/games/guess_player/bragantino/claudinho.png',
  // Cleiton segue no elenco atual — usa a mesma URL real do CDN oficial
  // (mais precisa que uma foto histórica de arquivo).
  'cleiton':
      'https://img.redbullbragantino.com/images/f_auto,q_auto,w_400/2026/3/13/gliozjfvi1mbxq88fibm/goleiro-cleiton',
  'emiliano_martinez':
      'lib/assets/games/guess_player/bragantino/emiliano_martinez.png',
  'eric_ramires': 'lib/assets/games/guess_player/bragantino/eric_ramires.jpg',
  'fabricio_bruno':
      'lib/assets/games/guess_player/bragantino/fabricio_bruno.jpg',
  'gabriel_novaes':
      'lib/assets/games/guess_player/bragantino/gabriel_novaes.jpg',
  'guilherme_lopes':
      'lib/assets/games/guess_player/bragantino/guilherme_lopes.jpg',
  'helinho': 'lib/assets/games/guess_player/bragantino/helinho.png',
  'jadsom': 'lib/assets/games/guess_player/bragantino/jadsom.png',
  'jan_hurtado': 'lib/assets/games/guess_player/bragantino/jan_hurtado.png',
  'julio_cesar': 'lib/assets/games/guess_player/bragantino/julio_cesar.jpg',
  'leandrinho': 'lib/assets/games/guess_player/bragantino/leandrinho.png',
  'leo_ortiz': 'lib/assets/games/guess_player/bragantino/leo_ortiz.png',
  'leo_realpe': 'lib/assets/games/guess_player/bragantino/leo_realpe.jpg',
  'luan_candido': 'lib/assets/games/guess_player/bragantino/luan_candido.png',
  'lucas_evangelista':
      'lib/assets/games/guess_player/bragantino/lucas_evangelista.jpg',
  'luis_phelipe': 'lib/assets/games/guess_player/bragantino/luis_phelipe.jpg',
  'matheus_jesus': 'lib/assets/games/guess_player/bragantino/matheus_jesus.jpg',
  'natan': 'lib/assets/games/guess_player/bragantino/natan.jpg',
  'pedro_naressi': 'lib/assets/games/guess_player/bragantino/pedro_naressi.jpg',
  'praxedes': 'lib/assets/games/guess_player/bragantino/praxedes.png',
  'raul': 'lib/assets/games/guess_player/bragantino/raul.jpg',
  'ricardo_ryller':
      'lib/assets/games/guess_player/bragantino/ricardo_ryller.png',
  'thonny_anderson':
      'lib/assets/games/guess_player/bragantino/thonny_anderson.png',
  'tomas_cuello': 'lib/assets/games/guess_player/bragantino/tomas_cuello.png',
  'uillian_correia':
      'lib/assets/games/guess_player/bragantino/uillian_correia.jpg',
  'vitinho': 'lib/assets/games/guess_player/bragantino/vitinho.png',
  'weverson_costa':
      'lib/assets/games/guess_player/bragantino/weverson_costa.jpg',
  'weverton': 'lib/assets/games/guess_player/bragantino/weverton.png',
  'ytalo': 'lib/assets/games/guess_player/bragantino/ytalo.png',
};

const bragantinoClubConfig = ClubConfig(
  identity: ClubIdentity(
    code: 'bragantino',
    slug: 'bragantino',
    displayName: 'Red Bull Bragantino',
    shortName: 'Bragantino',
    // "Massa Bruta" — apelido do clube desde a conquista da Taça Raul Leme
    // (1931), usado até hoje pela própria torcida/clube (ver
    // massabruta.com.br, programa oficial de sócio-torcedor). Confirmado
    // via pesquisa em fontes oficiais/imprensa em 2026-09-05.
    fanDemonym: 'Massa Bruta',
    // UUID REAL, já aplicado em public.clubs do projeto Bragantino
    // (yrgyzkaaudyzmsqwzecj) — uuidV5(CLUBS_UUID_NAMESPACE,
    // 'goias-app:multiclub:club:2'), canonizado em
    // tooling/multiclub/clubs_registry.json e confirmado ao vivo via
    // `select * from public.clubs` (ver docs/multiclub/53+). Não é mais
    // placeholder desde a convergência de schema de 2026-09-04.
    canonicalClubId: '51683d2a-ea1d-57c6-8014-996146f242e7',
    // Fundação do Clube Atlético Bragantino em 8/1/1928 (docs/bragantino_data
    // /data/club.json + BragantinoHistoryData) — nunca o ano do Goiás (1943).
    foundingYear: 1928,
  ),
  branding: ClubBranding(light: _bragantinoLight, dark: _bragantinoDark),
  assets: ClubAssets(
    crest: _crestSealReal,
    crestBadge: _crestBadgeReal,
    crest3d: _phRaster,
    loginBackground: _loginBackgroundReal,
    // `null` — sem foto oficial de estádio ainda. `StadiumBackdrop` (usado
    // pelo hero do cadastro) já desenha um fundo procedural com as cores
    // reais do clube nesse caso, bem melhor que o placeholder neutro.
    stadium: null,
    matchHero: _phRaster,
    tacticsBoardIllustration: _phRaster,
    arenaStadiumIcon: _phVector,
    arenaStadiumPhoto: _phRaster,
    storeBanner: _phRaster,
    // Sem vídeo oficial do Bragantino ainda — `null` explícito, nunca o
    // vídeo de outro clube. `SplashVideoPage` cai pra `StaticLogoSplash`
    // (mostra `crestBadge`, já é o placeholder neutro acima).
    splashVideo: null,
    // Quem Vestiu o Manto — mesmas 10 URLs do CDN oficial já usadas em
    // `bragantino_squad_members.sql` (elenco atual) + fotos históricas
    // locais, por `photo_key` (`GuessPlayerRepository` resolve por
    // `ClubConfig.assets.guessPlayerPhotos` — campo separado de
    // `squadPhotos` porque aqui misturamos URL remota e asset local, e
    // `SquadAvatar` — dono de `squadPhotos` — só sabe tratar asset local).
    guessPlayerPhotos: _bragantinoGuessPlayerPhotos,
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
    // Worker do Bragantino live desde 2026-09-04 — Cloudflare Workers
    // Builds (Git integration) rodando `tool/cloudflare_build_web_flavor.sh
    // bragantino`, validado ao vivo: /, /api/football/team/bragantino,
    // /api/football/standings (Brasileirão Série A), /api/football/
    // current-round todos OK; /api/football/team/goias corretamente
    // rejeitado (404) por este mesmo deploy.
    workerBaseUrl: 'https://bragantino-app.lucasdiogo1234.workers.dev',
    // Projeto Supabase REAL já existe (yrgyzkaaudyzmsqwzecj) e já tem o
    // schema canônico convergido (SCHEMA_DIFF=0 contra o Goiás). URL +
    // chave publishable/anon confirmadas pelo usuário em 2026-09-04 —
    // chave client-side oficial (nunca a anon key legacy, nunca service_
    // role/senha de banco). `Supabase.initialize`/Auth passam a apontar
    // de verdade pro projeto Bragantino quando o flavor `bragantino` roda.
    supabaseUrl: 'https://yrgyzkaaudyzmsqwzecj.supabase.co',
    supabasePublishableKey: 'sb_publishable_pa2JzbHgClEqRBAajsPjig_uvL5Ntcc',
    // Worker próprio existe desde 2026-09-04 — mesmo padrão do Goiás
    // (redirectTo dos fluxos de auth aponta pro Worker do próprio clube).
    supabaseRedirectUrl: 'https://bragantino-app.lucasdiogo1234.workers.dev',
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
    // 2026-09-07: as 186 partidas e os 49 estádios do Bragantino estão no
    // Supabase dele, a auditoria pós-importação passou, e a identidade da
    // tela agora é própria do clube (`bragantinoPassportContent`: "Passaporte
    // Massa Bruta", "Braga Raiz", "Lenda da Massa Bruta") — nada mais lê as
    // strings do Goiás. Falta só o teste autenticado do dono antes de marcar
    // como confirmado em produção.
    hasPassport: true,
    // 2026-09-08: Worker passou a integrar a fonte oficial real do Bragantino
    // (API JSON interna da própria SPA do Red Bull, sem raspagem/dado
    // inventado — ver `project_goias_app_media_multiclub.md`).
    hasNews: true,
    // 2026-09-08: YouTube oficial (@MassaBrutaTV / UC0x9Ypk2Z1lUdR4a88jMC2Q)
    // confirmado ao vivo contra a Data API v3 real — 15 vídeos reais
    // devolvidos pelo Worker, `?club=goias` no deploy do Bragantino segue
    // 404 (isolamento intacto). A causa do bloqueio anterior não era a
    // chave, era o secret gravado truncado (36/39 chars por um recorte no
    // prompt interativo do `wrangler secret put`) — corrigido regravando.
    // Instagram/X seguem sem config própria, mas o feed nunca falha global
    // por isso (`Promise.allSettled` por provider) — ver
    // `project_goias_app_media_multiclub.md`.
    hasSocial: true,
    // 2026-09-05: história/títulos/hino têm conteúdo real e pesquisado
    // (ver `BragantinoHistoryData`/`BragantinoTitlesData`/
    // `BragantinoSongsData`) — liga o `/clube`. Diretoria/Transparência
    // seguem vazias no Supabase do Bragantino ainda (SQL preparado, não
    // rodado) — a própria tela já trata isso como `LoadStatus.empty`
    // (ver `ClubDiretoriaPage`/`ClubTransparencyPage`), nunca crash.
    hasClubContent: true,
    // 10 parceiros confirmados com URL e logo oficiais direto da API do
    // clube (ver `BragantinoPartnersData`) — auditoria de 2026-09-06.
    hasPartners: true,
    // Worker deployado e validado ao vivo em 2026-09-04 (ver
    // ClubIntegrations.workerBaseUrl) — hasMatches liga junto com
    // workerBaseUrl, nunca um sem o outro (invariante já coberto pelo
    // teste em resolve_active_club_test.dart).
    hasMatches: true,
    enabledArenaGames: <String>{},
    // Todas as 3 capabilities de comércio já estão false acima — o modo
    // não importa funcionalmente ainda, mas precisa de um valor (nenhum
    // campo de ClubCapabilities é opcional). demo é o valor seguro/real
    // pros dois clubes hoje, nenhum tem gateway/bilheteria/API oficial.
    storeCommerceMode: CommerceMode.demo,
    ticketCommerceMode: CommerceMode.demo,
    membershipCommerceMode: CommerceMode.demo,
  ),
  productNames: ClubProductNaming(
    arenaName: 'Arena',
    passportName: 'Passaporte',
    storeName: 'Loja',
    membershipProgramName: 'Sócio',
  ),
  passportContent: BragantinoPassportContent.content,
  institutionalContent: ClubInstitutionalContent(
    history: BragantinoHistoryData.sections,
    timeline: BragantinoTimelineData.events,
    titles: BragantinoTitlesData.groups,
    historicalCampaigns: BragantinoTitlesData.historicalCampaigns,
    songs: BragantinoSongsData.songs,
    partners: BragantinoPartnersData.all,
    idols: BragantinoIdolsData.idols,
  ),
);
