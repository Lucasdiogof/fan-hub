import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:goias_app/core/l10n/l10n_extensions.dart';
import 'package:goias_app/core/theme/app_colors.dart';
import 'package:goias_app/core/theme/app_spacing.dart';
import 'package:goias_app/features/crowd_lineup/domain/formation.dart';
import 'package:goias_app/shared/domain/player_position.dart';
import 'package:goias_app/features/crowd_lineup/presentation/cubit/crowd_lineup_cubit.dart';
import 'package:goias_app/features/crowd_lineup/presentation/cubit/crowd_lineup_state.dart';
import 'package:goias_app/features/crowd_lineup/presentation/layout/lineup_layout_engine.dart';
import 'package:goias_app/features/crowd_lineup/presentation/widgets/formation_selector.dart';
import 'package:goias_app/features/crowd_lineup/presentation/widgets/lineup_field.dart';
import 'package:goias_app/features/crowd_lineup/presentation/widgets/lineup_name_label.dart';
import 'package:goias_app/features/crowd_lineup/presentation/widgets/player_picker_sheet.dart';
import 'package:goias_app/shared/widgets/jersey_shirt.dart';

class EscaleTab extends StatelessWidget {
  const EscaleTab({
    required this.isHome,
    required this.onConfirm,
    required this.fieldKey,
    this.justSubmitted = false,
    super.key,
  });

  final bool isHome;
  final Future<void> Function() onConfirm;

  /// Mostra o estado de sucesso no botão por um instante antes da página
  /// trocar de aba (ver `CrowdLineupPage._submit`).
  final bool justSubmitted;

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
                        mode: LineupRenderMode.editable,
                        slotBuilder: (slotIndex, slot, footprint) => _Slot(
                          state: state,
                          slotIndex: slotIndex,
                          slot: slot,
                          footprint: footprint,
                          isHome: isHome,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            _ActionBar(onConfirm: onConfirm, justSubmitted: justSubmitted),
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
    required this.footprint,
    required this.isHome,
  });

  final CrowdLineupState state;
  final int slotIndex;
  final FormationSlot slot;
  final PlayerVisualFootprint footprint;
  final bool isHome;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final cubit = context.read<CrowdLineupCubit>();
    final player = state.playerAt(slotIndex);
    final canEdit = state.canEdit;
    final avatarSize = footprint.jerseySize;

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
                  // Camisa do clube ATIVO — ver comentário equivalente em
                  // `crowd_tab.dart` (mesmo achado real 2026-09-09).
                  fillColor: isHome ? context.colors.primary : Colors.white,
                  numberColor: isHome ? Colors.white : context.colors.primary,
                  trimColor: isHome ? Colors.white : context.colors.primary,
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
          LineupNameLabel(
            text: player?.name ?? slot.position.short(context),
            maxWidth: footprint.width,
            maxLines: footprint.nameMaxLines,
            allowSplit: player != null,
          ),
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

class _ActionBar extends StatelessWidget {
  const _ActionBar({required this.onConfirm, required this.justSubmitted});

  final Future<void> Function() onConfirm;
  final bool justSubmitted;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return BlocBuilder<CrowdLineupCubit, CrowdLineupState>(
      builder: (context, state) {
        if (!state.canEdit) {
          return Container(
            width: double.infinity,
            padding: const EdgeInsets.all(AppSpacing.lg),
            decoration: BoxDecoration(
              color: colors.surface,
              border: Border(top: BorderSide(color: colors.border)),
            ),
            child: Text(
              context.l10n.crowdVotingClosed,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: colors.textSecondary,
              ),
            ),
          );
        }
        return Padding(
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
                SizedBox(
                  height: 52,
                  child: FilledButton(
                    onPressed:
                        (state.isComplete &&
                            !state.submitting &&
                            !justSubmitted)
                        ? () => onConfirm()
                        : null,
                    style: FilledButton.styleFrom(
                      backgroundColor: colors.primary,
                      foregroundColor: colors.onPrimary,
                      disabledBackgroundColor: justSubmitted
                          ? colors.primary
                          : colors.primary.withValues(alpha: 0.3),
                      disabledForegroundColor: justSubmitted
                          ? colors.onPrimary
                          : colors.onPrimary.withValues(alpha: 0.75),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppRadius.button),
                      ),
                    ),
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 200),
                      child: justSubmitted
                          ? Row(
                              key: const ValueKey('success'),
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(
                                  Icons.check_circle_rounded,
                                  size: 20,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  context.l10n.crowdSubmitted,
                                  style: const TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ],
                            )
                          : state.submitting
                          ? const SizedBox(
                              key: ValueKey('loading'),
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.5,
                                color: Colors.white,
                              ),
                            )
                          : Text(
                              state.hasVoted
                                  ? context.l10n.crowdUpdateLineup
                                  : context.l10n.crowdConfirmLineup,
                              key: const ValueKey('label'),
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w800,
                              ),
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
