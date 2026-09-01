import 'package:flutter/material.dart';
import 'package:goias_app/core/l10n/l10n_extensions.dart';
import 'package:goias_app/core/theme/app_assets.dart';
import 'package:goias_app/core/theme/app_button_styles.dart';
import 'package:goias_app/core/theme/app_colors.dart';
import 'package:goias_app/core/theme/app_spacing.dart';
import 'package:goias_app/features/arena/shared/arena_colors.dart';

/// Entrada da Goiás Store na Home — um único banner (nunca dois blocos
/// separados: fundo, textura, camisa e conteúdo dividem o mesmo
/// `ClipRRect`). Fundo sempre nos verdes escuros de banner/hero
/// (`darkGreen`/`deepGreen`, ver `AppColors`), fixos nos dois temas — o
/// banner é institucional, não deve clarear no tema claro nem escurecer
/// mais ainda no escuro. Nunca mostra preço fixo aqui: é uma vitrine, não
/// uma oferta específica.
class StoreEntryCard extends StatelessWidget {
  const StoreEntryCard({required this.onTap, super.key});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        // Em telas muito estreitas, a camisa encolhe antes do texto —
        // nunca o contrário (o texto some quase por completo se encolher
        // demais; a camisa sempre pode perder um pouco de área).
        final jerseyWidth = (width * 0.4).clamp(120.0, 230.0);
        final textMaxWidth = (width - jerseyWidth - AppSpacing.xl).clamp(
          150.0,
          360.0,
        );

        return Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(AppRadius.banner),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onTap,
            // O botão "Conhecer a loja" já é o controle semântico real
            // (foco por teclado, rótulo próprio); esta camada só existe
            // pra deixar o cartão inteiro clicável no toque/mouse, sem
            // duplicar o mesmo botão pra leitores de tela.
            excludeFromSemantics: true,
            child: Ink(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(AppRadius.banner),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    AppColors.light.darkGreen,
                    AppColors.light.deepGreen,
                  ],
                ),
                border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
              ),
              // Altura mínima em vez de fixa: o conteúdo (badge + textos +
              // botão) define a altura real e cresce em telas estreitas ou com
              // fonte ampliada, em vez de estourar num `height` travado.
              child: ConstrainedBox(
                constraints: const BoxConstraints(minHeight: 196),
                child: Stack(
                  children: [
                    const Positioned.fill(child: _DiagonalTexture()),
                    Positioned(
                      right: -6,
                      top: 8,
                      bottom: 0,
                      width: jerseyWidth,
                      child: const ExcludeSemantics(
                        child: _StoreBannerWatermark(),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(
                        AppSpacing.xl,
                        AppSpacing.lg,
                        AppSpacing.md,
                        AppSpacing.lg,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _StoreBadge(label: l10n.storeHomeEntryBadge),
                          const SizedBox(height: AppSpacing.md),
                          Text(
                            l10n.storeHomeEntryTitle,
                            style: const TextStyle(
                              fontSize: 21,
                              fontWeight: FontWeight.w900,
                              color: Colors.white,
                              height: 1.15,
                            ),
                          ),
                          const SizedBox(height: 6),
                          SizedBox(
                            width: textMaxWidth,
                            child: Text(
                              l10n.storeHomeEntryDescription,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 12.5,
                                height: 1.35,
                                color: Colors.white.withValues(alpha: 0.8),
                              ),
                            ),
                          ),
                          const SizedBox(height: AppSpacing.md),
                          ElevatedButton(
                            onPressed: onTap,
                            style: whiteFilledOnDarkStyle(),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  l10n.storeHomeEntryCta,
                                  style: const TextStyle(
                                    fontSize: 13.5,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                const Icon(
                                  Icons.arrow_forward_rounded,
                                  size: 16,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _StoreBadge extends StatelessWidget {
  const _StoreBadge({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: colors.gold.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppRadius.pill),
        border: Border.all(color: colors.gold, width: 1.5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.shopping_bag_outlined,
            size: 12,
            color: Colors.white,
          ),
          const SizedBox(width: 5),
          Text(
            label,
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.7,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}

/// Marca d'água do banner — mesma linguagem visual do card da Arena
/// Esmeraldina na Home (ver `ArenaSpotlightCard`/`AppAssets.arenaStadiumPhoto`):
/// tingida de verde, translúcida, sem disputar leitura com o texto. A foto
/// de origem (`AppAssets.storeBanner`) não vem duotone/sem fundo como a da
/// Arena, então os dois efeitos são feitos aqui: `BlendMode.color` reduz a
/// imagem a um único matiz verde (preserva só a luminosidade dos pixels) e
/// o `ShaderMask` esmaece a borda esquerda pro fundo escuro do banner, pra
/// nunca aparecer como "uma foto colada em cima" com aresta reta.
class _StoreBannerWatermark extends StatelessWidget {
  const _StoreBannerWatermark();

  @override
  Widget build(BuildContext context) {
    return ShaderMask(
      shaderCallback: (bounds) => const LinearGradient(
        begin: Alignment.centerLeft,
        end: Alignment.centerRight,
        colors: [Colors.transparent, Colors.white],
        stops: [0.0, 0.55],
      ).createShader(bounds),
      blendMode: BlendMode.dstIn,
      child: Opacity(
        opacity: 0.55,
        child: ColorFiltered(
          colorFilter: const ColorFilter.mode(
            ArenaColors.pitch,
            BlendMode.color,
          ),
          child: Image.asset(AppAssets.storeBanner, fit: BoxFit.cover),
        ),
      ),
    );
  }
}

/// Textura quase imperceptível — linhas diagonais bem finas e de baixa
/// opacidade, só pra dar uma sutileza de tecido/material ao fundo sólido.
/// Estática (sem animação) e nunca competindo com texto ou produto.
class _DiagonalTexture extends StatelessWidget {
  const _DiagonalTexture();

  @override
  Widget build(BuildContext context) {
    return CustomPaint(painter: _DiagonalTexturePainter());
  }
}

class _DiagonalTexturePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.035)
      ..strokeWidth = 1;
    const gap = 14.0;
    final diagonal = size.width + size.height;
    for (var offset = -size.height; offset < diagonal; offset += gap) {
      canvas.drawLine(
        Offset(offset, 0),
        Offset(offset + size.height, size.height),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
