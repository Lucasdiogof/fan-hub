import 'package:equatable/equatable.dart';
import 'package:goias_app/features/ticket/domain/entities/ticket.dart';
import 'package:goias_app/features/ticket/domain/entities/ticket_event.dart';
import 'package:goias_app/features/ticket/domain/entities/ticket_order.dart';
import 'package:goias_app/shared/validation/app_validators.dart';

class PurchaseState extends Equatable {
  const PurchaseState({
    required this.event,
    this.quantities = const {},
    this.holderIsSelf = true,
    this.holderName = '',
    this.holderDocument = '',
    this.saving = false,
    this.order,
    this.purchasedTickets = const [],
    this.errorMessage,
  });

  final TicketEvent event;

  /// Chave `(sectorId, categoryId)` — Records em Dart já têm igualdade
  /// estrutural, então funcionam como chave de Map sem boilerplate.
  final Map<(String, String), int> quantities;
  final bool holderIsSelf;
  final String holderName;
  final String holderDocument;
  final bool saving;
  final TicketOrder? order;

  /// Ingressos de fato criados por [order] — buscados de volta depois da
  /// compra (ver `PurchaseCubit.finalizePurchase`), já que `purchase()` só
  /// devolve o pedido. Usado pra "Visualizar ingresso"/"Salvar ingresso" no
  /// sucesso mostrarem o PDF de verdade, não só linkarem pra Meus Ingressos.
  final List<Ticket> purchasedTickets;
  final String? errorMessage;

  int quantityFor(String sectorId, String categoryId) =>
      quantities[(sectorId, categoryId)] ?? 0;

  List<TicketOrderItem> get items {
    final result = <TicketOrderItem>[];
    for (final sector in event.info.sectors) {
      for (final category in sector.categories) {
        final quantity = quantityFor(sector.id, category.id);
        if (quantity <= 0) continue;
        result.add(
          TicketOrderItem(
            sectorId: sector.id,
            sectorName: sector.name,
            venueLabel: sector.venueLabel,
            gate: sector.gate,
            categoryId: category.id,
            categoryLabel: category.label,
            quantity: quantity,
            unitPrice: category.price,
          ),
        );
      }
    }
    return result;
  }

  int get totalQuantity =>
      quantities.values.fold(0, (sum, quantity) => sum + quantity);

  double get total => items.fold(0, (sum, item) => sum + item.subtotal);

  bool get canProceedToSummary => totalQuantity > 0;

  bool get canFinalize =>
      totalQuantity > 0 &&
      holderName.trim().isNotEmpty &&
      AppValidators.isValidDocument(holderDocument);

  PurchaseState copyWith({
    Map<(String, String), int>? quantities,
    bool? holderIsSelf,
    String? holderName,
    String? holderDocument,
    bool? saving,
    TicketOrder? order,
    List<Ticket>? purchasedTickets,
    String? errorMessage,
    bool clearError = false,
  }) {
    return PurchaseState(
      event: event,
      quantities: quantities ?? this.quantities,
      holderIsSelf: holderIsSelf ?? this.holderIsSelf,
      holderName: holderName ?? this.holderName,
      holderDocument: holderDocument ?? this.holderDocument,
      saving: saving ?? this.saving,
      order: order ?? this.order,
      purchasedTickets: purchasedTickets ?? this.purchasedTickets,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }

  @override
  List<Object?> get props => [
    event,
    quantities,
    holderIsSelf,
    holderName,
    holderDocument,
    saving,
    order,
    purchasedTickets,
    errorMessage,
  ];
}
