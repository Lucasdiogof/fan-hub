import 'package:dio/dio.dart';
import 'package:get_it/get_it.dart';
import 'package:goias_app/core/network/api_client.dart';
import 'package:goias_app/features/arena/data/arena_progress_repository.dart';
import 'package:goias_app/features/arena/data/arena_scores.dart';
import 'package:goias_app/features/arena/games/career_path/data/career_player_repository.dart';
import 'package:goias_app/features/arena/games/career_path/data/supabase_career_path_storage.dart';
import 'package:goias_app/features/arena/games/guess_player/data/guess_player_repository.dart';
import 'package:goias_app/features/arena/games/guess_player/data/guess_player_storage.dart';
import 'package:goias_app/features/arena/games/lineup/data/lineup_match_repository.dart';
import 'package:goias_app/features/arena/games/lineup/data/supabase_lineup_storage.dart';
import 'package:goias_app/features/arena/games/quiz/data/quiz_progress_repository.dart';
import 'package:goias_app/features/arena/games/quiz/data/quiz_question_repository.dart';
import 'package:goias_app/core/router/splash_gate.dart';
import 'package:goias_app/features/auth/data/auth_remote_data_source.dart';
import 'package:goias_app/core/theme/theme_cubit.dart';
import 'package:goias_app/features/crowd_lineup/data/supabase_crowd_lineup_repository.dart';
import 'package:goias_app/features/crowd_lineup/domain/repositories/crowd_lineup_repository.dart';
import 'package:goias_app/features/auth/data/auth_repository_impl.dart';
import 'package:goias_app/features/auth/domain/repositories/auth_repository.dart';
import 'package:goias_app/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:goias_app/features/home/presentation/cubit/home_cubit.dart';
import 'package:goias_app/features/home/presentation/cubit/home_shell_cubit.dart';
import 'package:goias_app/features/profile/data/supabase_profile_repository.dart';
import 'package:goias_app/features/profile/domain/repositories/profile_repository.dart';
import 'package:goias_app/features/profile/presentation/cubit/address_cubit.dart';
import 'package:goias_app/features/profile/presentation/cubit/profile_cubit.dart';
import 'package:goias_app/features/match/data/datasources/football_remote_data_source.dart';
import 'package:goias_app/features/match/data/repositories/football_repository_impl.dart';
import 'package:goias_app/features/match/domain/repositories/football_repository.dart';
import 'package:goias_app/features/match/presentation/cubit/games_cubit.dart';
import 'package:goias_app/features/membership/data/ibge_location_data_source.dart';
import 'package:goias_app/features/membership/data/membership_faq_data_source.dart';
import 'package:goias_app/features/membership/data/membership_regulation_repository.dart';
import 'package:goias_app/features/membership/data/mock_membership_repository.dart';
import 'package:goias_app/features/membership/data/viacep_address_repository.dart';
import 'package:goias_app/features/membership/data/viacep_data_source.dart';
import 'package:goias_app/features/membership/domain/repositories/address_repository.dart';
import 'package:goias_app/features/membership/domain/repositories/membership_repository.dart';
import 'package:goias_app/features/membership/presentation/cubit/membership_cubit.dart';
import 'package:goias_app/features/news/data/datasources/news_remote_data_source.dart';
import 'package:goias_app/features/news/data/repositories/news_repository_impl.dart';
import 'package:goias_app/features/news/domain/repositories/news_repository.dart';
import 'package:goias_app/features/news/presentation/cubit/news_cubit.dart';
import 'package:goias_app/features/profile/data/mock_user_repository.dart';
import 'package:goias_app/features/profile/domain/repositories/user_repository.dart';
import 'package:goias_app/features/social/data/datasources/social_remote_data_source.dart';
import 'package:goias_app/features/social/data/repositories/social_feed_repository_impl.dart';
import 'package:goias_app/features/social/domain/repositories/social_feed_repository.dart';
import 'package:goias_app/features/social/presentation/cubit/social_feed_cubit.dart';
import 'package:goias_app/features/squad/data/supabase_squad_repository.dart';
import 'package:goias_app/features/squad/domain/repositories/squad_repository.dart';
import 'package:goias_app/features/squad/presentation/cubit/squad_cubit.dart';
import 'package:goias_app/features/ticket/data/empty_ticket_repository.dart';
import 'package:goias_app/features/ticket/domain/repositories/ticket_repository.dart';
import 'package:goias_app/features/ticket/presentation/cubit/my_orders_cubit.dart';
import 'package:goias_app/features/ticket/presentation/cubit/my_tickets_cubit.dart';
import 'package:goias_app/features/ticket/presentation/cubit/tickets_cubit.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final GetIt sl = GetIt.instance;

void setupDependencies() {
  sl.registerLazySingleton<TicketRepository>(EmptyTicketRepository.new);
  sl.registerLazySingleton<MembershipRepository>(MockMembershipRepository.new);
  sl.registerLazySingleton<MembershipFaqDataSource>(
    () => MembershipFaqDataSource(Supabase.instance.client),
  );
  sl.registerLazySingleton<MembershipRegulationRepository>(
    () => MembershipRegulationRepository(Supabase.instance.client),
  );
  sl.registerLazySingleton<ViaCepDataSource>(() => ViaCepDataSource(sl()));
  sl.registerLazySingleton<IbgeLocationDataSource>(
    () => IbgeLocationDataSource(sl()),
  );
  sl.registerLazySingleton<AddressRepository>(
    () => ViaCepAddressRepository(sl(), sl()),
  );
  sl.registerLazySingleton<UserRepository>(MockUserRepository.new);

  sl.registerLazySingleton<Dio>(ApiClient.create);
  sl.registerLazySingleton<FootballRemoteDataSource>(
    () => FootballRemoteDataSource(sl()),
  );
  sl.registerLazySingleton<FootballRepository>(
    () => FootballRepositoryImpl(sl()),
  );

  sl.registerLazySingleton<SocialRemoteDataSource>(
    () => SocialRemoteDataSource(sl()),
  );
  sl.registerLazySingleton<SocialFeedRepository>(
    () => SocialFeedRepositoryImpl(sl()),
  );

  sl.registerLazySingleton<NewsRemoteDataSource>(
    () => NewsRemoteDataSource(sl()),
  );
  sl.registerLazySingleton<NewsRepository>(() => NewsRepositoryImpl(sl()));

  sl.registerLazySingleton<AuthRemoteDataSource>(
    () => AuthRemoteDataSource(Supabase.instance.client),
  );
  sl.registerLazySingleton<AuthRepository>(() => AuthRepositoryImpl(sl()));
  sl.registerLazySingleton<AuthCubit>(() => AuthCubit(sl()));

  sl.registerLazySingleton<ProfileRepository>(
    () => SupabaseProfileRepository(Supabase.instance.client),
  );
  sl.registerLazySingleton<HomeShellCubit>(HomeShellCubit.new);
  sl.registerLazySingleton<SplashGate>(SplashGate.new);
  sl.registerLazySingleton<ArenaScores>(
    () => ArenaScores(Supabase.instance.client),
  );
  sl.registerLazySingleton<SupabaseLineupStorage>(
    () => SupabaseLineupStorage(Supabase.instance.client),
  );
  sl.registerLazySingleton<LineupMatchRepository>(
    () => LineupMatchRepository(Supabase.instance.client),
  );
  sl.registerLazySingleton<SupabaseCareerPathStorage>(
    () => SupabaseCareerPathStorage(Supabase.instance.client),
  );
  sl.registerLazySingleton<CareerPlayerRepository>(
    () => CareerPlayerRepository(Supabase.instance.client),
  );
  sl.registerLazySingleton<GuessPlayerStorage>(GuessPlayerStorage.new);
  sl.registerLazySingleton<GuessPlayerRepository>(
    () => GuessPlayerRepository(Supabase.instance.client),
  );
  sl.registerLazySingleton<CrowdLineupRepository>(
    () => SupabaseCrowdLineupRepository(Supabase.instance.client),
  );
  sl.registerLazySingleton<ThemeCubit>(ThemeCubit.new);
  sl.registerLazySingleton<SquadRepository>(
    () => SupabaseSquadRepository(Supabase.instance.client),
  );
  sl.registerLazySingleton<QuizQuestionRepository>(
    () => QuizQuestionRepository(Supabase.instance.client),
  );
  sl.registerLazySingleton<QuizProgressRepository>(
    () => QuizProgressRepository(Supabase.instance.client),
  );
  sl.registerLazySingleton<ArenaProgressRepository>(
    () => ArenaProgressRepository(
      client: Supabase.instance.client,
      quizQuestionRepository: sl(),
      quizProgressRepository: sl(),
      lineupStorage: sl(),
      careerPathStorage: sl(),
      guessPlayerStorage: sl(),
    ),
  );

  // Singleton (não factory) — a Splash resolve/pré-carrega esse mesmo
  // Cubit por trás do vídeo antes de navegar (ver `splash_video_page.dart`),
  // então a Home precisa reaproveitar a MESMA instância, já carregada.
  sl.registerLazySingleton<HomeCubit>(() => HomeCubit(sl(), sl(), sl()));
  // Singleton — o preview da Home e a tela completa de Notícias
  // compartilham a mesma lista já carregada (ver `NewsCubit`).
  sl.registerLazySingleton<NewsCubit>(() => NewsCubit(sl()));
  sl.registerFactory<SquadCubit>(() => SquadCubit(sl()));
  sl.registerFactory<GamesCubit>(() => GamesCubit(sl()));
  sl.registerFactory<SocialFeedCubit>(() => SocialFeedCubit(sl()));
  sl.registerFactory<MembershipCubit>(() => MembershipCubit(sl(), sl(), sl()));
  sl.registerFactory<TicketsCubit>(() => TicketsCubit(sl()));
  sl.registerFactory<MyTicketsCubit>(() => MyTicketsCubit(sl()));
  sl.registerFactory<MyOrdersCubit>(() => MyOrdersCubit(sl()));
  sl.registerLazySingleton<ProfileCubit>(() => ProfileCubit(sl()));
  sl.registerFactory<AddressCubit>(() => AddressCubit(sl()));
}
