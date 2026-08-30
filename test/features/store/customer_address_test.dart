import 'package:flutter_test/flutter_test.dart';
import 'package:goias_app/features/store/domain/entities/customer.dart';

void main() {
  const residential = CustomerAddress(
    id: 'residential-1',
    zipCode: '74000-000',
    street: 'Rua A',
    number: '100',
    neighborhood: 'Setor Teste',
    city: 'Goiânia',
    state: 'GO',
  );

  group('copyAsNew', () {
    test('creates an independent record with a new id', () {
      final delivery = residential.copyAsNew(id: 'delivery-1', label: 'Casa');

      expect(delivery.id, 'delivery-1');
      expect(delivery.label, 'Casa');
      expect(delivery.street, residential.street);
      expect(delivery.isDefault, isFalse);
    });

    test('editing the residential address afterwards never changes the copy', () {
      final delivery = residential.copyAsNew(id: 'delivery-1');
      final editedResidential = residential.copyWith();

      // Simula o residencial mudando de rua depois que a cópia já existe.
      const changedResidential = CustomerAddress(
        id: 'residential-1',
        zipCode: '74000-000',
        street: 'Rua B',
        number: '200',
        neighborhood: 'Setor Teste',
        city: 'Goiânia',
        state: 'GO',
      );

      expect(delivery.street, 'Rua A');
      expect(changedResidential.street, isNot(delivery.street));
      expect(editedResidential.street, residential.street);
    });
  });

  group('copyWith', () {
    test('label can be cleared explicitly via the function wrapper', () {
      final labeled = residential.copyWith(label: () => 'Trabalho');
      final cleared = labeled.copyWith(label: () => null);

      expect(labeled.label, 'Trabalho');
      expect(cleared.label, isNull);
    });

    test('omitting label keeps the previous value', () {
      final labeled = residential.copyWith(label: () => 'Casa');
      final stillLabeled = labeled.copyWith(isDefault: true);

      expect(stillLabeled.label, 'Casa');
      expect(stillLabeled.isDefault, isTrue);
    });
  });
}
