import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:goias_app/core/theme/app_colors.dart';
import 'package:goias_app/core/theme/app_spacing.dart';

bool _isNetworkUrl(String value) =>
    value.startsWith('http://') || value.startsWith('https://');

/// A MESMA foto do jogador secreto, do início ao fim da rodada — só o
/// sigma do blur muda (animado suavemente entre níveis). Nunca troca de
/// asset. [imageUrl] pode ser um asset local (Goiás) ou uma URL remota do
/// CDN oficial do clube (Bragantino) — mesmo padrão já usado em
/// `PartnerCard`/`SquadAvatar`.
class GuessBlurredPhoto extends StatefulWidget {
  const GuessBlurredPhoto({
    required this.imageUrl,
    required this.sigma,
    super.key,
  });

  final String imageUrl;
  final double sigma;

  @override
  State<GuessBlurredPhoto> createState() => _GuessBlurredPhotoState();
}

class _GuessBlurredPhotoState extends State<GuessBlurredPhoto>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late Animation<double> _sigmaAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 450),
    );
    _sigmaAnimation = AlwaysStoppedAnimation(widget.sigma);
  }

  @override
  void didUpdateWidget(GuessBlurredPhoto oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.imageUrl != widget.imageUrl) {
      // Foto de outro jogador — pula direto pro sigma novo (sem tween a
      // partir do valor baixo/revelado do jogador anterior, senão dá pra
      // ver o rosto do próximo por um instante antes do blur "alcançar").
      _controller.stop();
      _sigmaAnimation = AlwaysStoppedAnimation(widget.sigma);
      return;
    }
    if (oldWidget.sigma != widget.sigma) {
      _sigmaAnimation =
          Tween<double>(
            begin: _sigmaAnimation.value,
            end: widget.sigma,
          ).animate(
            CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
          );
      _controller.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return AspectRatio(
      aspectRatio: 1,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppRadius.hero),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: colors.surface,
            border: Border.all(color: colors.border),
          ),
          child: AnimatedBuilder(
            animation: _sigmaAnimation,
            child: _isNetworkUrl(widget.imageUrl)
                ? Image.network(
                    widget.imageUrl,
                    fit: BoxFit.cover,
                    alignment: const Alignment(0, -0.85),
                    width: double.infinity,
                    height: double.infinity,
                  )
                : Image.asset(
                    widget.imageUrl,
                    fit: BoxFit.cover,
                    alignment: const Alignment(0, -0.85),
                    width: double.infinity,
                    height: double.infinity,
                  ),
            builder: (context, child) {
              final sigma = _sigmaAnimation.value;
              return ImageFiltered(
                imageFilter: ImageFilter.blur(
                  sigmaX: sigma,
                  sigmaY: sigma,
                  tileMode: TileMode.decal,
                ),
                child: child,
              );
            },
          ),
        ),
      ),
    );
  }
}
