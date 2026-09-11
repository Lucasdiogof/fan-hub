import 'package:goias_app/features/membership/domain/entities/membership_plan.dart';
import 'package:goias_app/features/membership/domain/entities/regulation_section.dart';
import 'package:goias_app/features/membership/domain/entities/regulation_version.dart';

/// Tudo que o Sócio Torcedor precisa saber sobre o PROGRAMA em si (planos,
/// regulamento, se pré-preenche do perfil, link oficial) — separado de
/// [ClubProductNaming.membershipProgramName] (que já existia e continua o
/// nome exibido em telas fora deste feature) pra não obrigar mudar todo
/// consumidor existente só pra adicionar os campos novos abaixo.
///
/// Cada clube com `hasMembership: true` fornece o seu — nunca um `if
/// (club.code == 'bragantino')` espalhado pela feature; toda tela de Sócio
/// lê só isto.
class MembershipProgramConfig {
  const MembershipProgramConfig({
    required this.plans,
    required this.regulationVersion,
    required this.regulationIntro,
    required this.regulationSections,
    required this.sourceLabel,
    required this.sourceUpdatedAt,
    this.prefillFromProfile = false,
    this.consentUrl,
    this.externalUrl,
  });

  /// Catálogo oficial de planos deste clube — mesma fonte única que
  /// `SupabaseMembershipRepository.getPlans()` devolve, nunca lido direto
  /// de um catálogo hardcoded de outro clube.
  final List<MembershipPlan> plans;

  final RegulationVersion regulationVersion;
  final String regulationIntro;
  final List<RegulationSection> regulationSections;

  /// De onde vêm os dados de [plans] e desde quando — section 5 do pedido
  /// M4-Massa Bruta: nunca esconder a origem, nem deixar preço "velho" no
  /// app sem ninguém saber há quanto tempo está desatualizado. Mostrado na
  /// tela de planos/detalhes (rodapé discreto) quando não-vazio.
  final String sourceLabel;
  final DateTime sourceUpdatedAt;

  /// Se a Etapa 1 do cadastro deve vir pré-preenchida com nome/CPF/e-mail/
  /// telefone/nascimento/endereço já existentes no perfil do usuário. O
  /// Sócio Esmeralda (Goiás) decidiu explicitamente que NÃO (o titular
  /// preenche do zero, mesmo repetindo dado já cadastrado — decisão de
  /// produto anterior a este trabalho, preservada aqui via `false`
  /// default); o Massa Bruta (Bragantino) pede pré-preenchimento
  /// explicitamente (spec M4 §9) — por isso é campo de configuração, não
  /// comportamento fixo.
  final bool prefillFromProfile;

  /// Link pra política de privacidade/termos OFICIAIS do programa (fora do
  /// app) — mostrado como "ver termos oficiais" quando não-nulo. Nunca
  /// implica que o app manda dado pra lá de verdade.
  final String? consentUrl;

  /// Site oficial do programa (ex.: `https://massabruta.com.br/`) — nunca o
  /// site institucional geral do clube quando os dois divergem.
  final String? externalUrl;
}
