import 'package:flutter/material.dart';
import 'package:goias_app/core/l10n/l10n_extensions.dart';
import 'package:goias_app/core/theme/app_colors.dart';
import 'package:goias_app/core/theme/app_spacing.dart';
import 'package:goias_app/features/match/domain/entities/knockout_round.dart';
import 'package:goias_app/features/match/domain/entities/knockout_tie.dart';
import 'package:goias_app/features/match/domain/entities/team.dart';
import 'package:goias_app/shared/widgets/club_badge.dart';
import 'package:intl/intl.dart';

const double _kColumnWidth = 240;
const double _kColumnHeight = 460;

/// Chaveamento de mata-mata — uma coluna por rodada (Oitavas/Quartas/Semi/
/// Final...), scroll horizontal no mobile (spec multi-competição
/// 2026-09-10/11, item 6/8/15). [rounds] são as rodadas de UMA
/// `CompetitionStage` de mata-mata (já ordenadas pelo Worker),
/// [focusRoundId] é a rodada atual (`CompetitionStage.currentRound`) — a
/// view rola até a coluna correspondente uma vez, mas TODAS as rodadas
/// continuam visíveis/roláveis.
class KnockoutBracketView extends StatefulWidget {
  const KnockoutBracketView({
    required this.rounds,
    this.focusRoundId,
    super.key,
  });

  final List<KnockoutRound> rounds;
  final String? focusRoundId;

  @override
  State<KnockoutBracketView> createState() => _KnockoutBracketViewState();
}

class _KnockoutBracketViewState extends State<KnockoutBracketView> {
  final _controller = ScrollController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToFocus());
  }

  @override
  void didUpdateWidget(covariant KnockoutBracketView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.focusRoundId != widget.focusRoundId) {
      _scrollToFocus();
    }
  }

  void _scrollToFocus() {
    if (!_controller.hasClients) return;
    final index = widget.rounds.indexWhere((r) => r.id == widget.focusRoundId);
    if (index <= 0) return;
    final target = (index * (_kColumnWidth + AppSpacing.lg)).clamp(
      0.0,
      _controller.position.maxScrollExtent,
    );
    // `jumpTo` em vez de `animateTo`: rodar a lista inteira de uma vez no
    // primeiro frame é mais estável que animar (spec item 8: "se causar
    // instabilidade de lifecycle/layout, priorize estabilidade") — a troca
    // de rodada pelo usuário (tap no card/seletor futuro) continua podendo
    // usar `animateTo` sem risco, é só a inicialização que prioriza
    // segurança.
    _controller.jumpTo(target);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.rounds.isEmpty) return const SizedBox.shrink();
    return SizedBox(
      height: _kColumnHeight,
      child: ListView.separated(
        controller: _controller,
        scrollDirection: Axis.horizontal,
        itemCount: widget.rounds.length,
        separatorBuilder: (_, _) => const SizedBox(width: AppSpacing.lg),
        itemBuilder: (context, index) {
          final round = widget.rounds[index];
          return _RoundColumn(
            round: round,
            isFocused: round.id == widget.focusRoundId,
          );
        },
      ),
    );
  }
}

class _RoundColumn extends StatelessWidget {
  const _RoundColumn({required this.round, required this.isFocused});

  final KnockoutRound round;
  final bool isFocused;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return SizedBox(
      width: _kColumnWidth,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            round.name.toUpperCase(),
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.6,
              color: isFocused ? colors.primary : colors.textHint,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Expanded(
            child: round.ties.isEmpty
                ? Center(
                    child: Text(
                      context.l10n.standingsUnavailable,
                      textAlign: TextAlign.center,
                      style: TextStyle(color: colors.textHint, fontSize: 12.5),
                    ),
                  )
                : ListView.separated(
                    itemCount: round.ties.length,
                    separatorBuilder: (_, _) =>
                        const SizedBox(height: AppSpacing.sm),
                    itemBuilder: (context, index) =>
                        _TieCard(tie: round.ties[index]),
                  ),
          ),
        ],
      ),
    );
  }
}

class _TieCard extends StatelessWidget {
  const _TieCard({required this.tie});

  final KnockoutTie tie;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final winner = tie.winner;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: colors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _TeamRow(
            team: tie.homeTeam,
            score: tie.aggregateHome,
            isWinner: winner?.id == tie.homeTeam.id,
          ),
          const SizedBox(height: AppSpacing.xs),
          _TeamRow(
            team: tie.awayTeam,
            score: tie.aggregateAway,
            isWinner: winner?.id == tie.awayTeam.id,
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            _statusLabel(context),
            style: TextStyle(fontSize: 11, color: colors.textHint),
          ),
        ],
      ),
    );
  }

  String _statusLabel(BuildContext context) {
    final l10n = context.l10n;
    if (tie.wentToPenalties) {
      return l10n.knockoutPenalties(tie.penaltyHome!, tie.penaltyAway!);
    }
    if (tie.isDecided) return l10n.matchStatusFinished;
    final locale = Localizations.localeOf(context).toString();
    final nextLeg = tie.legs.where((l) => l.kickoff != null).lastOrNull;
    final kickoff = nextLeg?.kickoff;
    if (kickoff == null) return '';
    final label = tie.legs.length > 1
        ? (nextLeg!.legType == KnockoutLegType.first
              ? l10n.knockoutFirstLeg
              : l10n.knockoutSecondLeg)
        : null;
    final formatted = DateFormat('d MMM · HH:mm', locale).format(kickoff);
    return label != null ? '$label · $formatted' : formatted;
  }
}

class _TeamRow extends StatelessWidget {
  const _TeamRow({
    required this.team,
    required this.score,
    required this.isWinner,
  });

  final Team team;
  final int? score;
  final bool isWinner;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Row(
      children: [
        ClubBadge(team: team, size: 22),
        const SizedBox(width: AppSpacing.xs),
        Expanded(
          child: Text(
            team.shortName,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 13,
              fontWeight: isWinner ? FontWeight.w800 : FontWeight.w600,
              color: colors.textPrimary,
            ),
          ),
        ),
        Text(
          score?.toString() ?? '-',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w800,
            color: isWinner ? colors.primary : colors.textPrimary,
          ),
        ),
      ],
    );
  }
}
