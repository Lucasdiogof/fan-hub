import 'package:flutter/widgets.dart';

class ArenaGame {
  const ArenaGame({
    required this.id,
    required this.title,
    required this.tagline,
    required this.icon,
    required this.route,
    this.featured = false,
    this.usesFlame = true,
    this.available = false,
  });

  final String id;
  final String title;
  final String tagline;
  final IconData icon;
  final String route;
  final bool featured;
  final bool usesFlame;
  final bool available;
}
