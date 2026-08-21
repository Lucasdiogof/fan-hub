import 'package:dio/dio.dart';

/// Só fala com o IBGE (https://servicodados.ibge.gov.br) — API pública do
/// governo brasileiro, sem chave, com a lista oficial de municípios por UF.
class IbgeLocationDataSource {
  IbgeLocationDataSource(this._dio);

  final Dio _dio;

  Future<List<String>> getCitiesByState(String ufCode) async {
    final response = await _dio.get<List<dynamic>>(
      'https://servicodados.ibge.gov.br/api/v1/localidades/estados/$ufCode/municipios',
    );
    final data = response.data ?? [];
    return data.map((e) => (e as Map<String, dynamic>)['nome'] as String).toList();
  }
}
