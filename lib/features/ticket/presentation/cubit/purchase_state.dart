import 'package:equatable/equatable.dart';
import 'package:goias_app/features/ticket/domain/entities/ticket_event.dart';
import 'package:goias_app/features/ticket/domain/entities/ticket_order.dart';
import 'package:goias_app/shared/validation/app_validators.dart';

class PurchaseState extends Equatable {
  const PurchaseState({
    required this.event,
    this.quantities = const {},
    this.holders = const [],
    this.saving = false,
    this.order,
    this.errorMessage,
  });

  final TicketEvent event;

  /// Chave `(sectorId, categoryId)` — Records em Dart já têm igualdade
  /// estrutural, então funcionam como chave de Map sem boilerplate.
  final Map<(String, String), int> quantities;

  /// Um titular por ingresso físico, na mesma ordem que [items] expande
  /// (item na ordem do carrinho, quantidade dentro do item) — índice `i`
  /// aqui é sempre o titular do i-ésimo ingresso de [items] "achatado".
  /// Sincronizado com [totalQuantity] via `PurchaseCubit.ensureHolderSlots`.
  final List<TicketHolder> holders;
  final bool saving;
  final TicketOrder? order;
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

  /// [items] "achatado" — um `TicketOrderItem` de quantidade 1 por
  /// ingresso físico, na mesma ordem que [holders]. É o que a tela de
  /// titulares itera pra mostrar "Ingresso N · setor · categoria" ao lado
  /// de cada formulário.
  List<TicketOrderItem> get ticketUnits => [
    for (final item in items)
      for (var i = 0; i < item.quantity; i++)
        TicketOrderItem(
          sectorId: item.sectorId,
          sectorName: item.sectorName,
          venueLabel: item.venueLabel,
          gate: item.gate,
          categoryId: item.categoryId,
          categoryLabel: item.categoryLabel,
          quantity: 1,
          unitPrice: item.unitPrice,
        ),
  ];

  bool get canProceedToSummary => totalQuantity > 0;

  bool get canFinalize =>
      totalQuantity > 0 &&
      holders.length == totalQuantity &&
      holders.every(
        (holder) =>
            holder.name.trim().isNotEmpty &&
            AppValidators.isValidDocument(holder.document),
      );

  PurchaseState copyWith({
    Map<(String, String), int>? quantities,
    List<TicketHolder>? holders,
    bool? saving,
    TicketOrder? order,
    String? errorMessage,
    bool clearError = false,
  }) {
    return PurchaseState(
      event: event,
      quantities: quantities ?? this.quantities,
      holders: holders ?? this.holders,
      saving: saving ?? this.saving,
      order: order ?? this.order,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }

  @override
  List<Object?> get props => [
    event,
    quantities,
    holders,
    saving,
    order,
    errorMessage,
  ];
}
