import 'package:flutter/material.dart';

/// Finalidade da página — decide a largura máxima do conteúdo no desktop.
/// Nunca escolha um número direto numa tela: escolha a categoria que
/// descreve o que a tela É, e a largura vem daqui.
enum ContentWidth {
  /// Quiz, autenticação, cadastro, formulários — coluna estreita,
  /// confortável de ler e preencher.
  form,

  /// Leitura/detalhe comum — texto corrido, letra de música, artigo, resumo
  /// de pedido, detalhe de partida.
  detail,

  /// Jogos visuais, escalação, experiências interativas — mais espaço que
  /// um detalhe comum, mas sem esticar até a largura de uma listagem.
  interactive,

  /// Home, Arena, rankings, listagens e páginas com grid — se beneficia de
  /// mais largura pra mostrar mais itens por vez sem virar uma coluna
  /// estreita de celular esticada.
  wide,
}

extension ContentWidthX on ContentWidth {
  double get maxWidth => switch (this) {
    ContentWidth.form => 680,
    ContentWidth.detail => 880,
    ContentWidth.interactive => 960,
    ContentWidth.wide => 1240,
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
    this.width = ContentWidth.detail,
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
