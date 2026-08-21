import 'package:dio/dio.dart';
import 'package:get_it/get_it.dart';
import 'package:goias_app/core/network/api_client.dart';
import 'package:goias_app/features/auth/data/auth_remote_data_source.dart';
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
import 'package:goias_app/features/membership/data/mock_membership_repository.dart';
import 'package:goias_app/features/membership/data/viacep_address_repository.dart';
import 'package:goias_app/features/membership/data/viacep_data_source.dart';
import 'package:goias_app/features/membership/domain/repositories/address_repository.dart';
import 'package:goias_app/features/membership/domain/repositories/membership_repository.dart';
import 'package:goias_app/features/membership/presentation/cubit/membership_cubit.dart';
import 'package:goias_app/features/news/data/mock_news_repository.dart';
import 'package:goias_app/features/news/domain/repositories/news_repository.dart';
import 'package:goias_app/features/profile/data/mock_user_repository.dart';
import 'package:goias_app/features/profile/domain/repositories/user_repository.dart';
import 'package:goias_app/features/social/data/datasources/social_remote_data_source.dart';
import 'package:goias_app/features/social/data/repositories/social_feed_repository_impl.dart';
import 'package:goias_app/features/social/domain/repositories/social_feed_repository.dart';
import 'package:goias_app/features/social/presentation/cubit/social_feed_cubit.dart';
import 'package:goias_app/features/ticket/data/empty_ticket_repository.dart';
import 'package:goias_app/features/ticket/domain/repositories/ticket_repository.dart';
import 'package:goias_app/features/ticket/presentation/cubit/my_orders_cubit.dart';
import 'package:goias_app/features/ticket/presentation/cubit/my_tickets_cubit.dart';
import 'package:goias_app/features/ticket/presentation/cubit/tickets_cubit.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final GetIt sl = GetIt.instance;

void setupDependencies() {
  sl.registerLazySingleton<NewsRepository>(MockNewsRepository.new);
  sl.registerLazySingleton<TicketRepository>(EmptyTicketRepository.new);
  sl.registerLazySingleton<MembershipRepository>(MockMembershipRepository.new);
  sl.registerLazySingleton<MembershipFaqDataSource>(MembershipFaqDataSource.new);
  sl.registerLazySingleton<ViaCepDataSource>(() => ViaCepDataSource(sl()));
  sl.registerLazySingleton<IbgeLocationDataSource>(() => IbgeLocationDataSource(sl()));
  sl.registerLazySingleton<AddressRepository>(() => ViaCepAddressRepository(sl(), sl()));
  sl.registerLazySingleton<UserRepository>(MockUserRepository.new);

  sl.registerLazySingleton<Dio>(ApiClient.create);
  sl.registerLazySingleton<FootballRemoteDataSource>(() => FootballRemoteDataSource(sl()));
  sl.registerLazySingleton<FootballRepository>(() => FootballRepositoryImpl(sl()));

  sl.registerLazySingleton<SocialRemoteDataSource>(() => SocialRemoteDataSource(sl()));
  sl.registerLazySingleton<SocialFeedRepository>(() => SocialFeedRepositoryImpl(sl()));

  sl.registerLazySingleton<AuthRemoteDataSource>(
    () => AuthRemoteDataSource(Supabase.instance.client),
  );
  sl.registerLazySingleton<AuthRepository>(() => AuthRepositoryImpl(sl()));
  sl.registerLazySingleton<AuthCubit>(() => AuthCubit(sl()));

  sl.registerLazySingleton<ProfileRepository>(() => SupabaseProfileRepository(Supabase.instance.client));
  sl.registerLazySingleton<HomeShellCubit>(HomeShellCubit.new);

  sl.registerFactory<HomeCubit>(() => HomeCubit(sl(), sl()));
  sl.registerFactory<GamesCubit>(() => GamesCubit(sl()));
  sl.registerFactory<SocialFeedCubit>(() => SocialFeedCubit(sl()));
  sl.registerFactory<MembershipCubit>(() => MembershipCubit(sl(), sl(), sl()));
  sl.registerFactory<TicketsCubit>(() => TicketsCubit(sl()));
  sl.registerFactory<MyTicketsCubit>(() => MyTicketsCubit(sl()));
  sl.registerFactory<MyOrdersCubit>(() => MyOrdersCubit(sl()));
  sl.registerFactory<ProfileCubit>(() => ProfileCubit(sl()));
  sl.registerFactory<AddressCubit>(() => AddressCubit(sl()));
}
