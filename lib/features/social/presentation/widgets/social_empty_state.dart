import 'package:flutter/material.dart';
import 'package:goias_app/core/l10n/l10n_extensions.dart';
import 'package:goias_app/core/theme/app_colors.dart';
import 'package:goias_app/core/theme/app_spacing.dart';
import 'package:goias_app/shared/utils/external_link_launcher.dart';

class SocialEmptyState extends StatelessWidget {
  const SocialEmptyState({super.key});

  static const _profiles = [
    (label: 'Instagram', url: 'https://instagram.com/goiasoficial', icon: Icons.camera_alt_rounded),
    (label: 'YouTube', url: 'https://youtube.com/@TVGoias', icon: Icons.play_circle_filled),
    (label: 'X', url: 'https://x.com/goiasoficial', icon: Icons.tag),
  ];

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xxl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.podcasts_rounded, size: 48, color: colors.textHint),
            const SizedBox(height: AppSpacing.lg),
            Text(
              context.l10n.socialEmptyState,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: colors.textPrimary,
              ),
            ),
            const SizedBox(height: AppSpacing.xxl),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                for (final profile in _profiles) ...[
                  _ProfileLink(
                    icon: profile.icon,
                    label: profile.label,
                    onTap: () => openExternalUrl(context, profile.url),
                  ),
                  if (profile != _profiles.last) const SizedBox(width: AppSpacing.xl),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ProfileLink extends StatelessWidget {
  const _ProfileLink({required this.icon, required this.label, required this.onTap});

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.card),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 48,
            height: 48,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: colors.secondary,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 22, color: colors.primary),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: colors.textSecondary)),
        ],
      ),
    );
  }
}
