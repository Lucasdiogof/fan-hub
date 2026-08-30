import 'package:goias_app/features/store/domain/entities/customer.dart';

/// Endereços de ENTREGA da conta — zero, um ou vários, cada um com CRUD
/// próprio (nunca "carrega tudo, muta em memória, salva tudo de volta":
/// isso era aceitável pra `SharedPreferences` local, mas custoso/arriscado
/// contra um backend real). Conceitualmente separado do endereço
/// RESIDENCIAL (único, editado em `ProfileRepository`/`AddressCubit`) — ver
/// [[project_goias_app_address_split]] se essa memória existir.
abstract interface class DeliveryAddressRepository {
  Future<List<CustomerAddress>> list();
  Future<CustomerAddress> create(CustomerAddress address);
  Future<void> update(CustomerAddress address);
  Future<void> delete(String id);

  /// O próprio backend garante que só um endereço fica padrão por vez (ver
  /// `supabase/delivery_addresses.sql`) — nunca um loop de updates no app.
  Future<void> setDefault(String id);
}
