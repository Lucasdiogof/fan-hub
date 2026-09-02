import 'package:goias_app/core/club/club_config.dart';
import 'package:goias_app/core/club/club_identity.dart';
import 'package:goias_app/core/club/goias_club_config.dart';

/// Clube sintético/neutro pra testes de tenant-scope (M3.1) — nunca um
/// time real, nunca cadastrado em `clubRegistry`. Reaproveita
/// branding/assets/integrations/capabilities/productNames de
/// `goiasClubConfig` (irrelevantes pro que estes testes verificam — só a
/// identidade muda) pra não precisar duplicar todo o resto do objeto.
///
/// `canonicalClubId` é um UUID qualquer, deliberadamente DIFERENTE do
/// Goiás — usado pra provar que uma query nunca vaza `club_id` de outro
/// clube por acidente.
final syntheticClubBConfig = ClubConfig(
  identity: const ClubIdentity(
    code: 'club-b',
    slug: 'club-b',
    displayName: 'Clube Sintético B',
    shortName: 'Clube B',
    fanDemonym: 'Torcedor B',
    canonicalClubId: '00000000-0000-0000-0000-0000000000b1',
  ),
  branding: goiasClubConfig.branding,
  assets: goiasClubConfig.assets,
  integrations: goiasClubConfig.integrations,
  capabilities: goiasClubConfig.capabilities,
  productNames: goiasClubConfig.productNames,
);
