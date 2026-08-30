import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:goias_app/l10n/app_localizations.dart';
import 'package:goias_app/shared/validation/app_validators.dart';

void main() {
  late AppLocalizations l10n;

  setUpAll(() async {
    l10n = await AppLocalizations.delegate.load(const Locale('pt'));
  });

  group('AppValidators.isValidCpf', () {
    test('accepts a real valid CPF', () {
      expect(AppValidators.isValidCpf('11144477735'), isTrue);
    });

    test('rejects a CPF with a wrong check digit', () {
      expect(AppValidators.isValidCpf('11144477736'), isFalse);
    });

    test(
      'rejects repeated-digit sequences even though they pass the checksum math',
      () {
        expect(AppValidators.isValidCpf('00000000000'), isFalse);
        expect(AppValidators.isValidCpf('11111111111'), isFalse);
      },
    );

    test('rejects wrong length', () {
      expect(AppValidators.isValidCpf('123'), isFalse);
    });
  });

  group('AppValidators.cpf', () {
    test('blocks an invalid CPF with a Portuguese message', () {
      expect(AppValidators.cpf(l10n, '123.456.789-00'), 'CPF inválido.');
    });

    test('accepts a valid masked CPF', () {
      expect(AppValidators.cpf(l10n, '111.444.777-35'), isNull);
    });

    test('requires a value', () {
      expect(AppValidators.cpf(l10n, ''), 'Informe o CPF.');
    });
  });

  group('AppValidators.fullName', () {
    test('requires first and last name', () {
      expect(AppValidators.fullName(l10n, 'Lucas'), isNotNull);
      expect(AppValidators.fullName(l10n, 'Lucas Diogo'), isNull);
    });
  });

  group('AppValidators.email', () {
    test('rejects malformed addresses', () {
      expect(AppValidators.email(l10n, 'not-an-email'), isNotNull);
      expect(AppValidators.email(l10n, 'lucas@example.com'), isNull);
    });
  });

  group('AppValidators.phone', () {
    test('requires at least 10 digits', () {
      expect(AppValidators.phone(l10n, '(62) 1234'), isNotNull);
      expect(AppValidators.phone(l10n, '(62) 3245-8888'), isNull);
    });
  });

  group('AppValidators.mobilePhone', () {
    test('requires DDD + 9 digits starting with 9', () {
      expect(AppValidators.mobilePhone(l10n, '(62) 3245-8888'), isNotNull);
      expect(AppValidators.mobilePhone(l10n, '(62) 99999-8888'), isNull);
    });
  });

  group('AppValidators.zipCode', () {
    test('requires exactly 8 digits', () {
      expect(AppValidators.zipCode(l10n, '74000'), isNotNull);
      expect(AppValidators.zipCode(l10n, '74000-000'), isNull);
    });
  });

  group('AppValidators.birthDate', () {
    test('rejects incomplete or impossible dates', () {
      expect(AppValidators.birthDate(l10n, '31/02/2000'), isNotNull);
      expect(AppValidators.birthDate(l10n, '15/05/1995'), isNull);
    });
  });
}
