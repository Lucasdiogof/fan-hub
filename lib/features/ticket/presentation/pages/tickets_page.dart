import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:goias_app/core/club/club_config.dart';
import 'package:goias_app/core/di/injection_container.dart';
import 'package:goias_app/core/error/result.dart';
import 'package:goias_app/core/l10n/l10n_extensions.dart';
import 'package:goias_app/core/theme/app_colors.dart';
import 'package:goias_app/core/theme/app_spacing.dart';
import 'package:goias_app/features/membership/presentation/cubit/membership_status_cubit.dart';
import 'package:goias_app/features/profile/domain/repositories/profile_repository.dart';
import 'package:goias_app/features/ticket/domain/entities/ticket.dart';
import 'package:goias_app/features/ticket/domain/entities/ticket_event.dart';
import 'package:goias_app/features/ticket/domain/repositories/ticket_repository.dart';
import 'package:goias_app/features/ticket/presentation/cubit/purchase_cubit.dart';
import 'package:goias_app/features/ticket/presentation/cubit/tickets_cubit.dart';
import 'package:goias_app/features/ticket/presentation/cubit/tickets_state.dart';
import 'package:goias_app/features/ticket/presentation/pages/check_in_confirmation_page.dart';
import 'package:goias_app/features/ticket/presentation/widgets/featured_event_card.dart';
import 'package:goias_app/shared/state/load_status.dart';
import 'package:goias_app/shared/widgets/app_bottom_sheet.dart';
import 'package:goias_app/shared/widgets/back_button_circle.dart';
import 'package:goias_app/shared/widgets/global_loading.dart';
import 'package:goias_app/shared/widgets/goias_loading_indicator.dart';
import 'package:goias_app/shared/widgets/page_title.dart';
import 'package:goias_app/shared/widgets/state_message.dart';
import 'package:goias_app/shared/widgets/content_container.dart';

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

  Future<void> _openCheckIn(BuildContext context, TicketEvent event) async {
    final profileResult = await GlobalLoading.run(
      context,
      () => sl<ProfileRepository>().getProfile(),
    );
    if (!context.mounted) return;
    final profile = switch (profileResult) {
      Success(:final data) => data,
      Error() => null,
    };
    // Já carregada pela `MembershipStatusCubit` (fonte única de "é sócio?")
    // — nunca uma nova consulta a `MembershipRepository` só pra esta tela.
    final membership = sl<MembershipStatusCubit>().state.membership;
    if (profile == null || membership == null) {
      _showLoadError(context);
      return;
    }
    await context.push(
      '/tickets/checkin',
      extra: CheckInArgs(
        event: event,
        profile: profile,
        membership: membership,
      ),
    );
    if (context.mounted) await context.read<TicketsCubit>().load();
  }

  Future<void> _openPurchase(BuildContext context, TicketEvent event) async {
    final profileResult = await GlobalLoading.run(
      context,
      () => sl<ProfileRepository>().getProfile(),
    );
    if (!context.mounted) return;
    final profile = switch (profileResult) {
      Success(:final data) => data,
      Error() => null,
    };
    if (profile == null) {
      _showLoadError(context);
      return;
    }
    final cubit = PurchaseCubit(sl<TicketRepository>(), event);
    await context.push(
      '/tickets/purchase',
      extra: (cubit: cubit, profile: profile),
    );
    if (context.mounted) await context.read<TicketsCubit>().load();
  }

  void _showLoadError(BuildContext context) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(content: Text(context.l10n.ticketsLoadUserDataError)),
      );
  }

  void _viewTicket(BuildContext context, Ticket ticket) {
    context.push('/tickets/view', extra: ticket);
  }

  Future<void> _undoCheckIn(BuildContext context, TicketEvent event) async {
    final l10n = context.l10n;
    final confirmed = await AppBottomSheet.show(
      context,
      icon: Icons.event_busy_outlined,
      title: l10n.ticketsUndoCheckInConfirmTitle,
      description: l10n.ticketsUndoCheckInConfirmMessage,
      confirmLabel: l10n.ticketsKeepCheckInButton,
      cancelLabel: l10n.ticketsUndoCheckInButton,
    );
    if (confirmed != false || !context.mounted) return;
    await GlobalLoading.run(
      context,
      () => sl<TicketRepository>().undoCheckIn(event.match.id.toString()),
    );
    if (context.mounted) await context.read<TicketsCubit>().load();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Scaffold(
      backgroundColor: colors.background,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: ContentWidth.detail.maxWidth),
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
                  PageTitle(context.l10n.homeTickets),
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
                              title: context.l10n.ticketsLoadError,
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
                                _SectionLabel(context.l10n.ticketsNextEvent),
                                const SizedBox(height: AppSpacing.md),
                                state.event == null
                                    ? const _EmptyEventCard()
                                    : FeaturedEventCard(
                                        event: state.event!,
                                        isMember: state.isMember,
                                        onCheckIn: () =>
                                            _openCheckIn(context, state.event!),
                                        onBuyTicket: () => _openPurchase(
                                          context,
                                          state.event!,
                                        ),
                                        onViewTicket: (ticket) =>
                                            _viewTicket(context, ticket),
                                        onViewMyTickets: () =>
                                            context.push('/tickets/my'),
                                        onUndoCheckIn: () =>
                                            _undoCheckIn(context, state.event!),
                                      ),
                                const SizedBox(height: AppSpacing.xxl),
                                _SectionLabel(context.l10n.ticketsQuickAccess),
                                const SizedBox(height: AppSpacing.md),
                                _ShortcutCard(
                                  icon: Icons.confirmation_number_outlined,
                                  title: context.l10n.ticketsMyTickets,
                                  subtitle: context.l10n
                                      .ticketsMyTicketsSubtitle(
                                        sl<ClubConfig>().identity.shortName,
                                      ),
                                  onTap: () => context.push('/tickets/my'),
                                ),
                                const SizedBox(height: AppSpacing.md),
                                _ShortcutCard(
                                  icon: Icons.receipt_long_outlined,
                                  title: context.l10n.ticketsMyOrders,
                                  subtitle:
                                      context.l10n.ticketsMyOrdersSubtitle,
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
            context.l10n.ticketsNoEvents,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: colors.textPrimary,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            context.l10n.ticketsNoEventsMessage,
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
