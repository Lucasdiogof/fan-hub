import 'package:flutter/material.dart';
import 'package:goias_app/core/club/club_config.dart';
import 'package:goias_app/core/di/injection_container.dart';
import 'package:goias_app/core/l10n/l10n_extensions.dart';
import 'package:goias_app/core/theme/app_button_styles.dart';
import 'package:goias_app/core/theme/app_colors.dart';
import 'package:goias_app/core/theme/app_spacing.dart';
import 'package:goias_app/shared/widgets/diagonal_texture.dart';

/// Entrada da Goiás Store na Home — um único banner (nunca dois blocos
/// separados: fundo, textura, camisa e conteúdo dividem o mesmo
/// `ClipRRect`). Fundo sempre no verde principal (`AppColors.primary`),
/// fixo nos dois temas — o banner é institucional, não deve clarear no
/// tema claro nem escurecer mais ainda no escuro. Nunca mostra preço fixo
/// aqui: é uma vitrine, não uma oferta específica. Mesma proporção/altura
/// do `ArenaSpotlightCard` logo acima dele na Home — sem altura mínima
/// própria, o conteúdo define o tamanho dos dois igual.
class StoreEntryCard extends StatelessWidget {
  const StoreEntryCard({required this.onTap, super.key});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(AppRadius.banner),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        // O botão "Conhecer a loja" já é o controle semântico real (foco
        // por teclado, rótulo próprio); esta camada só existe pra deixar o
        // cartão inteiro clicável no toque/mouse, sem duplicar o mesmo
        // botão pra leitores de tela.
        excludeFromSemantics: true,
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadius.banner),
            // `context.colors` (clube ATIVO) — era `AppColors.light`
            // direto, fixo no Goiás mesmo com outro clube rodando
            // (achado real 2026-09-09, ainda sem efeito hoje porque a
            // Loja está desligada pro Bragantino, mas prontidão pra
            // quando ligar).
            color: context.colors.brandDeep,
            border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
          ),
          child: Stack(
            children: [
              const Positioned.fill(child: DiagonalTexture()),
              // Marca d'água — sem nenhum tingimento/`ColorFilter`: toda
              // tentativa de colorir essa imagem (via `ColorFiltered`
              // externo OU via `Image.color`/`colorBlendMode` nativo) saiu
              // como um retângulo sólido em vez de respeitar a
              // transparência real do PNG (alfa conferido pixel a pixel,
              // está correto — o problema é só na composição do
              // Skia/Flutter). Só a opacidade, imagem como está.
              //
              // `sl<ClubConfig>().assets.storeBanner` — era
              // `AppAssets.storeBanner` direto, sempre o banner do Goiás
              // (achado real 2026-09-09). Ainda sem efeito hoje porque a
              // Loja do Bragantino está desligada (`hasStore=false`,
              // `storeBanner` continua placeholder até existir arte real
              // — o banner do Goiás tem "GOIAS STORE"/escudo cravado nos
              // próprios pixels, NUNCA reaproveitável só recolorindo).
              Positioned.fill(
                child: Align(
                  alignment: const Alignment(1.15, 0.3),
                  child: ExcludeSemantics(
                    child: Opacity(
                      opacity: 0.50,
                      child: Image.asset(
                        sl<ClubConfig>().assets.storeBanner,
                        width: 190,
                      ),
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _StoreBadge(
                      label: l10n.storeHomeEntryBadge(
                        sl<ClubConfig>().productNames.storeName.toUpperCase(),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      l10n.storeHomeEntryTitle,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                        height: 1.15,
                      ),
                    ),
                    const SizedBox(height: 4),
                    SizedBox(
                      width: 220,
                      child: Text(
                        l10n.storeHomeEntryDescription(
                          sl<ClubConfig>().identity.code,
                          sl<ClubConfig>().identity.shortName,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 12.5,
                          height: 1.3,
                          color: Colors.white.withValues(alpha: 0.78),
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    ElevatedButton(
                      onPressed: onTap,
                      style: whiteFilledOnDarkStyle(),
                      child: Text(
                        l10n.storeHomeEntryCta,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
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
