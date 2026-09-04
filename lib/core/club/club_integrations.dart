/// Endereço fixo de retirada — mesmo shape de `PickupInformation`
/// (`features/store/domain/entities/shipping.dart`), duplicado aqui de
/// propósito: `core/club` nunca deveria importar de `features/*` (a
/// dependência é sempre feature -> core, nunca o contrário). Nenhum
/// consumidor real lê isto ainda.
class ClubPickupAddress {
  const ClubPickupAddress({
    required this.storeName,
    required this.street,
    required this.neighborhood,
    required this.city,
    required this.state,
    required this.zipCode,
  });

  final String storeName;
  final String street;
  final String neighborhood;
  final String city;
  final String state;
  final String zipCode;
}

/// Integrações externas do clube — IDs/slugs de provider, contato,
/// endereço. NUNCA um `SupabaseClient`/repository aqui — isso é acesso a
/// dado, não configuração (ver decisão explícita no relatório da M1).
class ClubIntegrations {
  const ClubIntegrations({
    required this.oneFootballTeamId,
    required this.oneFootballSlug,
    required this.oneFootballCompetitionSlug,
    required this.orderPrefix,
    required this.pickupAddress,
    this.workerBaseUrl,
    this.contactWhatsappNumber,
    this.contactWhatsappUrl,
    this.socialInstagramUrl,
    this.socialYoutubeUrl,
    this.socialTiktokUrl,
    this.socialFacebookUrl,
    this.socialXUrl,
    this.officialSiteUrl,
  });

  /// Substitui `Team.goiasId = 1863` (hoje hardcoded em
  /// `lib/features/match/domain/entities/team.dart:37`) — nenhum
  /// consumidor real migrado ainda.
  final int oneFootballTeamId;

  /// Substitui `GOIAS_ONEFOOTBALL_SLUG` do lado Flutter — o Worker
  /// (`wrangler.toml`) continua com sua própria env var, não lê isto.
  final String oneFootballSlug;
  final String oneFootballCompetitionSlug;

  /// URL base do Worker deste clube (`ApiClient` lê daqui — nunca mais um
  /// literal fixo, ver `resolve_api_base_url.dart`). `null` enquanto o
  /// Worker do clube não existir/não foi validado — `ApiClient` NUNCA cai
  /// pro Worker de outro clube quando isto é `null`; as chamadas falham de
  /// forma controlada (host `.invalid`), e a UI que depende delas
  /// (`hasMatches`, `hasNews`, `hasSocial`) já fica indisponível antes
  /// disso de qualquer jeito.
  final String? workerBaseUrl;

  /// Substitui o literal `'GOI'` em `generate_store_order_number()`
  /// (`supabase/store_orders.sql`) — hoje só documentado, a function SQL
  /// continua hardcoded (fora do escopo Dart desta M1).
  final String orderPrefix;

  final ClubPickupAddress pickupAddress;
  final String? contactWhatsappNumber;
  final String? contactWhatsappUrl;

  /// Redes sociais oficiais do clube — `null` quando o clube não tem perfil
  /// numa dessas plataformas (`SocialLinksData` pula a entrada, nunca
  /// inventa/reusa a URL de outro clube).
  final String? socialInstagramUrl;
  final String? socialYoutubeUrl;
  final String? socialTiktokUrl;
  final String? socialFacebookUrl;
  final String? socialXUrl;
  final String? officialSiteUrl;
}
