import 'dart:async';

import 'package:dio/dio.dart';
import 'package:goias_app/core/error/failures.dart';
import 'package:goias_app/core/error/result.dart';
import 'package:goias_app/features/social/data/datasources/social_remote_data_source.dart';
import 'package:goias_app/features/social/domain/entities/social_post.dart';
import 'package:goias_app/features/social/domain/repositories/social_feed_repository.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

class SocialFeedRepositoryImpl implements SocialFeedRepository {
  SocialFeedRepositoryImpl(this._remote);

  final SocialRemoteDataSource _remote;

  @override
  Future<Result<List<SocialPost>>> getFeed({SocialPlatform? platform}) async {
    try {
      final platformStr = platform?.name;
      final dtos = await _remote.getFeed(platform: platformStr);
      final posts = dtos.map((dto) => dto.toEntity()).toList()
        ..sort((a, b) => b.publishedAt.compareTo(a.publishedAt));
      return Success(posts);
    } on DioException catch (error, stackTrace) {
      unawaited(Sentry.captureException(error, stackTrace: stackTrace));
      return Error(_mapDioError(error));
    } catch (error, stackTrace) {
      unawaited(Sentry.captureException(error, stackTrace: stackTrace));
      return const Error(UnexpectedFailure());
    }
  }

  Failure _mapDioError(DioException e) {
    if (e.type == DioExceptionType.connectionError ||
        e.type == DioExceptionType.connectionTimeout) {
      return const ServerFailure('Sem conexão com a internet.');
    }
    return const ServerFailure();
  }
}
