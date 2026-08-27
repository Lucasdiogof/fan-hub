import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:goias_app/features/club/data/club_song_volume_store.dart';
import 'package:goias_app/features/club/domain/entities/club_song.dart';
import 'package:goias_app/features/club/presentation/cubit/club_song_player_state.dart';
import 'package:just_audio/just_audio.dart';

/// Player de UMA música — vive só enquanto a página de detalhes dela está
/// aberta. Criado via `BlocProvider` (não DI singleton): o próprio
/// `BlocProvider` chama `close()` quando a página é desempilhada, e é lá
/// que o `AudioPlayer` para e libera os recursos (ver [close]) — nunca
/// música tocando em segundo plano, nunca dois `AudioPlayer` simultâneos.
class ClubSongPlayerCubit extends Cubit<ClubSongPlayerState> {
  ClubSongPlayerCubit(this.song, this._volumeStore)
    : super(const ClubSongPlayerState()) {
    _playerStateSubscription = _player.playerStateStream.listen(
      _onPlayerStateChanged,
    );
  }

  final ClubSong song;
  final ClubSongVolumeStore _volumeStore;
  final AudioPlayer _player = AudioPlayer();
  late final StreamSubscription<PlayerState> _playerStateSubscription;

  /// Fica de fora do estado de propósito — muda muitas vezes por segundo
  /// enquanto toca, e um `emit` a cada tique geraria rebuild da tela
  /// inteira. A barra de progresso assina isso direto via `StreamBuilder`.
  Stream<Duration> get positionStream => _player.positionStream;

  Future<void> init() async {
    final savedVolume = await _volumeStore.loadVolume();
    emit(state.copyWith(userVolume: savedVolume));
    await _applyVolume();

    final asset = song.audioAsset;
    if (asset == null) return;
    try {
      final duration = await _player.setAsset(asset);
      emit(state.copyWith(duration: duration ?? Duration.zero));
    } catch (_) {
      emit(state.copyWith(status: ClubSongPlayerStatus.error));
    }
  }

  void _onPlayerStateChanged(PlayerState playerState) {
    final processingState = playerState.processingState;
    if (processingState == ProcessingState.completed) {
      // Volta pro início — a próxima vez que o usuário der play começa do
      // zero, nunca "reproduz" um fim já alcançado.
      unawaited(_player.pause());
      unawaited(_player.seek(Duration.zero));
      emit(state.copyWith(status: ClubSongPlayerStatus.completed));
      return;
    }
    if (processingState == ProcessingState.loading ||
        processingState == ProcessingState.buffering) {
      emit(state.copyWith(status: ClubSongPlayerStatus.loading));
      return;
    }
    if (processingState == ProcessingState.idle) return;
    emit(
      state.copyWith(
        status: playerState.playing
            ? ClubSongPlayerStatus.playing
            : ClubSongPlayerStatus.paused,
      ),
    );
  }

  Future<void> togglePlayback() async {
    if (song.audioAsset == null) return;
    if (state.status == ClubSongPlayerStatus.playing) {
      await _player.pause();
      return;
    }
    if (state.status == ClubSongPlayerStatus.loading) return;
    try {
      await _player.play();
    } catch (_) {
      emit(state.copyWith(status: ClubSongPlayerStatus.error));
    }
  }

  Future<void> seek(Duration position) => _player.seek(position);

  /// Volume ESCOLHIDO PELO USUÁRIO — o volume de fato aplicado no player
  /// ainda passa pelo `volumeFactor` da faixa (ver [_applyVolume]), mas o
  /// slider sempre reflete só isto aqui, nunca o valor já compensado.
  Future<void> setUserVolume(double value) async {
    emit(state.copyWith(userVolume: value.clamp(0.0, 1.0), isMuted: false));
    await _applyVolume();
    unawaited(_volumeStore.saveVolume(state.userVolume));
  }

  Future<void> toggleMute() async {
    emit(state.copyWith(isMuted: !state.isMuted));
    await _applyVolume();
  }

  /// `userVolume × volumeFactor` — o slider nunca mostra esse número, só o
  /// player recebe. Compensa gravações mais altas/baixas sem que o usuário
  /// precise reajustar o volume toda vez que troca de música.
  Future<void> _applyVolume() async {
    final effective = (state.displayVolume * song.volumeFactor).clamp(0.0, 1.0);
    await _player.setVolume(effective);
  }

  @override
  Future<void> close() async {
    await _playerStateSubscription.cancel();
    await _player.stop();
    await _player.dispose();
    return super.close();
  }
}
