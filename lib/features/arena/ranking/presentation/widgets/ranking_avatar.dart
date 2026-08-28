import 'package:flutter/material.dart';
import 'package:goias_app/core/l10n/l10n_extensions.dart';
import 'package:goias_app/core/theme/app_colors.dart';
import 'package:goias_app/features/arena/ranking/domain/ranking_entities.dart';

/// Nome de exibição de uma entrada do ranking — `RankingEntry.name` pode
/// vir vazio (perfil sem nome, ver `SupabaseArenaRankingRepository`); o
/// fallback traduzido é resolvido aqui, na apresentação, e não no
/// repositório (que não tem acesso a l10n).
String rankingDisplayName(BuildContext context, RankingEntry entry) =>
    entry.name.isEmpty ? context.l10n.arenaRankingUnknownFan : entry.name;

class RankingAvatar extends StatelessWidget {
  const RankingAvatar({
    required this.name,
    required this.avatarUrl,
    this.size = 34,
    super.key,
  });

  final String name;
  final String? avatarUrl;
  final double size;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final hasAvatar = avatarUrl != null && avatarUrl!.isNotEmpty;
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: colors.primary,
        shape: BoxShape.circle,
        image: hasAvatar
            ? DecorationImage(
                image: NetworkImage(avatarUrl!),
                fit: BoxFit.cover,
              )
            : null,
      ),
      child: hasAvatar
          ? null
          : Text(
              _initials(name),
              style: TextStyle(
                fontSize: size * 0.36,
                fontWeight: FontWeight.w800,
                color: Colors.white,
              ),
            ),
    );
  }
}

class RankingMemberBadge extends StatelessWidget {
  const RankingMemberBadge({required this.label, super.key});

  final String label;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: colors.gold.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 9.5,
          fontWeight: FontWeight.w800,
          color: colors.gold,
        ),
      ),
    );
  }
}

String _initials(String name) {
  final words = name
      .trim()
      .split(RegExp(r'\s+'))
      .where((word) => word.isNotEmpty)
      .toList();
  if (words.isEmpty) return '';
  if (words.length == 1) return words.first.substring(0, 1).toUpperCase();
  return (words.first[0] + words.last[0]).toUpperCase();
}
