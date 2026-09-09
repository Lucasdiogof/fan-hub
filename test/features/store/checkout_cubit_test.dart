import 'package:flutter_test/flutter_test.dart';
import 'package:goias_app/features/store/domain/entities/cart.dart';
import 'package:goias_app/features/store/domain/entities/customer.dart';
import 'package:goias_app/features/store/domain/entities/payment.dart';
import 'package:goias_app/features/store/domain/entities/shipping.dart';
import 'package:goias_app/features/store/presentation/cubit/checkout_cubit.dart';
import 'package:goias_app/features/store/presentation/cubit/checkout_state.dart';

import 'fakes/fake_delivery_address_repository.dart';
import 'fakes/fake_store_orders_repository.dart';
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
  late FakeStoreOrdersRepository ordersRepository;
  late FakeDeliveryAddressRepository addressRepository;

  setUp(() {
    repository = FakeStoreRepository();
    ordersRepository = FakeStoreOrdersRepository();
    addressRepository = FakeDeliveryAddressRepository();
  });

  CheckoutCubit build(Cart cart) {
    final cubit = CheckoutCubit(
      repository,
      ordersRepository,
      addressRepository,
      cart,
    );
    addTearDown(cubit.close);
    return cubit;
  }

  group('identification step', () {
    test('empty fields block proceeding', () async {
      final cubit = build(Cart(items: [_cheapItem()]));
      expect(cubit.state.canProceedFromIdentification, isFalse);
    });

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

        expect(cubit.state.canProceedFromIdentification, isFalse);
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
      'the first delivery address created becomes the selected default',
      () async {
        final cubit = build(Cart(items: [_cheapItem()]));
        await cubit.addAddress(_address);

        expect(addressRepository.addresses, hasLength(1));
        expect(addressRepository.addresses.single.isDefault, isTrue);
        expect(cubit.state.selectedAddressId, _address.id);
      },
    );

    test('marking a second address as default unmarks the first one', () async {
      final cubit = build(Cart(items: [_cheapItem()]));
      await cubit.addAddress(_address);
      await cubit.addAddress(_address.copyAsNew(id: 'addr-2'));
      await cubit.setAddressAsDefault('addr-2');

      final byId = {for (final a in addressRepository.addresses) a.id: a};
      expect(byId['addr-2']!.isDefault, isTrue);
      expect(byId[_address.id]!.isDefault, isFalse);
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

    test(
      'a name and any digits are not enough — CPF must actually be valid',
      () async {
        final cubit = build(Cart(items: [_cheapItem()]));
        await cubit.setFulfillmentMethod(FulfillmentMethod.pickup);
        cubit.setSelfPickup(false);

        cubit.updatePickupResponsible(name: 'Outra Pessoa', cpf: '1');
        expect(cubit.state.canProceedFromDelivery, isFalse);

        cubit.updatePickupResponsible(cpf: '111.444.777-36');
        expect(cubit.state.canProceedFromDelivery, isFalse);
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
      expect(ordersRepository.createOrderCallCount, 1);
    });

    test(
      'is idempotent — calling it twice never creates a second order',
      () async {
        final cubit = await readyToConfirm();
        await cubit.confirmOrder();
        await cubit.confirmOrder();

        expect(ordersRepository.createOrderCallCount, 1);
      },
    );

    test(
      'a failed creation surfaces an error, keeps the cart, and never advances the step',
      () async {
        ordersRepository.failWith = Exception('network down');
        final cubit = await readyToConfirm();
        await cubit.confirmOrder();

        expect(cubit.state.order, isNull);
        expect(cubit.state.errorMessage, isNotNull);
        expect(cubit.state.step, isNot(CheckoutStep.confirmation));
        expect(cubit.state.submitting, isFalse);
        expect(cubit.state.cart.items, isNotEmpty);
      },
    );

    test('retrying after a failure can still succeed', () async {
      ordersRepository.failWith = Exception('network down');
      final cubit = await readyToConfirm();
      await cubit.confirmOrder();
      expect(cubit.state.order, isNull);

      ordersRepository.failWith = null;
      await cubit.confirmOrder();

      expect(cubit.state.order, isNotNull);
      expect(cubit.state.step, CheckoutStep.confirmation);
    });
  });
}
