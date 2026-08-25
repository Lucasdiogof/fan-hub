import 'package:flutter/material.dart';

class SocialLink {
  const SocialLink({
    required this.name,
    required this.url,
    this.svgPathData,
    this.icon,
  }) : assert(
         (svgPathData == null) != (icon == null),
         'Informe svgPathData (glifo de marca) ou icon (Material), nunca os dois.',
       );

  final String name;
  final String url;

  /// Dado de um único `<path d="...">` num viewBox 24x24 — glifo de marca
  /// (Instagram, YouTube, TikTok, Facebook, X), tintado na cor do app.
  final String? svgPathData;

  /// Ícone Material — usado quando não é uma marca (ex.: "Site oficial").
  final IconData? icon;
}
