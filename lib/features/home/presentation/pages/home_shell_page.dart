import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:goias_app/core/theme/app_colors.dart';
import 'package:goias_app/features/home/presentation/cubit/home_shell_cubit.dart';
import 'package:goias_app/features/home/presentation/cubit/home_shell_state.dart';
import 'package:goias_app/features/home/presentation/pages/home_page.dart';
import 'package:goias_app/features/membership/presentation/pages/membership_home_page.dart';
import 'package:goias_app/features/match/presentation/pages/matches_page.dart';
import 'package:goias_app/features/profile/presentation/pages/profile_page.dart';
import 'package:goias_app/features/ticket/presentation/pages/tickets_page.dart';

class HomeShellPage extends StatefulWidget {
  const HomeShellPage({super.key});

  @override
  State<HomeShellPage> createState() => _HomeShellPageState();
}

class _HomeShellPageState extends State<HomeShellPage> {
  final _shellCubit = HomeShellCubit();

  @override
  void dispose() {
    _shellCubit.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _shellCubit,
      child: BlocBuilder<HomeShellCubit, HomeShellState>(
        builder: (context, shellState) {
          const pages = [
            HomePage(),
            MatchesPage(),
            TicketsPage(),
            MembershipHomePage(),
            ProfilePage(),
          ];
          return Scaffold(
            body: IndexedStack(index: shellState.index, children: pages),
            bottomNavigationBar: Container(
              decoration: BoxDecoration(
                color: context.colors.surface,
                border: Border(top: BorderSide(color: context.colors.border)),
              ),
              child: SafeArea(
                top: false,
                child: NavigationBar(
                  selectedIndex: shellState.index,
                  onDestinationSelected: _shellCubit.navigateToTab,
                  backgroundColor: Colors.transparent,
                  elevation: 0,
                  destinations: [
                    NavigationDestination(
                      icon: const Icon(Icons.home_outlined),
                      selectedIcon: Icon(Icons.home, color: context.colors.primary),
                      label: 'Início',
                    ),
                    NavigationDestination(
                      icon: const Icon(Icons.sports_soccer_outlined),
                      selectedIcon: Icon(Icons.sports_soccer, color: context.colors.primary),
                      label: 'Jogos',
                    ),
                    NavigationDestination(
                      icon: const Icon(Icons.confirmation_number_outlined),
                      selectedIcon: Icon(Icons.confirmation_number, color: context.colors.primary),
                      label: 'Ingressos',
                    ),
                    NavigationDestination(
                      icon: const Icon(Icons.emoji_events_outlined),
                      selectedIcon: Icon(Icons.emoji_events, color: context.colors.primary),
                      label: 'Sócio',
                    ),
                    NavigationDestination(
                      icon: const Icon(Icons.person_outline),
                      selectedIcon: Icon(Icons.person, color: context.colors.primary),
                      label: 'Perfil',
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
