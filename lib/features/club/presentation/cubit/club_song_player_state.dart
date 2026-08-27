import 'package:equatable/equatable.dart';

/// Volume inicial do player — equilibrado de propósito: 100% arriscaria
/// abrir uma gravação de arquibancada muito alta; um valor bem baixo
/// passaria sensação de áudio quebrado. 65% funciona pras duas situações
/// e ainda deixa margem pro usuário subir.
const kDefaultPlayerVolume = 0.65;

enum ClubSongPlayerStatus { idle, loading, playing, paused, completed, error }

class ClubSongPlayerState extends Equatable {
  const ClubSongPlayerState({
    this.status = ClubSongPlayerStatus.idle,
    this.duration = Duration.zero,
    this.userVolume = kDefaultPlayerVolume,
    this.isMuted = false,
  });

  final ClubSongPlayerStatus status;
  final Duration duration;

  /// Volume escolhido pelo usuário no slider — nunca é zerado pelo mute
  /// (ver [isMuted]), então desmutar sempre volta pro valor de antes, e o
  /// slider nunca "esquece" a posição enquanto está mudo.
  final double userVolume;
  final bool isMuted;

  /// O que de fato sai do alto-falante agora — 0 quando mudo, senão
  /// [userVolume]. É isso (não [userVolume] puro) que o slider deve
  /// mostrar visualmente.
  double get displayVolume => isMuted ? 0.0 : userVolume;

  ClubSongPlayerState copyWith({
    ClubSongPlayerStatus? status,
    Duration? duration,
    double? userVolume,
    bool? isMuted,
  }) {
    return ClubSongPlayerState(
      status: status ?? this.status,
      duration: duration ?? this.duration,
      userVolume: userVolume ?? this.userVolume,
      isMuted: isMuted ?? this.isMuted,
    );
  }

  @override
  List<Object?> get props => [status, duration, userVolume, isMuted];
}
