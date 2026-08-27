import 'dart:async';

import 'package:flutter/material.dart';
import 'package:goias_app/shared/widgets/goias_loading_indicator.dart';

/// Loading global bloqueante — pro caso em que uma tela só deve navegar
/// depois que os dados essenciais dela já estão prontos (nunca abrir vazia/
/// parcial pra depois preencher). Um componente só, reutilizado por
/// qualquer feature, em vez de um loader inventado por tela.
///
/// Uso típico num handler de tap:
/// ```dart
/// final data = await GlobalLoading.run(context, () => repository.load());
/// if (!context.mounted) return;
/// context.push('/destino', extra: data);
/// ```
class GlobalLoading {
  const GlobalLoading._();

  static bool _active = false;

  /// Espera ~130ms antes de mostrar o overlay (evita flash visual em
  /// operações rápidas) — se [action] já tiver terminado antes disso, o
  /// overlay nunca chega a aparecer. Ignora chamadas concorrentes (um
  /// segundo tap enquanto já está carregando só aguarda a mesma operação,
  /// nunca dispara duas). Remove o overlay sempre — sucesso, erro tratado
  /// ou exceção — via `finally`, então nunca fica preso na tela.
  static Future<T> run<T>(
    BuildContext context,
    Future<T> Function() action,
  ) async {
    if (_active) return action();
    _active = true;

    OverlayEntry? entry;
    final showTimer = Timer(const Duration(milliseconds: 130), () {
      entry = OverlayEntry(builder: (_) => const _GlobalLoadingScrim());
      Overlay.of(context, rootOverlay: true).insert(entry!);
    });

    try {
      return await action();
    } finally {
      showTimer.cancel();
      entry?.remove();
      _active = false;
    }
  }
}

class _GlobalLoadingScrim extends StatelessWidget {
  const _GlobalLoadingScrim();

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: GestureDetector(
        // Absorve todo toque — nada da tela de trás deve reagir.
        behavior: HitTestBehavior.opaque,
        onTap: () {},
        child: ColoredBox(
          // Mais escuro que um scrim comum de propósito — o fundo precisa
          // recuar bastante pra o brasão pulsando ficar em evidência, não
          // só uma sombra fraca por cima da tela (feedback: ficava "apagado").
          color: Colors.black.withValues(alpha: 0.68),
          // Branco aqui (não o verde padrão) — o fundo é sempre escuro
          // nesse overlay, então branco é quem garante contraste; o verde
          // é pro caso comum, sobre fundo claro (ver `GoiasLoadingBadge`).
          child: const Center(
            child: GoiasLoadingIndicator(size: 48, color: Colors.white),
          ),
        ),
      ),
    );
  }
}
