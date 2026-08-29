import 'dart:async';

import 'package:dio/dio.dart';
import 'package:goias_app/core/error/failures.dart';
import 'package:goias_app/core/error/result.dart';
import 'package:goias_app/features/news/data/datasources/news_remote_data_source.dart';
import 'package:goias_app/features/news/domain/entities/news_article.dart';
import 'package:goias_app/features/news/domain/entities/news_item.dart';
import 'package:goias_app/features/news/domain/repositories/news_repository.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

class NewsRepositoryImpl implements NewsRepository {
  NewsRepositoryImpl(this._remote);

  final NewsRemoteDataSource _remote;

  @override
  Future<Result<List<NewsItem>>> getList() async {
    try {
      final dtos = await _remote.getList();
      return Success(dtos.map((dto) => dto.toEntity()).toList());
    } on DioException catch (error, stackTrace) {
      unawaited(Sentry.captureException(error, stackTrace: stackTrace));
      return Error(_mapDioError(error));
    } catch (error, stackTrace) {
      unawaited(Sentry.captureException(error, stackTrace: stackTrace));
      return const Error(UnexpectedFailure());
    }
  }

  @override
  Future<Result<NewsArticle?>> getArticle(String id) async {
    try {
      final dto = await _remote.getArticle(id);
      return Success(dto?.toEntity());
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
