import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:goias_app/core/mock/mock_data.dart';
import 'package:goias_app/core/l10n/l10n_extensions.dart';
import 'package:goias_app/core/theme/app_colors.dart';
import 'package:goias_app/core/theme/app_spacing.dart';
import 'package:goias_app/features/club/data/club_songs_data.dart';
import 'package:goias_app/features/club/domain/entities/club_song.dart';
import 'package:goias_app/shared/widgets/back_button_circle.dart';
import 'package:goias_app/shared/widgets/club_badge.dart';
import 'package:goias_app/shared/widgets/page_title.dart';

class ClubSongsPage extends StatelessWidget {
  const ClubSongsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final anthems = ClubSongsData.songs
        .where((s) => s.type == ClubSongType.anthem)
        .toList();
    final songs = ClubSongsData.songs
        .where((s) => s.type == ClubSongType.song)
        .toList();
    return Scaffold(
      backgroundColor: colors.background,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                AppSpacing.md,
                AppSpacing.lg,
                0,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  BackButtonCircle(onTap: () => context.pop()),
                  const SizedBox(height: AppSpacing.lg),
                  PageTitle(context.l10n.clubSectionSongs.toUpperCase()),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.lg,
                  AppSpacing.xl,
                  AppSpacing.lg,
                  AppSpacing.xxxl,
                ),
                children: [
                  _SectionLabel(context.l10n.clubAnthemSection, colors: colors),
                  const SizedBox(height: AppSpacing.md),
                  for (var i = 0; i < anthems.length; i++) ...[
                    if (i > 0) const SizedBox(height: AppSpacing.sm),
                    _SongCard(song: anthems[i]),
                  ],
                  const SizedBox(height: AppSpacing.xl),
                  _SectionLabel(context.l10n.clubSongsSection, colors: colors),
                  const SizedBox(height: AppSpacing.md),
                  for (var i = 0; i < songs.length; i++) ...[
                    if (i > 0) const SizedBox(height: AppSpacing.sm),
                    _SongCard(song: songs[i]),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text, {required this.colors});

  final String text;
  final AppColors colors;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w800,
        letterSpacing: 1.2,
        color: colors.textSecondary,
      ),
    );
  }
}

class _SongCard extends StatelessWidget {
  const _SongCard({required this.song});

  final ClubSong song;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final hasAudio = song.audioUrl != null;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(color: colors.border),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: colors.secondary,
              shape: BoxShape.circle,
            ),
            child: const ClubBadge(team: MockData.goias, size: 28),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  song.title,
                  style: TextStyle(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w700,
                    color: colors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  song.artist,
                  style: TextStyle(fontSize: 12.5, color: colors.textSecondary),
                ),
              ],
            ),
          ),
          if (song.lyrics != null)
            TextButton(
              onPressed: () => _showLyrics(context, song),
              child: Text(context.l10n.clubViewLyrics),
            ),
          Icon(
            hasAudio
                ? Icons.play_circle_fill_rounded
                : Icons.play_circle_outline_rounded,
            size: 32,
            color: hasAudio ? colors.primary : colors.textHint,
          ),
        ],
      ),
    );
  }

  void _showLyrics(BuildContext context, ClubSong song) {
    final colors = context.colors;
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      backgroundColor: colors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppRadius.hero),
        ),
      ),
      builder: (sheetContext) => SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.xxl,
            0,
            AppSpacing.xxl,
            AppSpacing.xl,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                song.title,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: colors.textPrimary,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                song.lyrics ?? '',
                style: TextStyle(
                  fontSize: 14,
                  height: 1.5,
                  color: colors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
