import 'package:flutter/material.dart';
import 'package:goias_app/core/di/injection_container.dart';
import 'package:goias_app/core/error/result.dart';
import 'package:goias_app/core/l10n/l10n_extensions.dart';
import 'package:goias_app/core/theme/app_colors.dart';
import 'package:goias_app/core/theme/app_spacing.dart';
import 'package:goias_app/features/membership/data/mock_membership_repository.dart';
import 'package:goias_app/features/membership/domain/entities/membership.dart';
import 'package:goias_app/features/membership/domain/repositories/membership_repository.dart';

class MockMembershipToggle extends StatefulWidget {
  const MockMembershipToggle({super.key});

  @override
  State<MockMembershipToggle> createState() => _MockMembershipToggleState();
}

class _MockMembershipToggleState extends State<MockMembershipToggle> {
  bool _isActive = false;
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final result = await sl<MembershipRepository>().getMyMembership();
    if (!mounted) return;
    setState(() {
      _isActive = switch (result) {
        Success(:final data) => data?.status == MembershipStatus.active,
        _ => false,
      };
      _loaded = true;
    });
  }

  void _toggle(bool value) {
    final repository = sl<MembershipRepository>();
    if (repository is MockMembershipRepository) {
      repository.debugSetActive(value);
      setState(() => _isActive = value);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(color: colors.border),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  context.l10n.debugMockMembershipTitle,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: colors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  context.l10n.debugMockMembershipDescription,
                  style: TextStyle(
                    fontSize: 12,
                    color: colors.textSecondary,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Switch(
            value: _isActive,
            onChanged: _loaded ? _toggle : null,
            activeThumbColor: colors.primary,
          ),
        ],
      ),
    );
  }
}
