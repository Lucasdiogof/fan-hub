import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:goias_app/features/home/presentation/cubit/home_cubit.dart';
import 'package:goias_app/features/home/presentation/widgets/live_match_hero.dart';
import 'package:goias_app/features/home/presentation/widgets/next_match_hero.dart';
import 'package:goias_app/features/match/domain/entities/match.dart';
import 'package:goias_app/features/match/presentation/match_navigation.dart';
import 'package:goias_app/features/match/presentation/widgets/live_match_poller.dart';

/// Escolhe entre a contagem regressiva (pré-jogo) e o placar ao vivo — quem
/// decide é `match.status`, nunca o relógio local do widget: `HomeCubit`
/// só mantém o jogo aqui enquanto ele está "aberto"
/// (`MatchOrdering.isOpen`), então quando o jogo termina de verdade a
/// própria Home para de mostrar este card (ver `home_page.dart`). A
/// contagem chegar a zero só dispara um recarregamento (`HomeCubit.load`)
/// pra buscar o status real — nunca assume "começou" só pelo relógio.
class NextMatchSection extends StatelessWidget {
  const NextMatchSection({required this.match, this.onTickets, super.key});

  final Match match;
  final VoidCallback? onTickets;

  bool get _isLive =>
      match.status == MatchStatus.live || match.status == MatchStatus.halftime;

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
        child: _isLive
            ? LiveMatchPoller(
                key: const ValueKey('live'),
                match: match,
                onMatchEnded: () => context.read<HomeCubit>().load(),
                builder: (context, liveMatch) => LiveMatchHero(
                  match: liveMatch,
                  onFollow: () => openMatchDetails(context, liveMatch),
                ),
              )
            : NextMatchHero(
                key: const ValueKey('upcoming'),
                match: match,
                onTickets: onTickets,
                onMatchStarted: () => context.read<HomeCubit>().load(),
              ),
      ),
    );
  }
}
