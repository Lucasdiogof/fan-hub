import 'package:flutter/material.dart';
import 'package:goias_app/core/mock/mock_data.dart';
import 'package:goias_app/core/theme/app_colors.dart';
import 'package:goias_app/core/theme/app_spacing.dart';
import 'package:goias_app/features/membership/domain/entities/membership.dart';
import 'package:goias_app/shared/widgets/club_badge.dart';

/// Carteirinha visual do Sócio Esmeralda — mock enquanto não existe emissão
/// real (QR Code, biometria etc. fora de escopo por enquanto).
class DigitalMembershipCard extends StatelessWidget {
  const DigitalMembershipCard({
    required this.holderName,
    required this.planName,
    required this.status,
    this.memberNumber,
    super.key,
  });

  final String holderName;
  final String planName;
  final MembershipStatus status;
  final String? memberNumber;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.xxl),
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppRadius.card),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [colors.primary, colors.darkGreen],
        ),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.28), blurRadius: 28, offset: const Offset(0, 16)),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            top: -40,
            right: -60,
            child: Transform.rotate(
              angle: -0.5,
              child: Container(width: 140, height: 320, color: Colors.white.withValues(alpha: 0.05)),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  const ClubBadge(team: MockData.goias, size: 30, onDark: true),
                  const SizedBox(width: AppSpacing.sm),
                  const Text(
                    'SÓCIO ESMERALDA',
                    style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 0.8),
                  ),
                  const Spacer(),
                  _StatusPill(status: status),
                ],
              ),
              const SizedBox(height: AppSpacing.xxxl),
              Text(
                holderName.toUpperCase(),
                style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 2),
              Text(
                planName,
                style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 13, fontWeight: FontWeight.w600),
              ),
              if (memberNumber != null) ...[
                const SizedBox(height: AppSpacing.lg),
                Text(
                  'Nº $memberNumber',
                  style: TextStyle(color: Colors.white.withValues(alpha: 0.65), fontSize: 12, letterSpacing: 0.6),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.status});

  final MembershipStatus status;

  @override
  Widget build(BuildContext context) {
    final (label, color) = switch (status) {
      MembershipStatus.active => ('ATIVO', const Color(0xFF4CC37A)),
      MembershipStatus.pending => ('PENDENTE', const Color(0xFFD9B25C)),
      MembershipStatus.suspended => ('SUSPENSO', const Color(0xFFFF6B6B)),
      MembershipStatus.cancelled => ('CANCELADO', const Color(0xFFFF6B6B)),
      MembershipStatus.none => ('', Colors.transparent),
    };
    if (label.isEmpty) return const SizedBox.shrink();
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(width: 7, height: 7, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 5),
        Text(
          label,
          style: TextStyle(color: Colors.white.withValues(alpha: 0.85), fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 0.6),
        ),
      ],
    );
  }
}
