import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:goias_app/core/club/club_config.dart';
import 'package:goias_app/core/club/commerce_mode.dart';
import 'package:goias_app/core/di/injection_container.dart';
import 'package:goias_app/core/l10n/l10n_extensions.dart';
import 'package:goias_app/core/theme/app_colors.dart';
import 'package:goias_app/core/theme/app_spacing.dart';
import 'package:goias_app/features/profile/domain/entities/profile.dart';
import 'package:goias_app/features/ticket/domain/entities/ticket_enums.dart';
import 'package:goias_app/features/ticket/domain/entities/ticket_order.dart';
import 'package:goias_app/features/ticket/presentation/cubit/purchase_cubit.dart';
import 'package:goias_app/features/ticket/presentation/cubit/purchase_state.dart';
import 'package:goias_app/shared/utils/currency.dart';
import 'package:goias_app/shared/utils/date_labels.dart';
import 'package:goias_app/shared/utils/team_name.dart';
import 'package:goias_app/shared/validation/app_validators.dart';
import 'package:goias_app/shared/validation/field_touch.dart';
import 'package:goias_app/shared/widgets/app_bottom_sheet.dart';
import 'package:goias_app/shared/widgets/app_modal_sheet.dart';
import 'package:goias_app/shared/widgets/app_primary_button.dart';
import 'package:goias_app/shared/widgets/content_container.dart';
import 'package:goias_app/shared/widgets/demo_disclaimer_banner.dart';
import 'package:goias_app/shared/widgets/detail_page_header.dart';
import 'package:goias_app/features/ticket/domain/gate_label.dart';
import 'package:image_picker/image_picker.dart';

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

class _PurchaseSummaryViewState extends State<_PurchaseSummaryView> {
  late final List<TextEditingController> _nameControllers;
  late final List<TextEditingController> _documentControllers;
  late final List<FieldTouch> _nameTouches;
  late final List<FieldTouch> _documentTouches;

  @override
  void initState() {
    super.initState();
    final cubit = context.read<PurchaseCubit>();
    cubit.ensureHolderSlots();
    // Primeiro ingresso nasce pré-marcado "é pra mim" — caso mais comum é
    // comprar pelo menos 1 ingresso pro próprio usuário. Os demais ficam
    // em branco, aguardando os dados de quem realmente vai usá-los.
    final holders = cubit.state.holders;
    if (holders.isNotEmpty &&
        holders.first.name.isEmpty &&
        !holders.first.isSelf) {
      cubit.setHolderIsSelf(
        0,
        value: true,
        profileName: widget.profile.displayName,
        profileDocument: widget.profile.cpf,
      );
    }
    final current = cubit.state.holders;
    _nameControllers = [
      for (final holder in current) TextEditingController(text: holder.name),
    ];
    _documentControllers = [
      for (final holder in current)
        TextEditingController(text: holder.document),
    ];
    _nameTouches = [for (final _ in current) FieldTouch()];
    _documentTouches = [for (final _ in current) FieldTouch()];
  }

  @override
  void dispose() {
    for (final controller in _nameControllers) {
      controller.dispose();
    }
    for (final controller in _documentControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  void _syncControllers(PurchaseState state) {
    for (
      var i = 0;
      i < state.holders.length && i < _nameControllers.length;
      i++
    ) {
      final holder = state.holders[i];
      if (_nameControllers[i].text != holder.name) {
        _nameControllers[i].text = holder.name;
      }
      if (_documentControllers[i].text != holder.document) {
        _documentControllers[i].text = holder.document;
      }
    }
  }

  Future<void> _showSuccessSheet(BuildContext context) async {
    final cubit = context.read<PurchaseCubit>();
    final order = cubit.state.order;
    if (order == null) return;
    final l10n = context.l10n;
    await AppBottomSheet.show(
      context,
      icon: Icons.celebration_outlined,
      title: l10n.ticketsPurchaseSuccessTitle,
      description: l10n.ticketsPurchaseSuccessMessage,
      confirmLabel: l10n.ticketsMyTickets,
      cancelLabel: l10n.ticketsCloseButton,
      onConfirm: () => context.push('/tickets/my'),
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
        final units = state.ticketUnits;
        final title = context.l10n.ticketsSummaryTitle;
        return Scaffold(
          backgroundColor: colors.background,
          body: Column(
            children: [
              Expanded(
                child: DetailPageHeader(
                  maxWidth: ContentWidth.detail,
                  title: title,
                  onBack: () =>
                      context.canPop() ? context.pop() : context.go('/'),
                  heroTitle: Text(
                    title,
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w900,
                      color: colors.textPrimary,
                    ),
                  ),
                  body: Padding(
                    padding: const EdgeInsets.only(top: AppSpacing.xl),
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
                                            withGate(
                                              item.sectorName,
                                              item.gate,
                                            ),
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
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
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
                          context.l10n.ticketsHolderDataTitle(
                            state.holders.length,
                          ),
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1,
                            color: colors.textHint,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.md),
                        for (var i = 0; i < units.length; i++) ...[
                          if (i > 0) const SizedBox(height: AppSpacing.lg),
                          _HolderSection(
                            index: i,
                            unit: units[i],
                            holder: i < state.holders.length
                                ? state.holders[i]
                                : const TicketHolder(name: '', document: ''),
                            nameController: _nameControllers[i],
                            documentController: _documentControllers[i],
                            nameTouch: _nameTouches[i],
                            documentTouch: _documentTouches[i],
                            profile: widget.profile,
                          ),
                        ],
                        const SizedBox(height: AppSpacing.md),
                        Text(
                          context.l10n.ticketsNominalWarning,
                          style: TextStyle(
                            fontSize: 12,
                            color: colors.textHint,
                          ),
                        ),
                      ],
                    ),
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
                    if (sl<ClubConfig>().capabilities.ticketCommerceMode ==
                        CommerceMode.demo) ...[
                      DemoDisclaimerBanner(
                        title: context.l10n.commonDemoBannerTitle,
                        body: context.l10n.ticketsDemoDisclaimerBody,
                      ),
                      const SizedBox(height: AppSpacing.md),
                    ],
                    AppPrimaryButton(
                      label: context.l10n.ticketsFinalizePurchaseButton,
                      loading: state.saving,
                      onPressed: state.canFinalize
                          ? () =>
                                context.read<PurchaseCubit>().finalizePurchase()
                          : null,
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _PurchaseSummaryView extends StatefulWidget {
  const _PurchaseSummaryView({required this.profile});

  final Profile profile;

  @override
  State<_PurchaseSummaryView> createState() => _PurchaseSummaryViewState();
}

class _HolderSection extends StatelessWidget {
  const _HolderSection({
    required this.index,
    required this.unit,
    required this.holder,
    required this.nameController,
    required this.documentController,
    required this.nameTouch,
    required this.documentTouch,
    required this.profile,
  });

  final int index;
  final TicketOrderItem unit;
  final TicketHolder holder;
  final TextEditingController nameController;
  final TextEditingController documentController;
  final FieldTouch nameTouch;
  final FieldTouch documentTouch;
  final Profile profile;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final l10n = context.l10n;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(AppRadius.cardSmall),
        border: Border.all(color: colors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.ticketsHolderSlotLabel(
              index + 1,
              unit.sectorName,
              unit.categoryLabel,
            ),
            style: TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.3,
              color: colors.textHint,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          InkWell(
            onTap: () => context.read<PurchaseCubit>().setHolderIsSelf(
              index,
              value: !holder.isSelf,
              profileName: profile.displayName,
              profileDocument: profile.cpf,
            ),
            borderRadius: BorderRadius.circular(AppRadius.cardSmall),
            child: Row(
              children: [
                Checkbox(
                  value: holder.isSelf,
                  onChanged: (value) =>
                      context.read<PurchaseCubit>().setHolderIsSelf(
                        index,
                        value: value ?? false,
                        profileName: profile.displayName,
                        profileDocument: profile.cpf,
                      ),
                  activeColor: colors.primary,
                ),
                Expanded(
                  child: Text(
                    l10n.ticketsHolderIsSelfCheckbox,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          TextField(
            controller: nameController,
            enabled: !holder.isSelf,
            onChanged: (v) {
              nameTouch.touched = true;
              context.read<PurchaseCubit>().setHolderName(index, v);
            },
            decoration: InputDecoration(
              labelText: l10n.authFullNameLabel,
              errorText: nameTouch.errorFor(
                nameController.text,
                submitted: false,
                requiredMessage: l10n.validatorNameRequired,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          TextField(
            controller: documentController,
            enabled: !holder.isSelf,
            onChanged: (v) {
              documentTouch.touched = true;
              context.read<PurchaseCubit>().setHolderDocument(index, v);
            },
            decoration: InputDecoration(
              labelText: l10n.ticketsDocumentLabel,
              errorText: documentTouch.errorFor(
                documentController.text,
                submitted: false,
                format: (v) => AppValidators.isValidDocument(v)
                    ? null
                    : l10n.storeValCpfInvalid,
              ),
            ),
          ),
          if (unit.isHalfPrice) ...[
            const SizedBox(height: AppSpacing.md),
            _HalfPriceSection(index: index, holder: holder),
          ],
        ],
      ),
    );
  }
}

class _HalfPriceSection extends StatelessWidget {
  const _HalfPriceSection({required this.index, required this.holder});

  final int index;
  final TicketHolder holder;

  Future<void> _pickAndUpload(BuildContext context) async {
    final source = await AppModalSheet.show<ImageSource>(
      context,
      builder: (sheetContext) {
        final colors = sheetContext.colors;
        final l10n = sheetContext.l10n;
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: Icon(
                  Icons.photo_camera_outlined,
                  color: colors.primary,
                ),
                title: Text(l10n.avatarTakePhoto),
                onTap: () => Navigator.of(sheetContext).pop(ImageSource.camera),
              ),
              ListTile(
                leading: Icon(
                  Icons.photo_library_outlined,
                  color: colors.primary,
                ),
                title: Text(l10n.avatarChooseFromGallery),
                onTap: () =>
                    Navigator.of(sheetContext).pop(ImageSource.gallery),
              ),
              const SizedBox(height: AppSpacing.sm),
            ],
          ),
        );
      },
    );
    if (source == null || !context.mounted) return;
    final cubit = context.read<PurchaseCubit>();
    final picked = await ImagePicker().pickImage(
      source: source,
      maxWidth: 1600,
      imageQuality: 85,
    );
    if (picked == null) return;
    final bytes = await picked.readAsBytes();
    final ext = picked.name.contains('.') ? picked.name.split('.').last : 'jpg';
    await cubit.uploadHalfPriceProof(index, bytes, ext);
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final l10n = context.l10n;
    final hasProof = holder.halfPriceProofPath?.isNotEmpty ?? false;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(height: 1, color: colors.border),
        const SizedBox(height: AppSpacing.md),
        Text(
          l10n.ticketsHalfPriceTypeLabel,
          style: TextStyle(
            fontSize: 11.5,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.3,
            color: colors.textHint,
          ),
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            Expanded(
              child: _HalfPriceTypeOption(
                label: l10n.ticketsHalfPriceLawOption,
                selected: holder.halfPriceType == HalfPriceType.law,
                onTap: () => context
                    .read<PurchaseCubit>()
                    .setHolderHalfPriceType(index, HalfPriceType.law),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: _HalfPriceTypeOption(
                label: l10n.ticketsHalfPricePromotionalOption,
                selected: holder.halfPriceType == HalfPriceType.promotional,
                onTap: () => context
                    .read<PurchaseCubit>()
                    .setHolderHalfPriceType(index, HalfPriceType.promotional),
              ),
            ),
          ],
        ),
        if (holder.halfPriceType == HalfPriceType.law) ...[
          const SizedBox(height: AppSpacing.md),
          Text(
            l10n.ticketsHalfPriceProofLabel,
            style: TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.3,
              color: colors.textHint,
            ),
          ),
          const SizedBox(height: 6),
          InkWell(
            onTap: () => _pickAndUpload(context),
            borderRadius: BorderRadius.circular(AppRadius.cardSmall),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.md,
              ),
              decoration: BoxDecoration(
                color: colors.background,
                borderRadius: BorderRadius.circular(AppRadius.cardSmall),
                border: Border.all(
                  color: hasProof ? colors.primary : colors.border,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    hasProof
                        ? Icons.check_circle_rounded
                        : Icons.upload_file_outlined,
                    size: 18,
                    color: hasProof ? colors.primary : colors.textSecondary,
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(
                      hasProof
                          ? l10n.ticketsHalfPriceProofUploaded
                          : l10n.ticketsHalfPriceProofUploadButton,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: hasProof
                            ? colors.textPrimary
                            : colors.textSecondary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _HalfPriceTypeOption extends StatelessWidget {
  const _HalfPriceTypeOption({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Material(
      color: selected ? colors.secondary : colors.background,
      borderRadius: BorderRadius.circular(AppRadius.cardSmall),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.cardSmall),
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.sm,
            vertical: AppSpacing.sm,
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadius.cardSmall),
            border: Border.all(
              color: selected ? colors.primary : colors.border,
              width: selected ? 1.6 : 1,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                selected
                    ? Icons.radio_button_checked_rounded
                    : Icons.radio_button_off_rounded,
                size: 18,
                color: selected ? colors.primary : colors.textHint,
              ),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    color: colors.textPrimary,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
