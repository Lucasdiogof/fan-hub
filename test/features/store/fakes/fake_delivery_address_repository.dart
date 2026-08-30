import 'package:goias_app/features/store/domain/entities/customer.dart';
import 'package:goias_app/features/store/domain/repositories/delivery_address_repository.dart';

/// Mesma regra do trigger real (ver `supabase/delivery_addresses.sql`): o
/// primeiro endereço nasce padrão, marcar um como padrão desmarca os outros
/// — reproduzida aqui em memória pra testar sem precisar de um Supabase de
/// verdade.
class FakeDeliveryAddressRepository implements DeliveryAddressRepository {
  final List<CustomerAddress> addresses = [];

  @override
  Future<List<CustomerAddress>> list() async => List.unmodifiable(addresses);

  @override
  Future<CustomerAddress> create(CustomerAddress address) async {
    final withDefault = address.copyWith(isDefault: addresses.isEmpty);
    if (withDefault.isDefault) {
      for (var i = 0; i < addresses.length; i++) {
        addresses[i] = addresses[i].copyWith(isDefault: false);
      }
    }
    addresses.add(withDefault);
    return withDefault;
  }

  @override
  Future<void> update(CustomerAddress address) async {
    final index = addresses.indexWhere((a) => a.id == address.id);
    if (index != -1) addresses[index] = address;
  }

  @override
  Future<void> delete(String id) async {
    addresses.removeWhere((a) => a.id == id);
  }

  @override
  Future<void> setDefault(String id) async {
    for (var i = 0; i < addresses.length; i++) {
      addresses[i] = addresses[i].copyWith(isDefault: addresses[i].id == id);
    }
  }
}
