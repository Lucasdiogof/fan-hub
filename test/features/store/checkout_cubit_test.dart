import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:goias_app/features/store/domain/entities/cart.dart';
import 'package:goias_app/features/store/domain/entities/customer.dart';
import 'package:goias_app/features/store/domain/entities/payment.dart';
import 'package:goias_app/features/store/domain/entities/shipping.dart';
import 'package:goias_app/features/store/presentation/cubit/checkout_cubit.dart';
import 'package:goias_app/features/store/presentation/cubit/checkout_state.dart';
import 'package:goias_app/l10n/app_localizations.dart';

import 'fakes/fake_store_repository.dart';

CartItem _cheapItem() => const CartItem(
  id: 'item-1',
  productId: 'cap-unico',
  productName: 'Boné Goiás Casual',
  thumbnail: 'cap_thumb.jpg',
  size: 'ÚNICO',
  unitPrice: 79.90,
);

const _address = CustomerAddress(
  id: 'addr-1',
  zipCode: '74000-000',
  street: 'Rua Teste',
  number: '123',
  neighborhood: 'Setor Teste',
  city: 'Goiânia',
  state: 'GO',
);

void main() {
  late FakeStoreRepository repository;
  late AppLocalizations l10n;

  setUpAll(() async {
    l10n = await AppLocalizations.delegate.load(const Locale('pt'));
  });

  setUp(() => repository = FakeStoreRepository());

  CheckoutCubit build(Cart cart) {
    final cubit = CheckoutCubit(repository, cart);
    addTearDown(cubit.close);
    return cubit;
  }

  group('identification step', () {
    test(
      'validateIdentification fills errors for empty fields and blocks proceeding',
      () async {
        final cubit = build(Cart(items: [_cheapItem()]));
        final valid = cubit.validateIdentification();

        expect(valid, isFalse);
        expect(cubit.state.invalidIdentificationFields, contains('cpf'));
        expect(cubit.state.canProceedFromIdentification, isFalse);
      },
    );

    test(
      'an invalid CPF blocks proceeding even with the other fields filled',
      () async {
        final cubit = build(Cart(items: [_cheapItem()]));
        cubit.updateIdentification(
          fullName: 'Lucas Diogo',
          cpf: '123.456.789-00',
          email: 'lucas@example.com',
          phone: '(62) 99999-8888',
        );
        final valid = cubit.validateIdentification();

        expect(valid, isFalse);
        expect(cubit.state.invalidIdentificationFields, contains('cpf'));
        expect(cubit.state.identificationErrors(l10n)['cpf'], 'CPF inválido.');
      },
    );

    test('a valid CPF and complete fields pass validation', () async {
      final cubit = build(Cart(items: [_cheapItem()]));
      cubit.updateIdentification(
        fullName: 'Lucas Diogo',
        cpf: '111.444.777-35',
        email: 'lucas@example.com',
        phone: '(62) 99999-8888',
      );
      final valid = cubit.validateIdentification();

      expect(valid, isTrue);
      expect(cubit.state.canProceedFromIdentification, isTrue);
    });
  });

  group('delivery step', () {
    test('selecting an address quotes shipping automatically', () async {
      final cubit = build(Cart(items: [_cheapItem()]));
      await cubit.addAddress(_address);

      expect(cubit.state.shippingOptions, isNotEmpty);
      expect(cubit.state.selectedShippingSpeed, isNotNull);
    });

    test(
      'delivery cannot proceed without both an address and a shipping speed',
      () async {
        final cubit = build(Cart(items: [_cheapItem()]));
        expect(cubit.state.canProceedFromDelivery, isFalse);

        await cubit.addAddress(_address);
        expect(cubit.state.canProceedFromDelivery, isTrue);
      },
    );

    test(
      'below the free-shipping threshold, economy shipping has a price',
      () async {
        final cubit = build(
          Cart(items: [_cheapItem()]),
        ); // 79.90, well under 399.90
        await cubit.addAddress(_address);

        final economy = cubit.state.shippingOptions.firstWhere(
          (o) => o.speed == ShippingSpeed.economy,
        );
        expect(economy.price, greaterThan(0));
      },
    );

    test(
      'at or above the free-shipping threshold, economy shipping is free',
      () async {
        final expensiveItem = _cheapItem().copyWith(
          quantity: 6,
        ); // 6 * 79.90 = 479.40
        final cubit = build(Cart(items: [expensiveItem]));
        await cubit.addAddress(_address);

        final economy = cubit.state.shippingOptions.firstWhere(
          (o) => o.speed == ShippingSpeed.economy,
        );
        expect(economy.price, 0);
      },
    );

    test('pickup never charges shipping, regardless of cart value', () async {
      final cubit = build(Cart(items: [_cheapItem()]));
      await cubit.setFulfillmentMethod(FulfillmentMethod.pickup);

      expect(cubit.state.shippingCost, 0);
    });

    test(
      'self pickup can proceed immediately; pickup for someone else needs a name and CPF',
      () async {
        final cubit = build(Cart(items: [_cheapItem()]));
        await cubit.setFulfillmentMethod(FulfillmentMethod.pickup);
        expect(cubit.state.canProceedFromDelivery, isTrue);

        cubit.setSelfPickup(false);
        expect(cubit.state.canProceedFromDelivery, isFalse);

        cubit.updatePickupResponsible(
          name: 'Outra Pessoa',
          cpf: '111.444.777-35',
        );
        expect(cubit.state.canProceedFromDelivery, isTrue);
      },
    );
  });

  group('payment step', () {
    test('simulating a Pix payment approves it immediately', () async {
      final cubit = build(Cart(items: [_cheapItem()]));
      expect(cubit.state.canProceedFromPayment, isFalse);

      cubit.simulatePayment();
      expect(cubit.state.paymentApproved, isTrue);
      expect(cubit.state.canProceedFromPayment, isTrue);
    });

    test(
      'simulating a credit card payment keeps only the last 4 digits and the installments',
      () async {
        final cubit = build(Cart(items: [_cheapItem()]));
        cubit.choosePaymentMethod(PaymentMethod.creditCard);
        cubit.simulatePayment(
          cardHolderName: 'LUCAS DIOGO',
          cardLastFourDigits: '4242',
          installments: 3,
        );

        expect(cubit.state.paymentApproved, isTrue);
        expect(cubit.state.cardSummary?.lastFourDigits, '4242');
        expect(cubit.state.cardSummary?.installments, 3);
      },
    );

    test('switching payment method resets the previous approval', () async {
      final cubit = build(Cart(items: [_cheapItem()]));
      cubit.simulatePayment();
      expect(cubit.state.paymentApproved, isTrue);

      cubit.choosePaymentMethod(PaymentMethod.creditCard);
      expect(cubit.state.paymentApproved, isFalse);
    });
  });

  group('totals', () {
    test('total is the cart total plus the selected shipping cost', () async {
      final cubit = build(Cart(items: [_cheapItem()]));
      await cubit.addAddress(_address);
      final shippingCost = cubit.state.shippingCost;

      expect(cubit.state.total, closeTo(79.90 + shippingCost, 0.001));
    });

    test('pickup total never includes shipping', () async {
      final cubit = build(Cart(items: [_cheapItem()]));
      await cubit.setFulfillmentMethod(FulfillmentMethod.pickup);

      expect(cubit.state.total, closeTo(79.90, 0.001));
    });
  });

  group('confirmOrder', () {
    Future<CheckoutCubit> readyToConfirm() async {
      final cubit = build(Cart(items: [_cheapItem()]));
      cubit.updateIdentification(
        fullName: 'Lucas Diogo',
        cpf: '111.444.777-35',
        email: 'lucas@example.com',
        phone: '(62) 99999-8888',
      );
      cubit.validateIdentification();
      await cubit.setFulfillmentMethod(FulfillmentMethod.pickup);
      cubit.simulatePayment();
      cubit.setAcceptedTerms(true);
      return cubit;
    }

    test('cannot confirm before accepting the terms', () async {
      final cubit = build(Cart(items: [_cheapItem()]));
      expect(cubit.state.canConfirmOrder, isFalse);
    });

    test('creates the order and moves to the confirmation step', () async {
      final cubit = await readyToConfirm();
      await cubit.confirmOrder();

      expect(cubit.state.order, isNotNull);
      expect(cubit.state.step, CheckoutStep.confirmation);
      expect(repository.createOrderCallCount, 1);
    });

    test(
      'is idempotent — calling it twice never creates a second order',
      () async {
        final cubit = await readyToConfirm();
        await cubit.confirmOrder();
        await cubit.confirmOrder();

        expect(repository.createOrderCallCount, 1);
      },
    );
  });
}
