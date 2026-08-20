import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:goias_app/core/di/injection_container.dart';
import 'package:goias_app/core/router/route_observer.dart';
import 'package:goias_app/core/theme/app_colors.dart';
import 'package:goias_app/core/theme/app_spacing.dart';
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

class _MembershipHomeView extends StatefulWidget {
  const _MembershipHomeView();

  @override
  State<_MembershipHomeView> createState() => _MembershipHomeViewState();
}

class _MembershipHomeViewState extends State<_MembershipHomeView> with RouteAware {
  ModalRoute<void>? _route;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final route = ModalRoute.of(context);
    if (route != _route) {
      if (_route != null) appRouteObserver.unsubscribe(this);
      _route = route;
      if (route != null) appRouteObserver.subscribe(this, route);
    }
  }

  @override
  void dispose() {
    appRouteObserver.unsubscribe(this);
    super.dispose();
  }

  /// Ex.: usuário alterou o status de sócio (mock) no Perfil e voltou.
  @override
  void didPopNext() => context.read<MembershipCubit>().load();

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
