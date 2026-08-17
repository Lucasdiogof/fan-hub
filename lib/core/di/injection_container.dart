import 'package:get_it/get_it.dart';
import 'package:goias_app/features/match/data/mock_match_repository.dart';
import 'package:goias_app/features/match/domain/repositories/match_repository.dart';
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
}
