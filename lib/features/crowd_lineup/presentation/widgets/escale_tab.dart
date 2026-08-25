import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:goias_app/core/theme/app_colors.dart';
import 'package:goias_app/core/theme/app_spacing.dart';
import 'package:goias_app/features/arena/shared/arena_colors.dart';
import 'package:goias_app/features/crowd_lineup/domain/formation.dart';
import 'package:goias_app/shared/domain/player_position.dart';
import 'package:goias_app/features/crowd_lineup/domain/squad_player.dart';
import 'package:goias_app/features/crowd_lineup/presentation/cubit/crowd_lineup_cubit.dart';
import 'package:goias_app/features/crowd_lineup/presentation/cubit/crowd_lineup_state.dart';
import 'package:goias_app/features/crowd_lineup/presentation/widgets/formation_selector.dart';
import 'package:goias_app/features/crowd_lineup/presentation/widgets/lineup_field.dart';
import 'package:goias_app/features/crowd_lineup/presentation/widgets/player_picker_sheet.dart';
import 'package:goias_app/shared/widgets/jersey_shirt.dart';

class EscaleTab extends StatelessWidget {
  const EscaleTab({
    required this.isHome,
    required this.onConfirm,
    required this.fieldKey,
    super.key,
  });

  final bool isHome;
  final Future<void> Function() onConfirm;

  /// Dono é a página (`CrowdLineupPage`) — o botão de compartilhar mora no
  /// cabeçalho, fora desta aba, e precisa alcançar o mesmo `RepaintBoundary`.
  final GlobalKey fieldKey;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CrowdLineupCubit, CrowdLineupState>(
      builder: (context, state) {
        final cubit = context.read<CrowdLineupCubit>();
        return Column(
          children: [
            const SizedBox(height: AppSpacing.md),
            FormationSelector(
              selectedId: state.formationId,
              enabled: state.canEdit,
              onSelect: cubit.selectFormation,
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.lg,
                  AppSpacing.md,
                  AppSpacing.lg,
                  AppSpacing.md,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    RepaintBoundary(
                      key: fieldKey,
                      child: LineupField(
                        formation: state.formation,
                        slotBuilder: (slotIndex, slot, avatarSize) => _Slot(
                          state: state,
                          slotIndex: slotIndex,
                          slot: slot,
                          avatarSize: avatarSize,
                          isHome: isHome,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            _ActionBar(onConfirm: onConfirm),
          ],
        );
      },
    );
  }
}

class _Slot extends StatelessWidget {
  const _Slot({
    required this.state,
    required this.slotIndex,
    required this.slot,
    required this.avatarSize,
    required this.isHome,
  });

  final CrowdLineupState state;
  final int slotIndex;
  final FormationSlot slot;
  final double avatarSize;
  final bool isHome;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final cubit = context.read<CrowdLineupCubit>();
    final player = state.playerAt(slotIndex);
    final canEdit = state.canEdit;

    return GestureDetector(
      onTap: canEdit
          ? () async {
              final picked = await showPlayerPicker(
                context,
                position: slot.position,
                pickedIds: state.pickedIds,
                currentPlayerId: player?.id,
              );
              if (picked != null) cubit.selectPlayer(slotIndex, picked);
            }
          : null,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.center,
            children: [
              if (player == null)
                _EmptyJersey(size: avatarSize)
              else
                JerseyShirt(
                  size: avatarSize,
                  number: player.shirtNumber,
                  fillColor: isHome ? ArenaColors.goiasOutfield : Colors.white,
                  numberColor: isHome
                      ? Colors.white
                      : ArenaColors.goiasOutfield,
                  trimColor: isHome ? Colors.white : ArenaColors.goiasOutfield,
                ),
              if (player != null && canEdit)
                Positioned(
                  top: -avatarSize * 0.09,
                  right: -avatarSize * 0.09,
                  child: GestureDetector(
                    onTap: () => cubit.removeSlot(slotIndex),
                    child: Container(
                      width: avatarSize * 0.37,
                      height: avatarSize * 0.37,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: colors.error,
                        border: Border.all(color: Colors.white, width: 1.5),
                        boxShadow: const [
                          BoxShadow(
                            color: Colors.black26,
                            blurRadius: 2,
                            offset: Offset(0, 1),
                          ),
                        ],
                      ),
                      child: Icon(
                        Icons.close_rounded,
                        size: avatarSize * 0.22,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 4),
          _Label(player: player, position: slot.position.short),
        ],
      ),
    );
  }
}

/// Slot ainda vazio (nenhum jogador escalado) — mesma silhueta de camisa,
/// só que apagada, com um "+" no lugar do número.
class _EmptyJersey extends StatelessWidget {
  const _EmptyJersey({required this.size});

  final double size;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Stack(
      alignment: Alignment.center,
      children: [
        JerseyShirt(
          size: size,
          fillColor: colors.primary.withValues(alpha: 0.08),
          trimColor: colors.primary.withValues(alpha: 0.35),
        ),
        Icon(
          Icons.add_rounded,
          size: size * 0.4,
          color: colors.primary.withValues(alpha: 0.6),
        ),
      ],
    );
  }
}

class _Label extends StatelessWidget {
  const _Label({required this.player, required this.position});

  final SquadPlayer? player;
  final String position;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 76),
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        (player?.name ?? position).toUpperCase(),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        textAlign: TextAlign.center,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 9.5,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.1,
        ),
      ),
    );
  }
}

class _ActionBar extends StatelessWidget {
  const _ActionBar({required this.onConfirm});

  final Future<void> Function() onConfirm;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return BlocBuilder<CrowdLineupCubit, CrowdLineupState>(
      builder: (context, state) {
        final cubit = context.read<CrowdLineupCubit>();
        if (!state.canEdit) {
          return Container(
            width: double.infinity,
            padding: const EdgeInsets.all(AppSpacing.lg),
            decoration: BoxDecoration(
              color: colors.surface,
              border: Border(top: BorderSide(color: colors.border)),
            ),
            child: Text(
              'Votação encerrada — esta é a escalação que você enviou.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: colors.textSecondary,
              ),
            ),
          );
        }
        return Container(
          decoration: BoxDecoration(
            color: colors.surface,
            border: Border(top: BorderSide(color: colors.border)),
          ),
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.md,
            AppSpacing.lg,
            AppSpacing.md,
          ),
          child: SafeArea(
            top: false,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (state.filledCount > 0)
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton.icon(
                      onPressed: cubit.clear,
                      style: TextButton.styleFrom(
                        foregroundColor: colors.textSecondary,
                      ),
                      icon: const Icon(Icons.delete_sweep_outlined, size: 18),
                      label: const Text('Limpar'),
                    ),
                  ),
                const SizedBox(height: AppSpacing.xs),
                SizedBox(
                  height: 52,
                  child: FilledButton(
                    onPressed: (state.isComplete && !state.submitting)
                        ? () => onConfirm()
                        : null,
                    style: FilledButton.styleFrom(
                      backgroundColor: colors.primary,
                      foregroundColor: colors.onPrimary,
                      disabledBackgroundColor: colors.primary.withValues(
                        alpha: 0.3,
                      ),
                      disabledForegroundColor: colors.onPrimary.withValues(
                        alpha: 0.75,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppRadius.button),
                      ),
                    ),
                    child: state.submitting
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              color: Colors.white,
                            ),
                          )
                        : Text(
                            state.hasVoted
                                ? 'ATUALIZAR ESCALAÇÃO'
                                : 'CONFIRMAR ESCALAÇÃO',
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
