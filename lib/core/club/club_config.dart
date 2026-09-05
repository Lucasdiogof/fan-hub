import 'package:goias_app/core/club/club_assets.dart';
import 'package:goias_app/core/club/club_branding.dart';
import 'package:goias_app/core/club/club_capabilities.dart';
import 'package:goias_app/core/club/club_identity.dart';
import 'package:goias_app/core/club/club_institutional_content.dart';
import 'package:goias_app/core/club/club_integrations.dart';
import 'package:goias_app/core/club/club_product_naming.dart';

/// Configuração completa e IMUTÁVEL de um clube — a raiz de tudo que este
/// build do app sabe sobre "qual clube estamos executando".
///
/// Deliberadamente NUNCA:
///   - carrega `SupabaseClient`/repository (isso é acesso a dado, não
///     configuração — ver `docs/multiclub/09_supabase_migration_plan.md`);
///   - muda em runtime (não existe seletor de clube pelo usuário, não
///     existe `Cubit<ClubConfig>`/`ChangeNotifier` — é `const`, resolvido
///     uma vez no bootstrap, igual qualquer outra constante de build).
///
/// Composta por 5 sub-objetos semânticos (identidade, marca, assets,
/// integrações, capacidades) + nomes de produto — nunca um objeto único
/// "bagunçado" com 30 campos soltos.
class ClubConfig {
  const ClubConfig({
    required this.identity,
    required this.branding,
    required this.assets,
    required this.integrations,
    required this.capabilities,
    required this.productNames,
    this.institutionalContent = const ClubInstitutionalContent(),
  });

  final ClubIdentity identity;
  final ClubBranding branding;
  final ClubAssets assets;
  final ClubIntegrations integrations;
  final ClubCapabilities capabilities;
  final ClubProductNaming productNames;

  /// História/títulos/hino/parceiros — ver `ClubInstitutionalContent`.
  /// Default vazio: um clube sem `ClubConfig` explícito pra isto (nenhum
  /// hoje) nunca herdaria conteúdo de outro por omissão.
  final ClubInstitutionalContent institutionalContent;
}
