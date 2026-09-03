import 'package:flutter/material.dart';
import 'package:goias_app/core/di/injection_container.dart';
import 'package:goias_app/core/l10n/l10n_extensions.dart';
import 'package:goias_app/core/release/release_gate.dart';
import 'package:goias_app/core/theme/app_colors.dart';
import 'package:goias_app/shared/utils/external_link_launcher.dart';
import 'package:goias_app/shared/widgets/content_container.dart';
import 'package:goias_app/shared/widgets/state_message.dart';

/// Só é alcançada via redirect do router quando `ReleaseGate.blocked` —
/// nunca navegada diretamente. `PopScope(canPop: false)` de propósito: um
/// force-update não pode ter saída por gesto/botão físico de voltar (ver
/// spec §12, "sem botão continuar mesmo assim").
///
/// A tela sozinha NÃO é a proteção real — só reduz o quanto uma instalação
/// já atualizada o bastante pra ver este gate consegue continuar usando o
/// app. Ver docs/multiclub/36_etapa_rollout_gate_report.md §18.
class UpdateRequiredPage extends StatelessWidget {
  const UpdateRequiredPage({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final requirement = sl<ReleaseGate>().requirement;
    final storeUrl = requirement?.storeUrl;
    final hasStoreUrl = storeUrl != null && storeUrl.trim().isNotEmpty;
    final serverMessage = requirement?.message?.trim();

    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: colors.background,
        body: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: ContentWidth.form.maxWidth,
              ),
              child: StateMessage(
                icon: Icons.system_update_rounded,
                title: context.l10n.releaseGateTitle,
                message: (serverMessage != null && serverMessage.isNotEmpty)
                    ? serverMessage
                    : context.l10n.releaseGateMessage,
                actionLabel: hasStoreUrl
                    ? context.l10n.releaseGateUpdateButton
                    : null,
                onAction: hasStoreUrl
                    ? () => openExternalUrl(context, storeUrl)
                    : null,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
