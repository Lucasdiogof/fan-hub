import 'package:flutter/material.dart';
import 'package:goias_app/core/theme/app_spacing.dart';

/// Mesma arte pronta do banner de topo da Goiás Store (`lib/assets/goias_store.png`,
/// textos e CTA já embutidos na imagem) — usada aqui como um segundo banner
/// na Home, logo abaixo do `StoreEntryCard`. Toque sempre leva pra loja
/// (nunca um produto específico, ao contrário do banner dentro da própria
/// loja).
class GoiasStoreBanner extends StatelessWidget {
  const GoiasStoreBanner({required this.onTap, super.key});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(AppRadius.banner),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Image.asset(
          'lib/assets/goias_store.png',
          width: double.infinity,
          fit: BoxFit.fitWidth,
        ),
      ),
    );
  }
}
