import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:goias_app/core/club/club_config.dart';
import 'package:goias_app/core/di/injection_container.dart';
import 'package:goias_app/core/l10n/l10n_extensions.dart';
import 'package:goias_app/core/theme/app_colors.dart';
import 'package:goias_app/core/theme/app_spacing.dart';
import 'package:goias_app/features/club/domain/entities/club_song.dart';
import 'package:goias_app/features/club/presentation/widgets/club_section_label.dart';
import 'package:goias_app/shared/widgets/detail_page_header.dart';

/// Catálogo/listagem — sem áudio nenhum aqui. Tocar num card só navega
/// pra `ClubSongDetailsPage`, que é quem toca a música (ver
/// `club_song_details_page.dart`).
class ClubSongsPage extends StatelessWidget {
  const ClubSongsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final allSongs = sl<ClubConfig>().institutionalContent.songs;
    final anthems = allSongs
        .where((s) => s.category == ClubSongCategory.anthem)
        .toList();
    final songs = allSongs
        .where((s) => s.category == ClubSongCategory.fanChant)
        .toList();
    final title = context.l10n.clubSectionSongs.toUpperCase();
    return Scaffold(
      backgroundColor: colors.background,
      body: DetailPageHeader(
        title: title,
        heroTitle: Text(
          title,
          style: TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.w900,
            color: colors.textPrimary,
          ),
        ),
        body: Padding(
          padding: const EdgeInsets.only(top: AppSpacing.xl),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (anthems.isNotEmpty) ...[
                ClubSectionLabel(context.l10n.clubAnthemSection),
                const SizedBox(height: AppSpacing.sm),
                for (var i = 0; i < anthems.length; i++) ...[
                  if (i > 0) const SizedBox(height: AppSpacing.sm),
                  _SongCard(song: anthems[i]),
                ],
              ],
              if (anthems.isNotEmpty && songs.isNotEmpty)
                const SizedBox(height: AppSpacing.xl),
              if (songs.isNotEmpty) ...[
                ClubSectionLabel(
                  context.l10n.clubSongsSection(
                    sl<ClubConfig>().identity.code,
                    sl<ClubConfig>().identity.shortName.toUpperCase(),
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                for (var i = 0; i < songs.length; i++) ...[
                  if (i > 0) const SizedBox(height: AppSpacing.sm),
                  _SongCard(song: songs[i]),
                ],
              ],
            ],
          ),
        ),
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
