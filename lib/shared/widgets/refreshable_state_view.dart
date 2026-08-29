import 'package:flutter/material.dart';
import 'package:goias_app/core/l10n/l10n_extensions.dart';
import 'package:goias_app/core/theme/app_colors.dart';
import 'package:goias_app/shared/state/load_status.dart';
import 'package:goias_app/shared/widgets/goias_loading_indicator.dart';
import 'package:goias_app/shared/widgets/state_message.dart';
import 'package:goias_app/shared/widgets/viewport_centered.dart';

/// Padroniza loading/erro/vazio/sucesso com pull-to-refresh — usado tanto
/// pela lista de partidas quanto pela classificação, em vez de cada tela
/// reimplementar o mesmo switch de estado.
class RefreshableStateView extends StatelessWidget {
  const RefreshableStateView({
    required this.status,
    required this.onRefresh,
    required this.successBuilder,
    this.errorMessage,
    this.emptyIcon = Icons.inbox_outlined,
    this.emptyTitle,
    super.key,
  });

  final LoadStatus status;
  final Future<void> Function() onRefresh;
  final WidgetBuilder successBuilder;
  final String? errorMessage;
  final IconData emptyIcon;
  final String? emptyTitle;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return RefreshIndicator(
      onRefresh: onRefresh,
      color: colors.primary,
      child: switch (status) {
        LoadStatus.initial ||
        LoadStatus.loading => viewportCentered(const GoiasLoadingIndicator()),
        LoadStatus.error => viewportCentered(
          StateMessage(
            icon: Icons.wifi_off_rounded,
            title: context.l10n.commonLoadError,
            message: errorMessage,
          ),
        ),
        LoadStatus.empty => viewportCentered(
          StateMessage(
            icon: emptyIcon,
            title: emptyTitle ?? context.l10n.commonNoDataFound,
          ),
        ),
        LoadStatus.success => successBuilder(context),
      },
    );
  }
}
