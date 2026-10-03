import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:goias_app/core/theme/app_colors.dart';
import 'package:goias_app/core/theme/app_spacing.dart';

/// Barra de abas única do app ("container refinado"): container compacto com
/// borda sutil, aba ativa com fundo suave na cor do clube, só texto, sempre
/// uma linha — sem quebra, sem reticências, sem cortar a tradução.
///
/// Tamanho da fonte: um só para o conjunto inteiro. Tenta [preferredFontSize];
/// se algum rótulo não couber, tenta com o respiro lateral reduzido e só então
/// desce a fonte (de 1 em 1 ponto) até [minFontSize] — todas as abas ficam
/// sempre com o mesmo tamanho. Se nem assim couber (ex.: idioma longo + fonte
/// do sistema grande), vira uma faixa rolável horizontalmente em tamanho
/// legível ([scrollFontSize]), nunca texto ilegível.
class FanHubTabBar extends StatefulWidget {
  const FanHubTabBar({
    required this.labels,
    required this.selectedIndex,
    required this.onChanged,
    this.padding = EdgeInsets.zero,
    super.key,
  });

  final List<String> labels;
  final int selectedIndex;
  final ValueChanged<int> onChanged;

  /// Margem externa (a barra ocupa a largura restante).
  final EdgeInsetsGeometry padding;

  static const double height = 46;
  static const double preferredFontSize = 13;
  static const double minFontSize = 10;
  static const double scrollFontSize = 12;
  static const double comfortablePadding = 12;
  static const double tightPadding = 8;
  static const Duration animationDuration = Duration(milliseconds: 180);

  @override
  State<FanHubTabBar> createState() => _FanHubTabBarState();
}

class _FanHubTabBarState extends State<FanHubTabBar> {
  final _itemKeys = <int, GlobalKey>{};
  bool _scrolling = false;

  GlobalKey _keyFor(int index) =>
      _itemKeys.putIfAbsent(index, () => GlobalKey());

  @override
  void didUpdateWidget(FanHubTabBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_scrolling && oldWidget.selectedIndex != widget.selectedIndex) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final context = _itemKeys[widget.selectedIndex]?.currentContext;
        if (context != null && context.mounted) {
          Scrollable.ensureVisible(
            context,
            duration: FanHubTabBar.animationDuration,
            alignment: 0.5,
          );
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final labels = widget.labels;
    if (labels.isEmpty) return const SizedBox.shrink();
    final textScaler = MediaQuery.textScalerOf(context);

    return Padding(
      padding: widget.padding,
      child: Container(
        height: FanHubTabBar.height,
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: BorderRadius.circular(AppRadius.button),
          border: Border.all(color: colors.border.withValues(alpha: 0.7)),
        ),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final layout = _TabLayout.resolve(
              labels: labels,
              maxWidth: constraints.maxWidth,
              textScaler: textScaler,
              textDirection: Directionality.of(context),
            );
            _scrolling = layout.scrollable;
            Widget item(int index) => _TabItem(
              key: _keyFor(index),
              label: labels[index],
              selected: index == widget.selectedIndex,
              fontSize: layout.fontSize,
              horizontalPadding: layout.padding,
              onTap: () => widget.onChanged(index),
            );

            if (layout.scrollable) {
              return SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [for (var i = 0; i < labels.length; i++) item(i)],
                ),
              );
            }
            return Row(
              children: [
                for (var i = 0; i < labels.length; i++)
                  Expanded(flex: layout.flexes[i], child: item(i)),
              ],
            );
          },
        ),
      ),
    );
  }
}

/// Decide fonte, respiro e distribuição de largura do conjunto de abas.
class _TabLayout {
  const _TabLayout({
    required this.fontSize,
    required this.padding,
    required this.flexes,
    required this.scrollable,
  });

  final double fontSize;
  final double padding;
  final List<int> flexes;
  final bool scrollable;

  static TextStyle styleFor(double fontSize) => TextStyle(
    fontSize: fontSize,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.3,
  );

  static double _textWidth(
    String label,
    double fontSize,
    TextScaler textScaler,
    TextDirection textDirection,
  ) {
    final painter = TextPainter(
      text: TextSpan(text: label, style: styleFor(fontSize)),
      textDirection: textDirection,
      textScaler: textScaler,
      maxLines: 1,
    )..layout();
    final width = painter.width;
    painter.dispose();
    return width;
  }

  static _TabLayout resolve({
    required List<String> labels,
    required double maxWidth,
    required TextScaler textScaler,
    required TextDirection textDirection,
  }) {
    // Primeiro trecho: tenta sempre o maior tamanho possível, com respiro
    // confortável e depois com respiro reduzido, antes de descer a fonte.
    var size = FanHubTabBar.preferredFontSize;
    while (size >= FanHubTabBar.minFontSize) {
      final widths = [
        for (final label in labels)
          _textWidth(label, size, textScaler, textDirection),
      ];
      for (final pad in [
        FanHubTabBar.comfortablePadding,
        FanHubTabBar.tightPadding,
      ]) {
        final natural = [for (final w in widths) w + 2 * pad];
        final total = natural.fold<double>(0, (a, b) => a + b);
        if (total <= maxWidth) {
          final equal = maxWidth / labels.length;
          final fitsEqual = natural.every((w) => w <= equal);
          return _TabLayout(
            fontSize: size,
            padding: pad,
            flexes: fitsEqual
                ? List.filled(labels.length, 1)
                : [for (final w in natural) math.max(1, w.round())],
            scrollable: false,
          );
        }
      }
      size -= 1;
    }
    return const _TabLayout(
      fontSize: FanHubTabBar.scrollFontSize,
      padding: FanHubTabBar.comfortablePadding,
      flexes: [],
      scrollable: true,
    );
  }
}

class _TabItem extends StatelessWidget {
  const _TabItem({
    required this.label,
    required this.selected,
    required this.fontSize,
    required this.horizontalPadding,
    required this.onTap,
    super.key,
  });

  final String label;
  final bool selected;
  final double fontSize;
  final double horizontalPadding;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final dark = Theme.of(context).brightness == Brightness.dark;
    final activeBackground = colors.primary.withValues(
      alpha: dark ? 0.22 : 0.12,
    );
    return Semantics(
      button: true,
      selected: selected,
      label: label,
      excludeSemantics: true,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.button - 5),
        child: AnimatedContainer(
          duration: FanHubTabBar.animationDuration,
          alignment: Alignment.center,
          padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
          decoration: BoxDecoration(
            color: selected ? activeBackground : Colors.transparent,
            borderRadius: BorderRadius.circular(AppRadius.button - 5),
          ),
          child: AnimatedDefaultTextStyle(
            duration: FanHubTabBar.animationDuration,
            style: _TabLayout.styleFor(fontSize).copyWith(
              fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
              color: selected ? colors.primary : colors.textSecondary,
            ),
            maxLines: 1,
            softWrap: false,
            overflow: TextOverflow.visible,
            child: Text(label),
          ),
        ),
      ),
    );
  }
}

/// Variante para telas que já têm um [TabController] (e `TabBarView`): o
/// controller continua sendo a fonte da verdade — aqui só muda a aparência.
class FanHubControllerTabBar extends StatefulWidget {
  const FanHubControllerTabBar({
    required this.controller,
    required this.labels,
    this.padding = EdgeInsets.zero,
    super.key,
  });

  final TabController controller;
  final List<String> labels;
  final EdgeInsetsGeometry padding;

  @override
  State<FanHubControllerTabBar> createState() => _FanHubControllerTabBarState();
}

class _FanHubControllerTabBarState extends State<FanHubControllerTabBar> {
  late int _index = widget.controller.index;

  @override
  void initState() {
    super.initState();
    widget.controller.animation?.addListener(_sync);
  }

  @override
  void didUpdateWidget(FanHubControllerTabBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller.animation?.removeListener(_sync);
      widget.controller.animation?.addListener(_sync);
      _index = widget.controller.index;
    }
  }

  @override
  void dispose() {
    widget.controller.animation?.removeListener(_sync);
    super.dispose();
  }

  void _sync() {
    final next = (widget.controller.animation?.value ?? _index).round();
    if (next != _index && mounted) setState(() => _index = next);
  }

  @override
  Widget build(BuildContext context) {
    return FanHubTabBar(
      labels: widget.labels,
      selectedIndex: _index,
      padding: widget.padding,
      onChanged: widget.controller.animateTo,
    );
  }
}
