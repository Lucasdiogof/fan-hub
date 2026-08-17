import 'package:flutter/material.dart';
import 'package:goias_app/core/mock/mock_data.dart';
import 'package:goias_app/core/theme/app_colors.dart';
import 'package:goias_app/core/theme/app_spacing.dart';
import 'package:goias_app/shared/widgets/club_badge.dart';

class HomeHeader extends StatelessWidget {
  const HomeHeader({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const ClubBadge(team: MockData.goias, size: 34),
        const SizedBox(width: AppSpacing.sm),
        Text(
          'GOIÁS ESPORTE CLUBE',
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.6,
            color: colors.textPrimary,
          ),
        ),
        const Spacer(),
        _CircleIconButton(icon: Icons.notifications_outlined, onTap: () {}),
        const SizedBox(width: AppSpacing.sm),
        _CircleIconButton(icon: Icons.person_outline, onTap: () {}),
      ],
    );
  }
}

class _CircleIconButton extends StatelessWidget {
  const _CircleIconButton({required this.icon, required this.onTap});

  final IconData icon;
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
        child: Icon(icon, size: 18, color: colors.textPrimary),
      ),
    );
  }
}
