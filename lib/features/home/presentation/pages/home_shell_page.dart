import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:goias_app/features/home/presentation/cubit/home_shell_cubit.dart';
import 'package:goias_app/features/home/presentation/cubit/home_shell_state.dart';
import 'package:goias_app/features/home/presentation/pages/home_page.dart';
import 'package:goias_app/features/home/presentation/widgets/main_bottom_navigation.dart';
import 'package:goias_app/features/membership/presentation/pages/membership_home_page.dart';
import 'package:goias_app/features/match/presentation/pages/games_page.dart';
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
            GamesPage(),
            TicketsPage(),
            MembershipHomePage(),
            ProfilePage(),
          ];
          return Scaffold(
            body: IndexedStack(index: shellState.index, children: pages),
            bottomNavigationBar: MainBottomNavigation(
              selectedIndex: shellState.index,
              onSelected: _shellCubit.navigateToTab,
            ),
          );
        },
      ),
    );
  }
}
