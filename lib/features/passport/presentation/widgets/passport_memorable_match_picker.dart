import 'package:flutter/material.dart';
import 'package:goias_app/core/l10n/l10n_extensions.dart';
import 'package:goias_app/core/theme/app_colors.dart';
import 'package:goias_app/core/theme/app_spacing.dart';
import 'package:goias_app/features/passport/domain/entities/passport_match.dart';
import 'package:goias_app/shared/widgets/app_modal_sheet.dart';

/// Lista só as partidas que o usuário marcou como "Eu fui" — nunca deixa
/// escolher fora disso (a RPC também recusaria, mas a UI já não oferece a
/// opção). Devolve a partida escolhida, ou `null` se o usuário fechou sem
/// escolher.
Future<PassportMatch?> showMemorableMatchPicker(
  BuildContext context, {
  required List<PassportMatch> matches,
  required String? selectedMatchId,
}) {
  return AppModalSheet.show<PassportMatch>(
    context,
    builder: (sheetContext) => _MemorableMatchPickerSheet(
      matches: matches,
      selectedMatchId: selectedMatchId,
    ),
  );
}

class _MemorableMatchPickerSheet extends StatelessWidget {
  const _MemorableMatchPickerSheet({
    required this.matches,
    required this.selectedMatchId,
  });

  final List<PassportMatch> matches;
  final String? selectedMatchId;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return SafeArea(
      top: false,
      child: SizedBox(
        height: MediaQuery.sizeOf(context).height * 0.75,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.xl,
                AppSpacing.sm,
                AppSpacing.xl,
                AppSpacing.md,
              ),
              child: Text(
                context.l10n.passportTrajectoryPickMatch,
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  color: colors.textPrimary,
                ),
              ),
            ),
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.lg,
                  0,
                  AppSpacing.lg,
                  AppSpacing.xl,
                ),
                itemCount: matches.length,
                separatorBuilder: (_, _) =>
                    const SizedBox(height: AppSpacing.xs),
                itemBuilder: (context, i) {
                  final match = matches[i];
                  return _MatchRow(
                    match: match,
                    selected: match.id == selectedMatchId,
                    onTap: () => Navigator.of(context).pop(match),
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

class _MatchRow extends StatelessWidget {
  const _MatchRow({
    required this.match,
    required this.selected,
    required this.onTap,
  });

  final PassportMatch match;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final date = match.matchDate;
    final dateLabel =
        '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')}/${date.year}';
    final hasScore = match.goiasScore != null && match.opponentScore != null;

    return Material(
      color: selected
          ? colors.primary.withValues(alpha: 0.08)
          : Colors.transparent,
      borderRadius: BorderRadius.circular(AppRadius.card),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.card),
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm + 2,
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadius.card),
            border: Border.all(
              color: selected ? colors.primary : colors.border,
              width: selected ? 1.4 : 1,
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Goiás x ${match.opponent}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: colors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '$dateLabel · ${match.competition}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 11.5, color: colors.textHint),
                    ),
                  ],
                ),
              ),
              if (hasScore) ...[
                const SizedBox(width: AppSpacing.sm),
                Text(
                  '${match.goiasScore} x ${match.opponentScore}',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                    color: colors.textPrimary,
                  ),
                ),
              ],
              const SizedBox(width: AppSpacing.xs),
              Icon(
                selected ? Icons.check_circle_rounded : Icons.circle_outlined,
                size: 18,
                color: selected ? colors.primary : colors.border,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
