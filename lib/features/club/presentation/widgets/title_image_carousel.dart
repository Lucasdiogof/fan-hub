import 'package:flutter/material.dart';
import 'package:goias_app/core/theme/app_spacing.dart';
import 'package:goias_app/features/club/presentation/widgets/title_image_card.dart';

/// Carrossel horizontal de "momentos históricos" — `ListView.separated` já
/// constrói só os cards visíveis (lazy por padrão). Lista vazia = não
/// renderiza nada, nunca um placeholder feio no lugar da foto que ainda
/// não chegou. [title] é o nome da competição/campanha, repassado pro
/// viewer em tela cheia de cada card.
class TitleImageCarousel extends StatelessWidget {
  const TitleImageCarousel({
    required this.images,
    required this.title,
    super.key,
  });

  final List<String> images;
  final String title;

  @override
  Widget build(BuildContext context) {
    if (images.isEmpty) return const SizedBox.shrink();
    return SizedBox(
      height: titleImageCardHeight,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: images.length,
        separatorBuilder: (_, _) => const SizedBox(width: AppSpacing.sm),
        itemBuilder: (context, i) => TitleImageCard(
          assetPath: images[i],
          allImages: images,
          index: i,
          title: title,
        ),
      ),
    );
  }
}
