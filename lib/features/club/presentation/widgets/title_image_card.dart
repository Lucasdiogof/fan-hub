import 'package:flutter/material.dart';
import 'package:goias_app/core/theme/app_spacing.dart';
import 'package:goias_app/features/club/presentation/widgets/title_image_viewer.dart';

const titleImageCardWidth = 220.0;
const titleImageCardHeight = 150.0;

/// Um card do carrossel de "momentos históricos" — só a foto, sem legenda
/// nenhuma por cima (o contexto mora no título da seção acima e no viewer
/// em tela cheia, ver `title_image_viewer.dart`).
class TitleImageCard extends StatelessWidget {
  const TitleImageCard({
    required this.assetPath,
    required this.allImages,
    required this.index,
    required this.title,
    super.key,
  });

  final String assetPath;

  /// Todas as fotos do carrossel — o viewer aberto a partir daqui continua
  /// permitindo passar pras outras fotos do mesmo grupo, não só a tocada.
  final List<String> allImages;
  final int index;

  /// Nome da competição/campanha — mostrado no viewer em tela cheia.
  final String title;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: titleImageCardWidth,
      height: titleImageCardHeight,
      child: Material(
        clipBehavior: Clip.antiAlias,
        borderRadius: BorderRadius.circular(AppRadius.card),
        child: InkWell(
          onTap: () => showTitleImageViewer(
            context,
            images: allImages,
            initialIndex: index,
            title: title,
          ),
          child: Stack(
            fit: StackFit.expand,
            children: [
              Image.asset(assetPath, fit: BoxFit.cover),
              DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(AppRadius.card),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.08),
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
