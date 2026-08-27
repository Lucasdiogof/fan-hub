import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:goias_app/core/l10n/l10n_extensions.dart';
import 'package:goias_app/core/theme/app_colors.dart';
import 'package:goias_app/core/theme/app_spacing.dart';
import 'package:goias_app/features/profile/domain/entities/profile.dart';
import 'package:goias_app/features/ticket/presentation/cubit/purchase_cubit.dart';
import 'package:goias_app/features/ticket/presentation/cubit/purchase_state.dart';
import 'package:goias_app/shared/utils/currency.dart';
import 'package:goias_app/shared/utils/date_labels.dart';
import 'package:goias_app/shared/utils/team_name.dart';
import 'package:goias_app/shared/widgets/app_bottom_sheet.dart';
import 'package:goias_app/shared/widgets/app_primary_button.dart';
import 'package:goias_app/shared/widgets/back_button_circle.dart';
import 'package:goias_app/shared/widgets/page_title.dart';

class PurchaseSummaryArgs {
  const PurchaseSummaryArgs({required this.cubit, required this.profile});

  final PurchaseCubit cubit;
  final Profile profile;
}

class PurchaseSummaryPage extends StatelessWidget {
  const PurchaseSummaryPage({required this.args, super.key});

  final PurchaseSummaryArgs args;

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: args.cubit,
      child: _PurchaseSummaryView(profile: args.profile),
    );
  }
}

class _PurchaseSummaryView extends StatefulWidget {
  const _PurchaseSummaryView({required this.profile});

  final Profile profile;

  @override
  State<_PurchaseSummaryView> createState() => _PurchaseSummaryViewState();
}

class _PurchaseSummaryViewState extends State<_PurchaseSummaryView> {
  final _nameController = TextEditingController();
  final _documentController = TextEditingController();

  @override
  void initState() {
    super.initState();
    final cubit = context.read<PurchaseCubit>();
    if (cubit.state.holderIsSelf && cubit.state.holderName.isEmpty) {
      cubit.setHolderIsSelf(
        true,
        profileName: widget.profile.displayName,
        profileDocument: widget.profile.cpf,
      );
    }
    _nameController.text = cubit.state.holderName;
    _documentController.text = cubit.state.holderDocument;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _documentController.dispose();
    super.dispose();
  }

  void _syncControllers(PurchaseState state) {
    if (_nameController.text != state.holderName) {
      _nameController.text = state.holderName;
    }
    if (_documentController.text != state.holderDocument) {
      _documentController.text = state.holderDocument;
    }
  }

  Future<void> _showSuccessSheet(BuildContext context) async {
    final cubit = context.read<PurchaseCubit>();
    final order = cubit.state.order;
    if (order == null) return;
    final tickets = cubit.state.purchasedTickets;
    final firstTicket = tickets.isEmpty ? null : tickets.first;
    final l10n = context.l10n;
    await AppBottomSheet.show(
      context,
      icon: Icons.celebration_outlined,
      title: l10n.ticketsPurchaseSuccessTitle,
      description: l10n.ticketsPurchaseSuccessMessage,
      confirmLabel: l10n.ticketsViewTicketButton,
      cancelLabel: l10n.ticketsCloseButton,
      onConfirm: () {
        if (firstTicket != null) {
          context.push('/tickets/view', extra: firstTicket);
        } else {
          context.push('/tickets/my');
        }
      },
    );
    if (context.mounted) {
      context
        ..pop()
        ..pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return BlocConsumer<PurchaseCubit, PurchaseState>(
      listenWhen: (previous, current) =>
          previous.order == null && current.order != null,
      listener: (context, state) => _showSuccessSheet(context),
      builder: (context, state) {
        _syncControllers(state);
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
                        child: PageTitle(context.l10n.ticketsSummaryTitle),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.lg,
                      AppSpacing.lg,
                      AppSpacing.lg,
                      AppSpacing.xxxl,
                    ),
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
                              '${shortTeamName(match.homeTeam.name)} x ${shortTeamName(match.awayTeam.name)}',
                              style: TextStyle(
                                fontSize: 15.5,
                                fontWeight: FontWeight.w800,
                                color: colors.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 2),
                            if (match.kickoff != null)
                              Text(
                                '${fullDateLabel(match.kickoff!)} às ${timeLabel(match.kickoff!)}',
                                style: TextStyle(
                                  fontSize: 12.5,
                                  color: colors.textSecondary,
                                ),
                              ),
                            const SizedBox(height: AppSpacing.md),
                            Container(height: 1, color: colors.border),
                            const SizedBox(height: AppSpacing.md),
                            for (final item in state.items) ...[
                              Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          '${item.sectorName} · ${item.gate}',
                                          style: TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w700,
                                            color: colors.textPrimary,
                                          ),
                                        ),
                                        Text(
                                          '${item.categoryLabel} · ${item.quantity}x ${formatBrl(item.unitPrice)}',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: colors.textSecondary,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Text(
                                    formatBrl(item.subtotal),
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w700,
                                      color: colors.textPrimary,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: AppSpacing.sm),
                            ],
                            Container(height: 1, color: colors.border),
                            const SizedBox(height: AppSpacing.sm),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  context.l10n.ticketsTotalLabel,
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                    color: colors.textPrimary,
                                  ),
                                ),
                                Text(
                                  formatBrl(state.total),
                                  style: TextStyle(
                                    fontSize: 17,
                                    fontWeight: FontWeight.w900,
                                    color: colors.primary,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xl),
                      Text(
                        context.l10n.ticketsHolderDataTitle,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1,
                          color: colors.textHint,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      _SelfCheckbox(profile: widget.profile),
                      const SizedBox(height: AppSpacing.md),
                      TextField(
                        controller: _nameController,
                        enabled: !state.holderIsSelf,
                        onChanged: context.read<PurchaseCubit>().setHolderName,
                        decoration: InputDecoration(
                          labelText: context.l10n.authFullNameLabel,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      TextField(
                        controller: _documentController,
                        enabled: !state.holderIsSelf,
                        onChanged: context
                            .read<PurchaseCubit>()
                            .setHolderDocument,
                        decoration: InputDecoration(
                          labelText: context.l10n.ticketsDocumentLabel,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      Text(
                        context.l10n.ticketsNominalWarning,
                        style: TextStyle(fontSize: 12, color: colors.textHint),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  child: AppPrimaryButton(
                    label: context.l10n.ticketsFinalizePurchaseButton,
                    loading: state.saving,
                    onPressed: state.canFinalize
                        ? () => context.read<PurchaseCubit>().finalizePurchase()
                        : null,
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

class _SelfCheckbox extends StatelessWidget {
  const _SelfCheckbox({required this.profile});

  final Profile profile;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return BlocBuilder<PurchaseCubit, PurchaseState>(
      buildWhen: (previous, current) =>
          previous.holderIsSelf != current.holderIsSelf,
      builder: (context, state) {
        return InkWell(
          onTap: () => context.read<PurchaseCubit>().setHolderIsSelf(
            !state.holderIsSelf,
            profileName: profile.displayName,
            profileDocument: profile.cpf,
          ),
          borderRadius: BorderRadius.circular(AppRadius.cardSmall),
          child: Row(
            children: [
              Checkbox(
                value: state.holderIsSelf,
                onChanged: (value) =>
                    context.read<PurchaseCubit>().setHolderIsSelf(
                      value ?? false,
                      profileName: profile.displayName,
                      profileDocument: profile.cpf,
                    ),
                activeColor: colors.primary,
              ),
              Expanded(
                child: Text(
                  context.l10n.ticketsHolderIsSelfCheckbox,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
