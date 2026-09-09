import 'package:dio/dio.dart';
import 'package:goias_app/core/club/club_config.dart';
import 'package:goias_app/features/social/data/dto/social_post_dto.dart';

/// M4.2A — mesmo motivo de `NewsRemoteDataSource`: o gate `?club=` do
/// Worker só protege de verdade se o Flutter realmente mandar o parâmetro.
class SocialRemoteDataSource {
  SocialRemoteDataSource(this._dio, this._clubConfig);

  final Dio _dio;
  final ClubConfig _clubConfig;

  Future<List<SocialPostDto>> getFeed({String? platform}) async {
    final queryParams = <String, dynamic>{'club': _clubConfig.identity.code};
    if (platform != null) queryParams['platform'] = platform;

    final response = await _dio.get<Map<String, dynamic>>(
      '/api/social/feed',
      queryParameters: queryParams,
    );
    final data = response.data!;
    final posts = data['posts'] as List;
    return posts
        .map((p) => SocialPostDto.fromJson(p as Map<String, dynamic>))
        .toList();
  }
}
