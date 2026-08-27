import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:goias_app/core/l10n/l10n_extensions.dart';
import 'package:goias_app/core/theme/app_colors.dart';
import 'package:goias_app/core/theme/app_spacing.dart';
import 'package:goias_app/features/club/data/club_songs_data.dart';
import 'package:goias_app/features/club/domain/entities/club_song.dart';
import 'package:goias_app/shared/widgets/back_button_circle.dart';
import 'package:goias_app/shared/widgets/page_title.dart';

/// Catálogo/listagem — sem áudio nenhum aqui. Tocar num card só navega
/// pra `ClubSongDetailsPage`, que é quem toca a música (ver
/// `club_song_details_page.dart`).
class ClubSongsPage extends StatelessWidget {
  const ClubSongsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final anthems = ClubSongsData.songs
        .where((s) => s.category == ClubSongCategory.anthem)
        .toList();
    final songs = ClubSongsData.songs
        .where((s) => s.category == ClubSongCategory.esmeraldina)
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
                  _SectionLabel(context.l10n.clubAnthemSection),
                  const SizedBox(height: AppSpacing.sm),
                  for (var i = 0; i < anthems.length; i++) ...[
                    if (i > 0) const SizedBox(height: AppSpacing.sm),
                    _SongCard(song: anthems[i]),
                  ],
                  const SizedBox(height: AppSpacing.xl),
                  _SectionLabel(context.l10n.clubSongsSection),
                  const SizedBox(height: AppSpacing.sm),
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
  const _SectionLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w800,
        letterSpacing: 1.2,
        color: context.colors.textSecondary,
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
    return Material(
      color: colors.surface,
      borderRadius: BorderRadius.circular(AppRadius.cardSmall),
      child: InkWell(
        onTap: () => context.push('/clube/hino/letra', extra: song),
        borderRadius: BorderRadius.circular(AppRadius.cardSmall),
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm + 4,
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadius.cardSmall),
            border: Border.all(color: colors.border),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      song.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: colors.textPrimary,
                        height: 1.25,
                      ),
                    ),
                    if (song.artist != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        song.artist!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 12.5,
                          color: colors.textSecondary,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Icon(
                Icons.chevron_right_rounded,
                size: 22,
                color: colors.textHint,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
