import 'package:dio/dio.dart';
import 'package:goias_app/features/social/data/dto/social_post_dto.dart';

class SocialRemoteDataSource {
  SocialRemoteDataSource(this._dio);

  final Dio _dio;

  Future<List<SocialPostDto>> getFeed({String? platform}) async {
    final queryParams = <String, dynamic>{};
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
