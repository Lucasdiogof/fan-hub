import 'package:flutter/material.dart';
import 'package:goias_app/core/l10n/l10n_extensions.dart';
import 'package:goias_app/core/theme/app_colors.dart';
import 'package:goias_app/core/theme/app_spacing.dart';
import 'package:goias_app/features/passport/domain/entities/passport_match.dart';
import 'package:goias_app/features/passport/presentation/v2/widgets/passport_match_ticket_v2.dart';

/// Um mês na linha do tempo — o traço vertical à esquerda liga os cabeçalhos
/// de mês em vez de cada partida individualmente, pra não poluir. O
/// cabeçalho mostra quantas do mês já foram vividas, nunca duplicando a
/// contagem da temporada inteira.
class PassportMonthGroupV2 extends StatelessWidget {
  const PassportMonthGroupV2({
    required this.label,
    required this.matches,
    required this.effectiveAttended,
    required this.onToggle,
    required this.isLast,
    super.key,
  });

  final String label;
  final List<PassportMatch> matches;
  final bool Function(PassportMatch) effectiveAttended;
  final ValueChanged<PassportMatch> onToggle;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final l10n = context.l10n;
    final finished = matches.where((m) => m.isFinished).length;
    final marked = matches
        .where((m) => m.isFinished && effectiveAttended(m))
        .length;

    // `IntrinsicHeight` é necessário aqui: a coluna da esquerda tem um
    // `Expanded` (o traço vertical que liga os meses) e precisa de uma
    // altura definida pra calcular esse espaço — sem isso, herda altura
    // livre (infinita) de quem chama isto dentro de uma `ListView`/`Column`
    // sem altura própria, e o layout quebra com "RenderBox was not laid
    // out" (reproduzido em produção).
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 16,
            child: Column(
              children: [
                const SizedBox(height: 4),
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: marked > 0 ? colors.primary : colors.border,
                    shape: BoxShape.circle,
                  ),
                ),
                if (!isLast)
                  Expanded(child: Container(width: 1.5, color: colors.border)),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: isLast ? 0 : AppSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                    child: Row(
                      children: [
                        Text(
                          label,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.5,
                            color: colors.textPrimary,
                          ),
                        ),
                        if (finished > 0) ...[
                          const SizedBox(width: 8),
                          Text(
                            l10n.passportMonthProgressLine(marked, finished),
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: colors.textSecondary,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  for (var i = 0; i < matches.length; i++) ...[
                    if (i > 0) const SizedBox(height: AppSpacing.sm),
                    PassportMatchTicketV2(
                      match: matches[i],
                      attended: effectiveAttended(matches[i]),
                      onToggle: () => onToggle(matches[i]),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
