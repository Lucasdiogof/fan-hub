import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:goias_app/core/theme/app_colors.dart';
import 'package:goias_app/core/theme/app_spacing.dart';
import 'package:goias_app/features/partners/data/partners_data.dart';
import 'package:goias_app/features/partners/presentation/widgets/partner_card.dart';

class PartnersPage extends StatelessWidget {
  const PartnersPage({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Scaffold(
      backgroundColor: colors.background,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1100),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.md, AppSpacing.lg, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _BackButton(onTap: () => context.canPop() ? context.pop() : context.go('/')),
                      const SizedBox(height: AppSpacing.lg),
                      Text(
                        'Parceiros do Goiás',
                        style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: colors.textPrimary),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Marcas que caminham junto com o Verdão.',
                        style: TextStyle(fontSize: 14, color: colors.textSecondary),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                Expanded(
                  child: GridView.builder(
                    padding: const EdgeInsets.fromLTRB(AppSpacing.lg, 0, AppSpacing.lg, AppSpacing.xxxl),
                    gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                      maxCrossAxisExtent: 230,
                      mainAxisSpacing: AppSpacing.md,
                      crossAxisSpacing: AppSpacing.md,
                      childAspectRatio: 1.3,
                    ),
                    itemCount: PartnersData.all.length,
                    itemBuilder: (context, index) => PartnerCard(partner: PartnersData.all[index]),
                  ),
                ),
              ],
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
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Container(
        width: 38,
        height: 38,
        alignment: Alignment.center,
        decoration: BoxDecoration(color: colors.secondary, shape: BoxShape.circle),
        child: Icon(Icons.arrow_back_rounded, size: 18, color: colors.textPrimary),
      ),
    );
  }
}
