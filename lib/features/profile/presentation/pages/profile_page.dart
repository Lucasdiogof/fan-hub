import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:goias_app/core/mock/mock_data.dart';
import 'package:goias_app/core/theme/app_colors.dart';
import 'package:goias_app/core/theme/app_spacing.dart';
import 'package:goias_app/shared/widgets/page_title.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final user = MockData.currentUser;
    return Scaffold(
      backgroundColor: colors.background,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 900),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.md, AppSpacing.lg, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const PageTitle('PERFIL'),
                  const SizedBox(height: AppSpacing.xxxl),
                  Center(
                    child: Column(
                      children: [
                        _InitialsAvatar(name: user.name),
                        const SizedBox(height: AppSpacing.lg),
                        Text(
                          user.name,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: colors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xxxl),
                  _ProfileOptions(
                    options: [
                      _ProfileOption(
                        icon: Icons.handshake_outlined,
                        label: 'Parceiros do Goiás',
                        onTap: () => context.push('/partners'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _InitialsAvatar extends StatelessWidget {
  const _InitialsAvatar({required this.name});

  final String name;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      width: 72,
      height: 72,
      alignment: Alignment.center,
      decoration: BoxDecoration(color: colors.primary, shape: BoxShape.circle),
      child: Text(
        _initialsFrom(name),
        style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: Colors.white),
      ),
    );
  }
}

String _initialsFrom(String name) {
  final words = name.trim().split(RegExp(r'\s+')).where((w) => w.isNotEmpty).toList();
  if (words.isEmpty) return '';
  if (words.length == 1) return words.first.substring(0, 1).toUpperCase();
  return (words.first[0] + words.last[0]).toUpperCase();
}

class _ProfileOption {
  const _ProfileOption({required this.icon, required this.label, required this.onTap});

  final IconData icon;
  final String label;
  final VoidCallback onTap;
}

class _ProfileOptions extends StatelessWidget {
  const _ProfileOptions({required this.options});

  final List<_ProfileOption> options;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(color: colors.border),
      ),
      child: Column(
        children: [
          for (var i = 0; i < options.length; i++) ...[
            if (i > 0) Divider(height: 1, color: colors.border),
            _ProfileOptionRow(option: options[i]),
          ],
        ],
      ),
    );
  }
}

class _ProfileOptionRow extends StatelessWidget {
  const _ProfileOptionRow({required this.option});

  final _ProfileOption option;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return InkWell(
      onTap: option.onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.md),
        child: Row(
          children: [
            Icon(option.icon, size: 20, color: colors.textSecondary),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Text(
                option.label,
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: colors.textPrimary),
              ),
            ),
            Icon(Icons.chevron_right_rounded, size: 20, color: colors.textHint),
          ],
        ),
      ),
    );
  }
}
