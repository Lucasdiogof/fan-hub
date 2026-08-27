import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:goias_app/core/di/injection_container.dart';
import 'package:goias_app/core/theme/app_breakpoints.dart';
import 'package:goias_app/features/arena/presentation/pages/arena_page.dart';
import 'package:goias_app/features/home/presentation/cubit/home_shell_cubit.dart';
import 'package:goias_app/features/home/presentation/cubit/home_shell_state.dart';
import 'package:goias_app/features/home/presentation/pages/home_page.dart';
import 'package:goias_app/features/home/presentation/widgets/main_bottom_navigation.dart';
import 'package:goias_app/features/home/presentation/widgets/main_navigation_rail.dart';
import 'package:goias_app/features/membership/presentation/pages/membership_home_page.dart';
import 'package:goias_app/features/match/presentation/pages/games_page.dart';
import 'package:goias_app/features/profile/presentation/cubit/profile_cubit.dart';
import 'package:goias_app/features/social/presentation/pages/social_feed_page.dart';

class HomeShellPage extends StatefulWidget {
  const HomeShellPage({super.key});

  @override
  State<HomeShellPage> createState() => _HomeShellPageState();
}

class _HomeShellPageState extends State<HomeShellPage> {
  final _shellCubit = sl<HomeShellCubit>();

  // Só resolver o singleton já dispara o carregamento (ver `ProfileCubit`)
  // — aquece em segundo plano assim que a Home monta, pra não deixar
  // nome/foto do usuário em branco na primeira vez que ele abre o Perfil.
  // ignore: unused_field
  final _profileCubit = sl<ProfileCubit>();

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
          final content = IndexedStack(
            index: shellState.index,
            children: pages,
          );

          // Rail lateral fixo em telas expandidas/largas (desktop/tablet
          // grande) em vez da barra inferior — mesmas 5 abas, mesmo
          // `HomeShellCubit`, só a apresentação muda. Abaixo do corte, o
          // shell fica idêntico ao que já era (bottom nav, sem rail).
          if (context.isAtLeastExpanded) {
            return Scaffold(
              body: Row(
                children: [
                  MainNavigationRail(
                    selectedIndex: shellState.index,
                    onSelected: _shellCubit.navigateToTab,
                  ),
                  Expanded(child: content),
                ],
              ),
            );
          }

          return Scaffold(
            body: content,
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
