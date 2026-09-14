import 'package:flutter/material.dart';
import 'package:goias_app/core/club/club_config.dart';
import 'package:goias_app/core/di/injection_container.dart';
import 'package:goias_app/core/l10n/l10n_extensions.dart';
import 'package:goias_app/core/theme/app_colors.dart';
import 'package:goias_app/core/theme/app_spacing.dart';
import 'package:goias_app/features/match/domain/entities/knockout_round.dart';
import 'package:goias_app/features/match/domain/entities/knockout_tie.dart';
import 'package:goias_app/features/match/domain/entities/team.dart';
import 'package:goias_app/features/match/presentation/widgets/segmented_chip_row.dart';
import 'package:goias_app/shared/utils/brazil_time.dart';
import 'package:goias_app/shared/widgets/club_badge.dart';
import 'package:intl/intl.dart';

const double _kScoreColumnWidth = 34;

/// Mata-mata como FASE → LISTA VERTICAL DE CONFRONTOS (spec 2026-09-12) —
/// substitui o antigo `KnockoutBracketView` (colunas horizontais tentando
/// simular um bracket). [rounds] são as rodadas de UMA `CompetitionStage`
/// de mata-mata (Oitavas/Quartas/Semis/Final — só as que existirem nos
/// dados, já ordenadas cronologicamente pelo Worker); o usuário escolhe a
/// rodada num seletor de chips e vê só os confrontos dela, sem nenhum
/// scroll horizontal na lista de jogos.
class KnockoutStageView extends StatefulWidget {
  const KnockoutStageView({required this.rounds, super.key});

  final List<KnockoutRound> rounds;

  @override
  State<KnockoutStageView> createState() => _KnockoutStageViewState();
}

class _KnockoutStageViewState extends State<KnockoutStageView> {
  late String? _selectedRoundId = _initialRoundId();

  String? _initialRoundId() {
    if (widget.rounds.isEmpty) return null;
    for (final round in widget.rounds) {
      if (round.isCurrent) return round.id;
    }
    return widget.rounds.last.id;
  }

  @override
  void didUpdateWidget(covariant KnockoutStageView oldWidget) {
    super.didUpdateWidget(oldWidget);
    final stillExists = widget.rounds.any((r) => r.id == _selectedRoundId);
    if (!stillExists) {
      _selectedRoundId = _initialRoundId();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.rounds.isEmpty) return const SizedBox.shrink();
    final selected = widget.rounds.firstWhere(
      (r) => r.id == _selectedRoundId,
      orElse: () => widget.rounds.last,
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SegmentedChipRow(
          items: [
            for (final round in widget.rounds)
              SegmentedChipItem(id: round.id, label: round.name),
          ],
          selectedId: selected.id,
          onSelected: (id) => setState(() => _selectedRoundId = id),
          padding: EdgeInsets.zero,
        ),
        if (widget.rounds.length > 1) const SizedBox(height: AppSpacing.lg),
        if (selected.ties.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.xl),
            child: Center(
              child: Text(
                context.l10n.standingsUnavailable,
                style: TextStyle(color: context.colors.textHint),
              ),
            ),
          )
        else
          for (var i = 0; i < selected.ties.length; i++) ...[
            if (i > 0) const SizedBox(height: AppSpacing.sm),
            _TieCard(tie: selected.ties[i]),
          ],
      ],
    );
  }
}

/// Um confronto — jogo único ou ida/volta — como card vertical
/// independente, sem nenhuma linha conectando a outros cards (spec item
/// 4/5). Cabe na largura normal de um celular: nome do time trunca antes
/// dos números, os números nunca espremem.
class _TieCard extends StatelessWidget {
  const _TieCard({required this.tie});

  final KnockoutTie tie;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final winner = tie.winner;
    final isTwoLegs = tie.legs.length > 1;
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
          if (isTwoLegs) _ColumnHeaders(tie: tie, colors: colors),
          _TeamRow(
            team: tie.homeTeam,
            legScores: tie.legs.map((l) => l.homeScore).toList(),
            aggregate: isTwoLegs ? tie.aggregateHome : null,
            penalties: tie.wentToPenalties ? tie.penaltyHome : null,
            isWinner: winner?.id == tie.homeTeam.id,
            isActiveClub: tie.homeTeam.matchesClub(sl<ClubConfig>()),
          ),
          const SizedBox(height: AppSpacing.xs),
          _TeamRow(
            team: tie.awayTeam,
            legScores: tie.legs.map((l) => l.awayScore).toList(),
            aggregate: isTwoLegs ? tie.aggregateAway : null,
            penalties: tie.wentToPenalties ? tie.penaltyAway : null,
            isWinner: winner?.id == tie.awayTeam.id,
            isActiveClub: tie.awayTeam.matchesClub(sl<ClubConfig>()),
          ),
          if (!tie.isDecided && !tie.wentToPenalties) ...[
            const SizedBox(height: AppSpacing.xs),
            Text(
              _pendingLabel(context),
              style: TextStyle(fontSize: 11, color: colors.textHint),
            ),
          ],
        ],
      ),
    );
  }

  String _pendingLabel(BuildContext context) {
    final l10n = context.l10n;
    final locale = Localizations.localeOf(context).toString();
    final nextLeg = tie.legs.where((l) => l.kickoff != null).lastOrNull;
    final kickoff = nextLeg?.kickoff;
    if (kickoff == null) return '';
    final label = tie.legs.length > 1
        ? (nextLeg!.legType == KnockoutLegType.first
              ? l10n.knockoutFirstLeg
              : l10n.knockoutSecondLeg)
        : null;
    // `toBrazilTime`, nunca `.toLocal()` (spec 2026-09-12).
    final formatted = DateFormat(
      'd MMM · HH:mm',
      locale,
    ).format(toBrazilTime(kickoff));
    return label != null ? '$label · $formatted' : formatted;
  }
}

/// "IDA · VOLTA · AGREGADO" acima dos placares — só existe quando o
/// confronto tem duas pernas (spec item 4/7: jogo único nunca ganha uma
/// coluna "VOLTA" artificial).
class _ColumnHeaders extends StatelessWidget {
  const _ColumnHeaders({required this.tie, required this.colors});

  final KnockoutTie tie;
  final AppColors colors;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.xs),
      child: Row(
        children: [
          const Spacer(),
          for (final leg in tie.legs)
            SizedBox(
              width: _kScoreColumnWidth,
              child: Text(
                leg.legType == KnockoutLegType.first
                    ? l10n.knockoutFirstLeg
                    : l10n.knockoutSecondLeg,
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 9.5, color: colors.textHint),
              ),
            ),
          SizedBox(
            width: _kScoreColumnWidth,
            child: Text(
              l10n.knockoutAggregateShort,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 9.5,
                fontWeight: FontWeight.w700,
                color: colors.textHint,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TeamRow extends StatelessWidget {
  const _TeamRow({
    required this.team,
    required this.legScores,
    required this.aggregate,
    required this.penalties,
    required this.isWinner,
    required this.isActiveClub,
  });

  final Team team;
  final List<int?> legScores;
  final int? aggregate;
  final int? penalties;
  final bool isWinner;
  final bool isActiveClub;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      // Destaque discreto do clube do flavor (spec item 10) — barra lateral
      // fina na cor primária, nunca amarelo hardcoded; genérico pra
      // qualquer clube via `Team.matchesClub`.
      decoration: isActiveClub
          ? BoxDecoration(
              border: Border(left: BorderSide(color: colors.primary, width: 3)),
            )
          : null,
      padding: isActiveClub
          ? const EdgeInsets.only(left: AppSpacing.xs)
          : EdgeInsets.zero,
      child: Row(
        children: [
          ClubBadge(team: team, size: 22),
          const SizedBox(width: AppSpacing.xs),
          Expanded(
            // Nome completo (spec 2026-09-12: "temos espaço pra colocar o
            // nome do time completo") — `shortName` só entrava quando o
            // card era mais apertado (layout de bracket antigo); a lista
            // vertical atual sobra largura, e o `Expanded`+ellipsis
            // continua protegendo o placar em qualquer tamanho de tela.
            child: Text(
              team.name,
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
              style: TextStyle(
                fontSize: 13,
                fontWeight: isWinner || isActiveClub
                    ? FontWeight.w800
                    : FontWeight.w600,
                color: colors.textPrimary,
              ),
            ),
          ),
          for (final score in legScores)
            // Jogo único: essa É a nota final do confronto, ganha o mesmo
            // destaque de pílula que o agregado teria em ida/volta (spec
            // 2026-09-12: "deixar um pouco mais destacado o time que
            // classificou") — sem largura fixa, a pílula cresce o quanto
            // precisar. Ida/volta: cada perna é só um dado intermediário,
            // fica neutra numa coluna estreita — quem sinaliza o vencedor
            // é a coluna de agregado.
            legScores.length == 1
                ? _ScorePill(
                    text: score?.toString() ?? '-',
                    highlighted: isWinner,
                  )
                : SizedBox(
                    width: _kScoreColumnWidth,
                    child: Text(
                      score?.toString() ?? '-',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: colors.textSecondary,
                      ),
                    ),
                  ),
          if (aggregate != null)
            _ScorePill(
              text: penalties != null
                  ? '$aggregate ($penalties)'
                  : '$aggregate',
              highlighted: isWinner,
            ),
        ],
      ),
    );
  }
}

/// Placar decisivo do confronto (agregado em ida/volta, placar único em
/// jogo só) — vira uma pílula na cor primária do flavor quando é o time
/// que avançou, pra ficar claramente mais destacado que os placares de
/// cada perna (spec 2026-09-12).
class _ScorePill extends StatelessWidget {
  const _ScorePill({required this.text, required this.highlighted});

  final String text;
  final bool highlighted;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    // `minWidth`, nunca uma largura fixa: garante que o placar de quem NÃO
    // classificou alinhe com a coluna normal, mas deixa a pílula do
    // vencedor crescer o quanto precisar (ex.: "1 (8)" de pênaltis) sem
    // cortar o texto.
    return ConstrainedBox(
      constraints: const BoxConstraints(minWidth: _kScoreColumnWidth),
      child: !highlighted
          ? Text(
              text,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w800,
                color: colors.textPrimary,
              ),
            )
          : Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
              decoration: BoxDecoration(
                color: colors.primary.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                text,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w900,
                  color: colors.primary,
                ),
              ),
            ),
    );
  }
}
