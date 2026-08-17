import 'package:dio/dio.dart';
import 'package:get_it/get_it.dart';
import 'package:goias_app/core/network/api_client.dart';
import 'package:goias_app/features/home/presentation/cubit/home_cubit.dart';
import 'package:goias_app/features/match/data/datasources/football_remote_data_source.dart';
import 'package:goias_app/features/match/data/repositories/football_repository_impl.dart';
import 'package:goias_app/features/match/domain/repositories/football_repository.dart';
import 'package:goias_app/features/match/presentation/cubit/games_cubit.dart';
import 'package:goias_app/features/membership/data/mock_membership_repository.dart';
import 'package:goias_app/features/membership/domain/repositories/membership_repository.dart';
import 'package:goias_app/features/news/data/mock_news_repository.dart';
import 'package:goias_app/features/news/domain/repositories/news_repository.dart';
import 'package:goias_app/features/profile/data/mock_user_repository.dart';
import 'package:goias_app/features/profile/domain/repositories/user_repository.dart';
import 'package:goias_app/features/social/data/datasources/social_remote_data_source.dart';
import 'package:goias_app/features/social/data/repositories/social_feed_repository_impl.dart';
import 'package:goias_app/features/social/domain/repositories/social_feed_repository.dart';
import 'package:goias_app/features/social/presentation/cubit/social_feed_cubit.dart';
import 'package:goias_app/features/ticket/data/mock_ticket_repository.dart';
import 'package:goias_app/features/ticket/domain/repositories/ticket_repository.dart';

final GetIt sl = GetIt.instance;

void setupDependencies() {
  sl.registerLazySingleton<NewsRepository>(MockNewsRepository.new);
  sl.registerLazySingleton<TicketRepository>(MockTicketRepository.new);
  sl.registerLazySingleton<MembershipRepository>(MockMembershipRepository.new);
  sl.registerLazySingleton<UserRepository>(MockUserRepository.new);

  sl.registerLazySingleton<Dio>(ApiClient.create);
  sl.registerLazySingleton<FootballRemoteDataSource>(() => FootballRemoteDataSource(sl()));
  sl.registerLazySingleton<FootballRepository>(() => FootballRepositoryImpl(sl()));

  sl.registerLazySingleton<SocialRemoteDataSource>(() => SocialRemoteDataSource(sl()));
  sl.registerLazySingleton<SocialFeedRepository>(() => SocialFeedRepositoryImpl(sl()));

  sl.registerFactory<HomeCubit>(() => HomeCubit(sl(), sl()));
  sl.registerFactory<GamesCubit>(() => GamesCubit(sl()));
  sl.registerFactory<SocialFeedCubit>(() => SocialFeedCubit(sl()));
}
