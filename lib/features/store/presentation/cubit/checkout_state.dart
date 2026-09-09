import 'package:equatable/equatable.dart';
import 'package:goias_app/features/store/domain/entities/cart.dart';
import 'package:goias_app/features/store/domain/entities/customer.dart';
import 'package:goias_app/features/store/domain/entities/payment.dart';
import 'package:goias_app/features/store/domain/entities/shipping.dart';
import 'package:goias_app/features/store/domain/entities/store_order.dart';
import 'package:goias_app/shared/validation/app_validators.dart';

enum CheckoutStep { identification, delivery, review, payment, confirmation }

class CheckoutState extends Equatable {
  const CheckoutState({
    required this.cart,
    this.step = CheckoutStep.identification,
    this.fullName = '',
    this.cpf = '',
    this.email = '',
    this.phone = '',
    this.fulfillmentMethod = FulfillmentMethod.delivery,
    this.addresses = const [],
    this.selectedAddressId,
    this.shippingOptions = const [],
    this.selectedShippingSpeed,
    this.loadingShipping = false,
    this.selfPickup = true,
    this.pickupResponsibleName,
    this.pickupResponsibleCpf,
    this.paymentMethod = PaymentMethod.pix,
    this.cardSummary,
    this.paymentSimulated = false,
    this.paymentApproved = false,
    this.acceptedTerms = false,
    this.submitting = false,
    this.order,
    this.errorMessage,
  });

  final Cart cart;
  final CheckoutStep step;

  // Etapa 1 — identificação (nunca escreve direto no Profile).
  final String fullName;
  final String cpf;
  final String email;
  final String phone;

  // Etapa 2 — entrega ou retirada.
  final FulfillmentMethod fulfillmentMethod;
  final List<CustomerAddress> addresses;
  final String? selectedAddressId;
  final List<ShippingOption> shippingOptions;
  final ShippingSpeed? selectedShippingSpeed;
  final bool loadingShipping;
  final bool selfPickup;
  final String? pickupResponsibleName;
  final String? pickupResponsibleCpf;

  // Etapa 4 — pagamento simulado (depois da revisão).
  final PaymentMethod paymentMethod;
  final CardBillingSummary? cardSummary;
  final bool paymentSimulated;
  final bool paymentApproved;

  // Etapa 3 — revisão (antes do pagamento).
  final bool acceptedTerms;

  final bool submitting;
  final StoreOrder? order;
  final String? errorMessage;

  CustomerAddress? get selectedAddress {
    if (selectedAddressId == null) return null;
    for (final address in addresses) {
      if (address.id == selectedAddressId) return address;
    }
    return null;
  }

  ShippingOption? get selectedShippingOption {
    if (selectedShippingSpeed == null) return null;
    for (final option in shippingOptions) {
      if (option.speed == selectedShippingSpeed) return option;
    }
    return null;
  }

  double get shippingCost {
    if (fulfillmentMethod == FulfillmentMethod.pickup) return 0;
    return selectedShippingOption?.price ?? 0;
  }

  double get total => cart.totalAfterDiscount + shippingCost;

  bool get canProceedFromIdentification =>
      AppValidators.isValidFullName(fullName) &&
      AppValidators.isValidCpf(cpf.replaceAll(RegExp(r'\D'), '')) &&
      AppValidators.isValidEmailShape(email) &&
      AppValidators.isValidMobilePhone(phone);

  bool get canProceedFromDelivery {
    if (fulfillmentMethod == FulfillmentMethod.pickup) {
      if (selfPickup) return true;
      return AppValidators.isValidFullName(pickupResponsibleName ?? '') &&
          AppValidators.isValidCpf(
            (pickupResponsibleCpf ?? '').replaceAll(RegExp(r'\D'), ''),
          );
    }
    return selectedAddressId != null && selectedShippingSpeed != null;
  }

  bool get canProceedFromReview => acceptedTerms;

  bool get canProceedFromPayment => paymentApproved;

  bool get canConfirmOrder =>
      acceptedTerms && paymentApproved && !submitting;

  CheckoutState copyWith({
    Cart? cart,
    CheckoutStep? step,
    String? fullName,
    String? cpf,
    String? email,
    String? phone,
    FulfillmentMethod? fulfillmentMethod,
    List<CustomerAddress>? addresses,
    String? Function()? selectedAddressId,
    List<ShippingOption>? shippingOptions,
    ShippingSpeed? Function()? selectedShippingSpeed,
    bool? loadingShipping,
    bool? selfPickup,
    String? Function()? pickupResponsibleName,
    String? Function()? pickupResponsibleCpf,
    PaymentMethod? paymentMethod,
    CardBillingSummary? Function()? cardSummary,
    bool? paymentSimulated,
    bool? paymentApproved,
    bool? acceptedTerms,
    bool? submitting,
    StoreOrder? Function()? order,
    String? Function()? errorMessage,
  }) => CheckoutState(
    cart: cart ?? this.cart,
    step: step ?? this.step,
    fullName: fullName ?? this.fullName,
    cpf: cpf ?? this.cpf,
    email: email ?? this.email,
    phone: phone ?? this.phone,
    fulfillmentMethod: fulfillmentMethod ?? this.fulfillmentMethod,
    addresses: addresses ?? this.addresses,
    selectedAddressId: selectedAddressId != null
        ? selectedAddressId()
        : this.selectedAddressId,
    shippingOptions: shippingOptions ?? this.shippingOptions,
    selectedShippingSpeed: selectedShippingSpeed != null
        ? selectedShippingSpeed()
        : this.selectedShippingSpeed,
    loadingShipping: loadingShipping ?? this.loadingShipping,
    selfPickup: selfPickup ?? this.selfPickup,
    pickupResponsibleName: pickupResponsibleName != null
        ? pickupResponsibleName()
        : this.pickupResponsibleName,
    pickupResponsibleCpf: pickupResponsibleCpf != null
        ? pickupResponsibleCpf()
        : this.pickupResponsibleCpf,
    paymentMethod: paymentMethod ?? this.paymentMethod,
    cardSummary: cardSummary != null ? cardSummary() : this.cardSummary,
    paymentSimulated: paymentSimulated ?? this.paymentSimulated,
    paymentApproved: paymentApproved ?? this.paymentApproved,
    acceptedTerms: acceptedTerms ?? this.acceptedTerms,
    submitting: submitting ?? this.submitting,
    order: order != null ? order() : this.order,
    errorMessage: errorMessage != null ? errorMessage() : this.errorMessage,
  );

  @override
  List<Object?> get props => [
    cart,
    step,
    fullName,
    cpf,
    email,
    phone,
    fulfillmentMethod,
    addresses,
    selectedAddressId,
    shippingOptions,
    selectedShippingSpeed,
    loadingShipping,
    selfPickup,
    pickupResponsibleName,
    pickupResponsibleCpf,
    paymentMethod,
    cardSummary,
    paymentSimulated,
    paymentApproved,
    acceptedTerms,
    submitting,
    order,
    errorMessage,
  ];
}
