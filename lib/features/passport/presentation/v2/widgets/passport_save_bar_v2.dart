import 'package:flutter/material.dart';
import 'package:goias_app/core/l10n/l10n_extensions.dart';
import 'package:goias_app/core/theme/app_colors.dart';
import 'package:goias_app/core/theme/app_spacing.dart';
import 'package:goias_app/features/passport/presentation/cubit/passport_state.dart';
import 'package:goias_app/shared/state/load_status.dart';
import 'package:goias_app/shared/widgets/app_primary_button.dart';

/// Barra de salvar — recolhida (altura zero) quando não há mudança
/// pendente, nunca um botão gigante permanentemente visível. Some/aparece
/// com uma transição curta, não some/aparece abruptamente como a V1.
class PassportSaveBarV2 extends StatelessWidget {
  const PassportSaveBarV2({required this.state, required this.onSave, super.key});

  final PassportState state;
  final VoidCallback onSave;

  @override
  Widget build(BuildContext context) {
    final visible =
        state.hasUnsavedChanges || state.saveStatus == LoadStatus.loading;
    final colors = context.colors;
    final l10n = context.l10n;
    final onlyAdditions = state.pendingChanges.values.every((v) => v);
    final label = onlyAdditions
        ? l10n.passportSaveCountLabel(state.pendingChangeCount)
        : l10n.passportSaveGenericLabel;

    return ClipRect(
      child: AnimatedAlign(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
        alignment: Alignment.topCenter,
        heightFactor: visible ? 1 : 0,
        child: AnimatedOpacity(
          duration: const Duration(milliseconds: 180),
          opacity: visible ? 1 : 0,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: colors.surface,
              border: Border(top: BorderSide(color: colors.border)),
            ),
            child: SafeArea(
              top: false,
              minimum: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                AppSpacing.sm,
                AppSpacing.lg,
                AppSpacing.sm,
              ),
              child: AppPrimaryButton(
                label: label,
                loading: state.saveStatus == LoadStatus.loading,
                onPressed: state.saveStatus == LoadStatus.loading ? null : onSave,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
