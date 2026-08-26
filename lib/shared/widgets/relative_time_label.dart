import 'package:flutter/material.dart';
import 'package:goias_app/core/l10n/l10n_extensions.dart';
import 'package:goias_app/core/theme/app_colors.dart';

class RelativeTimeLabel extends StatelessWidget {
  const RelativeTimeLabel({required this.dateTime, this.style, super.key});

  final DateTime dateTime;
  final TextStyle? style;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Text(
      _relativeTime(context, dateTime),
      style: style ?? TextStyle(fontSize: 11, color: colors.textHint),
    );
  }

  static String _relativeTime(BuildContext context, DateTime dt) {
    final l10n = context.l10n;
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return l10n.relTimeNow;
    if (diff.inMinutes < 60) return l10n.relTimeMinutes(diff.inMinutes);
    if (diff.inHours < 24) return l10n.relTimeHours(diff.inHours);
    if (diff.inDays < 7) return l10n.relTimeDays(diff.inDays);
    if (diff.inDays < 30) return l10n.relTimeWeeks((diff.inDays / 7).floor());
    return l10n.relTimeMonths((diff.inDays / 30).floor());
  }
}
