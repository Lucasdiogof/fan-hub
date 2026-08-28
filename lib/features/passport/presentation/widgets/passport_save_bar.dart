import 'package:flutter/material.dart';
import 'package:goias_app/core/l10n/l10n_extensions.dart';
import 'package:goias_app/core/theme/app_colors.dart';
import 'package:goias_app/core/theme/app_spacing.dart';
import 'package:goias_app/features/passport/presentation/cubit/passport_state.dart';
import 'package:goias_app/shared/state/load_status.dart';
import 'package:goias_app/shared/widgets/app_primary_button.dart';

/// Barra fixa embaixo — só aparece quando há alteração pendente. Nunca uma
/// requisição por checkbox: o botão dispara `cubit.save()` uma vez só, com
/// todo o delta acumulado.
class PassportSaveBar extends StatelessWidget {
  const PassportSaveBar({
    required this.state,
    required this.onSave,
    super.key,
  });

  final PassportState state;
  final VoidCallback onSave;

  @override
  Widget build(BuildContext context) {
    if (!state.hasUnsavedChanges && state.saveStatus != LoadStatus.loading) {
      return const SizedBox.shrink();
    }
    final colors = context.colors;
    final l10n = context.l10n;
    final onlyAdditions = state.pendingChanges.values.every((v) => v);
    final label = onlyAdditions
        ? l10n.passportSaveCountLabel(state.pendingChangeCount)
        : l10n.passportSaveGenericLabel;

    return DecoratedBox(
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
    );
  }
}
