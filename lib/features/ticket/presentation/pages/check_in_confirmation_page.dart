import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:goias_app/core/di/injection_container.dart';
import 'package:goias_app/core/l10n/l10n_extensions.dart';
import 'package:goias_app/core/theme/app_colors.dart';
import 'package:goias_app/core/theme/app_spacing.dart';
import 'package:goias_app/features/membership/domain/entities/membership.dart';
import 'package:goias_app/features/membership/presentation/widgets/digital_membership_card.dart';
import 'package:goias_app/features/profile/domain/entities/profile.dart';
import 'package:goias_app/features/ticket/domain/entities/ticket_event.dart';
import 'package:goias_app/features/ticket/domain/entities/ticket_sector.dart';
import 'package:goias_app/features/ticket/domain/repositories/ticket_repository.dart';
import 'package:goias_app/features/ticket/presentation/cubit/check_in_cubit.dart';
import 'package:goias_app/features/ticket/presentation/cubit/check_in_state.dart';
import 'package:goias_app/shared/utils/date_labels.dart';
import 'package:goias_app/shared/utils/team_name.dart';
import 'package:goias_app/shared/widgets/app_bottom_sheet.dart';
import 'package:goias_app/shared/widgets/app_primary_button.dart';
import 'package:goias_app/shared/widgets/back_button_circle.dart';
import 'package:goias_app/shared/widgets/global_loading.dart';
import 'package:goias_app/shared/widgets/page_title.dart';

class CheckInArgs {
  const CheckInArgs({
    required this.event,
    required this.profile,
    required this.membership,
  });

  final TicketEvent event;
  final Profile profile;
  final Membership membership;
}

class CheckInConfirmationPage extends StatelessWidget {
  const CheckInConfirmationPage({required this.args, super.key});

  final CheckInArgs args;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => CheckInCubit(sl<TicketRepository>(), args.event),
      child: _CheckInView(profile: args.profile, membership: args.membership),
    );
  }
}

class _CheckInView extends StatelessWidget {
  const _CheckInView({required this.profile, required this.membership});

  final Profile profile;
  final Membership membership;

  Future<void> _openSectorPicker(BuildContext context) async {
    final cubit = context.read<CheckInCubit>();
    final sectors = cubit.state.event.info.checkInSectors;
    final colors = context.colors;
    final sectorId = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      backgroundColor: colors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.hero)),
      ),
      builder: (_) => _SectorPickerSheet(sectors: sectors),
    );
    if (sectorId == null || !context.mounted) return;
    cubit.selectSector(sectorId);
    await GlobalLoading.run(
      context,
      () => cubit.confirm(
        holderName: profile.displayName,
        holderDocument: profile.cpf ?? '',
      ),
    );
  }

  Future<void> _confirmDecline(BuildContext context) async {
    final cubit = context.read<CheckInCubit>();
    final l10n = context.l10n;
    final result = await AppBottomSheet.show(
      context,
      icon: Icons.sentiment_dissatisfied_outlined,
      title: l10n.ticketsDeclineConfirmTitle,
      description: l10n.ticketsDeclineConfirmMessage,
      confirmLabel: l10n.ticketsWantToGoButton,
      cancelLabel: l10n.ticketsConfirmDeclineButton,
    );
    if (result != false || !context.mounted) return;
    await GlobalLoading.run(context, cubit.decline);
  }

  Future<void> _showConfirmedSheet(BuildContext context) async {
    final cubit = context.read<CheckInCubit>();
    final ticket = cubit.state.confirmedTicket;
    final l10n = context.l10n;
    await AppBottomSheet.show(
      context,
      icon: Icons.emoji_events_rounded,
      title: l10n.ticketsCheckinSuccessTitle,
      description: l10n.ticketsCheckinSuccessMessage,
      confirmLabel: l10n.ticketsViewTicketButton,
      cancelLabel: l10n.ticketsCloseButton,
      onConfirm: () {
        if (ticket != null) context.push('/tickets/view', extra: ticket);
      },
    );
    if (context.mounted) context.pop();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return BlocConsumer<CheckInCubit, CheckInState>(
      listenWhen: (previous, current) =>
          (current.justConfirmed && !previous.justConfirmed) ||
          (current.justDeclined && !previous.justDeclined),
      listener: (context, state) async {
        if (state.justDeclined) {
          context.pop();
          return;
        }
        if (state.justConfirmed) {
          await _showConfirmedSheet(context);
        }
      },
      builder: (context, state) {
        final match = state.event.match;
        return Scaffold(
          backgroundColor: colors.background,
          body: SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.lg,
                    AppSpacing.md,
                    AppSpacing.lg,
                    0,
                  ),
                  child: Row(
                    children: [
                      BackButtonCircle(
                        onTap: () =>
                            context.canPop() ? context.pop() : context.go('/'),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: PageTitle(context.l10n.ticketsConfirmPresenceTitle),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.lg,
                      AppSpacing.lg,
                      AppSpacing.lg,
                      AppSpacing.xl,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(AppSpacing.lg),
                          decoration: BoxDecoration(
                            color: colors.surface,
                            borderRadius: BorderRadius.circular(AppRadius.card),
                            border: Border.all(color: colors.border),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                match.competition,
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: colors.textHint,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                '${shortTeamName(match.homeTeam.name)} x ${shortTeamName(match.awayTeam.name)}',
                                style: TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.w800,
                                  color: colors.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 6),
                              if (match.kickoff != null)
                                Text(
                                  '${fullDateLabel(match.kickoff!)} às ${timeLabel(match.kickoff!)}',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: colors.textSecondary,
                                  ),
                                ),
                              const SizedBox(height: 2),
                              Text(
                                match.stadium,
                                style: TextStyle(
                                  fontSize: 13,
                                  color: colors.textSecondary,
                                ),
                              ),
                              if (match.round.isNotEmpty) ...[
                                const SizedBox(height: 2),
                                Text(
                                  match.round,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: colors.textHint,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                        const SizedBox(height: AppSpacing.xl),
                        DigitalMembershipCard(
                          holderName: profile.displayName,
                          planName: membership.plan.name,
                          status: membership.status,
                          memberNumber: membership.memberNumber,
                          avatarUrl: profile.avatarUrl,
                        ),
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.lg,
                    0,
                    AppSpacing.lg,
                    AppSpacing.lg,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      AppPrimaryButton(
                        label: context.l10n.ticketsGoToMatchButton,
                        loading: state.saving,
                        onPressed: state.saving
                            ? null
                            : () => _openSectorPicker(context),
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      TextButton(
                        onPressed: state.saving
                            ? null
                            : () => _confirmDecline(context),
                        style: TextButton.styleFrom(
                          foregroundColor: colors.textSecondary,
                          minimumSize: const Size.fromHeight(46),
                        ),
                        child: Text(
                          context.l10n.ticketsNotThisTimeButton,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _SectorPickerSheet extends StatefulWidget {
  const _SectorPickerSheet({required this.sectors});

  final List<TicketSector> sectors;

  @override
  State<_SectorPickerSheet> createState() => _SectorPickerSheetState();
}

class _SectorPickerSheetState extends State<_SectorPickerSheet> {
  String? _selected;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.xxl,
          AppSpacing.sm,
          AppSpacing.xxl,
          AppSpacing.xl,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              context.l10n.ticketsSectorPickerTitle,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              context.l10n.ticketsSectorPickerSubtitle,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13.5, color: colors.textSecondary),
            ),
            const SizedBox(height: AppSpacing.xl),
            for (final sector in widget.sectors) ...[
              _SectorOption(
                sector: sector,
                selected: _selected == sector.id,
                onTap: () => setState(() => _selected = sector.id),
              ),
              const SizedBox(height: AppSpacing.sm),
            ],
            const SizedBox(height: AppSpacing.md),
            AppPrimaryButton(
              label: context.l10n.ticketsConfirmCheckInButton,
              onPressed: _selected == null
                  ? null
                  : () => Navigator.of(context).pop(_selected),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectorOption extends StatelessWidget {
  const _SectorOption({
    required this.sector,
    required this.selected,
    required this.onTap,
  });

  final TicketSector sector;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Material(
      color: selected ? colors.secondary : colors.surface,
      borderRadius: BorderRadius.circular(AppRadius.cardSmall),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.cardSmall),
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.md,
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadius.cardSmall),
            border: Border.all(
              color: selected ? colors.primary : colors.border,
              width: selected ? 1.6 : 1,
            ),
          ),
          child: Row(
            children: [
              Icon(
                selected
                    ? Icons.radio_button_checked_rounded
                    : Icons.radio_button_off_rounded,
                color: selected ? colors.primary : colors.textHint,
                size: 22,
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      sector.name,
                      style: TextStyle(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w700,
                        color: colors.textPrimary,
                      ),
                    ),
                    Text(
                      '${sector.venueLabel} · ${sector.gate}',
                      style: TextStyle(fontSize: 12, color: colors.textSecondary),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
