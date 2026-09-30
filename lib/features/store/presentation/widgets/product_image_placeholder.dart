import 'package:flutter/material.dart';
import 'package:goias_app/core/theme/app_colors.dart';

/// Placeholder neutro pra produto sem foto capturada ainda — só ícone/cor
/// do tema, nunca uma imagem (genérica, de outro produto ou de outro
/// clube) fingindo ser a foto real do produto.
class ProductImagePlaceholder extends StatelessWidget {
  const ProductImagePlaceholder({super.key, this.iconSize = 40});

  final double iconSize;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      color: colors.secondary,
      alignment: Alignment.center,
      child: Icon(
        Icons.shopping_bag_outlined,
        size: iconSize,
        color: colors.textHint,
      ),
    );
  }
}
