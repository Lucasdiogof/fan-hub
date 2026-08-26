import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:goias_app/core/l10n/l10n_extensions.dart';
import 'package:goias_app/core/theme/app_colors.dart';
import 'package:goias_app/core/theme/app_spacing.dart';
import 'package:goias_app/features/arena/domain/arena_game.dart';
import 'package:goias_app/features/arena/shared/arena_colors.dart';
import 'package:goias_app/features/arena/shared/arena_game_l10n.dart';

/// `progress` é opcional de propósito — só os jogos com progressão
/// persistente (Quiz, Adivinhe a Escalação, Adivinhe o Jogador) passam um
/// valor; os demais (recorde solto ou sem sistema de progresso ainda)
/// simplesmente não mostram a barra.
class ArenaFeaturedCard extends StatelessWidget {
  const ArenaFeaturedCard({
    required this.game,
    required this.onTap,
    this.progress,
    super.key,
  });

  final ArenaGame game;
  final VoidCallback onTap;
  final ({int completed, int total})? progress;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(AppRadius.card),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.card),
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.xl),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadius.card),
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [ArenaColors.goiasOutfield, ArenaColors.arenaBottom],
            ),
            border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(AppRadius.cardSmall),
                    ),
                    child: Icon(game.icon, color: Colors.white, size: 24),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Text(
                      arenaGameTitle(context.l10n, game.id).toUpperCase(),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                arenaGameTagline(context.l10n, game.id),
                style: TextStyle(
                  fontSize: 13.5,
                  height: 1.35,
                  color: Colors.white.withValues(alpha: 0.85),
                ),
              ),
              if (progress != null) ...[
                const SizedBox(height: AppSpacing.md),
                _ProgressBar(
                  progress: progress!,
                  trackColor: Colors.white.withValues(alpha: 0.18),
                  fillColor: Colors.white,
                ),
              ],
              const SizedBox(height: AppSpacing.lg),
              Align(
                alignment: Alignment.centerRight,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.lg,
                    vertical: AppSpacing.sm,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        context.l10n.arenaPlay,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w900,
                          color: ArenaColors.goiasOutfield,
                        ),
                      ),
                      const SizedBox(width: 6),
                      const Icon(
                        Icons.arrow_forward_rounded,
                        size: 16,
                        color: ArenaColors.goiasOutfield,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Card compacto da grade da Arena — estrutura fixa (ícone → título →
/// subtítulo opcional → rodapé sempre colado embaixo, via `Spacer`) pra
/// todos os jogos ficarem visualmente consistentes entre si, com ou sem
/// progresso. `footer` é livre de propósito (barra de progresso pros jogos
/// de coleção finita, texto de desempenho pros que não são) — um único
/// componente configurável em vez de um card por tipo de jogo.
class ArenaCompactCard extends StatelessWidget {
  const ArenaCompactCard({
    required this.game,
    required this.onTap,
    this.subtitle,
    this.footer,
    this.badge,
    this.decorativeBackground,
    super.key,
  });

  final ArenaGame game;
  final VoidCallback onTap;
  final String? subtitle;
  final Widget? footer;
  final String? badge;
  final Widget? decorativeBackground;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Material(
      color: colors.surface,
      borderRadius: BorderRadius.circular(AppRadius.card),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            border: Border.all(color: colors.border),
            borderRadius: BorderRadius.circular(AppRadius.card),
          ),
          child: Stack(
            children: [
              if (decorativeBackground != null)
                Positioned(
                  right: -14,
                  bottom: -14,
                  child: decorativeBackground!,
                ),
              Padding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: colors.secondary,
                        borderRadius: BorderRadius.circular(
                          AppRadius.cardSmall,
                        ),
                      ),
                      child: Icon(game.icon, color: colors.primary, size: 22),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      arenaGameTitle(context.l10n, game.id),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: colors.textPrimary,
                        height: 1.15,
                      ),
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        subtitle!,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: colors.textSecondary,
                        ),
                      ),
                    ],
                    const Spacer(),
                    ?footer,
                  ],
                ),
              ),
              if (badge != null)
                Positioned(
                  top: AppSpacing.sm,
                  right: AppSpacing.sm,
                  child: _NewBadge(label: badge!),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NewBadge extends StatelessWidget {
  const _NewBadge({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: colors.gold.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 9,
          fontWeight: FontWeight.w800,
          color: colors.gold,
          letterSpacing: 0.4,
        ),
      ),
    );
  }
}

/// Rodapé de progresso (barra + `X/total · pct%`) — usado pelos jogos de
/// coleção finita (Quiz, Adivinhe a Escalação, Adivinhe o Jogador).
class ArenaCardProgressFooter extends StatelessWidget {
  const ArenaCardProgressFooter({required this.progress, super.key});

  final ({int completed, int total}) progress;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _ProgressBar(
          progress: progress,
          trackColor: colors.border,
          fillColor: colors.primary,
        ),
        const SizedBox(height: 4),
        Text(
          progress.total == 0
              ? '—'
              : '${progress.completed}/${progress.total} · ${(progress.completed / progress.total * 100).round()}%',
          style: TextStyle(
            fontSize: 10.5,
            fontWeight: FontWeight.w700,
            color: colors.textHint,
          ),
        ),
      ],
    );
  }
}

/// Rodapé de desempenho simples (sem barra) — pros jogos que não são uma
/// coleção finita, então "X/total" não faz sentido (ver Quem Vestiu o
/// Manto?).
class ArenaCardStatFooter extends StatelessWidget {
  const ArenaCardStatFooter({required this.text, super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: TextStyle(
        fontSize: 10.5,
        fontWeight: FontWeight.w700,
        color: context.colors.textHint,
      ),
    );
  }
}

class _ProgressBar extends StatelessWidget {
  const _ProgressBar({
    required this.progress,
    required this.trackColor,
    required this.fillColor,
  });

  final ({int completed, int total}) progress;
  final Color trackColor;
  final Color fillColor;

  @override
  Widget build(BuildContext context) {
    final fraction = progress.total == 0
        ? 0.0
        : (progress.completed / progress.total).clamp(0.0, 1.0);
    return ClipRRect(
      borderRadius: BorderRadius.circular(999),
      child: LinearProgressIndicator(
        value: fraction,
        minHeight: 4,
        backgroundColor: trackColor,
        valueColor: AlwaysStoppedAnimation(fillColor),
      ),
    );
  }
}

/// Elemento puramente decorativo pro card do "Quem Vestiu o Manto?" — uma
/// silhueta genérica de rosto/ombros, desfocada e com opacidade bem baixa.
/// NUNCA é a foto do jogador secreto da rodada (não dá nenhuma pista) — é
/// só uma forma abstrata pra dar identidade visual ao card sem virar um
/// banner cheio de informação.
class ArenaCardFaceDecoration extends StatelessWidget {
  const ArenaCardFaceDecoration({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return IgnorePointer(
      child: Opacity(
        opacity: 0.06,
        child: ImageFiltered(
          imageFilter: ImageFilter.blur(sigmaX: 7, sigmaY: 7),
          child: CustomPaint(
            painter: _FaceSilhouettePainter(color: colors.primary),
            size: const Size(96, 96),
          ),
        ),
      ),
    );
  }
}

class _FaceSilhouettePainter extends CustomPainter {
  const _FaceSilhouettePainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color;
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(size.width * 0.5, size.height * 0.38),
        width: size.width * 0.46,
        height: size.height * 0.5,
      ),
      paint,
    );
    final shoulders = Path()
      ..moveTo(0, size.height)
      ..lineTo(0, size.height * 0.86)
      ..quadraticBezierTo(
        size.width * 0.5,
        size.height * 0.5,
        size.width,
        size.height * 0.86,
      )
      ..lineTo(size.width, size.height)
      ..close();
    canvas.drawPath(shoulders, paint);
  }

  @override
  bool shouldRepaint(covariant _FaceSilhouettePainter oldDelegate) =>
      oldDelegate.color != color;
}
