import 'package:flutter/material.dart';

/// Centraliza [child] de verdade dentro da altura visível de um
/// `RefreshIndicator`/scroll — não um `Center` solto dentro de um
/// `ListView` (que só centraliza dentro da altura do próprio conteúdo,
/// ou seja, não faz nada; o resultado antes disso era um `top: 100` fixo
/// empurrando o brasão de loading pro topo da tela, não pro meio dela).
/// `LayoutBuilder` dá a altura real do viewport pro `SizedBox` preencher,
/// e o `ListView` continua ali por fora só pra manter o gesto de
/// pull-to-refresh funcionando mesmo em loading/erro/vazio.
Widget viewportCentered(Widget child) {
  return LayoutBuilder(
    builder: (context, constraints) => ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        SizedBox(
          height: constraints.maxHeight,
          child: Center(child: child),
        ),
      ],
    ),
  );
}
