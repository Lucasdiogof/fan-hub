import 'package:flutter/material.dart';
import 'package:goias_app/core/theme/app_colors.dart';
import 'package:goias_app/core/theme/app_spacing.dart';
import 'package:goias_app/features/news/domain/entities/news_item.dart';
import 'package:goias_app/shared/utils/image_proxy.dart';
import 'package:goias_app/shared/widgets/relative_time_label.dart';

/// Item de notícia — imagem + título/categoria/data. Usado tanto no preview
/// da Home quanto na lista completa, pra manter o mesmo visual nos dois
/// lugares.
class NewsItemRow extends StatelessWidget {
  const NewsItemRow({required this.item, required this.onTap, super.key});

  final NewsItem item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Semantics(
      button: true,
      label: item.title,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.cardSmall),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(AppRadius.cardSmall),
                child: SizedBox(
                  // As artes do site (ex.: "Guia da Partida") sempre vêm
                  // quase quadradas, ligeiramente mais altas que largas
                  // (~425×480 nas imagens reais), com o texto e os dois
                  // escudos perto do rodapé e uma faixa de topo vazia que
                  // não importa. Uma caixa exatamente na proporção da
                  // imagem (ou mais alta que ela) não corta nada de
                  // cima/baixo, mas aí aquela faixa vazia do topo ocupa
                  // espaço à toa. Uma caixa um pouco mais LARGA que a
                  // proporção real força o `cover` a cortar uma fatia do
                  // topo (nunca do rodapé, com `Alignment.bottomCenter`) —
                  // dosado pra sobrar folga antes de chegar nos escudos.
                  width: 100,
                  height: 93,
                  child: ColoredBox(
                    color: colors.secondary,
                    child: Image.network(
                      proxiedImageUrl(item.imageUrl),
                      fit: BoxFit.cover,
                      // As artes "Guia da Partida" põem o texto e os dois
                      // escudos perto do rodapé, com uma faixa de topo que
                      // não importa — `bottomCenter` corta a sobra de cima
                      // em vez de esconder justo a parte com informação.
                      alignment: Alignment.bottomCenter,
                      errorBuilder: (context, error, stackTrace) => Icon(
                        Icons.image_not_supported_outlined,
                        color: colors.textHint,
                        size: 22,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            item.category.toUpperCase(),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 10.5,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.4,
                              color: colors.primary,
                            ),
                          ),
                        ),
                        if (item.publishedAt != null) ...[
                          const SizedBox(width: 6),
                          Text(
                            '•',
                            style: TextStyle(
                              fontSize: 10,
                              color: colors.textHint,
                            ),
                          ),
                          const SizedBox(width: 6),
                          RelativeTimeLabel(dateTime: item.publishedAt!),
                        ],
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      item.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w700,
                        color: colors.textPrimary,
                        height: 1.3,
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
