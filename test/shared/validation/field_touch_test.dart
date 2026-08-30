import 'package:flutter_test/flutter_test.dart';
import 'package:goias_app/shared/validation/field_touch.dart';

void main() {
  String? format(String value) => value == 'valid' ? null : 'invalid format';

  group('FieldTouch.errorFor', () {
    test('pristine empty field shows no error', () {
      final field = FieldTouch();
      expect(
        field.errorFor(
          '',
          submitted: false,
          format: format,
          requiredMessage: 'required',
        ),
        isNull,
      );
    });

    test('typing an invalid value shows the error live, before submit', () {
      final field = FieldTouch()..touched = true;
      expect(
        field.errorFor(
          'wrong',
          submitted: false,
          format: format,
          requiredMessage: 'required',
        ),
        'invalid format',
      );
    });

    test('finishing a valid value clears the error immediately', () {
      final field = FieldTouch()..touched = true;
      expect(
        field.errorFor(
          'valid',
          submitted: false,
          format: format,
          requiredMessage: 'required',
        ),
        isNull,
      );
    });

    test('clearing the field back to empty returns to neutral', () {
      final field = FieldTouch()..touched = true;
      // Já foi inválido antes, mas o usuário apagou tudo.
      field.errorFor(
        'wrong',
        submitted: false,
        format: format,
        requiredMessage: 'required',
      );
      expect(
        field.errorFor(
          '',
          submitted: false,
          format: format,
          requiredMessage: 'required',
        ),
        isNull,
      );
    });

    test('submitting with an empty required field reveals it', () {
      final field = FieldTouch();
      expect(
        field.errorFor(
          '',
          submitted: true,
          format: format,
          requiredMessage: 'required',
        ),
        'required',
      );
    });

    test('correcting after a failed submit clears the error', () {
      final field = FieldTouch();
      field.errorFor(
        '',
        submitted: true,
        format: format,
        requiredMessage: 'required',
      );
      field.touched = true;
      expect(
        field.errorFor(
          'valid',
          submitted: true,
          format: format,
          requiredMessage: 'required',
        ),
        isNull,
      );
    });

    test('a pre-filled untouched value stays neutral until edited', () {
      final field = FieldTouch();
      expect(
        field.errorFor(
          'wrong',
          submitted: false,
          format: format,
          requiredMessage: 'required',
        ),
        isNull,
      );
    });
  });
}
