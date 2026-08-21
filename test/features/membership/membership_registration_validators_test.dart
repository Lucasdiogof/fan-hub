import 'package:flutter_test/flutter_test.dart';
import 'package:goias_app/features/membership/domain/membership_registration_validators.dart';

void main() {
  group('isValidCpf', () {
    test('accepts a mathematically valid CPF', () {
      expect(isValidCpf('123.456.789-09'), isTrue);
      expect(isValidCpf('111.444.777-35'), isTrue);
    });

    test('rejects a CPF with a wrong check digit', () {
      expect(isValidCpf('123.456.789-00'), isFalse);
    });

    test('rejects repeated-digit sequences even if 11 digits long', () {
      expect(isValidCpf('000.000.000-00'), isFalse);
      expect(isValidCpf('111.111.111-11'), isFalse);
      expect(isValidCpf('222.222.222-22'), isFalse);
    });

    test('rejects anything that is not 11 digits', () {
      expect(isValidCpf('123.456.789'), isFalse);
      expect(isValidCpf(''), isFalse);
    });
  });

  group('isValidEmailShape', () {
    test('accepts a normal address', () {
      expect(isValidEmailShape('lucas@gmail.com'), isTrue);
    });

    test('rejects missing @ or domain', () {
      expect(isValidEmailShape('lucas'), isFalse);
      expect(isValidEmailShape('lucas@'), isFalse);
      expect(isValidEmailShape('@gmail.com'), isFalse);
      expect(isValidEmailShape('lucas@gmail'), isFalse);
    });
  });

  group('isValidFullName', () {
    test('accepts legitimate names with accents, hyphen and apostrophe', () {
      expect(isValidFullName('Lucas Diogo'), isTrue);
      expect(isValidFullName('João D\'Ávila Nogueira-Silva'), isTrue);
    });

    test('rejects empty, too short, or digits-only values', () {
      expect(isValidFullName(''), isFalse);
      expect(isValidFullName('Al'), isFalse);
      expect(isValidFullName('123456'), isFalse);
    });
  });

  group('parseDdMmYyyy', () {
    test('parses a real date', () {
      final date = parseDdMmYyyy('23/09/1996');
      expect(date, DateTime(1996, 9, 23));
    });

    test('rejects a day that does not exist in that month (31/02)', () {
      expect(parseDdMmYyyy('31/02/2020'), isNull);
    });

    test('rejects an incomplete date', () {
      expect(parseDdMmYyyy('23/09'), isNull);
    });

    test('rejects garbage digits', () {
      expect(parseDdMmYyyy('45141996'), isNull);
      expect(parseDdMmYyyy('00000000'), isNull);
    });
  });

  group('isAtLeast18', () {
    test('accepts someone older than 18', () {
      final birthDate = DateTime.now().subtract(const Duration(days: 365 * 20));
      expect(isAtLeast18(birthDate), isTrue);
    });

    test('rejects someone younger than 18', () {
      final birthDate = DateTime.now().subtract(const Duration(days: 365 * 10));
      expect(isAtLeast18(birthDate), isFalse);
    });

    test('rejects someone who turns 18 later this year', () {
      final now = DateTime.now();
      final birthDate = DateTime(now.year - 18, now.month, now.day + 1);
      expect(isAtLeast18(birthDate), isFalse);
    });
  });

  group('isValidMobilePhone', () {
    test('accepts a real-looking Brazilian mobile number', () {
      expect(isValidMobilePhone('(62) 99999-8888'), isTrue);
    });

    test('rejects an incomplete number', () {
      expect(isValidMobilePhone('(62) 9999-888'), isFalse);
    });

    test('rejects an obviously fake sequence', () {
      expect(isValidMobilePhone('(00) 00000-0000'), isFalse);
    });

    test('rejects a number missing the mobile 9 prefix', () {
      expect(isValidMobilePhone('(62) 32222-1234'), isFalse);
    });
  });

  group('isValidCep', () {
    test('accepts 8 digits regardless of mask', () {
      expect(isValidCep('74000-000'), isTrue);
      expect(isValidCep('74000000'), isTrue);
    });

    test('rejects fewer than 8 digits', () {
      expect(isValidCep('7400-00'), isFalse);
      expect(isValidCep(''), isFalse);
    });
  });

  group('isValidPassportShape', () {
    test('accepts a plausible passport number', () {
      expect(isValidPassportShape('AB1234567'), isTrue);
    });

    test('rejects something too short or with symbols', () {
      expect(isValidPassportShape('AB1'), isFalse);
      expect(isValidPassportShape('AB-1234567'), isFalse);
    });
  });
}
