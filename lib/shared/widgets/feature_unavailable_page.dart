import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:goias_app/core/l10n/l10n_extensions.dart';
import 'package:goias_app/core/theme/app_colors.dart';
import 'package:goias_app/core/theme/app_spacing.dart';
import 'package:goias_app/shared/widgets/back_button_circle.dart';
import 'package:goias_app/shared/widgets/state_message.dart';
import 'package:goias_app/shared/widgets/content_container.dart';

/// Destino genérico de rota bloqueada por `ClubCapabilities` — M4.2A.
/// Diferente de [ComingSoonPage] (que promete "em breve NESTE clube"), esta
/// tela nunca promete nada: a feature simplesmente não existe pra esse
/// clube, sem prazo. Nunca recebe dado nenhum do clube ativo — não é a
/// tela de erro de uma feature real, é o destino de quem tentou abrir uma
/// rota/deep-link gateada (`capabilityGateRedirect`), então o corpo é
/// 100% genérico de propósito.
class FeatureUnavailablePage extends StatelessWidget {
  const FeatureUnavailablePage({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final l10n = context.l10n;
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
                  Expanded(
                    child: Center(
                      child: StateMessage(
                        icon: Icons.block_rounded,
                        title: l10n.featureUnavailableTitle,
                        message: l10n.featureUnavailableMessage,
                      ),
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
