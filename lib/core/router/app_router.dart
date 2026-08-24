import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:go_router/go_router.dart';
import 'package:goias_app/features/arena/games/keepy_uppy/pages/keepy_uppy_game_page.dart';
import 'package:goias_app/features/arena/games/penalty/pages/penalty_result_page.dart';
import 'package:goias_app/features/arena/games/penalty/penalty_game.dart';
import 'package:goias_app/features/arena/games/penalty/penalty_game_page.dart';
import 'package:goias_app/features/arena/games/career_path/pages/career_path_page.dart';
import 'package:goias_app/features/arena/games/lineup/pages/lineup_page.dart';
import 'package:goias_app/features/arena/games/quiz/pages/quiz_level_page.dart';
import 'package:goias_app/features/arena/games/quiz/pages/quiz_page.dart';
import 'package:goias_app/features/arena/games/quiz/pages/quiz_result_page.dart';
import 'package:goias_app/features/arena/games/quiz/quiz_models.dart';
import 'package:goias_app/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:goias_app/features/auth/presentation/cubit/auth_state.dart';
import 'package:goias_app/features/auth/presentation/pages/check_your_email_page.dart';
import 'package:goias_app/features/auth/presentation/pages/login_page.dart';
import 'package:goias_app/features/auth/presentation/pages/register_page.dart';
import 'package:goias_app/features/auth/presentation/pages/reset_password_page.dart';
import 'package:goias_app/features/home/presentation/pages/home_shell_page.dart';
import 'package:goias_app/features/match/presentation/pages/match_details_page.dart';
import 'package:goias_app/features/membership/domain/entities/membership.dart';
import 'package:goias_app/features/membership/presentation/pages/find_zip_code_page.dart';
import 'package:goias_app/features/membership/presentation/pages/membership_faq_page.dart';
import 'package:goias_app/features/membership/presentation/pages/membership_plan_details_page.dart';
import 'package:goias_app/features/membership/presentation/pages/membership_plans_catalog_page.dart';
import 'package:goias_app/features/membership/presentation/pages/membership_regulation_page.dart';
import 'package:goias_app/features/membership/presentation/pages/membership_registration_page.dart';
import 'package:goias_app/features/partners/presentation/pages/partners_page.dart';
import 'package:goias_app/features/membership/presentation/pages/my_membership_page.dart';
import 'package:goias_app/features/profile/presentation/pages/address_page.dart';
import 'package:goias_app/features/profile/presentation/pages/personal_data_page.dart';
import 'package:goias_app/features/profile/presentation/pages/profile_page.dart';
import 'package:goias_app/features/profile/presentation/pages/security_page.dart';
import 'package:goias_app/features/ticket/presentation/pages/my_orders_page.dart';
import 'package:goias_app/features/ticket/presentation/pages/my_tickets_page.dart';
import 'package:goias_app/features/ticket/presentation/pages/tickets_page.dart';
import 'package:goias_app/core/router/route_observer.dart';
import 'package:goias_app/shared/widgets/coming_soon_page.dart';

const _authArea = {'/login', '/register', '/check-email'};

GoRouter createAppRouter(AuthCubit authCubit) {
  return GoRouter(
    initialLocation: '/',
    observers: [appRouteObserver],
    refreshListenable: _AuthRefresh(authCubit.stream),
    redirect: (context, state) {
      final authState = authCubit.state;
      final location = state.matchedLocation;

      if (authState is AuthPasswordRecovery) {
        return location == '/reset-password' ? null : '/reset-password';
      }

      final loggedIn = authState is AuthAuthenticated;
      final onAuthArea = _authArea.contains(location);

      if (!loggedIn && !onAuthArea) return '/login';
      if (loggedIn && (onAuthArea || location == '/reset-password')) return '/';
      return null;
    },
    routes: [
      GoRoute(path: '/', builder: (context, state) => const HomeShellPage()),
      GoRoute(
        path: '/match/:fixtureId',
        builder: (context, state) =>
            MatchDetailsPage(fixtureId: state.pathParameters['fixtureId']!),
      ),
      GoRoute(
        path: '/profile',
        builder: (context, state) => const ProfilePage(),
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
        builder: (context, state) => const AddressPage(),
      ),
      GoRoute(
        path: '/profile/security',
        builder: (context, state) => const SecurityPage(),
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
        path: '/arena/keepy-uppy',
        builder: (context, state) => const KeepyUppyGamePage(),
      ),
      GoRoute(
        path: '/arena/quiz',
        builder: (context, state) => const QuizLevelPage(),
      ),
      GoRoute(
        path: '/arena/quiz/play',
        builder: (context, state) {
          final args =
              state.extra! as ({QuizDifficulty difficulty, Set<String> avoid});
          return QuizPlayPage(difficulty: args.difficulty, avoid: args.avoid);
        },
      ),
      GoRoute(
        path: '/arena/quiz/result',
        builder: (context, state) =>
            QuizResultPage(data: state.extra! as QuizEndData),
      ),
      GoRoute(
        path: '/arena/lineup',
        builder: (context, state) => const LineupPage(),
      ),
      GoRoute(
        path: '/arena/career-path',
        builder: (context, state) => const CareerPathPage(),
      ),
      GoRoute(
        path: '/partners',
        builder: (context, state) => const PartnersPage(),
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
