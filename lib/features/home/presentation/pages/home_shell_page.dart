import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:goias_app/core/di/injection_container.dart';
import 'package:goias_app/features/arena/presentation/pages/arena_page.dart';
import 'package:goias_app/features/home/presentation/cubit/home_shell_cubit.dart';
import 'package:goias_app/features/home/presentation/cubit/home_shell_state.dart';
import 'package:goias_app/features/home/presentation/pages/home_page.dart';
import 'package:goias_app/features/home/presentation/widgets/main_bottom_navigation.dart';
import 'package:goias_app/features/membership/presentation/pages/membership_home_page.dart';
import 'package:goias_app/features/match/presentation/pages/games_page.dart';
import 'package:goias_app/features/social/presentation/pages/social_feed_page.dart';

class HomeShellPage extends StatefulWidget {
  const HomeShellPage({super.key});

  @override
  State<HomeShellPage> createState() => _HomeShellPageState();
}

class _HomeShellPageState extends State<HomeShellPage> {
  final _shellCubit = sl<HomeShellCubit>();

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _shellCubit,
      child: BlocBuilder<HomeShellCubit, HomeShellState>(
        builder: (context, shellState) {
          const pages = [
            HomePage(),
            GamesPage(),
            MembershipHomePage(),
            SocialFeedPage(),
            ArenaPage(),
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
