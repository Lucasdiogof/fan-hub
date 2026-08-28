import 'package:equatable/equatable.dart';
import 'package:goias_app/features/store/domain/entities/cart.dart';
import 'package:goias_app/features/store/domain/entities/customer.dart';
import 'package:goias_app/features/store/domain/entities/payment.dart';
import 'package:goias_app/features/store/domain/entities/shipping.dart';
import 'package:goias_app/features/store/domain/entities/store_order.dart';
import 'package:goias_app/features/store/presentation/store_validators.dart';
import 'package:goias_app/l10n/app_localizations.dart';

enum CheckoutStep { identification, delivery, payment, review, confirmation }

class CheckoutState extends Equatable {
  const CheckoutState({
    required this.cart,
    this.step = CheckoutStep.identification,
    this.fullName = '',
    this.cpf = '',
    this.email = '',
    this.phone = '',
    this.invalidIdentificationFields = const {},
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

  /// Nomes dos campos (`fullName`/`cpf`/`email`/`phone`) que falharam na
  /// última validação — nunca a mensagem pronta (ver
  /// `identificationErrors(l10n)` abaixo, que traduz sob demanda).
  final Set<String> invalidIdentificationFields;

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

  // Etapa 3 — pagamento simulado.
  final PaymentMethod paymentMethod;
  final CardBillingSummary? cardSummary;
  final bool paymentSimulated;
  final bool paymentApproved;

  // Etapa 4 — revisão.
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
      StoreValidators.isValidFullName(fullName) &&
      StoreValidators.isValidCpf(cpf.replaceAll(RegExp(r'\D'), '')) &&
      StoreValidators.isValidEmailShape(email) &&
      StoreValidators.isValidPhone(phone);

  /// Traduzida sob demanda (ver `StoreValidators`) — nunca guardada pronta
  /// em [invalidIdentificationFields], só os nomes dos campos com problema.
  Map<String, String> identificationErrors(AppLocalizations l10n) {
    final errors = <String, String>{};
    if (invalidIdentificationFields.contains('fullName')) {
      final message = StoreValidators.fullName(l10n, fullName);
      if (message != null) errors['fullName'] = message;
    }
    if (invalidIdentificationFields.contains('cpf')) {
      final message = StoreValidators.cpf(l10n, cpf);
      if (message != null) errors['cpf'] = message;
    }
    if (invalidIdentificationFields.contains('email')) {
      final message = StoreValidators.email(l10n, email);
      if (message != null) errors['email'] = message;
    }
    if (invalidIdentificationFields.contains('phone')) {
      final message = StoreValidators.phone(l10n, phone);
      if (message != null) errors['phone'] = message;
    }
    return errors;
  }

  bool get canProceedFromDelivery {
    if (fulfillmentMethod == FulfillmentMethod.pickup) {
      if (selfPickup) return true;
      return (pickupResponsibleName?.isNotEmpty ?? false) &&
          (pickupResponsibleCpf?.isNotEmpty ?? false);
    }
    return selectedAddressId != null && selectedShippingSpeed != null;
  }

  bool get canProceedFromPayment => paymentApproved;

  bool get canConfirmOrder => acceptedTerms && !submitting;

  CheckoutState copyWith({
    Cart? cart,
    CheckoutStep? step,
    String? fullName,
    String? cpf,
    String? email,
    String? phone,
    Set<String>? invalidIdentificationFields,
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
    invalidIdentificationFields:
        invalidIdentificationFields ?? this.invalidIdentificationFields,
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
    invalidIdentificationFields,
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
