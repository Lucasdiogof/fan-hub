import 'dart:async';

import 'package:flutter/material.dart';
import 'package:goias_app/core/theme/app_colors.dart';
import 'package:goias_app/core/theme/app_spacing.dart';

const _autoplayInterval = Duration(seconds: 5);
const _pageTransitionDuration = Duration(milliseconds: 350);

/// Todos os banners de um mesmo clube compartilham a mesma proporção (ver
/// `ClubAssets.storeHomeBanners`) — usada só pra dar altura ao `PageView`
/// quando há carousel (>1 banner). Não afeta o modo de banner único, que
/// continua se auto-dimensionando pela imagem como sempre (ver
/// `_BannerImage`).
const _carouselAspectRatio = 1920 / 826;

/// Banner de topo da Loja — genérico por clube, decide sozinho pela
/// quantidade de imagens em [banners] (nunca por `if (club == ...)` aqui
/// dentro): 0 = nada; 1 = imagem fixa, sem `PageView`/`Timer`/dots
/// (comportamento idêntico ao banner único de sempre); >1 = carousel com
/// autoplay de 5s e dots. Quem decide QUANTOS banners cada clube tem é
/// `ClubAssets.storeHomeBanners`, nunca este widget.
class StoreBannerCarousel extends StatefulWidget {
  const StoreBannerCarousel({super.key, required this.banners, this.onTap});

  final List<String> banners;
  final VoidCallback? onTap;

  @override
  State<StoreBannerCarousel> createState() => _StoreBannerCarouselState();
}

class _StoreBannerCarouselState extends State<StoreBannerCarousel> {
  PageController? _controller;
  Timer? _autoplayTimer;
  int _currentIndex = 0;

  bool get _isCarousel => widget.banners.length > 1;

  @override
  void initState() {
    super.initState();
    _setUp();
  }

  @override
  void didUpdateWidget(covariant StoreBannerCarousel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_sameBanners(oldWidget.banners, widget.banners)) {
      _tearDown();
      _currentIndex = 0;
      _setUp();
    }
  }

  @override
  void dispose() {
    _tearDown();
    super.dispose();
  }

  bool _sameBanners(List<String> a, List<String> b) {
    if (identical(a, b)) return true;
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  void _setUp() {
    if (!_isCarousel) return;
    _controller = PageController();
    _autoplayTimer = Timer.periodic(_autoplayInterval, (_) => _advance());
  }

  void _tearDown() {
    _autoplayTimer?.cancel();
    _autoplayTimer = null;
    _controller?.dispose();
    _controller = null;
  }

  void _advance() {
    final controller = _controller;
    if (!mounted || controller == null || !controller.hasClients) return;
    final next = (_currentIndex + 1) % widget.banners.length;
    unawaited(
      controller.animateToPage(
        next,
        duration: _pageTransitionDuration,
        curve: Curves.easeInOut,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final banners = widget.banners;
    if (banners.isEmpty) return const SizedBox.shrink();

    if (!_isCarousel) {
      return _BannerImage(asset: banners.first, onTap: widget.onTap);
    }

    final colors = context.colors;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        AspectRatio(
          aspectRatio: _carouselAspectRatio,
          child: PageView.builder(
            controller: _controller,
            itemCount: banners.length,
            onPageChanged: (i) => setState(() => _currentIndex = i),
            itemBuilder: (context, i) => _BannerImage(
              asset: banners[i],
              onTap: widget.onTap,
              fit: BoxFit.cover,
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        ExcludeSemantics(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              for (var i = 0; i < banners.length; i++)
                Container(
                  key: ValueKey('store_banner_dot_$i'),
                  width: i == _currentIndex ? 18 : 6,
                  height: 6,
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  decoration: BoxDecoration(
                    color: i == _currentIndex ? colors.primary : colors.border,
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _BannerImage extends StatelessWidget {
  const _BannerImage({required this.asset, this.onTap, this.fit});

  final String asset;
  final VoidCallback? onTap;

  /// `null` no modo de banner único preserva o auto-dimensionamento por
  /// `BoxFit.fitWidth` + `width: double.infinity` de sempre (a imagem
  /// define a própria altura). No modo carousel a altura já vem fixa do
  /// `AspectRatio` do pai, então usa `BoxFit.cover` pra preencher sem
  /// distorcer.
  final BoxFit? fit;

  @override
  Widget build(BuildContext context) {
    final image = fit == null
        ? Image.asset(asset, width: double.infinity, fit: BoxFit.fitWidth)
        : Image.asset(asset, fit: fit, width: double.infinity);
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(AppRadius.banner),
      clipBehavior: Clip.antiAlias,
      child: InkWell(onTap: onTap, child: image),
    );
  }
}
