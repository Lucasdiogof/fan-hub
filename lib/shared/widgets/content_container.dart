import 'package:flutter/material.dart';

/// Finalidade da página — decide a largura máxima do conteúdo no desktop.
/// Nunca escolha um número direto numa tela: escolha a categoria que
/// descreve o que a tela É, e a largura vem daqui.
enum ContentWidth {
  /// Login, cadastro, formulários — coluna estreita, confortável de ler e
  /// preencher.
  form,

  /// Leitura/detalhe — texto corrido, letra de música, artigo, resumo de
  /// pedido, detalhe de partida.
  reading,

  /// Listas, ranking, histórico, catálogos — se beneficia de mais largura
  /// pra mostrar mais itens por vez sem virar uma coluna estreita de
  /// celular esticada.
  list,

  /// Dashboards com vários cards independentes (ex.: Home).
  dashboard,

  /// Telas que se beneficiam da largura total (ex.: o campo de um
  /// mini-game) — ainda ganha um teto generoso pra nunca esticar sem fim
  /// num monitor ultrawide.
  full,
}

extension ContentWidthX on ContentWidth {
  double get maxWidth => switch (this) {
    ContentWidth.form => 640,
    ContentWidth.reading => 840,
    ContentWidth.list => 1080,
    ContentWidth.dashboard => 1320,
    ContentWidth.full => 1600,
  };
}

/// Substitui o antigo `Center(child: ConstrainedBox(maxWidth: 720))`
/// espalhado tela por tela — mesma ideia, mas a largura vem de
/// [ContentWidth] em vez de um número fixo repetido. No celular (largura
/// disponível abaixo do teto) isto é um no-op visual: o conteúdo já ocupa
/// tudo, então o comportamento mobile atual não muda em nada.
///
/// Fica de fora de propósito qualquer padding lateral extra — cada tela já
/// define o próprio `Padding` interno (tunado pro mobile); duplicar isso
/// aqui só dobraria a margem em telas largas. O que este widget garante é
/// só o teto de largura + centralização, que já cria a margem lateral
/// "de graça" assim que o conteúdo bate no teto.
class ContentContainer extends StatelessWidget {
  const ContentContainer({
    required this.child,
    this.width = ContentWidth.reading,
    this.alignment = Alignment.center,
    super.key,
  });

  final Widget child;
  final ContentWidth width;
  final AlignmentGeometry alignment;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: alignment,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: width.maxWidth),
        child: child,
      ),
    );
  }
}
