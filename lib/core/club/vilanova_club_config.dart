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
import 'package:goias_app/features/membership/data/vilanova_membership_plans_catalog.dart';
import 'package:goias_app/features/membership/data/vilanova_regulation_content.dart';
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
//   * workerBaseUrl/supabaseRedirectUrl — Worker do Vila criado em
//     2026-09-30 (F8, `wrangler.vilanova.toml`). Jogos, notícias e redes
//     ligados (ver `hasNews`/`hasSocial`).
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
  // 2026-09-30: usuário reportou o vermelho de erro anterior
  // (`0xFFA4161A`) "meio apagado" ao lado do vermelho de marca — mais
  // vívido/saturado agora, pra realmente destacar como alerta.
  error: Color(0xFFD7263D),
  // Identidade "vermelho e branco, nada de verde" (usuário, 2026-09-30):
  // dourado faz o papel de "acerto"/sucesso aqui — o INVERSO do Goiás
  // (onde dourado = erro e verde = sucesso, ver `app_colors.dart`). Mesmo
  // valor de `gold` acima, não uma cor nova.
  success: Color(0xFFE0A526),
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
  // Ver nota da versão light: dourado = acerto/sucesso no Vila, nunca
  // verde. Mesmo valor de `gold` acima.
  success: Color(0xFFF2B84B),
);

// Assets de marca gerados do vetor oficial por
// `tooling/vilanova_brand/build_brand_assets.py` (nada redesenhado).
// Fotos individuais reais do elenco atual, extraídas de
// vilanovafc.com.br/elenco-profissional em 2026-09-30 (atributo `data-src`
// de cada `<img>`, formato AVIF) — hotlink direto pro CDN oficial do
// clube, nunca baixadas/redistribuídas (mesmo padrão do Bragantino,
// `_bragantinoGuessPlayerPhotos`). Chave = `SquadMember.id`, reaproveitada
// como `photo_key` das cartas do Manto que são o mesmo atleta do elenco
// atual (`vilanova_guess_players.sql`) — a MESMA foto nas duas telas.
//
// CAVEAT conhecido: o CDN do Vila só serve `.avif`, sem negociação de
// formato (`f_auto`) como o CDN do Bragantino — `Image.network` decodifica
// AVIF via Skia no Flutter recente, mas isso não foi testado ainda num
// device/emulador real neste momento. Se alguma foto não renderizar em
// produção, é o primeiro suspeito a checar.
const _vilaNovaGuessPlayerPhotos = {
  'vn_dalberson':
      'https://www.vilanovafc.com.br/imgs/270/370/images/dalberson-810.avif',
  'vn_gabriel_atila':
      'https://www.vilanovafc.com.br/imgs/270/370/images/gabriel-atila-692.avif',
  'vn_helton_leite':
      'https://www.vilanovafc.com.br/imgs/270/370/images/helton-leite-453.avif',
  'vn_anderson_jesus':
      'https://www.vilanovafc.com.br/imgs/270/370/images/anderson-jesus-051.avif',
  'vn_breno_bora':
      'https://www.vilanovafc.com.br/imgs/270/370/images/breno-bora-580.avif',
  'vn_douglas_mendes':
      'https://www.vilanovafc.com.br/imgs/270/370/images/douglas-mendes-285.avif',
  'vn_jonathan_costa':
      'https://www.vilanovafc.com.br/imgs/270/370/images/jonathan-costa-809.avif',
  'vn_samuel':
      'https://www.vilanovafc.com.br/imgs/270/370/images/samuel-648.avif',
  'vn_tiago_pagnussat':
      'https://www.vilanovafc.com.br/imgs/270/370/images/tiago-pagnussat-614.avif',
  'vn_dudu': 'https://www.vilanovafc.com.br/imgs/270/370/images/dudu-248.avif',
  'vn_enzo_bizzotto':
      'https://www.vilanovafc.com.br/imgs/270/370/images/enzo-806.avif',
  'vn_higor_meritao':
      'https://www.vilanovafc.com.br/imgs/270/370/images/higor-meritao-627.avif',
  'vn_joao_vieira':
      'https://www.vilanovafc.com.br/imgs/270/370/images/joao-vieira-816.avif',
  'vn_nathan_camargo':
      'https://www.vilanovafc.com.br/imgs/270/370/images/nathan-camargo-402.avif',
  'vn_willian_maranhao':
      'https://www.vilanovafc.com.br/imgs/270/370/images/willian-maranhao-793.avif',
  'vn_hayner':
      'https://www.vilanovafc.com.br/imgs/270/370/images/hayner-143.avif',
  'vn_higor_luiz':
      'https://www.vilanovafc.com.br/imgs/270/370/images/higor-luiz-583.avif',
  'vn_igor_carius':
      'https://www.vilanovafc.com.br/imgs/270/370/images/igor-carius-029.avif',
  'vn_willian_formiga':
      'https://www.vilanovafc.com.br/imgs/270/370/images/willian-formiga-896.avif',
  'vn_dodo': 'https://www.vilanovafc.com.br/imgs/270/370/images/dodo-759.avif',
  'vn_marquinhos_gabriel':
      'https://www.vilanovafc.com.br/imgs/270/370/images/marquinhos-gabriel-089.avif',
  'vn_andre_luis':
      'https://www.vilanovafc.com.br/imgs/270/370/images/andre-luis-941.avif',
  'vn_bruno_xavier':
      'https://www.vilanovafc.com.br/imgs/270/370/images/bruno-xavier-973.avif',
  'vn_dellatorre':
      'https://www.vilanovafc.com.br/imgs/270/370/images/dellatorre-534.avif',
  'vn_emerson_urso':
      'https://www.vilanovafc.com.br/imgs/270/370/images/emerson-urso-896.avif',
  'vn_everton_galdino':
      'https://www.vilanovafc.com.br/imgs/270/370/images/everton-galdino-691.avif',
  'vn_gustavo_puskas':
      'https://www.vilanovafc.com.br/imgs/270/370/images/gustavo-puskas-783.avif',
  'vn_janderson':
      'https://www.vilanovafc.com.br/imgs/270/370/images/janderson-468.avif',
  'vn_lincoln':
      'https://www.vilanovafc.com.br/imgs/270/370/images/lincoln-317.avif',
  'vn_rafa_silva':
      'https://www.vilanovafc.com.br/imgs/270/370/images/rafa-silva-051.avif',
  'vn_ryan': 'https://www.vilanovafc.com.br/imgs/270/370/images/ryan-385.avif',
};

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
    // 2026-09-30: usuário notou que o card "Arena Vila Nova" da Home
    // ficava sem a marca d'água de estádio que Goiás/Bragantino têm.
    // Mesmo render 3D genérico dos outros dois clubes (não é um estádio
    // real específico), reconvertido em duotone vermelho/vinho por
    // `tooling/vilanova_brand/build_arena_stadium.py`.
    arenaStadiumPhoto: '$_dir/arena_stadium.png',
    // FAQ oficial do Sócio Tigrão (API pública do provedor de adesão),
    // gerado por `tooling/vilanova_membership/build_membership_content.mjs`.
    membershipFaqAssetPath: 'lib/assets/content/vilanova_membership_faq.json',
    storeBanner: _phRaster,
    guessPlayerPhotos: _vilaNovaGuessPlayerPhotos,
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
    // "Falar com atendimento" do Sócio Tigrão: o mesmo WhatsApp que o botão
    // do portal oficial do programa abre (`whatsappLink` em
    // vilanova.ingressosa.com.br/public/api/v1/socio/general-configuration-portal,
    // 2026-09-30).
    contactWhatsappNumber: '(62) 99644-1943',
    contactWhatsappUrl: 'https://wa.me/5562996441943',
    // F8 (2026-09-30): Worker próprio (`wrangler.vilanova.toml`, deploy
    // pela CLI). Mesmo código-fonte dos outros clubes, `CLUB_CODE =
    // "vilanova"` — rejeita `?club=goias`/`bragantino`.
    workerBaseUrl: 'https://vilanova-app.lucasdiogo1234.workers.dev',
    // Mesmo padrão de Goiás/Bragantino: redirectTo dos fluxos de auth
    // aponta pro Worker do próprio clube. A Auth Site URL/Redirect URLs
    // do projeto Supabase precisam listar esta URL (dashboard).
    supabaseRedirectUrl: 'https://vilanova-app.lucasdiogo1234.workers.dev',
  ),
  capabilities: const ClubCapabilities(
    // F7 (2026-09-30): 4 planos reais do Sócio Tigrão (RUBI/OURO/PRATA/TIME
    // DO POVO), confirmados na API pública do provedor de adesão
    // (`vilanova.ingressosa.com.br/public/api/v1/socio/benefits-plan`) —
    // nome, valor "/mês" exibido, valor anual total real e benefícios
    // batem exatamente com o checkout oficial. `hasMembership` liga só a
    // listagem/detalhes/CTA (que abre o checkout oficial externo, ver
    // `membershipProgram.externalCheckoutUrl` abaixo) — não depende de
    // regulamento (ausente, botão fica escondido) nem de preço anual
    // inventado (o anual é real, não `mensal * 12`).
    hasMembership: true,
    hasStore: false,
    hasTickets: false,
    hasCrowdLineup: false,
    // F6 (2026-09-30): 468 partidas / 78 estádios (2019-2026) aplicados e
    // verificados ao vivo no Supabase do Vila
    // (`tooling/multiclub/verify-vilanova-live.mjs`), `passportContent` já
    // aponta pro `VilaNovaPassportContent` ("Passaporte Colorado") e o
    // repositório (`SupabasePassportRepository`) é genérico por clube — nada
    // de código precisou mudar, só esta flag.
    hasPassport: true,
    // F8 (2026-09-30): aba Mídia. Notícias = parser próprio do site oficial
    // no Worker (`src/news/vilanova_parser.ts`). Redes = X (KV alimentado
    // pelo GitHub Action), Instagram (Apify -> KV, também agendado pelo
    // Action) e YouTube "TigrãoTV" (precisa do secret YOUTUBE_API_KEY no
    // Worker). Rede sem dado ainda aparece vazia, nunca com post de outro
    // clube.
    hasNews: true,
    hasSocial: true,
    // F3: história, linha do tempo, títulos e ídolos estáticos (pacote
    // v1.2). F4 (2026-09-29): diretoria (6 seções/28 pessoas) e
    // transparência (5 documentos) confirmadas ao vivo no Supabase do Vila
    // (`tooling/multiclub/verify-vilanova-live.mjs`) — a mesma flag já
    // cobria os dois, só faltava o banco existir.
    hasClubContent: true,
    // Lista de patrocinadores incompleta no pacote (máster não confirmado) —
    // fica desligado até a lista fechar e passar por decisão editorial.
    hasPartners: false,
    // F8 (2026-09-30): Worker deployado e validado ao vivo (ver
    // ClubIntegrations.workerBaseUrl) — hasMatches liga junto com
    // workerBaseUrl, nunca um sem o outro.
    hasMatches: true,
    // F5 (2026-09-29), depois de reauditar o Supabase real do Vila:
    //   * 'quiz': 45/45 ativas, todas com 4 opções.
    //   * 'lineup': 15/15 ativas, 11 jogadores/1 GOL cada, só formações que
    //     o FormationLayoutService reconhece (4-4-2/4-3-3/3-5-2/4-2-3-1).
    //   * 'player_identity'/'tactical_identity': referências convertidas e
    //     calibradas no motor real (ver `vilanova_player_identity_references.dart`
    //     e `vilanova_tactical_coach_references.dart`), sem depender do banco.
    //   * 'career_path': 30/30 ativas, todas do elenco ATUAL (decisão (c) do
    //     handoff ainda em aberto sobre esperar nomes históricos — ligado
    //     agora com o que existe; troca sem custo quando o lote histórico
    //     chegar, os dados só são substituídos).
    // 'guess_player' (Manto) LIGADO em 2026-09-30 (ASSET_GAP resolvido):
    // 31 fotos individuais reais extraídas de
    // vilanovafc.com.br/elenco-profissional (hotlink AVIF, ver
    // `_vilaNovaGuessPlayerPhotos` acima) preenchem `photo_key` em
    // `vilanova_guess_players.sql`. Nem toda carta com foto é elegível
    // como segredo (`GuessPlayer.eligibleAsSecret` também exige
    // `academy_club`/`shirt_number`/etc. completos) — hoje são **14 de 50**
    // realmente elegíveis (verificado no simulador: `guess status:
    // verified=14, incomplete=36`), o resto seguem sem inventar dado que
    // falta. 14 é o suficiente pra sortear sem repetição óbvia.
    enabledArenaGames: {
      'quiz',
      'lineup',
      'player_identity',
      'tactical_identity',
      'career_path',
      'guess_player',
    },
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
  // F7 (2026-09-30): planos reais (`VilaNovaMembershipPlansCatalog`), fonte
  // = API pública do próprio provedor de adesão. Regulamento = o "Termo de
  // Adesão ao Programa Sócio-Tigrão" oficial, da mesma API
  // (`/socio/terms-of-use`), texto sem reescrita, gerado por
  // `tooling/vilanova_membership/build_membership_content.mjs`. O
  // `assetPath` não é lido pelo app (só `regulationIntro`/
  // `regulationSections`), mas é obrigatório na entidade.
  membershipProgram: MembershipProgramConfig(
    plans: VilaNovaMembershipPlansCatalog.plans,
    regulationVersion: RegulationVersion(
      id: 'socio-tigrao-termo-de-adesao-$vilaNovaRegulationUpdatedAt',
      version: vilaNovaRegulationUpdatedAt,
      effectiveAt: DateTime.parse(vilaNovaRegulationUpdatedAt),
      assetPath: 'lib/assets/legal/vilanova_membership_regulation.md',
    ),
    regulationIntro: vilaNovaMembershipRegulationIntro,
    regulationSections: vilaNovaMembershipRegulationSections,
    sourceLabel:
        'Sócio Tigrão — API pública do provedor de adesão '
        '(vilanova.ingressosa.com.br), consultada em 2026-09-30.',
    sourceUpdatedAt: DateTime(2026, 9, 30),
    // Sem integração própria de pagamento: o CTA "Quero ser sócio" abre o
    // checkout oficial do provedor real em vez de simular um cadastro que
    // não gera nenhuma adesão de verdade (ver
    // `MembershipProgramConfig.externalCheckoutUrl`).
    externalCheckoutUrl: 'https://vilanova.ingressosa.com.br/selecionar-plano',
  ),
  institutionalContent: const ClubInstitutionalContent(
    history: VilaNovaHistoryData.sections,
    timeline: VilaNovaTimelineData.events,
    titles: VilaNovaTitlesData.groups,
    historicalCampaigns: VilaNovaTitlesData.historicalCampaigns,
    idols: VilaNovaIdolsData.idols,
  ),
);
