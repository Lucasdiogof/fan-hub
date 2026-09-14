import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:goias_app/core/di/injection_container.dart';
import 'package:goias_app/core/l10n/l10n_extensions.dart';
import 'package:goias_app/core/theme/app_colors.dart';
import 'package:goias_app/core/theme/app_spacing.dart';
import 'package:goias_app/features/club/data/club_song_volume_store.dart';
import 'package:goias_app/features/club/domain/entities/club_song.dart';
import 'package:goias_app/features/club/presentation/cubit/club_song_player_cubit.dart';
import 'package:goias_app/features/club/presentation/cubit/club_song_player_state.dart';
import 'package:goias_app/features/club/presentation/widgets/club_section_label.dart';
import 'package:goias_app/shared/widgets/content_container.dart';
import 'package:goias_app/shared/widgets/detail_page_header.dart';
import 'package:just_audio/just_audio.dart';

/// Letra + player de UMA música. O `ClubSongPlayerCubit` é criado aqui via
/// `BlocProvider` a cada visita — o `AudioPlayer` nativo é compartilhado
/// (singleton via DI, ver `ClubSongPlayerCubit`), mas o Cubit sempre para
/// ao sair (`BlocProvider` saindo da árvore fecha o Cubit — ver
/// `ClubSongPlayerCubit.close`), então nunca música em segundo plano.
class ClubSongDetailsPage extends StatelessWidget {
  const ClubSongDetailsPage({required this.song, super.key});

  final ClubSong song;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => ClubSongPlayerCubit(
        song,
        sl<ClubSongVolumeStore>(),
        sl<AudioPlayer>(),
      )..init(),
      child: _ClubSongDetailsView(song: song),
    );
  }
}

class _ClubSongDetailsView extends StatelessWidget {
  const _ClubSongDetailsView({required this.song});

  final ClubSong song;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Scaffold(
      backgroundColor: colors.background,
      body: DetailPageHeader(
        maxWidth: ContentWidth.detail,
        title: song.title,
        heroTitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              song.title,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: colors.primary,
                height: 1.2,
              ),
            ),
            if (song.artist != null) ...[
              const SizedBox(height: 2),
              Text(
                song.artist!,
                style: TextStyle(fontSize: 14, color: colors.textSecondary),
              ),
            ],
          ],
        ),
        body: Padding(
          padding: const EdgeInsets.only(top: AppSpacing.xl),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _SongPlayer(song: song),
              const SizedBox(height: AppSpacing.xxl),
              ClubSectionLabel(context.l10n.clubLyricsLabel),
              const SizedBox(height: AppSpacing.md),
              Text(
                song.lyrics ?? context.l10n.clubLyricsUnavailable,
                style: TextStyle(
                  fontSize: 16,
                  height: 1.6,
                  color: song.lyrics != null
                      ? colors.textPrimary
                      : colors.textHint,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Play/pause + seek + volume — tudo condicionado a `song.audioAsset`
/// existir. Sem áudio, mostra só o aviso discreto (nunca tenta abrir um
/// asset inexistente).
class _SongPlayer extends StatelessWidget {
  const _SongPlayer({required this.song});

  final ClubSong song;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final l10n = context.l10n;
    final hasAudio = song.audioAsset != null;

    if (!hasAudio) {
      return Text(
        l10n.clubAudioUnavailable,
        style: TextStyle(fontSize: 13, color: colors.textHint),
      );
    }

    return BlocBuilder<ClubSongPlayerCubit, ClubSongPlayerState>(
      builder: (context, state) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: _CirclePlayButton(song: song, state: state),
            ),
            const SizedBox(height: AppSpacing.lg),
            const _SeekBar(),
            const SizedBox(height: AppSpacing.md),
            const _VolumeControl(),
            if (state.status == ClubSongPlayerStatus.error) ...[
              const SizedBox(height: AppSpacing.sm),
              Text(
                l10n.clubPlaybackError,
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12.5, color: colors.error),
              ),
            ],
          ],
        );
      },
    );
  }
}

class _CirclePlayButton extends StatelessWidget {
  const _CirclePlayButton({required this.song, required this.state});

  final ClubSong song;
  final ClubSongPlayerState state;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final l10n = context.l10n;
    final isPlaying = state.status == ClubSongPlayerStatus.playing;
    final isLoading = state.status == ClubSongPlayerStatus.loading;

    return Semantics(
      button: true,
      excludeSemantics: true,
      label: isPlaying
          ? l10n.clubPauseSongSemantics(song.title)
          : l10n.clubPlaySongSemantics(song.title),
      child: Material(
        color: colors.primary,
        shape: const CircleBorder(),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: () => context.read<ClubSongPlayerCubit>().togglePlayback(),
          child: SizedBox(
            width: 60,
            height: 60,
            child: Center(
              child: isLoading
                  ? SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.4,
                        color: colors.onPrimary,
                      ),
                    )
                  : Icon(
                      isPlaying
                          ? Icons.pause_rounded
                          : Icons.play_arrow_rounded,
                      size: 30,
                      color: colors.onPrimary,
                    ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Barra de progresso arrastável. Mantém a posição arrastada em estado
/// local só enquanto o dedo está na tela (`_dragValueMs`) — forma padrão
/// de conciliar um `Slider` com um valor que também muda sozinho via
/// stream. Quem decide a posição real ao soltar é `ClubSongPlayerCubit.seek`.
class _SeekBar extends StatefulWidget {
  const _SeekBar();

  @override
  State<_SeekBar> createState() => _SeekBarState();
}

class _SeekBarState extends State<_SeekBar> {
  double? _dragValueMs;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final cubit = context.read<ClubSongPlayerCubit>();
    final duration = context.select(
      (ClubSongPlayerCubit c) => c.state.duration,
    );
    final maxMs = duration.inMilliseconds.toDouble();
    final seekable = maxMs > 0;

    return StreamBuilder<Duration>(
      stream: cubit.positionStream,
      builder: (context, snapshot) {
        final position = snapshot.data ?? Duration.zero;
        final sliderMax = maxMs > 0 ? maxMs : 1.0;
        final currentMs = (_dragValueMs ?? position.inMilliseconds.toDouble())
            .clamp(0.0, sliderMax);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            SliderTheme(
              data: SliderTheme.of(context).copyWith(
                trackHeight: 3,
                thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                overlayShape: const RoundSliderOverlayShape(overlayRadius: 14),
              ),
              child: Slider(
                value: currentMs,
                max: sliderMax,
                activeColor: colors.primary,
                inactiveColor: colors.border,
                onChanged: seekable
                    ? (value) => setState(() => _dragValueMs = value)
                    : null,
                onChangeEnd: seekable
                    ? (value) {
                        unawaited(
                          cubit.seek(Duration(milliseconds: value.round())),
                        );
                        setState(() => _dragValueMs = null);
                      }
                    : null,
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    _formatDuration(Duration(milliseconds: currentMs.round())),
                    style: TextStyle(fontSize: 11, color: colors.textSecondary),
                  ),
                  Text(
                    _formatDuration(duration),
                    style: TextStyle(fontSize: 11, color: colors.textSecondary),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

/// Ícone de volume (também botão de mute) + slider fino — visualmente
/// secundário ao play/pause, de propósito (ver spec: volume não compete
/// com o controle principal). Sem rótulo percentual — só aparece o
/// slider/ícone.
class _VolumeControl extends StatelessWidget {
  const _VolumeControl();

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final l10n = context.l10n;
    return BlocBuilder<ClubSongPlayerCubit, ClubSongPlayerState>(
      builder: (context, state) {
        final cubit = context.read<ClubSongPlayerCubit>();
        final muted = state.isMuted || state.userVolume == 0;
        return Row(
          children: [
            Semantics(
              button: true,
              excludeSemantics: true,
              label: muted ? l10n.clubUnmuteSemantics : l10n.clubMuteSemantics,
              child: IconButton(
                onPressed: cubit.toggleMute,
                icon: Icon(
                  muted ? Icons.volume_off_rounded : Icons.volume_up_rounded,
                ),
                iconSize: 20,
                color: colors.textSecondary,
                visualDensity: VisualDensity.compact,
              ),
            ),
            Expanded(
              child: Semantics(
                label: l10n.clubVolumeSemantics,
                child: SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    trackHeight: 2,
                    thumbShape: const RoundSliderThumbShape(
                      enabledThumbRadius: 5,
                    ),
                    overlayShape: const RoundSliderOverlayShape(
                      overlayRadius: 12,
                    ),
                  ),
                  child: Slider(
                    value: state.displayVolume,
                    activeColor: colors.textSecondary,
                    inactiveColor: colors.border,
                    onChanged: (value) => cubit.setUserVolume(value),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

String _formatDuration(Duration duration) {
  final minutes = duration.inMinutes;
  final seconds = duration.inSeconds % 60;
  return '$minutes:${seconds.toString().padLeft(2, '0')}';
}
