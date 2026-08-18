import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:goias_app/core/theme/app_assets.dart';
import 'package:goias_app/core/theme/app_colors.dart';
import 'package:goias_app/core/theme/app_spacing.dart';

class AuthScaffold extends StatelessWidget {
  const AuthScaffold({
    required this.title,
    required this.subtitle,
    required this.children,
    this.showCrest = true,
    super.key,
  });

  final String title;
  final String subtitle;
  final List<Widget> children;
  final bool showCrest;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Scaffold(
      backgroundColor: colors.background,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(AppSpacing.xxl, AppSpacing.lg, AppSpacing.xxl, AppSpacing.xxl),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 460),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _BackButton(onTap: () => context.canPop() ? context.pop() : context.go('/login')),
                  const SizedBox(height: AppSpacing.xl),
                  if (showCrest) ...[
                    SvgPicture.asset(AppAssets.goiasCrest, height: 40),
                    const SizedBox(height: AppSpacing.lg),
                  ],
                  Text(
                    title,
                    style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800, color: colors.textPrimary),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    subtitle,
                    style: TextStyle(fontSize: 14, height: 1.35, color: colors.textSecondary),
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  ...children,
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _BackButton extends StatelessWidget {
  const _BackButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Material(
      color: colors.surface,
      shape: CircleBorder(side: BorderSide(color: colors.border)),
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.sm),
          child: Icon(Icons.arrow_back_rounded, size: 20, color: colors.textPrimary),
        ),
      ),
    );
  }
}
