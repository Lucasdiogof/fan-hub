import 'dart:async';

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
///
/// Depois de salvar com sucesso, o botão mostra "Salvo" com um check por
/// um instante antes de recolher — nunca um SnackBar cinza por baixo (ver
/// `PassportPageV2`, que só trata erro por SnackBar; sucesso mora aqui).
class PassportSaveBarV2 extends StatefulWidget {
  const PassportSaveBarV2({
    required this.state,
    required this.onSave,
    super.key,
  });

  final PassportState state;
  final VoidCallback onSave;

  @override
  State<PassportSaveBarV2> createState() => _PassportSaveBarV2State();
}

class _PassportSaveBarV2State extends State<PassportSaveBarV2> {
  bool _showSuccess = false;
  Timer? _successTimer;

  @override
  void didUpdateWidget(covariant PassportSaveBarV2 oldWidget) {
    super.didUpdateWidget(oldWidget);
    final justSucceeded =
        oldWidget.state.saveStatus != LoadStatus.success &&
        widget.state.saveStatus == LoadStatus.success;
    if (!justSucceeded) return;
    setState(() => _showSuccess = true);
    _successTimer?.cancel();
    _successTimer = Timer(const Duration(milliseconds: 1400), () {
      if (mounted) setState(() => _showSuccess = false);
    });
  }

  @override
  void dispose() {
    _successTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = widget.state;
    final loading = state.saveStatus == LoadStatus.loading;
    final visible = state.hasUnsavedChanges || loading || _showSuccess;
    final colors = context.colors;
    final l10n = context.l10n;
    final onlyAdditions = state.pendingChanges.values.every((v) => v);
    final label = _showSuccess
        ? l10n.passportSaveSuccess
        : onlyAdditions
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
                icon: _showSuccess ? Icons.check_circle_rounded : null,
                loading: loading,
                onPressed: (loading || _showSuccess) ? null : widget.onSave,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
