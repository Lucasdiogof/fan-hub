import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:goias_app/core/di/injection_container.dart';
import 'package:goias_app/core/theme/app_colors.dart';
import 'package:goias_app/core/theme/app_spacing.dart';
import 'package:goias_app/features/match/domain/entities/match.dart';
import 'package:goias_app/features/match/domain/entities/match_event.dart';
import 'package:goias_app/features/match/domain/entities/team.dart';
import 'package:goias_app/features/match/domain/repositories/football_repository.dart';
import 'package:goias_app/features/match/presentation/cubit/match_details_cubit.dart';
import 'package:goias_app/features/match/presentation/cubit/match_details_state.dart';
import 'package:goias_app/features/match/presentation/widgets/match_events_timeline.dart';
import 'package:goias_app/features/match/presentation/widgets/match_status_label.dart';
import 'package:goias_app/shared/utils/date_labels.dart';
import 'package:goias_app/shared/widgets/club_badge.dart';
import 'package:goias_app/shared/widgets/refreshable_state_view.dart';

/// [cubit], quando fornecido, já veio construído e carregado por quem
/// navegou pra cá (ver `GlobalLoading.run` nos pontos de entrada) — a tela
/// só reaproveita via `BlocProvider.value`. Fica `null` (e a tela cria/
/// carrega o próprio Cubit, como antes) só em navegação direta por URL
/// (deep link, voltar/avançar do navegador) — o app é PWA, então isso
/// precisa continuar funcionando sem quebrar.
class MatchDetailsPage extends StatelessWidget {
  const MatchDetailsPage({required this.fixtureId, this.cubit, super.key});

  final String fixtureId;
  final MatchDetailsCubit? cubit;

  @override
  Widget build(BuildContext context) {
    final preloaded = cubit;
    if (preloaded != null) {
      return BlocProvider.value(
        value: preloaded,
        child: const _MatchDetailsView(),
      );
    }
    return BlocProvider(
      create: (_) =>
          MatchDetailsCubit(sl<FootballRepository>(), fixtureId)..load(),
      child: const _MatchDetailsView(),
    );
  }
}

class _MatchDetailsView extends StatelessWidget {
  const _MatchDetailsView();

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Scaffold(
      backgroundColor: colors.background,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                AppSpacing.md,
                AppSpacing.lg,
                0,
              ),
              child: _BackButton(onTap: () => context.pop()),
            ),
            Expanded(
              child: BlocBuilder<MatchDetailsCubit, MatchDetailsState>(
                builder: (context, state) {
                  return RefreshableStateView(
                    status: state.status,
                    onRefresh: () => context.read<MatchDetailsCubit>().load(),
                    errorMessage: state.errorMessage,
                    emptyIcon: Icons.sports_soccer_outlined,
                    emptyTitle: 'Não foi possível carregar a partida.',
                    successBuilder: (context) => _MatchDetailsContent(
                      match: state.match!,
                      events: state.events,
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BackButton extends StatelessWidget {
  const _BackButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Container(
        width: 38,
        height: 38,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: colors.secondary,
          shape: BoxShape.circle,
        ),
        child: Icon(
          Icons.arrow_back_rounded,
          size: 18,
          color: colors.textPrimary,
        ),
      ),
    );
  }
}

class _MatchDetailsContent extends StatelessWidget {
  const _MatchDetailsContent({required this.match, required this.events});

  final Match match;
  final List<MatchEvent> events;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return ListView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.lg,
        AppSpacing.lg,
        AppSpacing.xxxl,
      ),
      children: [
        Text(
          match.competition.toUpperCase(),
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.2,
            color: colors.primary,
          ),
        ),
        if (match.round.isNotEmpty) ...[
          const SizedBox(height: 4),
          Text(
            match.round.toUpperCase(),
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: colors.textHint,
            ),
          ),
        ],
        const SizedBox(height: AppSpacing.xxl),
        Row(
          children: [
            Expanded(child: _TeamBlock(team: match.homeTeam)),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
              child: _ScoreOrVs(match: match),
            ),
            Expanded(child: _TeamBlock(team: match.awayTeam)),
          ],
        ),
        const SizedBox(height: AppSpacing.xxl),
        Text(
          match.kickoff != null
              ? shortDateLabel(match.kickoff!)
              : 'Data a confirmar',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: colors.textPrimary,
          ),
        ),
        if (match.kickoff != null) ...[
          const SizedBox(height: 2),
          Text(
            timeLabel(match.kickoff!),
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: colors.textSecondary,
            ),
          ),
        ],
        if (match.stadium.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.sm),
          Text(
            match.stadium.toUpperCase(),
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w700,
              color: colors.textPrimary,
            ),
          ),
          if (match.city != null)
            Text(
              match.city!,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: colors.textHint),
            ),
        ],
        const SizedBox(height: AppSpacing.xxxl),
        Text(
          'INFORMAÇÕES',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.2,
            color: colors.textSecondary,
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.sm,
          ),
          decoration: BoxDecoration(
            color: colors.surface,
            borderRadius: BorderRadius.circular(AppRadius.card),
            border: Border.all(color: colors.border),
          ),
          child: Column(
            children: [
              _InfoRow(
                label: 'Data',
                value: match.kickoff != null
                    ? shortDateLabel(match.kickoff!)
                    : 'A confirmar',
              ),
              _InfoRow(
                label: 'Horário',
                value: match.kickoff != null ? timeLabel(match.kickoff!) : '—',
              ),
              _InfoRow(
                label: 'Estádio',
                value: match.stadium.isEmpty ? '—' : match.stadium,
              ),
              if (match.city != null)
                _InfoRow(label: 'Cidade', value: match.city!),
              _InfoRow(label: 'Competição', value: match.competition),
              _InfoRow(
                label: 'Rodada',
                value: match.round.isEmpty ? '—' : match.round,
              ),
              _InfoRow(
                label: 'Status',
                value: matchStatusLabel(match.status),
                isLast: true,
              ),
            ],
          ),
        ),
        MatchEventsTimeline(match: match, events: events),
      ],
    );
  }
}

class _ScoreOrVs extends StatelessWidget {
  const _ScoreOrVs({required this.match});

  final Match match;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final homeScore = match.homeScore;
    final awayScore = match.awayScore;
    if (homeScore == null || awayScore == null) {
      return Text(
        'X',
        style: TextStyle(color: colors.textHint, fontWeight: FontWeight.w800),
      );
    }
    return Text(
      '$homeScore x $awayScore',
      style: TextStyle(
        color: colors.textPrimary,
        fontWeight: FontWeight.w900,
        fontSize: 22,
      ),
    );
  }
}

class _TeamBlock extends StatelessWidget {
  const _TeamBlock({required this.team});

  final Team team;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        ClubBadge(team: team, size: 60),
        const SizedBox(height: AppSpacing.sm),
        Text(
          team.name.toUpperCase(),
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontWeight: FontWeight.w800,
            fontSize: 13,
            color: colors.textPrimary,
          ),
        ),
      ],
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.label,
    required this.value,
    this.isLast = false,
  });

  final String label;
  final String value;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
      decoration: BoxDecoration(
        border: isLast
            ? null
            : Border(bottom: BorderSide(color: colors.border)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(fontSize: 13, color: colors.textSecondary),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: colors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}
