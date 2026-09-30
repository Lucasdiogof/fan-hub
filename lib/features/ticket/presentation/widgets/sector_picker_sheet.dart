import 'package:flutter/material.dart';
import 'package:goias_app/core/club/club_config.dart';
import 'package:goias_app/core/di/injection_container.dart';
import 'package:goias_app/core/l10n/l10n_extensions.dart';
import 'package:goias_app/core/theme/app_colors.dart';
import 'package:goias_app/core/theme/app_spacing.dart';
import 'package:goias_app/features/ticket/domain/entities/ticket_sector.dart';
import 'package:goias_app/shared/widgets/app_primary_button.dart';
import 'package:goias_app/features/ticket/domain/gate_label.dart';

/// Bottom sheet de escolha de setor — usada tanto pro primeiro check-in
/// quanto pra alterar um check-in já confirmado (mesmo componente, o
/// repositório já trata `checkIn` como idempotente/upsert).
class SectorPickerSheet extends StatefulWidget {
  const SectorPickerSheet({
    required this.sectors,
    this.initialSectorId,
    super.key,
  });

  final List<TicketSector> sectors;
  final String? initialSectorId;

  @override
  State<SectorPickerSheet> createState() => _SectorPickerSheetState();
}

class _SectorPickerSheetState extends State<SectorPickerSheet> {
  String? _selected;

  @override
  void initState() {
    super.initState();
    _selected = widget.initialSectorId;
  }

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
              context.l10n.ticketsSectorPickerTitle(
                sl<ClubConfig>().identity.code,
                sl<ClubConfig>().identity.shortName,
              ),
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
                      withGate(sector.venueLabel, sector.gate),
                      style: TextStyle(
                        fontSize: 12,
                        color: colors.textSecondary,
                      ),
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
