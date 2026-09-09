import 'package:equatable/equatable.dart';
import 'package:goias_app/features/match/domain/entities/team.dart';
import 'package:goias_app/features/ticket/domain/entities/ticket_enums.dart';

enum TicketOrderStatus { confirmed, pending, cancelled, refunded }

extension TicketOrderStatusLabel on TicketOrderStatus {
  String get label => switch (this) {
    TicketOrderStatus.confirmed => 'Pago',
    TicketOrderStatus.pending => 'Pendente',
    TicketOrderStatus.cancelled => 'Cancelado',
    TicketOrderStatus.refunded => 'Reembolsado',
  };
}

/// Titular de UM ingresso físico — cada unidade comprada (mesmo dentro do
/// mesmo item/quantidade) tem o seu próprio, nunca um titular só cobrindo
/// vários ingressos de uma vez (ver regra #23 do módulo: ingresso é
/// nominal e intransferível, então "comprar 2" precisa de 2 titulares).
class TicketHolder extends Equatable {
  const TicketHolder({
    required this.name,
    required this.document,
    this.isSelf = false,
    this.halfPriceType,
    this.halfPriceProofPath,
  });

  final String name;
  final String document;
  final bool isSelf;

  /// Só relevante quando o ingresso deste titular é de categoria
  /// meia-entrada (`TicketOrderItem.isHalfPrice`) — `null` significa "ainda
  /// não escolheu", nunca um default silencioso.
  final HalfPriceType? halfPriceType;

  /// Path (privado, não URL pública) do comprovante no bucket
  /// `half_price_proofs` — obrigatório só quando [halfPriceType] é
  /// [HalfPriceType.law]. `null` até o upload terminar.
  final String? halfPriceProofPath;

  TicketHolder copyWith({
    String? name,
    String? document,
    bool? isSelf,
    HalfPriceType? halfPriceType,
    bool clearHalfPriceType = false,
    String? halfPriceProofPath,
    bool clearHalfPriceProofPath = false,
  }) => TicketHolder(
    name: name ?? this.name,
    document: document ?? this.document,
    isSelf: isSelf ?? this.isSelf,
    halfPriceType: clearHalfPriceType
        ? null
        : (halfPriceType ?? this.halfPriceType),
    halfPriceProofPath: clearHalfPriceProofPath
        ? null
        : (halfPriceProofPath ?? this.halfPriceProofPath),
  );

  @override
  List<Object?> get props => [
    name,
    document,
    isSelf,
    halfPriceType,
    halfPriceProofPath,
  ];
}

/// Uma linha do pedido — um setor+categoria+quantidade. Um pedido pode ter
/// mais de um item (ex.: 2 Inteiras + 1 Meia no mesmo setor, ou setores
/// diferentes), cada um vira um `Ticket` próprio na confirmação da compra.
class TicketOrderItem extends Equatable {
  const TicketOrderItem({
    required this.sectorId,
    required this.sectorName,
    required this.venueLabel,
    required this.gate,
    required this.categoryId,
    required this.categoryLabel,
    required this.quantity,
    required this.unitPrice,
    this.isHalfPrice = false,
  });

  final String sectorId;
  final String sectorName;
  final String venueLabel;
  final String gate;
  final String categoryId;
  final String categoryLabel;
  final int quantity;
  final double unitPrice;
  final bool isHalfPrice;

  double get subtotal => unitPrice * quantity;

  Map<String, dynamic> toJson() => {
    'sectorId': sectorId,
    'sectorName': sectorName,
    'venueLabel': venueLabel,
    'gate': gate,
    'categoryId': categoryId,
    'categoryLabel': categoryLabel,
    'quantity': quantity,
    'unitPrice': unitPrice,
    'isHalfPrice': isHalfPrice,
  };

  factory TicketOrderItem.fromJson(Map<String, dynamic> json) =>
      TicketOrderItem(
        sectorId: json['sectorId'] as String,
        sectorName: json['sectorName'] as String,
        venueLabel: json['venueLabel'] as String,
        gate: json['gate'] as String,
        categoryId: json['categoryId'] as String,
        categoryLabel: json['categoryLabel'] as String,
        quantity: json['quantity'] as int,
        unitPrice: (json['unitPrice'] as num).toDouble(),
        isHalfPrice: json['isHalfPrice'] as bool? ?? false,
      );

  @override
  List<Object?> get props => [
    sectorId,
    sectorName,
    venueLabel,
    gate,
    categoryId,
    categoryLabel,
    quantity,
    unitPrice,
    isHalfPrice,
  ];
}

class TicketOrder extends Equatable {
  const TicketOrder({
    required this.id,
    required this.number,
    required this.matchId,
    required this.competition,
    required this.round,
    required this.homeTeam,
    required this.awayTeam,
    required this.kickoff,
    required this.stadium,
    required this.items,
    required this.holderName,
    required this.holderDocument,
    required this.status,
    required this.createdAt,
  });

  final String id;
  final String number;
  final String matchId;
  final String competition;
  final String round;
  final Team homeTeam;
  final Team awayTeam;
  final DateTime? kickoff;
  final String stadium;
  final List<TicketOrderItem> items;
  final String holderName;
  final String holderDocument;
  final TicketOrderStatus status;
  final DateTime createdAt;

  double get total => items.fold(0, (sum, item) => sum + item.subtotal);

  @override
  List<Object?> get props => [
    id,
    number,
    matchId,
    competition,
    round,
    homeTeam,
    awayTeam,
    kickoff,
    stadium,
    items,
    holderName,
    holderDocument,
    status,
    createdAt,
  ];
}
