import 'package:flutter/material.dart';
import 'package:goias_app/core/theme/app_colors.dart';
import 'package:goias_app/shared/state/load_status.dart';
import 'package:goias_app/shared/widgets/state_message.dart';

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
    this.emptyTitle = 'Nenhum dado encontrado.',
    super.key,
  });

  final LoadStatus status;
  final Future<void> Function() onRefresh;
  final WidgetBuilder successBuilder;
  final String? errorMessage;
  final IconData emptyIcon;
  final String emptyTitle;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return RefreshIndicator(
      onRefresh: onRefresh,
      color: colors.primary,
      child: switch (status) {
        LoadStatus.initial || LoadStatus.loading => _centered(
          CircularProgressIndicator(color: colors.primary),
        ),
        LoadStatus.error => _centered(
          StateMessage(
            icon: Icons.wifi_off_rounded,
            title: 'Não foi possível carregar os dados',
            message: errorMessage,
          ),
        ),
        LoadStatus.empty => _centered(StateMessage(icon: emptyIcon, title: emptyTitle)),
        LoadStatus.success => successBuilder(context),
      },
    );
  }

  Widget _centered(Widget child) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        Padding(padding: const EdgeInsets.only(top: 100), child: Center(child: child)),
      ],
    );
  }
}
