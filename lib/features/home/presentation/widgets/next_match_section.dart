import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:goias_app/core/di/injection_container.dart';
import 'package:goias_app/features/home/presentation/widgets/next_match_hero.dart';
import 'package:goias_app/features/match/domain/entities/match.dart';
import 'package:goias_app/features/match/domain/repositories/football_repository.dart';
import 'package:goias_app/features/match/presentation/cubit/match_details_cubit.dart';
import 'package:goias_app/shared/widgets/global_loading.dart';

/// Decide se o Hero do próximo jogo aparece — e some suavemente (sem
/// recompilar a Home inteira) assim que `match.kickoff` chega. Não inventa
/// "AO VIVO": quando o tempo zera, o card simplesmente deixa de existir.
class NextMatchSection extends StatefulWidget {
  const NextMatchSection({required this.match, this.onTickets, super.key});

  final Match match;
  final VoidCallback? onTickets;

  @override
  State<NextMatchSection> createState() => _NextMatchSectionState();
}

class _NextMatchSectionState extends State<NextMatchSection> {
  bool _hidden = false;

  @override
  void didUpdateWidget(covariant NextMatchSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.match.id != widget.match.id) {
      _hidden = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    // Sem horário confirmado (kickoff == null), não tem como já ter
    // começado — trata como ainda por vir.
    final kickoff = widget.match.kickoff;
    final alreadyStarted = kickoff != null && !DateTime.now().isBefore(kickoff);
    final show = !_hidden && !alreadyStarted;

    return AnimatedSize(
      duration: const Duration(milliseconds: 320),
      curve: Curves.easeOut,
      alignment: Alignment.topCenter,
      child: show
          ? NextMatchHero(
              match: widget.match,
              onTickets: widget.onTickets,
              onViewDetails: () => _openMatchDetails(context, widget.match),
              onMatchStarted: () {
                if (mounted) setState(() => _hidden = true);
              },
            )
          : const SizedBox(width: double.infinity),
    );
  }

  Future<void> _openMatchDetails(BuildContext context, Match match) async {
    final cubit = MatchDetailsCubit(sl<FootballRepository>(), match.id);
    await GlobalLoading.run(context, cubit.load);
    if (!context.mounted) return;
    unawaited(context.push('/match/${match.id}', extra: cubit));
  }
}
