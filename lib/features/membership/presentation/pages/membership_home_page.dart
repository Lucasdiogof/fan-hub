import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:goias_app/core/di/injection_container.dart';
import 'package:goias_app/core/theme/app_colors.dart';
import 'package:goias_app/core/theme/app_spacing.dart';
import 'package:goias_app/features/home/presentation/cubit/home_shell_cubit.dart';
import 'package:goias_app/features/home/presentation/cubit/home_shell_state.dart';
import 'package:goias_app/features/membership/presentation/cubit/membership_cubit.dart';
import 'package:goias_app/features/membership/presentation/cubit/membership_state.dart';
import 'package:goias_app/features/membership/presentation/widgets/member_view.dart';
import 'package:goias_app/features/membership/presentation/widgets/non_member_view.dart';
import 'package:goias_app/shared/state/load_status.dart';
import 'package:goias_app/shared/widgets/page_title.dart';
import 'package:goias_app/shared/widgets/state_message.dart';

const _sociTabIndex = 2;

class MembershipHomePage extends StatelessWidget {
  const MembershipHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<MembershipCubit>(
      create: (_) => sl<MembershipCubit>(),
      child: const _MembershipHomeView(),
    );
  }
}

class _MembershipHomeView extends StatelessWidget {
  const _MembershipHomeView();

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return BlocListener<HomeShellCubit, HomeShellState>(
      // Só recarrega ao reabrir a aba Sócio (ex.: depois de mudar o mock no
      // Perfil) — não a cada rota empurrada/fechada por cima (Regulamento,
      // Dúvidas Frequentes), que são só leitura e não mudam esse estado.
      listenWhen: (previous, current) => previous.index != _sociTabIndex && current.index == _sociTabIndex,
      listener: (context, state) => context.read<MembershipCubit>().load(),
      child: Scaffold(
        backgroundColor: colors.background,
        body: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 900),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.md, AppSpacing.lg, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const PageTitle('SÓCIO ESMERALDA'),
                    const SizedBox(height: AppSpacing.xxxl),
                    Expanded(
                      child: BlocBuilder<MembershipCubit, MembershipState>(
                        builder: (context, state) {
                          return switch (state.status) {
                            LoadStatus.initial || LoadStatus.loading => Center(
                              child: CircularProgressIndicator(color: colors.primary),
                            ),
                            LoadStatus.error => Center(
                              child: StateMessage(
                                icon: Icons.error_outline_rounded,
                                title: 'Não foi possível carregar o Sócio Esmeralda.',
                                message: state.errorMessage,
                              ),
                            ),
                            _ => state.isMember
                                ? MemberView(state: state)
                                : NonMemberView(
                                    plans: state.plans,
                                    onSelectPlan: (plan) async {
                                      final result = await context.push<String>('/membership/plans/${plan.id}');
                                      if (!context.mounted) return;
                                      switch (result) {
                                        case 'memberArea':
                                          // Já estamos na aba Sócio — só recarrega pra trocar a
                                          // vitrine de planos pela experiência de sócio ativo.
                                          unawaited(context.read<MembershipCubit>().load());
                                        case 'home':
                                          context.read<HomeShellCubit>().navigateToTab(0);
                                      }
                                    },
                                  ),
                          };
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
