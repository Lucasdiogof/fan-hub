import 'package:go_router/go_router.dart';
import 'package:goias_app/features/home/presentation/pages/home_shell_page.dart';
import 'package:goias_app/features/match/presentation/pages/match_details_page.dart';

final GoRouter appRouter = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) => const HomeShellPage(),
    ),
    GoRoute(
      path: '/match/:fixtureId',
      builder: (context, state) {
        final fixtureId = state.pathParameters['fixtureId']!;
        return MatchDetailsPage(fixtureId: fixtureId);
      },
    ),
  ],
);
