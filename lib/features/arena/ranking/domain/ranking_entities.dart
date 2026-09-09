import 'package:equatable/equatable.dart';

enum RankingPeriod { weekly, monthly, allTime }

extension RankingPeriodApi on RankingPeriod {
  String get apiValue => switch (this) {
    RankingPeriod.weekly => 'weekly',
    RankingPeriod.monthly => 'monthly',
    RankingPeriod.allTime => 'all_time',
  };
}

/// Ids estáveis dos 4 jogos pra fins de pontuação — não confundir com o
/// `gameId()` por dificuldade que o Quiz já usava no sistema de recorde
/// antigo (removido). Aqui cada jogo é UM balde de pontos só, mesmo o Quiz
/// tendo 3 dificuldades internamente. Os nomes de exibição vêm do l10n
/// (ver `arenaGameQuizTitle` etc.), não daqui — esta classe não sabe de UI.
class ArenaGameIds {
  const ArenaGameIds._();

  static const quiz = 'quiz';
  static const lineup = 'lineup';
  static const careerPath = 'career_path';
  static const guessPlayer = 'guess_player';
  static const tacticalIdentity = 'tactical_identity';
  static const playerIdentity = 'player_identity';

  /// `item_id` fixo dos 2 jogos de perfil acima — eles não têm coleção de
  /// conteúdo (pergunta/jogador/partida), só um resultado único por
  /// usuário, então o anti-replay da RPC (`arena_record_score`) ancora
  /// nesta chave constante, nunca um id de conteúdo real.
  static const profileItemId = 'profile';
}

class RankingEntry extends Equatable {
  const RankingEntry({
    required this.rank,
    required this.userId,
    required this.name,
    required this.totalScore,
    required this.isMe,
    this.avatarUrl,
    this.isMember = false,
  });

  final int rank;
  final String userId;
  final String name;
  final String? avatarUrl;
  final bool isMember;
  final int totalScore;
  final bool isMe;

  RankingEntry copyWith({bool? isMember}) => RankingEntry(
    rank: rank,
    userId: userId,
    name: name,
    totalScore: totalScore,
    isMe: isMe,
    avatarUrl: avatarUrl,
    isMember: isMember ?? this.isMember,
  );

  @override
  List<Object?> get props => [
    rank,
    userId,
    name,
    avatarUrl,
    isMember,
    totalScore,
    isMe,
  ];
}

class GameScoreBreakdown extends Equatable {
  const GameScoreBreakdown({
    required this.gameId,
    required this.score,
    required this.firstTryCount,
    required this.reviewCount,
    required this.abandonedOrRevealedCount,
  });

  final String gameId;
  final int score;
  final int firstTryCount;
  final int reviewCount;
  final int abandonedOrRevealedCount;

  @override
  List<Object?> get props => [
    gameId,
    score,
    firstTryCount,
    reviewCount,
    abandonedOrRevealedCount,
  ];
}

class RankingUserDetail extends Equatable {
  const RankingUserDetail({required this.entry, required this.breakdown});

  final RankingEntry entry;
  final List<GameScoreBreakdown> breakdown;

  int get firstTryTotal => breakdown.fold(0, (sum, b) => sum + b.firstTryCount);
  int get reviewTotal => breakdown.fold(0, (sum, b) => sum + b.reviewCount);
  int get abandonedOrRevealedTotal =>
      breakdown.fold(0, (sum, b) => sum + b.abandonedOrRevealedCount);

  @override
  List<Object?> get props => [entry, breakdown];
}

/// Resultado de uma chamada de pontuação — é isso que a tela de resultado
/// de cada jogo usa pra mostrar "+N pontos". `pointsEarned` já vem pronto
/// do servidor (pode ser 0 se o item já valia igual ou mais antes).
class ScoreResult extends Equatable {
  const ScoreResult({
    required this.pointsEarned,
    required this.itemScore,
    required this.totalScore,
    required this.gameScore,
  });

  final int pointsEarned;
  final int itemScore;
  final int totalScore;
  final int gameScore;

  @override
  List<Object?> get props => [pointsEarned, itemScore, totalScore, gameScore];
}
