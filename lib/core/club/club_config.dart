import 'package:goias_app/core/club/club_assets.dart';
import 'package:goias_app/core/club/club_branding.dart';
import 'package:goias_app/core/club/club_capabilities.dart';
import 'package:goias_app/core/club/club_identity.dart';
import 'package:goias_app/core/club/club_institutional_content.dart';
import 'package:goias_app/core/club/club_integrations.dart';
import 'package:goias_app/core/club/club_product_naming.dart';
import 'package:goias_app/core/club/membership_program_config.dart';
import 'package:goias_app/features/passport/domain/club_passport_content.dart';
import 'package:goias_app/features/ticket/domain/entities/club_tickets_content.dart';

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
    required this.passportContent,
    required this.membershipProgram,
    this.institutionalContent = const ClubInstitutionalContent(),
    this.ticketsContent,
  });

  final ClubIdentity identity;
  final ClubBranding branding;
  final ClubAssets assets;
  final ClubIntegrations integrations;
  final ClubCapabilities capabilities;
  final ClubProductNaming productNames;

  /// Planos/regulamento/pré-preenchimento do Sócio Torcedor — ver
  /// [MembershipProgramConfig]. Obrigatório mesmo quando
  /// `capabilities.hasMembership` é `false`, mesmo padrão de
  /// [passportContent]: identidade de programa não tem valor neutro
  /// razoável, cada clube escreve o seu ou não compila.
  final MembershipProgramConfig membershipProgram;

  /// História/títulos/hino/parceiros — ver `ClubInstitutionalContent`.
  /// Default vazio: um clube sem `ClubConfig` explícito pra isto (nenhum
  /// hoje) nunca herdaria conteúdo de outro por omissão.
  final ClubInstitutionalContent institutionalContent;

  /// Cópia do Passaporte nos três idiomas — ver `ClubPassportContent`.
  /// Obrigatório, sem default: identidade de clube não tem valor neutro
  /// razoável, e cair no texto de outro clube por omissão é exatamente o
  /// que não pode acontecer. Clube novo escreve a sua ou não compila.
  final ClubPassportContent passportContent;

  /// Setores/preços/portões de ingresso e o texto de "Informações da
  /// partida" — ver [ClubTicketsContent]. `null` (default) é o estado
  /// correto pra um clube sem esse dado pesquisado ainda: a feature de
  /// Ingressos trata isso como indisponível, NUNCA cai pro conteúdo de
  /// outro clube. `capabilities.hasTickets: true` sem isto preenchido é bug
  /// de configuração — ver `MockTicketRepository`.
  final ClubTicketsContent? ticketsContent;
}
