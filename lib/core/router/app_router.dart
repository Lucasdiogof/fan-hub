import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:go_router/go_router.dart';
import 'package:goias_app/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:goias_app/features/auth/presentation/cubit/auth_state.dart';
import 'package:goias_app/features/auth/presentation/pages/check_your_email_page.dart';
import 'package:goias_app/features/auth/presentation/pages/forgot_password_page.dart';
import 'package:goias_app/features/auth/presentation/pages/login_page.dart';
import 'package:goias_app/features/auth/presentation/pages/register_page.dart';
import 'package:goias_app/features/auth/presentation/pages/reset_password_page.dart';
import 'package:goias_app/features/home/presentation/pages/home_shell_page.dart';
import 'package:goias_app/features/match/presentation/pages/match_details_page.dart';
import 'package:goias_app/features/profile/presentation/pages/profile_page.dart';

const _authArea = {'/login', '/register', '/forgot-password', '/check-email'};

GoRouter createAppRouter(AuthCubit authCubit) {
  return GoRouter(
    initialLocation: '/',
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
        builder: (context, state) => MatchDetailsPage(fixtureId: state.pathParameters['fixtureId']!),
      ),
      GoRoute(path: '/profile', builder: (context, state) => const ProfilePage()),
      GoRoute(path: '/login', builder: (context, state) => const LoginPage()),
      GoRoute(path: '/register', builder: (context, state) => const RegisterPage()),
      GoRoute(
        path: '/check-email',
        builder: (context, state) => CheckYourEmailPage(email: state.extra as String? ?? ''),
      ),
      GoRoute(path: '/forgot-password', builder: (context, state) => const ForgotPasswordPage()),
      GoRoute(path: '/reset-password', builder: (context, state) => const ResetPasswordPage()),
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
