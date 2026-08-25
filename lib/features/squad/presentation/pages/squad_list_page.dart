import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:goias_app/core/di/injection_container.dart';
import 'package:goias_app/core/theme/app_colors.dart';
import 'package:goias_app/core/theme/app_spacing.dart';
import 'package:goias_app/features/squad/domain/position_groups.dart';
import 'package:goias_app/features/squad/domain/squad_member.dart';
import 'package:goias_app/features/squad/presentation/cubit/squad_cubit.dart';
import 'package:goias_app/features/squad/presentation/cubit/squad_state.dart';
import 'package:goias_app/features/squad/presentation/widgets/squad_avatar.dart';
import 'package:goias_app/shared/state/load_status.dart';
import 'package:goias_app/shared/widgets/back_button_circle.dart';
import 'package:goias_app/shared/widgets/page_title.dart';
import 'package:goias_app/shared/widgets/state_message.dart';

class SquadListPage extends StatelessWidget {
  const SquadListPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<SquadCubit>(),
      child: const _SquadListView(),
    );
  }
}

class _SquadListView extends StatelessWidget {
  const _SquadListView();

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
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                AppSpacing.md,
                AppSpacing.lg,
                0,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  BackButtonCircle(
                    onTap: () =>
                        context.canPop() ? context.pop() : context.go('/'),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  const PageTitle('ELENCO'),
                  const SizedBox(height: AppSpacing.xxxl),
                  Expanded(
                    child: BlocBuilder<SquadCubit, SquadState>(
                      builder: (context, state) {
                        return RefreshIndicator(
                          onRefresh: () => context.read<SquadCubit>().refresh(),
                          color: colors.primary,
                          child: switch (state.status) {
                            LoadStatus.initial ||
                            LoadStatus.loading => _centered(
                              CircularProgressIndicator(color: colors.primary),
                            ),
                            LoadStatus.error => _centered(
                              StateMessage(
                                icon: Icons.wifi_off_rounded,
                                title: 'Não foi possível carregar o elenco',
                                message: state.errorMessage,
                              ),
                            ),
                            LoadStatus.empty => _centered(
                              const StateMessage(
                                icon: Icons.groups_outlined,
                                title: 'Elenco indisponível no momento',
                              ),
                            ),
                            LoadStatus.success => ListView(
                              physics: const AlwaysScrollableScrollPhysics(),
                              padding: const EdgeInsets.only(
                                bottom: AppSpacing.xxxl,
                              ),
                              children: [
                                for (final group in positionGroupOrder)
                                  _PositionGroupSection(
                                    title: group,
                                    members: state.members
                                        .where(
                                          (member) =>
                                              member.positionGroup == group,
                                        )
                                        .toList(growable: false),
                                  ),
                              ],
                            ),
                          },
                        );
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

Widget _centered(Widget child) {
  return ListView(
    physics: const AlwaysScrollableScrollPhysics(),
    children: [
      Padding(
        padding: const EdgeInsets.only(top: 100),
        child: Center(child: child),
      ),
    ],
  );
}

class _PositionGroupSection extends StatelessWidget {
  const _PositionGroupSection({required this.title, required this.members});

  final String title;
  final List<SquadMember> members;

  @override
  Widget build(BuildContext context) {
    if (members.isEmpty) return const SizedBox.shrink();
    final colors = context.colors;
    final sorted = [...members]
      ..sort((a, b) {
        final numberA = a.shirtNumber;
        final numberB = b.shirtNumber;
        if (numberA == null && numberB == null) return 0;
        if (numberA == null) return 1;
        if (numberB == null) return -1;
        return numberA.compareTo(numberB);
      });
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title.toUpperCase(),
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              letterSpacing: 1,
              color: colors.textHint,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              mainAxisSpacing: AppSpacing.md,
              crossAxisSpacing: AppSpacing.md,
              childAspectRatio: 0.92,
            ),
            itemCount: sorted.length,
            itemBuilder: (context, index) => _SquadCard(member: sorted[index]),
          ),
        ],
      ),
    );
  }
}

class _SquadCard extends StatelessWidget {
  const _SquadCard({required this.member});

  final SquadMember member;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Material(
      color: colors.surface,
      borderRadius: BorderRadius.circular(AppRadius.card),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.card),
        onTap: () => context.push('/squad/${member.id}', extra: member),
        child: Container(
          padding: const EdgeInsets.symmetric(
            vertical: AppSpacing.sm,
            horizontal: AppSpacing.sm,
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadius.card),
            border: Border.all(color: colors.border),
          ),
          child: Column(
            children: [
              SquadAvatar(
                memberId: member.id,
                photoUrl: member.photoUrl,
                shirtNumber: member.shirtNumber,
                size: 60,
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                member.name,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: colors.textPrimary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
