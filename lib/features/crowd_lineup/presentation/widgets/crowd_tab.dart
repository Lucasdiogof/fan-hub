import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:goias_app/core/l10n/l10n_extensions.dart';
import 'package:goias_app/core/theme/app_colors.dart';
import 'package:goias_app/core/theme/app_spacing.dart';
import 'package:goias_app/features/arena/shared/arena_colors.dart';
import 'package:goias_app/features/crowd_lineup/domain/crowd_lineup.dart';
import 'package:goias_app/shared/domain/player_position.dart';
import 'package:goias_app/features/crowd_lineup/presentation/cubit/crowd_lineup_cubit.dart';
import 'package:goias_app/features/crowd_lineup/presentation/cubit/crowd_lineup_state.dart';
import 'package:goias_app/features/crowd_lineup/presentation/layout/lineup_layout_engine.dart';
import 'package:goias_app/features/crowd_lineup/presentation/widgets/lineup_field.dart';
import 'package:goias_app/features/crowd_lineup/presentation/widgets/lineup_name_label.dart';
import 'package:goias_app/features/crowd_lineup/presentation/widgets/lineup_percent_badge.dart';
import 'package:goias_app/shared/widgets/jersey_shirt.dart';

class CrowdTab extends StatelessWidget {
  const CrowdTab({required this.isHome, required this.fieldKey, super.key});

  final bool isHome;

  /// Dono é a página (`CrowdLineupPage`) — o botão de compartilhar mora no
  /// cabeçalho, fora desta aba, e precisa alcançar o mesmo `RepaintBoundary`.
  final GlobalKey fieldKey;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CrowdLineupCubit, CrowdLineupState>(
      buildWhen: (a, b) => a.crowd != b.crowd,
      builder: (context, state) {
        final crowd = state.crowd;
        if (!crowd.hasVotes) return const _EmptyCrowd();

        return SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.md,
            AppSpacing.lg,
            AppSpacing.xl,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _Summary(crowd: crowd),
              const SizedBox(height: AppSpacing.sm),
              RepaintBoundary(
                key: fieldKey,
                child: LineupField(
                  formation: crowd.topFormation!,
                  mode: LineupRenderMode.crowd,
                  slotBuilder: (slotIndex, slot, footprint) {
                    final result = slotIndex < crowd.slots.length
                        ? crowd.slots[slotIndex]
                        : null;
                    return _CrowdSlot(
                      result: result,
                      position: slot.position.short(context),
                      footprint: footprint,
                      isHome: isHome,
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _Summary extends StatelessWidget {
  const _Summary({required this.crowd});

  final CrowdLineup crowd;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(color: colors.border),
      ),
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Row(
        children: [
          Expanded(
            child: _Metric(
              value: '${crowd.totalVotes}',
              label: context.l10n.crowdSubmissionsLabel(crowd.totalVotes),
            ),
          ),
          Container(width: 1, height: 36, color: colors.border),
          Expanded(
            child: _Metric(
              value: crowd.topFormation!.label,
              label: context.l10n.crowdMostVotedFormation,
            ),
          ),
        ],
      ),
    );
  }
}

class _Metric extends StatelessWidget {
  const _Metric({required this.value, required this.label});

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w900,
            color: colors.primary,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 11.5,
            fontWeight: FontWeight.w600,
            color: colors.textSecondary,
          ),
        ),
      ],
    );
  }
}

class _CrowdSlot extends StatelessWidget {
  const _CrowdSlot({
    required this.result,
    required this.position,
    required this.footprint,
    required this.isHome,
  });

  final CrowdSlotResult? result;
  final String position;
  final PlayerVisualFootprint footprint;
  final bool isHome;

  @override
  Widget build(BuildContext context) {
    final player = result?.player;
    final avatarSize = footprint.jerseySize;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (player == null)
          _EmptyJersey(size: avatarSize)
        else
          JerseyShirt(
            size: avatarSize,
            number: player.shirtNumber,
            fillColor: isHome ? ArenaColors.goiasOutfield : Colors.white,
            numberColor: isHome ? Colors.white : ArenaColors.goiasOutfield,
            trimColor: isHome ? Colors.white : ArenaColors.goiasOutfield,
          ),
        const SizedBox(height: 3),
        if (result != null && player != null)
          LineupPercentBadge(percent: result!.percent)
        else
          const SizedBox(height: 15),
        const SizedBox(height: 4),
        LineupNameLabel(
          text: player?.name ?? position,
          maxWidth: footprint.width,
          maxLines: footprint.nameMaxLines,
          allowSplit: player != null,
        ),
      ],
    );
  }
}

/// Slot sem voto suficiente pra aparecer na escalação consolidada — mesma
/// silhueta apagada usada na aba "Escale".
class _EmptyJersey extends StatelessWidget {
  const _EmptyJersey({required this.size});

  final double size;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return JerseyShirt(
      size: size,
      fillColor: colors.primary.withValues(alpha: 0.08),
      trimColor: colors.primary.withValues(alpha: 0.35),
    );
  }
}

class _EmptyCrowd extends StatelessWidget {
  const _EmptyCrowd();

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xxl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.groups_2_rounded, size: 48, color: colors.textHint),
            const SizedBox(height: AppSpacing.md),
            Text(
              context.l10n.crowdNoVotes,
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w800,
                color: colors.textPrimary,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              context.l10n.crowdNoVotesMessage,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13.5,
                color: colors.textSecondary,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
