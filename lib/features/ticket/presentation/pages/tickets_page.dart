import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:goias_app/core/di/injection_container.dart';
import 'package:goias_app/core/theme/app_colors.dart';
import 'package:goias_app/core/theme/app_spacing.dart';
import 'package:goias_app/features/ticket/presentation/cubit/tickets_cubit.dart';
import 'package:goias_app/features/ticket/presentation/cubit/tickets_state.dart';
import 'package:goias_app/shared/state/load_status.dart';
import 'package:goias_app/shared/widgets/back_button_circle.dart';
import 'package:goias_app/shared/widgets/goias_loading_indicator.dart';
import 'package:goias_app/shared/widgets/page_title.dart';
import 'package:goias_app/shared/widgets/state_message.dart';

class TicketsPage extends StatelessWidget {
  const TicketsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<TicketsCubit>(),
      child: const _TicketsView(),
    );
  }
}

class _TicketsView extends StatelessWidget {
  const _TicketsView();

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
                  const PageTitle('INGRESSOS'),
                  const SizedBox(height: AppSpacing.xxxl),
                  Expanded(
                    child: BlocBuilder<TicketsCubit, TicketsState>(
                      builder: (context, state) {
                        return switch (state.status) {
                          LoadStatus.initial || LoadStatus.loading =>
                            const Center(child: GoiasLoadingIndicator()),
                          LoadStatus.error => Center(
                            child: StateMessage(
                              icon: Icons.error_outline_rounded,
                              title: 'Não foi possível carregar os ingressos.',
                              message: state.errorMessage,
                            ),
                          ),
                          _ => RefreshIndicator(
                            onRefresh: () =>
                                context.read<TicketsCubit>().load(),
                            color: colors.primary,
                            child: ListView(
                              physics: const AlwaysScrollableScrollPhysics(),
                              padding: const EdgeInsets.only(
                                bottom: AppSpacing.xxxl,
                              ),
                              children: [
                                const _SectionLabel('PRÓXIMO EVENTO'),
                                const SizedBox(height: AppSpacing.md),
                                const _EmptyEventCard(),
                                const SizedBox(height: AppSpacing.xxl),
                                const _SectionLabel('ACESSO RÁPIDO'),
                                const SizedBox(height: AppSpacing.md),
                                _ShortcutCard(
                                  icon: Icons.confirmation_number_outlined,
                                  title: 'Meus ingressos',
                                  subtitle: 'Ingressos para partidas do Goiás',
                                  onTap: () => context.push('/tickets/my'),
                                ),
                                const SizedBox(height: AppSpacing.md),
                                _ShortcutCard(
                                  icon: Icons.receipt_long_outlined,
                                  title: 'Meus pedidos',
                                  subtitle: 'Histórico das suas compras',
                                  onTap: () => context.push('/tickets/orders'),
                                ),
                              ],
                            ),
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

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w800,
        letterSpacing: 1,
        color: context.colors.textHint,
      ),
    );
  }
}

class _EmptyEventCard extends StatelessWidget {
  const _EmptyEventCard();

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.xl,
        vertical: AppSpacing.xxxl,
      ),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(color: colors.border),
      ),
      child: Column(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: colors.secondary,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.stadium_outlined,
              size: 30,
              color: colors.primary,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(
            'Nenhum evento disponível no momento',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: colors.textPrimary,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Quando uma nova partida estiver disponível para venda ou check-in, ela aparecerá aqui.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              height: 1.4,
              color: colors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

class _ShortcutCard extends StatelessWidget {
  const _ShortcutCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Material(
      color: colors.surface,
      borderRadius: BorderRadius.circular(AppRadius.card),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.card),
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.lg),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadius.card),
            border: Border.all(color: colors.border),
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: colors.secondary,
                  borderRadius: BorderRadius.circular(AppRadius.cardSmall),
                ),
                child: Icon(icon, size: 22, color: colors.primary),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: colors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 12.5,
                        color: colors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right_rounded, color: colors.textHint),
            ],
          ),
        ),
      ),
    );
  }
}
