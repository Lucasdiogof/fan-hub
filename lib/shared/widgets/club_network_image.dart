import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

/// Foto remota com cache em disco: quem já foi vista com internet continua
/// aparecendo depois de fechar o app, em modo avião. Substitui
/// `Image.network` (que só guarda em memória). Enquanto carrega ou se
/// falhar (sem rede e nunca vista), mostra [fallback] — nunca spinner
/// infinito nem área vazia.
class ClubNetworkImage extends StatelessWidget {
  const ClubNetworkImage({
    required this.url,
    required this.fallback,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.alignment = Alignment.center,
    super.key,
  });

  final String url;
  final Widget fallback;
  final double? width;
  final double? height;
  final BoxFit fit;
  final Alignment alignment;

  @override
  Widget build(BuildContext context) {
    return CachedNetworkImage(
      imageUrl: url,
      width: width,
      height: height,
      fit: fit,
      alignment: alignment,
      fadeInDuration: const Duration(milliseconds: 120),
      placeholder: (_, _) => fallback,
      errorWidget: (_, _, _) => fallback,
    );
  }
}
