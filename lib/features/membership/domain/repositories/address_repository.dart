import 'package:goias_app/core/error/result.dart';
import 'package:goias_app/features/membership/domain/entities/address_lookup_result.dart';

abstract interface class AddressRepository {
  /// Busca direta por CEP (8 dígitos). Só vale pra endereços do Brasil —
  /// quem decide se chama isso é a UI, com base no país selecionado.
  Future<Result<AddressLookupResult?>> findByZipCode(String zipCode);

  /// Busca reversa por UF + cidade + logradouro (pelo menos 3 caracteres),
  /// pode retornar múltiplos endereços.
  Future<Result<List<AddressLookupResult>>> searchByAddress({
    required String state,
    required String city,
    required String street,
  });

  /// Lista os municípios de uma UF (ex.: "GO") — usado pra Cidade depender
  /// do Estado selecionado em vez de ser texto livre.
  Future<Result<List<String>>> getCitiesByState(String stateCode);
}
