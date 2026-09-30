import 'package:equatable/equatable.dart';
import 'package:goias_app/features/membership/domain/entities/membership_commitment_period.dart';

class MembershipPlanPrice extends Equatable {
  const MembershipPlanPrice({
    required this.label,
    required this.monthlyPrice,
    required this.annualPrice,
  });

  final String label;
  final double monthlyPrice;
  final double annualPrice;

  @override
  List<Object?> get props => [label, monthlyPrice, annualPrice];
}

class MembershipPlan extends Equatable {
  const MembershipPlan({
    required this.id,
    required this.name,
    required this.tagline,
    required this.includesStadiumAccess,
    required this.benefits,
    required this.prices,
    this.allowedSectors = const [],
    this.highlight = false,
    this.commitmentPeriod = MembershipCommitmentPeriod.monthlyRecurring,
  });

  final String id;
  final String name;
  final String tagline;
  final bool includesStadiumAccess;

  /// Assinatura mensal recorrente (com opção de pré-pagar o ano) ou adesão
  /// anual só (o "/mês" exibido é a parcela do valor anual, nunca uma
  /// cobrança recorrente à parte) — ver `MembershipCommitmentPeriod`. Default
  /// `monthlyRecurring` preserva o comportamento de todo catálogo existente
  /// antes deste campo (Goiás/Bragantino).
  final MembershipCommitmentPeriod commitmentPeriod;

  /// Setores do estádio liberados pro check-in deste plano — LISTA, não um
  /// setor só (alguns programas, ex. Massa Bruta, liberam vários setores no
  /// mesmo plano: "Leste e Oeste", "Sul, Leste e Oeste" etc). Vazio quando
  /// `includesStadiumAccess` é `false`.
  final List<String> allowedSectors;
  final List<String> benefits;
  final List<MembershipPlanPrice> prices;
  final bool highlight;

  MembershipPlanPrice get defaultPrice => prices.first;

  /// Rótulo pronto pra UI ("Leste e Oeste") — `null` quando o plano não dá
  /// acesso a nenhum setor, pra manter o mesmo padrão de null-check que os
  /// call sites já usavam com o antigo campo singular.
  String? get sectorsLabel =>
      allowedSectors.isEmpty ? null : allowedSectors.join(' e ');

  /// Molde conceitual de "o que este plano libera" pro check-in — ver spec
  /// M4-Massa Bruta §15. Hoje é só modelagem/documentação: o check-in real
  /// (`CheckInCubit`) ainda não lê isto pra gatear setor (confirmado por
  /// auditoria — `stadiumSector`/`allowedSectors` nunca apareceu em
  /// `lib/features/ticket/`), então isto não muda comportamento nenhum
  /// ainda. Existe pra um trabalho futuro de enforcement não precisar
  /// redesenhar o formato de novo.
  ({bool checkInAllowed, List<String> allowedSectors}) get entitlements =>
      (checkInAllowed: includesStadiumAccess, allowedSectors: allowedSectors);

  @override
  List<Object?> get props => [
    id,
    name,
    tagline,
    includesStadiumAccess,
    allowedSectors,
    benefits,
    prices,
    highlight,
    commitmentPeriod,
  ];
}
