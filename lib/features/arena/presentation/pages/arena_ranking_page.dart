import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:goias_app/core/di/injection_container.dart';
import 'package:goias_app/core/l10n/l10n_extensions.dart';
import 'package:goias_app/core/theme/app_colors.dart';
import 'package:goias_app/core/theme/app_spacing.dart';
import 'package:goias_app/features/arena/data/arena_scores.dart';
import 'package:goias_app/shared/widgets/goias_loading_indicator.dart';

const defaultLeaderboardCategoryId = 'quiz_torcedor';

const _categories = <(String, String)>[
  // Pênaltis oculto por enquanto — reativar junto com o jogo.
  // ('penalty', 'Pênaltis'),
  (defaultLeaderboardCategoryId, 'Quiz · Torcedor'),
  ('quiz_esmeraldino', 'Quiz · Esmeraldino'),
  ('quiz_fanatico', 'Quiz · Fanático'),
];

class ArenaRankingPage extends StatefulWidget {
  const ArenaRankingPage({this.initialEntries, super.key});

  /// Ranking da categoria padrão já carregado por quem navegou pra cá (ver
  /// `GlobalLoading.run` em `arena_page.dart`) — evita spinner na abertura.
  /// Fica `null` (e a tela carrega sozinha) só em navegação direta por URL.
  final List<ArenaLeaderboardEntry>? initialEntries;

  @override
  State<ArenaRankingPage> createState() => _ArenaRankingPageState();
}

class _ArenaRankingPageState extends State<ArenaRankingPage> {
  int _selected = 0;
  late Future<List<ArenaLeaderboardEntry>> _future;

  @override
  void initState() {
    super.initState();
    final preloaded = widget.initialEntries;
    _future = preloaded != null ? Future.value(preloaded) : _load();
  }

  Future<List<ArenaLeaderboardEntry>> _load() =>
      sl<ArenaScores>().leaderboard(_categories[_selected].$1);

  void _select(int index) {
    if (index == _selected) return;
    setState(() {
      _selected = index;
      _future = _load();
    });
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Scaffold(
      backgroundColor: colors.background,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.md,
                AppSpacing.sm,
                AppSpacing.lg,
                AppSpacing.sm,
              ),
              child: Row(
                children: [
                  InkWell(
                    onTap: () =>
                        context.canPop() ? context.pop() : context.go('/'),
                    borderRadius: BorderRadius.circular(999),
                    child: Container(
                      width: 40,
                      height: 40,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: colors.secondary,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.arrow_back_rounded,
                        size: 20,
                        color: colors.textPrimary,
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Text(
                    context.l10n.arenaRankingTitle,
                    style: TextStyle(
                      fontSize: 19,
                      fontWeight: FontWeight.w900,
                      color: colors.textPrimary,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(
              height: 44,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                itemCount: _categories.length,
                separatorBuilder: (_, _) =>
                    const SizedBox(width: AppSpacing.sm),
                itemBuilder: (context, index) => _CategoryChip(
                  label: _categories[index].$2,
                  selected: index == _selected,
                  onTap: () => _select(index),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Expanded(
              child: FutureBuilder<List<ArenaLeaderboardEntry>>(
                future: _future,
                builder: (context, snapshot) {
                  if (snapshot.connectionState != ConnectionState.done) {
                    return const Center(child: GoiasLoadingIndicator());
                  }
                  final entries = snapshot.data ?? const [];
                  if (entries.isEmpty) return const _EmptyRanking();
                  return ListView.separated(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.lg,
                      AppSpacing.sm,
                      AppSpacing.lg,
                      AppSpacing.xxxl,
                    ),
                    itemCount: entries.length,
                    separatorBuilder: (_, _) =>
                        const SizedBox(height: AppSpacing.sm),
                    itemBuilder: (context, index) =>
                        _RankRow(entry: entries[index]),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CategoryChip extends StatelessWidget {
  const _CategoryChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Material(
      color: selected ? colors.primary : colors.surface,
      borderRadius: BorderRadius.circular(999),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: Container(
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: selected ? colors.primary : colors.border,
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13.5,
              fontWeight: FontWeight.w800,
              color: selected ? colors.onPrimary : colors.textPrimary,
            ),
          ),
        ),
      ),
    );
  }
}

class _RankRow extends StatelessWidget {
  const _RankRow({required this.entry});

  final ArenaLeaderboardEntry entry;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final medal = switch (entry.rank) {
      1 => colors.gold,
      2 => const Color(0xFFB8BCC0),
      3 => const Color(0xFFCD7F32),
      _ => null,
    };
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.md,
      ),
      decoration: BoxDecoration(
        color: entry.isMe ? colors.secondary : colors.surface,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(color: entry.isMe ? colors.primary : colors.border),
      ),
      child: Row(
        children: [
          Container(
            width: 30,
            height: 30,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: medal ?? colors.background,
              border: medal == null ? Border.all(color: colors.border) : null,
            ),
            child: Text(
              '${entry.rank}',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w900,
                color: medal != null ? Colors.white : colors.textSecondary,
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Text(
              entry.isMe ? context.l10n.arenaYouMarker(entry.name) : entry.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w800,
                color: entry.isMe ? colors.primary : colors.textPrimary,
              ),
            ),
          ),
          Text(
            '${entry.best}',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w900,
              color: colors.primary,
            ),
          ),
          const SizedBox(width: 3),
          Text(
            'pts',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: colors.textHint,
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyRanking extends StatelessWidget {
  const _EmptyRanking();

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xxl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.leaderboard_rounded, size: 48, color: colors.textHint),
            const SizedBox(height: AppSpacing.md),
            Text(
              context.l10n.arenaRankingEmpty,
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w800,
                color: colors.textPrimary,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              context.l10n.arenaRankingEmptyMessage,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13.5,
                color: colors.textSecondary,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
