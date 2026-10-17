import 'package:flutter/material.dart';
import 'package:goias_app/core/di/injection_container.dart';
import 'package:goias_app/core/network/offline_snapshot_interceptor.dart';
import 'package:goias_app/shared/widgets/saved_content_banner.dart';

/// Mostra o aviso "conteúdo salvo em <data>" enquanto a última resposta de
/// [category] (Home/Jogos/Mídia) veio do aparelho em vez do servidor.
/// Some sozinho assim que uma consulta nova chega fresca.
class StaleDataBanner extends StatelessWidget {
  const StaleDataBanner(this.category, {this.status, super.key});

  final SnapshotCategory category;

  /// Só para teste; em produção vem do service locator.
  final OfflineSnapshotStatus? status;

  @override
  Widget build(BuildContext context) {
    if (status == null && !sl.isRegistered<OfflineSnapshotStatus>()) {
      return const SizedBox.shrink();
    }
    final source = status ?? sl<OfflineSnapshotStatus>();
    return ListenableBuilder(
      listenable: source,
      builder: (context, _) {
        final savedAt = source.savedAt(category);
        if (savedAt == null) return const SizedBox.shrink();
        return SavedContentBanner(savedAt: savedAt);
      },
    );
  }
}
