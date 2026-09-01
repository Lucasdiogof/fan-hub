import 'package:goias_app/features/store/domain/entities/customer.dart';
import 'package:goias_app/features/store/domain/repositories/delivery_address_repository.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// `public.delivery_addresses` — cada linha pertence a UMA conta (RLS) e as
/// duas regras de "endereço padrão" (o primeiro nasce padrão; marcar um como
/// padrão desmarca os outros) vivem em triggers no banco, não aqui — o app
/// só faz updates de uma linha por vez, nunca precisa saber o estado dos
/// outros endereços pra manter a invariante.
class SupabaseDeliveryAddressRepository implements DeliveryAddressRepository {
  SupabaseDeliveryAddressRepository(this._client);

  final SupabaseClient _client;

  String get _uid => _client.auth.currentUser!.id;

  @override
  Future<List<CustomerAddress>> list() async {
    final rows = await _client
        .from('delivery_addresses')
        .select()
        .eq('user_id', _uid)
        .order('is_default', ascending: false)
        .order('created_at', ascending: true);
    return rows.map(_mapRow).toList();
  }

  @override
  Future<CustomerAddress> create(CustomerAddress address) async {
    final row = await _client
        .from('delivery_addresses')
        .insert({
          'user_id': _uid,
          'label': address.label,
          'zip_code': address.zipCode,
          'street': address.street,
          'number': address.number,
          'complement': address.complement,
          'neighborhood': address.neighborhood,
          'city': address.city,
          'state': address.state,
          'is_default': address.isDefault,
        })
        .select()
        .single();
    return _mapRow(row);
  }

  @override
  Future<void> update(CustomerAddress address) async {
    await _client
        .from('delivery_addresses')
        .update({
          'label': address.label,
          'zip_code': address.zipCode,
          'street': address.street,
          'number': address.number,
          'complement': address.complement,
          'neighborhood': address.neighborhood,
          'city': address.city,
          'state': address.state,
          'updated_at': DateTime.now().toIso8601String(),
        })
        .eq('id', address.id)
        .eq('user_id', _uid);
  }

  @override
  Future<void> delete(String id) async {
    await _client
        .from('delivery_addresses')
        .delete()
        .eq('id', id)
        .eq('user_id', _uid);
  }

  @override
  Future<void> setDefault(String id) async {
    await _client
        .from('delivery_addresses')
        .update({
          'is_default': true,
          'updated_at': DateTime.now().toIso8601String(),
        })
        .eq('id', id)
        .eq('user_id', _uid);
  }

  CustomerAddress _mapRow(Map<String, dynamic> row) => CustomerAddress(
    id: row['id'] as String,
    zipCode: row['zip_code'] as String,
    street: row['street'] as String,
    number: row['number'] as String,
    complement: row['complement'] as String?,
    neighborhood: row['neighborhood'] as String,
    city: row['city'] as String,
    state: row['state'] as String,
    isDefault: row['is_default'] as bool? ?? false,
    label: row['label'] as String?,
  );
}
