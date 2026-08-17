import 'package:go_router/go_router.dart';
import 'package:goias_app/features/home/presentation/pages/home_shell_page.dart';

final GoRouter appRouter = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) => const HomeShellPage(),
    ),
  ],
);
