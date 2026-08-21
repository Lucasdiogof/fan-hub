import 'package:dio/dio.dart';

/// Só fala com o ViaCEP (https://viacep.com.br) — não precisa de chave.
/// Reaproveita o `Dio` já injetado no app: como as URLs aqui são absolutas
/// (https://...), o `baseUrl` do backend interno é ignorado pelo Dio.
class ViaCepDataSource {
  ViaCepDataSource(this._dio);

  final Dio _dio;

  Future<Map<String, dynamic>?> findByZipCode(String zipCodeDigits) async {
    final response = await _dio.get<Map<String, dynamic>>(
      'https://viacep.com.br/ws/$zipCodeDigits/json/',
    );
    final data = response.data;
    if (data == null || data['erro'] == true) return null;
    return data;
  }

  Future<List<Map<String, dynamic>>> searchByAddress({
    required String state,
    required String city,
    required String street,
  }) async {
    final path =
        'https://viacep.com.br/ws/${Uri.encodeComponent(state)}/${Uri.encodeComponent(city)}/${Uri.encodeComponent(street)}/json/';
    final response = await _dio.get<List<dynamic>>(path);
    final data = response.data ?? [];
    return data.cast<Map<String, dynamic>>();
  }
}
