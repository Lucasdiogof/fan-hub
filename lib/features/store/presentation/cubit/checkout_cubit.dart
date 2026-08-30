import 'package:goias_app/features/store/domain/entities/cart.dart';
import 'package:goias_app/features/store/domain/entities/customer.dart';
import 'package:goias_app/features/store/domain/entities/payment.dart';
import 'package:goias_app/features/store/domain/entities/shipping.dart';
import 'package:goias_app/features/store/domain/entities/store_order.dart';
import 'package:goias_app/features/store/domain/repositories/delivery_address_repository.dart';
import 'package:goias_app/features/store/domain/repositories/store_orders_repository.dart';
import 'package:goias_app/features/store/domain/repositories/store_repository.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:goias_app/features/store/presentation/cubit/checkout_state.dart';

/// Uma instância por passagem pelo checkout (`registerFactory`, ver DI) —
/// opera sobre uma FOTOGRAFIA do carrinho tirada na criação (`initialCart`),
/// nunca o carrinho "ao vivo": se o usuário conseguisse mexer no carrinho
/// por trás durante o checkout, os totais aqui não podiam mudar sozinhos
/// no meio do fluxo.
class CheckoutCubit extends Cubit<CheckoutState> {
  CheckoutCubit(
    this._repository,
    this._ordersRepository,
    this._addressRepository,
    Cart initialCart, {
    String? prefillName,
    String? prefillEmail,
  }) : super(
         CheckoutState(
           cart: initialCart,
           fullName: prefillName ?? '',
           email: prefillEmail ?? '',
         ),
       ) {
    _loadAddresses();
  }

  final StoreRepository _repository;
  final StoreOrdersRepository _ordersRepository;
  final DeliveryAddressRepository _addressRepository;

  Future<void> _loadAddresses() async {
    final addresses = await _addressRepository.list();
    final defaultAddress =
        addresses.where((a) => a.isDefault).firstOrNull ??
        (addresses.isNotEmpty ? addresses.first : null);
    emit(
      state.copyWith(
        addresses: addresses,
        selectedAddressId: () => defaultAddress?.id,
      ),
    );
    if (defaultAddress != null) {
      await _quoteShipping(defaultAddress.zipCode);
    }
  }

  /// Recarrega do backend — usado depois que o usuário cria/edita/remove um
  /// endereço de entrega em outra tela (Perfil) e volta pro checkout.
  Future<void> refreshAddresses() => _loadAddresses();

  // ---------------------------------------------------------------------
  // Etapa 1 — identificação
  // ---------------------------------------------------------------------

  void updateIdentification({
    String? fullName,
    String? cpf,
    String? email,
    String? phone,
  }) {
    emit(
      state.copyWith(
        fullName: fullName ?? state.fullName,
        cpf: cpf ?? state.cpf,
        email: email ?? state.email,
        phone: phone ?? state.phone,
      ),
    );
  }

  // ---------------------------------------------------------------------
  // Etapa 2 — entrega ou retirada
  // ---------------------------------------------------------------------

  Future<void> setFulfillmentMethod(FulfillmentMethod method) async {
    emit(state.copyWith(fulfillmentMethod: method));
  }

  Future<void> selectAddress(String addressId) async {
    emit(state.copyWith(selectedAddressId: () => addressId));
    final address = state.selectedAddress;
    if (address != null) await _quoteShipping(address.zipCode);
  }

  Future<void> addAddress(CustomerAddress address) async {
    final created = await _addressRepository.create(address);
    // Um novo endereço pode ter nascido padrão (regra do backend: o
    // primeiro endereço de uma conta sempre nasce padrão) — recarrega do
    // zero em vez de só anexar, pra refletir isso corretamente.
    await _loadAddresses();
    emit(state.copyWith(selectedAddressId: () => created.id));
    await _quoteShipping(created.zipCode);
  }

  Future<void> removeAddress(String addressId) async {
    await _addressRepository.delete(addressId);
    final updated = state.addresses.where((a) => a.id != addressId).toList();
    emit(
      state.copyWith(
        addresses: updated,
        selectedAddressId: () => state.selectedAddressId == addressId
            ? null
            : state.selectedAddressId,
      ),
    );
  }

  Future<void> setAddressAsDefault(String addressId) async {
    await _addressRepository.setDefault(addressId);
    final updated = state.addresses
        .map((a) => a.copyWith(isDefault: a.id == addressId))
        .toList();
    emit(state.copyWith(addresses: updated));
  }

  Future<void> _quoteShipping(String zipCode) async {
    emit(state.copyWith(loadingShipping: true));
    final options = await _repository.calculateShipping(
      zipCode: zipCode,
      cartSubtotal: state.cart.totalAfterDiscount,
    );
    emit(
      state.copyWith(
        shippingOptions: options,
        loadingShipping: false,
        selectedShippingSpeed: () =>
            state.selectedShippingSpeed ?? options.first.speed,
      ),
    );
  }

  void selectShippingSpeed(ShippingSpeed speed) =>
      emit(state.copyWith(selectedShippingSpeed: () => speed));

  void setSelfPickup(bool value) => emit(
    state.copyWith(
      selfPickup: value,
      pickupResponsibleName: () => value ? null : state.pickupResponsibleName,
      pickupResponsibleCpf: () => value ? null : state.pickupResponsibleCpf,
    ),
  );

  void updatePickupResponsible({String? name, String? cpf}) => emit(
    state.copyWith(
      pickupResponsibleName: () => name ?? state.pickupResponsibleName,
      pickupResponsibleCpf: () => cpf ?? state.pickupResponsibleCpf,
    ),
  );

  // ---------------------------------------------------------------------
  // Etapa 3 — pagamento simulado
  // ---------------------------------------------------------------------

  void choosePaymentMethod(PaymentMethod method) => emit(
    state.copyWith(
      paymentMethod: method,
      paymentSimulated: false,
      paymentApproved: false,
      cardSummary: () => null,
    ),
  );

  /// [forceRejected] só existe pro fluxo de demonstração conseguir mostrar
  /// o estado de recusa — nunca fica exposto como uma opção "normal" na UI.
  void simulatePayment({
    String? cardHolderName,
    String? cardLastFourDigits,
    int installments = 1,
    bool forceRejected = false,
  }) {
    final summary = state.paymentMethod == PaymentMethod.creditCard
        ? CardBillingSummary(
            holderName: cardHolderName ?? '',
            lastFourDigits: cardLastFourDigits ?? '',
            installments: installments,
          )
        : null;
    emit(
      state.copyWith(
        paymentSimulated: true,
        paymentApproved: !forceRejected,
        cardSummary: () => summary,
      ),
    );
  }

  // ---------------------------------------------------------------------
  // Etapa 4 — revisão / navegação entre etapas
  // ---------------------------------------------------------------------

  void setAcceptedTerms(bool value) =>
      emit(state.copyWith(acceptedTerms: value));

  void goToStep(CheckoutStep step) => emit(state.copyWith(step: step));

  void nextStep() {
    final next = switch (state.step) {
      CheckoutStep.identification => CheckoutStep.delivery,
      CheckoutStep.delivery => CheckoutStep.payment,
      CheckoutStep.payment => CheckoutStep.review,
      CheckoutStep.review => CheckoutStep.confirmation,
      CheckoutStep.confirmation => CheckoutStep.confirmation,
    };
    emit(state.copyWith(step: next));
  }

  void previousStep() {
    final previous = switch (state.step) {
      CheckoutStep.identification => CheckoutStep.identification,
      CheckoutStep.delivery => CheckoutStep.identification,
      CheckoutStep.payment => CheckoutStep.delivery,
      CheckoutStep.review => CheckoutStep.payment,
      CheckoutStep.confirmation => CheckoutStep.review,
    };
    emit(state.copyWith(step: previous));
  }

  /// Idempotente: `submitting`/`order` já preenchido barra um segundo
  /// disparo (duplo toque no botão, por exemplo) de criar dois pedidos.
  Future<void> confirmOrder() async {
    if (state.submitting || state.order != null || !state.canConfirmOrder) {
      return;
    }
    emit(state.copyWith(submitting: true, errorMessage: () => null));

    final items = state.cart.items
        .map(
          (i) => OrderItem(
            productId: i.productId,
            productName: i.productName,
            thumbnail: i.thumbnail,
            size: i.size,
            unitPrice: i.unitPrice,
            quantity: i.quantity,
            personalizedName: i.personalizedName,
            personalizedNumber: i.personalizedNumber,
            personalizationSurcharge: i.personalizationSurcharge,
          ),
        )
        .toList();

    try {
      final order = await _ordersRepository.createOrder(
        items: items,
        identification: CustomerIdentification(
          fullName: state.fullName,
          cpf: state.cpf,
          email: state.email,
          phone: state.phone,
        ),
        fulfillmentMethod: state.fulfillmentMethod,
        address: state.selectedAddress,
        shippingOption: state.selectedShippingOption,
        pickupResponsible:
            state.fulfillmentMethod == FulfillmentMethod.pickup &&
                !state.selfPickup
            ? PickupResponsible(
                fullName: state.pickupResponsibleName ?? '',
                cpf: state.pickupResponsibleCpf ?? '',
              )
            : null,
        payment: PaymentSimulationInput(
          method: state.paymentMethod,
          cardHolderName: state.cardSummary?.holderName,
          cardLastFourDigits: state.cardSummary?.lastFourDigits,
          installments: state.cardSummary?.installments ?? 1,
        ),
        subtotal: state.cart.subtotal,
        discountAmount: state.cart.discountAmount,
        couponCode: state.cart.coupon?.code,
      );

      emit(
        state.copyWith(
          submitting: false,
          order: () => order,
          step: CheckoutStep.confirmation,
        ),
      );
    } catch (error) {
      // Sacola (`state.cart`) permanece intacta — o listener que a limpa só
      // dispara quando `state.order` deixa de ser nulo (ver `checkout_page`).
      // A mensagem aqui é só pra log/depuração — a UI sempre mostra um
      // texto fixo traduzido (`storeOrderCreateErrorTitle`), nunca isto.
      emit(
        state.copyWith(
          submitting: false,
          errorMessage: () => error.toString(),
        ),
      );
    }
  }
}

extension _FirstOrNull<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
