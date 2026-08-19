import 'package:flutter/material.dart';
import 'package:goias_app/core/mock/mock_data.dart';
import 'package:goias_app/core/theme/app_colors.dart';
import 'package:goias_app/core/theme/app_spacing.dart';
import 'package:goias_app/shared/widgets/club_badge.dart';

/// Carteirinha visual do Sócio Esmeralda — mock enquanto não existe emissão
/// real. Vive na tela Sócio, não na Home (a Home só convida a associar-se).
class MembershipCardMock extends StatelessWidget {
  const MembershipCardMock({required this.holderName, required this.planName, super.key});

  final String holderName;
  final String planName;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Transform.rotate(
      angle: -0.06,
      child: Container(
        width: 220,
        padding: const EdgeInsets.all(AppSpacing.xl),
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
              blurRadius: 24,
              offset: const Offset(0, 14),
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
                  width: 100,
                  height: 250,
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
                    ClubBadge(team: MockData.goias, size: 26, onDark: true),
                    SizedBox(width: AppSpacing.sm),
                    Text(
                      'SÓCIO ESMERALDA',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.6,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.xxxl),
                Text(
                  holderName.toUpperCase(),
                  style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 2),
                Text(
                  planName,
                  style: TextStyle(color: Colors.white.withValues(alpha: 0.75), fontSize: 12),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
