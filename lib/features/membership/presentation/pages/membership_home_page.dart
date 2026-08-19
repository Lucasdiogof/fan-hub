import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:goias_app/core/di/injection_container.dart';
import 'package:goias_app/core/theme/app_colors.dart';
import 'package:goias_app/core/theme/app_spacing.dart';
import 'package:goias_app/features/membership/data/mock_membership_repository.dart';
import 'package:goias_app/features/membership/domain/entities/membership.dart';
import 'package:goias_app/features/membership/domain/repositories/membership_repository.dart';
import 'package:goias_app/features/membership/presentation/cubit/membership_cubit.dart';
import 'package:goias_app/features/membership/presentation/cubit/membership_state.dart';
import 'package:goias_app/features/membership/presentation/widgets/member_view.dart';
import 'package:goias_app/features/membership/presentation/widgets/non_member_view.dart';
import 'package:goias_app/shared/state/load_status.dart';
import 'package:goias_app/shared/widgets/page_title.dart';
import 'package:goias_app/shared/widgets/state_message.dart';

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
    return Scaffold(
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
                  const Row(
                    children: [
                      Expanded(child: PageTitle('SÓCIO ESMERALDA')),
                      if (kDebugMode) _DebugStatusToggle(),
                    ],
                  ),
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
                                  pendingMembership: state.membership?.status == MembershipStatus.pending
                                      ? state.membership
                                      : null,
                                  onSelectPlan: (plan) async {
                                    final result = await context.push<bool>('/membership/plans/${plan.id}');
                                    if (result == true && context.mounted) {
                                      unawaited(context.read<MembershipCubit>().load());
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
    );
  }
}

/// Só existe fora de produção (`kDebugMode`) — alterna o estado mockado da
/// associação pra permitir testar as duas experiências da aba sem uma
/// integração real com o Sócio Esmeralda.
class _DebugStatusToggle extends StatelessWidget {
  const _DebugStatusToggle();

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.bug_report_outlined, size: 20),
      tooltip: 'Alternar estado de sócio (debug)',
      onPressed: () {
        final repository = sl<MembershipRepository>();
        if (repository is MockMembershipRepository) {
          repository.debugToggleStatus();
          context.read<MembershipCubit>().load();
        }
      },
    );
  }
}
