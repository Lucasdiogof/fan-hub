import 'package:flutter/material.dart';
import 'package:goias_app/features/home/presentation/widgets/live_match_hero.dart';
import 'package:goias_app/features/home/presentation/widgets/next_match_hero.dart';
import 'package:goias_app/features/match/domain/entities/match.dart';
import 'package:goias_app/features/match/presentation/match_navigation.dart';

/// Escolhe entre a contagem regressiva (pré-jogo), o placar ao vivo e o
/// placar final (jogo recém-encerrado, dentro da folga que `HomeCubit`
/// decide) — quem decide é `match.status`, nunca o relógio local do widget.
/// Puramente apresentacional: [match] já vem resolvido (e, se ao vivo, já
/// mantido atualizado por um `LiveMatchPoller`) por quem monta esta seção
/// (`home_page.dart`) — a mesma partida que alimenta o `CompactMatchHeader`,
/// nunca uma segunda busca/poller independente aqui.
class NextMatchSection extends StatelessWidget {
  const NextMatchSection({
    required this.match,
    this.onTickets,
    this.onMatchStarted,
    super.key,
  });

  final Match match;
  final VoidCallback? onTickets;
  final VoidCallback? onMatchStarted;

  bool get _showsScoreCard =>
      match.status == MatchStatus.live ||
      match.status == MatchStatus.halftime ||
      match.status == MatchStatus.finished;

  @override
  Widget build(BuildContext context) {
    return AnimatedSize(
      duration: const Duration(milliseconds: 320),
      curve: Curves.easeOut,
      alignment: Alignment.topCenter,
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 320),
        switchInCurve: Curves.easeOut,
        switchOutCurve: Curves.easeIn,
        child: _showsScoreCard
            ? LiveMatchHero(
                key: const ValueKey('live'),
                match: match,
                onFollow: () => openMatchDetails(context, match),
              )
            : NextMatchHero(
                key: const ValueKey('upcoming'),
                match: match,
                onTap: () => openMatchDetails(context, match),
                onTickets: onTickets,
                onMatchStarted: onMatchStarted,
              ),
      ),
    );
  }
}
