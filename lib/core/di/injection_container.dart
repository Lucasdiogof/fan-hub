import 'package:dio/dio.dart';
import 'package:get_it/get_it.dart';
import 'package:goias_app/core/network/api_client.dart';
import 'package:goias_app/features/home/presentation/cubit/home_cubit.dart';
import 'package:goias_app/features/match/data/datasources/football_remote_data_source.dart';
import 'package:goias_app/features/match/data/mock_match_repository.dart';
import 'package:goias_app/features/match/data/repositories/football_repository_impl.dart';
import 'package:goias_app/features/match/domain/repositories/football_repository.dart';
import 'package:goias_app/features/match/domain/repositories/match_repository.dart';
import 'package:goias_app/features/match/presentation/cubit/games_cubit.dart';
import 'package:goias_app/features/membership/data/mock_membership_repository.dart';
import 'package:goias_app/features/membership/domain/repositories/membership_repository.dart';
import 'package:goias_app/features/news/data/mock_news_repository.dart';
import 'package:goias_app/features/news/domain/repositories/news_repository.dart';
import 'package:goias_app/features/profile/data/mock_user_repository.dart';
import 'package:goias_app/features/profile/domain/repositories/user_repository.dart';
import 'package:goias_app/features/ticket/data/mock_ticket_repository.dart';
import 'package:goias_app/features/ticket/domain/repositories/ticket_repository.dart';

final GetIt sl = GetIt.instance;

void setupDependencies() {
  sl.registerLazySingleton<MatchRepository>(MockMatchRepository.new);
  sl.registerLazySingleton<NewsRepository>(MockNewsRepository.new);
  sl.registerLazySingleton<TicketRepository>(MockTicketRepository.new);
  sl.registerLazySingleton<MembershipRepository>(MockMembershipRepository.new);
  sl.registerLazySingleton<UserRepository>(MockUserRepository.new);

  sl.registerLazySingleton<Dio>(ApiClient.create);
  sl.registerLazySingleton<FootballRemoteDataSource>(() => FootballRemoteDataSource(sl()));
  sl.registerLazySingleton<FootballRepository>(() => FootballRepositoryImpl(sl()));

  sl.registerFactory<HomeCubit>(() => HomeCubit(sl(), sl(), sl()));
  sl.registerFactory<GamesCubit>(() => GamesCubit(sl()));
}
