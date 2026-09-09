import 'package:equatable/equatable.dart';

class TicketPriceCategory extends Equatable {
  const TicketPriceCategory({
    required this.id,
    required this.label,
    required this.price,
    this.soldOut = false,
    this.isHalfPrice = false,
  });

  final String id;
  final String label;
  final double price;
  final bool soldOut;

  /// Exige escolher [HalfPriceType] (e comprovante, se [HalfPriceType.law])
  /// na tela de titulares — nunca inferido do `label`/`id` livre.
  final bool isHalfPrice;

  @override
  List<Object?> get props => [id, label, price, soldOut, isHalfPrice];
}

/// Um setor do estádio pra uma partida — usado tanto na compra (com
/// [categories]/preços e contador de quantidade) quanto no check-in do
/// sócio ([availableForCheckIn], sem preço, seleção única). O mesmo setor
/// físico serve os dois fluxos: "Cadeiras" é um `TicketSector` só, não dois
/// modelos separados.
class TicketSector extends Equatable {
  const TicketSector({
    required this.id,
    required this.name,
    required this.venueLabel,
    required this.gate,
    required this.categories,
    this.isVisitorSector = false,
    this.availableForCheckIn = false,
  });

  final String id;
  final String name;
  final String venueLabel;
  final String gate;
  final List<TicketPriceCategory> categories;
  final bool isVisitorSector;
  final bool availableForCheckIn;

  /// Setor inteiro esgotado só quando TODAS as categorias estão — nunca um
  /// campo solto que possa dessincronizar da lista real de categorias.
  bool get soldOut =>
      categories.isNotEmpty && categories.every((c) => c.soldOut);

  @override
  List<Object?> get props => [
    id,
    name,
    venueLabel,
    gate,
    categories,
    isVisitorSector,
    availableForCheckIn,
  ];
}
