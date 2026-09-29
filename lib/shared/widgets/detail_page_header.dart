import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:goias_app/core/theme/app_colors.dart';
import 'package:goias_app/core/theme/app_spacing.dart';
import 'package:goias_app/shared/widgets/content_container.dart';

/// Cabeçalho padrão de tela FILHA (não raiz de seção — isso é `PageTitle`,
/// com o traço verde + escudo). Nunca usa traço/escudo/título grande fixo:
/// só comunica "isto é uma tela interna, dá pra voltar".
///
/// No topo, mostra só o botão de voltar sobre um fundo praticamente
/// transparente — [heroTitle] (o título grande de verdade) mora dentro do
/// conteúdo rolável, não aqui. Conforme a página rola e [heroTitle] sai da
/// tela, a barra ganha superfície translúcida + blur sutil e o [title]
/// (versão curta/inline) migra pra dentro dela — ao voltar pro topo, some
/// de novo. Nunca `scrollOffset > 100` solto pela tela: a barra observa a
/// posição REAL de [heroTitle] (mesma técnica do `CompactMatchHeader` da
/// Home — `GlobalKey` + `RenderBox.localToGlobal`), o fundo reage aos
/// primeiros ~60px de scroll (extensão explícita pedida, não um número
/// arbitrário reaproveitado de outro lugar).
class DetailPageHeader extends StatefulWidget {
  const DetailPageHeader({
    required this.title,
    required this.heroTitle,
    required this.body,
    this.onBack,
    this.actions,
    this.padding,
    this.maxWidth = ContentWidth.wide,
    this.showBackButton = true,
    super.key,
  });

  /// Título curto mostrado na barra só depois que [heroTitle] sai da tela.
  final String title;

  /// O título grande de verdade — vive no topo do conteúdo rolável, nunca
  /// na barra.
  final Widget heroTitle;

  /// Resto do conteúdo, abaixo de [heroTitle], dentro do mesmo scroll.
  final Widget body;

  final VoidCallback? onBack;
  final List<Widget>? actions;

  /// Padding horizontal/inferior do conteúdo rolável — o espaço reservado
  /// pra barra no topo já é somado por dentro, não precisa incluir aqui.
  final EdgeInsetsGeometry? padding;

  /// Largura máxima do conteúdo (rolável e da barra) — `wide` (1240) por
  /// padrão, igual às 2 primeiras migrações. Telas de formulário (senha,
  /// dados pessoais, endereço) devem passar `ContentWidth.form` (680),
  /// senão o formulário esticaria até 1240px em tablet/web/desktop.
  final ContentWidth maxWidth;

  /// `false` quando esta tela é a raiz de uma aba da bottom nav (nunca tem
  /// pra onde voltar) — esconde o botão, mantendo o espaço reservado pra
  /// não deslocar o título.
  final bool showBackButton;

  @override
  State<DetailPageHeader> createState() => _DetailPageHeaderState();
}

class _DetailPageHeaderState extends State<DetailPageHeader> {
  static const _barHeight = 52.0;
  static const _fadeDistance = 60.0;

  final _heroKey = GlobalKey();
  final _scrollController = ScrollController();
  bool _titleVisible = false;
  double _scrollT = 0;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => _updateTitleVisibility(),
    );
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    final t = (_scrollController.offset / _fadeDistance).clamp(0.0, 1.0);
    if (t != _scrollT) setState(() => _scrollT = t);
    _updateTitleVisibility();
  }

  void _updateTitleVisibility() {
    if (!mounted) return;
    final renderObject = _heroKey.currentContext?.findRenderObject();
    if (renderObject is! RenderBox || !renderObject.attached) return;
    final topInset = MediaQuery.paddingOf(context).top + _barHeight;
    final heroBottom = renderObject
        .localToGlobal(Offset(0, renderObject.size.height))
        .dy;
    final visible = heroBottom <= topInset;
    if (visible != _titleVisible) setState(() => _titleVisible = visible);
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final topInset = MediaQuery.paddingOf(context).top;

    return Stack(
      children: [
        Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: widget.maxWidth.maxWidth),
            child: SingleChildScrollView(
              controller: _scrollController,
              // Sempre "arrastável", mesmo com conteúdo mais curto que a
              // viewport — necessário pra telas que envolvem isto num
              // `RefreshIndicator` (ver `tickets_page.dart`) conseguirem
              // detectar o gesto de puxar mesmo com poucos itens.
              physics: const AlwaysScrollableScrollPhysics(),
              padding:
                  (widget.padding ??
                          const EdgeInsets.fromLTRB(
                            AppSpacing.lg,
                            0,
                            AppSpacing.lg,
                            AppSpacing.xxxl,
                          ))
                      .add(
                        EdgeInsets.only(
                          top: topInset + _barHeight + AppSpacing.sm,
                        ),
                      ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  KeyedSubtree(key: _heroKey, child: widget.heroTitle),
                  widget.body,
                ],
              ),
            ),
          ),
        ),
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: _Bar(
            title: widget.title,
            onBack: widget.onBack ??
                () => context.canPop() ? context.pop() : context.go('/'),
            actions: widget.actions,
            showTitle: _titleVisible,
            showBackButton: widget.showBackButton,
            surfaceT: _scrollT,
            barHeight: _barHeight,
            topInset: topInset,
            colors: colors,
            maxWidth: widget.maxWidth,
          ),
        ),
      ],
    );
  }
}

class _Bar extends StatelessWidget {
  const _Bar({
    required this.title,
    required this.onBack,
    required this.actions,
    required this.showTitle,
    required this.showBackButton,
    required this.surfaceT,
    required this.barHeight,
    required this.topInset,
    required this.colors,
    required this.maxWidth,
  });

  final String title;
  final VoidCallback onBack;
  final List<Widget>? actions;
  final bool showTitle;
  final bool showBackButton;
  final double surfaceT;
  final double barHeight;
  final double topInset;
  final AppColors colors;
  final ContentWidth maxWidth;

  @override
  Widget build(BuildContext context) {
    // 0 no topo (praticamente transparente) até ~0.85 de opacidade no fim
    // da faixa de transição — nunca 100% opaco, pra continuar parecendo uma
    // faixa e não um bloco sólido.
    final surfaceOpacity = surfaceT * 0.85;
    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: surfaceT * 6, sigmaY: surfaceT * 6),
        child: Container(
          height: topInset + barHeight,
          padding: EdgeInsets.only(top: topInset),
          decoration: BoxDecoration(
            color: colors.surface.withValues(alpha: surfaceOpacity),
            border: Border(
              bottom: BorderSide(
                color: colors.border.withValues(alpha: surfaceT),
              ),
            ),
          ),
          child: Align(
            alignment: Alignment.topCenter,
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: maxWidth.maxWidth),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                child: Row(
                  children: [
                    showBackButton
                        ? _BackButton(onTap: onBack, colors: colors)
                        : const SizedBox(width: 42),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: AnimatedOpacity(
                        duration: const Duration(milliseconds: 180),
                        opacity: showTitle ? 1 : 0,
                        child: AnimatedSlide(
                          duration: const Duration(milliseconds: 180),
                          curve: Curves.easeOut,
                          offset: showTitle
                              ? Offset.zero
                              : const Offset(0, 0.2),
                          child: Text(
                            title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                              color: colors.textPrimary,
                            ),
                          ),
                        ),
                      ),
                    ),
                    ...?actions,
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Botão de voltar discreto — 42x42, menor que o `BackButtonCircle` padrão
/// (38, na prática já pequeno; a versão usada aqui mira a faixa 42-46
/// pedida especificamente pra este componente, sem mudar o padrão global).
class _BackButton extends StatelessWidget {
  const _BackButton({required this.onTap, required this.colors});

  final VoidCallback onTap;
  final AppColors colors;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: colors.surfaceRaised,
      shape: const CircleBorder(),
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: SizedBox(
          width: 42,
          height: 42,
          child: Icon(
            Icons.arrow_back_rounded,
            size: 19,
            color: colors.textPrimary,
          ),
        ),
      ),
    );
  }
}
