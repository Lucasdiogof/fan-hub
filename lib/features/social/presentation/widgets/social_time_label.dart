import 'package:flutter/material.dart';
import 'package:goias_app/core/theme/app_colors.dart';

class SocialTimeLabel extends StatelessWidget {
  const SocialTimeLabel({required this.publishedAt, super.key});

  final DateTime publishedAt;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Text(
      _relativeTime(publishedAt),
      style: TextStyle(fontSize: 11, color: colors.textHint),
    );
  }

  static String _relativeTime(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return 'agora';
    if (diff.inMinutes < 60) return '${diff.inMinutes}min';
    if (diff.inHours < 24) return '${diff.inHours}h';
    if (diff.inDays < 7) return '${diff.inDays}d';
    if (diff.inDays < 30) return '${(diff.inDays / 7).floor()}sem';
    return '${(diff.inDays / 30).floor()}m';
  }
}
