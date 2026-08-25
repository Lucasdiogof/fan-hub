import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:goias_app/features/arena/games/penalty/pages/penalty_result_page.dart';
import 'package:goias_app/features/arena/games/penalty/penalty_game.dart';
import 'package:goias_app/features/arena/games/penalty/penalty_game_page.dart';
import 'package:goias_app/features/arena/games/career_path/cubit/career_path_cubit.dart';
import 'package:goias_app/features/arena/games/career_path/pages/career_path_page.dart';
import 'package:goias_app/features/arena/games/guess_player/pages/guess_player_page.dart';
import 'package:goias_app/features/arena/games/lineup/cubit/lineup_cubit.dart';
import 'package:goias_app/features/arena/games/lineup/pages/lineup_page.dart';
import 'package:goias_app/features/arena/games/quiz/cubit/quiz_cubit.dart';
import 'package:goias_app/features/arena/games/quiz/data/quiz_progress_repository.dart';
import 'package:goias_app/features/arena/games/quiz/pages/quiz_level_page.dart';
import 'package:goias_app/features/arena/games/quiz/pages/quiz_page.dart';
import 'package:goias_app/features/arena/games/quiz/pages/quiz_result_page.dart';
import 'package:goias_app/features/arena/games/quiz/quiz_models.dart';
import 'package:goias_app/features/arena/data/arena_scores.dart';
import 'package:goias_app/features/arena/presentation/pages/arena_ranking_page.dart';
import 'package:goias_app/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:goias_app/features/auth/presentation/cubit/auth_state.dart';
import 'package:goias_app/features/auth/presentation/pages/check_your_email_page.dart';
import 'package:goias_app/features/auth/presentation/pages/login_page.dart';
import 'package:goias_app/features/auth/presentation/pages/register_page.dart';
import 'package:goias_app/features/auth/presentation/pages/reset_password_page.dart';
import 'package:goias_app/features/club/presentation/pages/club_history_page.dart';
import 'package:goias_app/features/club/presentation/pages/club_page.dart';
import 'package:goias_app/features/club/presentation/pages/club_songs_page.dart';
import 'package:goias_app/features/club/presentation/pages/club_timeline_page.dart';
import 'package:goias_app/features/club/presentation/pages/club_titles_page.dart';
import 'package:goias_app/features/home/presentation/pages/home_shell_page.dart';
import 'package:goias_app/features/crowd_lineup/presentation/cubit/crowd_lineup_cubit.dart';
import 'package:goias_app/features/crowd_lineup/presentation/pages/crowd_lineup_page.dart';
import 'package:goias_app/features/match/domain/entities/match.dart';
import 'package:goias_app/features/match/presentation/cubit/match_details_cubit.dart';
import 'package:goias_app/features/match/presentation/pages/match_details_page.dart';
import 'package:goias_app/features/membership/domain/entities/membership.dart';
import 'package:goias_app/features/membership/presentation/pages/find_zip_code_page.dart';
import 'package:goias_app/features/membership/presentation/pages/membership_faq_page.dart';
import 'package:goias_app/features/membership/presentation/pages/membership_plan_details_page.dart';
import 'package:goias_app/features/membership/presentation/pages/membership_plans_catalog_page.dart';
import 'package:goias_app/features/membership/presentation/pages/membership_regulation_page.dart';
import 'package:goias_app/features/membership/presentation/pages/membership_registration_page.dart';
import 'package:goias_app/features/news/domain/entities/news_article.dart';
import 'package:goias_app/features/news/presentation/pages/news_article_page.dart';
import 'package:goias_app/features/news/presentation/pages/news_list_page.dart';
import 'package:goias_app/features/partners/presentation/pages/partners_page.dart';
import 'package:goias_app/features/membership/presentation/pages/my_membership_page.dart';
import 'package:goias_app/features/profile/presentation/cubit/address_cubit.dart';
import 'package:goias_app/features/profile/presentation/pages/address_page.dart';
import 'package:goias_app/features/profile/presentation/pages/personal_data_page.dart';
import 'package:goias_app/features/profile/presentation/pages/profile_page.dart';
import 'package:goias_app/features/profile/presentation/pages/delete_account_page.dart';
import 'package:goias_app/features/profile/presentation/pages/security_page.dart';
import 'package:goias_app/features/profile/presentation/pages/theme_settings_page.dart';
import 'package:goias_app/features/squad/domain/squad_member.dart';
import 'package:goias_app/features/squad/presentation/cubit/squad_cubit.dart';
import 'package:goias_app/features/squad/presentation/pages/squad_list_page.dart';
import 'package:goias_app/features/squad/presentation/pages/squad_member_detail_page.dart';
import 'package:goias_app/features/ticket/presentation/pages/my_orders_page.dart';
import 'package:goias_app/features/ticket/presentation/pages/my_tickets_page.dart';
import 'package:goias_app/features/ticket/presentation/pages/tickets_page.dart';
import 'package:goias_app/core/router/route_observer.dart';
import 'package:goias_app/core/router/splash_gate.dart';
import 'package:goias_app/features/splash/presentation/pages/splash_video_page.dart';
import 'package:goias_app/shared/widgets/coming_soon_page.dart';

const _authArea = {'/login', '/register', '/check-email'};

GoRouter createAppRouter(AuthCubit authCubit, SplashGate splashGate) {
  return GoRouter(
    initialLocation: '/',
    observers: [appRouteObserver],
    refreshListenable: Listenable.merge([
      _AuthRefresh(authCubit.stream),
      splashGate,
    ]),
    redirect: (context, state) {
      final authState = authCubit.state;
      final location = state.matchedLocation;

      if (authState is AuthPasswordRecovery) {
        return location == '/reset-password' ? null : '/reset-password';
      }

      if (!splashGate.done) {
        return location == '/splash' ? null : '/splash';
      }

      final loggedIn = authState is AuthAuthenticated;
      final onAuthArea = _authArea.contains(location);

      if (location == '/splash') return loggedIn ? '/' : '/login';
      if (!loggedIn && !onAuthArea) return '/login';
      if (loggedIn && (onAuthArea || location == '/reset-password')) return '/';
      return null;
    },
    routes: [
      GoRoute(
        path: '/splash',
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const SplashVideoPage(),
          transitionDuration: const Duration(milliseconds: 200),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(
              opacity: Tween<double>(
                begin: 1,
                end: 0,
              ).animate(secondaryAnimation),
              child: child,
            );
          },
        ),
      ),
      GoRoute(path: '/', builder: (context, state) => const HomeShellPage()),
      GoRoute(
        path: '/match/:fixtureId',
        builder: (context, state) => MatchDetailsPage(
          fixtureId: state.pathParameters['fixtureId']!,
          cubit: state.extra as MatchDetailsCubit?,
        ),
      ),
      GoRoute(
        path: '/crowd-lineup',
        builder: (context, state) {
          final args = state.extra! as ({Match match, CrowdLineupCubit cubit});
          return CrowdLineupPage(match: args.match, cubit: args.cubit);
        },
      ),
      GoRoute(
        path: '/profile',
        builder: (context, state) => const ProfilePage(),
      ),
      GoRoute(
        path: '/squad',
        builder: (context, state) =>
            SquadListPage(cubit: state.extra as SquadCubit?),
      ),
      GoRoute(
        path: '/squad/:memberId',
        builder: (context, state) =>
            SquadMemberDetailPage(member: state.extra! as SquadMember),
      ),
      GoRoute(
        path: '/tickets',
        builder: (context, state) => const TicketsPage(),
      ),
      GoRoute(
        path: '/tickets/my',
        builder: (context, state) => const MyTicketsPage(),
      ),
      GoRoute(
        path: '/tickets/orders',
        builder: (context, state) => const MyOrdersPage(),
      ),
      GoRoute(
        path: '/profile/personal',
        builder: (context, state) => const PersonalDataPage(),
      ),
      GoRoute(
        path: '/profile/address',
        builder: (context, state) =>
            AddressPage(cubit: state.extra as AddressCubit?),
      ),
      GoRoute(
        path: '/profile/security',
        builder: (context, state) => const SecurityPage(),
      ),
      GoRoute(
        path: '/profile/delete-account',
        builder: (context, state) => const DeleteAccountPage(),
      ),
      GoRoute(
        path: '/profile/theme',
        builder: (context, state) => const ThemeSettingsPage(),
      ),
      GoRoute(
        path: '/coming-soon',
        builder: (context, state) {
          final args = state.extra as ({String title, String? message})?;
          return ComingSoonPage(
            title: args?.title ?? 'EM BREVE',
            message: args?.message,
          );
        },
      ),
      GoRoute(
        path: '/arena/penalty',
        builder: (context, state) => const PenaltyGamePage(),
      ),
      GoRoute(
        path: '/arena/penalty/result',
        builder: (context, state) =>
            PenaltyResultPage(data: state.extra! as PenaltyEndData),
      ),
      GoRoute(
        path: '/arena/ranking',
        builder: (context, state) => ArenaRankingPage(
          initialEntries: state.extra as List<ArenaLeaderboardEntry>?,
        ),
      ),
      GoRoute(
        path: '/arena/quiz',
        builder: (context, state) => QuizLevelPage(
          initialSummaries:
              state.extra as Map<QuizDifficulty, QuizLevelSummary>?,
        ),
      ),
      GoRoute(
        path: '/arena/quiz/play',
        builder: (context, state) {
          final args =
              state.extra!
                  as ({
                    QuizDifficulty difficulty,
                    bool isReview,
                    QuizCubit? cubit,
                  });
          return QuizPlayPage(
            difficulty: args.difficulty,
            isReview: args.isReview,
            cubit: args.cubit,
          );
        },
      ),
      GoRoute(
        path: '/arena/quiz/result',
        builder: (context, state) =>
            QuizResultPage(data: state.extra! as QuizEndData),
      ),
      GoRoute(
        path: '/arena/lineup',
        builder: (context, state) =>
            LineupPage(cubit: state.extra as LineupCubit?),
      ),
      GoRoute(
        path: '/arena/career-path',
        builder: (context, state) =>
            CareerPathPage(cubit: state.extra as CareerPathCubit?),
      ),
      GoRoute(
        path: '/arena/guess-player',
        builder: (context, state) => const GuessPlayerPage(),
      ),
      GoRoute(
        path: '/partners',
        builder: (context, state) => const PartnersPage(),
      ),
      GoRoute(path: '/clube', builder: (context, state) => const ClubPage()),
      GoRoute(
        path: '/clube/historia',
        builder: (context, state) => const ClubHistoryPage(),
      ),
      GoRoute(
        path: '/clube/linha-do-tempo',
        builder: (context, state) => const ClubTimelinePage(),
      ),
      GoRoute(
        path: '/clube/titulos',
        builder: (context, state) => const ClubTitlesPage(),
      ),
      GoRoute(
        path: '/clube/hino',
        builder: (context, state) => const ClubSongsPage(),
      ),
      GoRoute(path: '/news', builder: (context, state) => const NewsListPage()),
      GoRoute(
        path: '/news/article',
        builder: (context, state) =>
            NewsArticlePage(article: state.extra! as NewsArticle),
      ),
      GoRoute(
        path: '/membership/plans',
        builder: (context, state) => const MembershipPlansCatalogPage(),
      ),
      GoRoute(
        path: '/membership/plans/:planId',
        builder: (context, state) =>
            MembershipPlanDetailsPage(planId: state.pathParameters['planId']!),
      ),
      GoRoute(
        path: '/membership/register',
        builder: (context, state) {
          final args = state.extra! as MembershipRegistrationArgs;
          return MembershipRegistrationPage(plan: args.plan, price: args.price);
        },
      ),
      GoRoute(
        path: '/membership/regulation',
        builder: (context, state) => const MembershipRegulationPage(),
      ),
      GoRoute(
        path: '/membership/find-zip-code',
        builder: (context, state) => const FindZipCodePage(),
      ),
      GoRoute(
        path: '/membership/faq',
        builder: (context, state) {
          final args =
              state.extra
                  as ({String? initialCategoryId, String? initialQuery})?;
          return MembershipFaqPage(
            initialCategoryId: args?.initialCategoryId,
            initialQuery: args?.initialQuery,
          );
        },
      ),
      GoRoute(
        path: '/membership/my',
        builder: (context, state) =>
            MyMembershipPage(membership: state.extra! as Membership),
      ),
      GoRoute(
        path: '/membership/coming-soon',
        builder: (context, state) {
          final args = state.extra as ({String title, String message})?;
          return ComingSoonPage(
            title: args?.title ?? 'EM BREVE',
            message: args?.message,
          );
        },
      ),
      GoRoute(path: '/login', builder: (context, state) => const LoginPage()),
      GoRoute(
        path: '/register',
        builder: (context, state) => const RegisterPage(),
      ),
      GoRoute(
        path: '/check-email',
        builder: (context, state) =>
            CheckYourEmailPage(email: state.extra as String? ?? ''),
      ),
      GoRoute(
        path: '/reset-password',
        builder: (context, state) => const ResetPasswordPage(),
      ),
    ],
  );
}

class _AuthRefresh extends ChangeNotifier {
  _AuthRefresh(Stream<AuthState> stream) {
    notifyListeners();
    _subscription = stream.asBroadcastStream().listen((_) => notifyListeners());
  }

  late final StreamSubscription<AuthState> _subscription;

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}
