import 'package:flutter/material.dart';
import 'package:goias_app/core/mock/mock_data.dart';
import 'package:goias_app/core/theme/app_colors.dart';
import 'package:goias_app/core/theme/app_spacing.dart';
import 'package:goias_app/shared/widgets/club_badge.dart';
import 'package:goias_app/shared/widgets/stadium_backdrop.dart';

class MembershipBanner extends StatelessWidget {
  const MembershipBanner({this.onViewPlans, super.key});

  final VoidCallback? onViewPlans;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth > 640;

        final visual = SizedBox(
          height: wide ? null : 176,
          child: const Stack(
            fit: StackFit.expand,
            children: [
              StadiumBackdrop(),
              Center(child: _MembershipCardMock()),
            ],
          ),
        );

        final content = ColoredBox(
          color: colors.surface,
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.xxl),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: colors.secondary,
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                  ),
                  child: Text(
                    'SÓCIO ESMERALDA',
                    style: TextStyle(
                      color: colors.primary,
                      fontSize: 10.5,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.2,
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                Text(
                  'Faça parte do\nSócio Esmeralda',
                  style: TextStyle(
                    color: colors.textPrimary,
                    fontSize: 23,
                    fontWeight: FontWeight.w800,
                    height: 1.18,
                    letterSpacing: -0.2,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  'Mais que um plano, um sentimento.',
                  style: TextStyle(color: colors.textSecondary, fontSize: 13.5, height: 1.3),
                ),
                const SizedBox(height: AppSpacing.xl),
                const _Benefit(label: 'Descontos exclusivos'),
                const SizedBox(height: AppSpacing.sm),
                const _Benefit(label: 'Prioridade nos ingressos'),
                const SizedBox(height: AppSpacing.sm),
                const _Benefit(label: 'Experiências diferenciadas'),
                const SizedBox(height: AppSpacing.xl),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: onViewPlans,
                    style: ElevatedButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppRadius.button),
                      ),
                      textStyle: const TextStyle(fontWeight: FontWeight.w700, letterSpacing: 0.3),
                    ),
                    child: const Text('CONHECER PLANOS'),
                  ),
                ),
              ],
            ),
          ),
        );

        return ClipRRect(
          borderRadius: BorderRadius.circular(AppRadius.banner),
          child: DecoratedBox(
            decoration: BoxDecoration(border: Border.all(color: colors.border)),
            child: wide
                ? IntrinsicHeight(
                    child: Row(
                      children: [
                        Expanded(flex: 3, child: content),
                        Expanded(flex: 2, child: visual),
                      ],
                    ),
                  )
                : Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [content, visual],
                  ),
          ),
        );
      },
    );
  }
}

class _Benefit extends StatelessWidget {
  const _Benefit({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Row(
      children: [
        Icon(Icons.check_circle_rounded, size: 17, color: colors.primary),
        const SizedBox(width: AppSpacing.sm),
        Text(
          label,
          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: colors.textPrimary),
        ),
      ],
    );
  }
}

class _MembershipCardMock extends StatelessWidget {
  const _MembershipCardMock();

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Transform.rotate(
      angle: -0.06,
      child: Container(
        width: 188,
        padding: const EdgeInsets.all(AppSpacing.lg),
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppRadius.cardSmall),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [colors.primary, colors.darkGreen],
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.28),
              blurRadius: 20,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        child: Stack(
          children: [
            Positioned(
              top: -30,
              right: -50,
              child: Transform.rotate(
                angle: -0.5,
                child: Container(
                  width: 90,
                  height: 220,
                  color: Colors.white.withValues(alpha: 0.06),
                ),
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Row(
                  children: [
                    ClubBadge(team: MockData.goias, size: 22, onDark: true),
                    SizedBox(width: AppSpacing.sm),
                    Text(
                      'SÓCIO ESMERALDA',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 9,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.6,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.xxl),
                const Text(
                  'LUCAS DIOGO',
                  style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 2),
                Text(
                  'Plano Cadeiras',
                  style: TextStyle(color: Colors.white.withValues(alpha: 0.75), fontSize: 11),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
