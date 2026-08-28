import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:goias_app/features/store/presentation/store_validators.dart';
import 'package:goias_app/l10n/app_localizations.dart';

void main() {
  late AppLocalizations l10n;

  setUpAll(() async {
    l10n = await AppLocalizations.delegate.load(const Locale('pt'));
  });

  group('StoreValidators.isValidCpf', () {
    test('accepts a real valid CPF', () {
      expect(StoreValidators.isValidCpf('11144477735'), isTrue);
    });

    test('rejects a CPF with a wrong check digit', () {
      expect(StoreValidators.isValidCpf('11144477736'), isFalse);
    });

    test(
      'rejects repeated-digit sequences even though they pass the checksum math',
      () {
        expect(StoreValidators.isValidCpf('00000000000'), isFalse);
        expect(StoreValidators.isValidCpf('11111111111'), isFalse);
      },
    );

    test('rejects wrong length', () {
      expect(StoreValidators.isValidCpf('123'), isFalse);
    });
  });

  group('StoreValidators.cpf', () {
    test('blocks an invalid CPF with a Portuguese message', () {
      expect(StoreValidators.cpf(l10n, '123.456.789-00'), 'CPF inválido.');
    });

    test('accepts a valid masked CPF', () {
      expect(StoreValidators.cpf(l10n, '111.444.777-35'), isNull);
    });

    test('requires a value', () {
      expect(StoreValidators.cpf(l10n, ''), 'Informe o CPF.');
    });
  });

  group('StoreValidators.fullName', () {
    test('requires first and last name', () {
      expect(StoreValidators.fullName(l10n, 'Lucas'), isNotNull);
      expect(StoreValidators.fullName(l10n, 'Lucas Diogo'), isNull);
    });
  });

  group('StoreValidators.email', () {
    test('rejects malformed addresses', () {
      expect(StoreValidators.email(l10n, 'not-an-email'), isNotNull);
      expect(StoreValidators.email(l10n, 'lucas@example.com'), isNull);
    });
  });

  group('StoreValidators.phone', () {
    test('requires at least 10 digits', () {
      expect(StoreValidators.phone(l10n, '(62) 1234'), isNotNull);
      expect(StoreValidators.phone(l10n, '(62) 99999-8888'), isNull);
    });
  });

  group('StoreValidators.zipCode', () {
    test('requires exactly 8 digits', () {
      expect(StoreValidators.zipCode(l10n, '74000'), isNotNull);
      expect(StoreValidators.zipCode(l10n, '74000-000'), isNull);
    });
  });
}
