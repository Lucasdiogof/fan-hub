import 'package:flutter/material.dart';

/// Classe de tamanho de tela — mesmo vocabulário das "window size classes"
/// do Material 3, adaptado aos 4 níveis que este app precisa distinguir.
enum AppScreenSize {
  /// < 600 — celular na vertical (o app inteiro foi desenhado pra isso
  /// originalmente; layout aqui NUNCA muda).
  compact,

  /// 600–839 — celular deitado / tablet pequeno.
  medium,

  /// 840–1199 — tablet grande / janela de desktop "normal".
  expanded,

  /// >= 1200 — desktop largo / monitor grande.
  large,
}

/// Breakpoints centralizados — única fonte de verdade pra "número mágico
/// de largura" no app inteiro. Qualquer decisão de layout por tamanho de
/// tela passa por aqui, nunca por um valor solto numa tela específica.
class AppBreakpoints {
  const AppBreakpoints._();

  static const compact = 600.0;
  static const medium = 840.0;
  static const expanded = 1200.0;

  static AppScreenSize sizeFor(double width) {
    if (width < compact) return AppScreenSize.compact;
    if (width < medium) return AppScreenSize.medium;
    if (width < expanded) return AppScreenSize.expanded;
    return AppScreenSize.large;
  }
}

/// Pra decisões que dependem da JANELA/dispositivo como um todo (ex.: usar
/// `NavigationRail` em vez de bottom nav) — usa `MediaQuery`, de propósito,
/// porque não há um `LayoutBuilder` local fazendo sentido pra essa escolha
/// (é uma decisão do shell do app, não de um componente dentro de uma
/// coluna). Componentes que decidem seu PRÓPRIO layout a partir do espaço
/// que receberam devem usar `LayoutBuilder`/`constraints.maxWidth` em vez
/// desta extension — ver `ContentContainer`/`ResponsiveGrid`.
extension AppScreenSizeX on BuildContext {
  AppScreenSize get screenSize =>
      AppBreakpoints.sizeFor(MediaQuery.sizeOf(this).width);

  bool get isCompactScreen => screenSize == AppScreenSize.compact;
  bool get isMediumScreen => screenSize == AppScreenSize.medium;
  bool get isExpandedScreen => screenSize == AppScreenSize.expanded;
  bool get isLargeScreen => screenSize == AppScreenSize.large;

  /// Tablet pra cima (idêntico ao "não é mais um celular estreito").
  bool get isAtLeastMedium => screenSize != AppScreenSize.compact;

  /// Desktop pra cima — ponto de corte usado pra trocar bottom nav por
  /// `NavigationRail`, converter bottom sheet em `Dialog`, etc.
  bool get isAtLeastExpanded =>
      screenSize == AppScreenSize.expanded || screenSize == AppScreenSize.large;
}

/// Quantas colunas um grid deveria ter dado o espaço DISPONÍVEL (não a tela
/// inteira) — pensado pra ser chamado com `constraints.maxWidth` de dentro
/// de um `LayoutBuilder`, não com a largura da janela. `itemWidth` é a
/// largura confortável de um item; o resultado nunca passa de [maxColumns]
/// nem fica abaixo de [minColumns] — sem um piso, uma tela de celular mais
/// estreita que `itemWidth` cai pra 1 coluna e estica o card inteiro, que já
/// foi um bug real aqui (ver Arena).
int responsiveColumnCount(
  double availableWidth, {
  double itemWidth = 220,
  int minColumns = 1,
  int maxColumns = 4,
}) {
  final columns = (availableWidth / itemWidth).floor();
  return columns.clamp(minColumns, maxColumns);
}
