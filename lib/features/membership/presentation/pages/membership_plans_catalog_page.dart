import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:goias_app/core/theme/app_colors.dart';
import 'package:goias_app/core/theme/app_spacing.dart';
import 'package:goias_app/features/membership/data/membership_plans_catalog.dart';
import 'package:goias_app/shared/widgets/back_button_circle.dart';
import 'package:goias_app/shared/widgets/page_title.dart';

/// "Conhecer outros planos" a partir da experiência de quem já é sócio —
/// lista completa, sem competir com o plano atual.
class MembershipPlansCatalogPage extends StatelessWidget {
  const MembershipPlansCatalogPage({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
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
                  BackButtonCircle(onTap: () => context.pop()),
                  const SizedBox(height: AppSpacing.lg),
                  const PageTitle('PLANOS'),
                  const SizedBox(height: AppSpacing.xl),
                  Expanded(
                    child: ListView.separated(
                      itemCount: MembershipPlansCatalog.plans.length,
                      separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.md),
                      itemBuilder: (context, index) {
                        final plan = MembershipPlansCatalog.plans[index];
                        return _PlanRow(
                          name: plan.name,
                          sector: plan.stadiumSector,
                          onTap: () async {
                            final result = await context.push<bool>('/membership/plans/${plan.id}');
                            if (result == true && context.mounted) context.pop(true);
                          },
                        );
                      },
                    ),
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

class _PlanRow extends StatelessWidget {
  const _PlanRow({required this.name, required this.sector, required this.onTap});

  final String name;
  final String? sector;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.cardSmall),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: BorderRadius.circular(AppRadius.cardSmall),
          border: Border.all(color: colors.border),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name, style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.w800, color: colors.textPrimary)),
                  if (sector != null)
                    Text('Setor $sector', style: TextStyle(fontSize: 12, color: colors.textSecondary)),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded, size: 20, color: colors.textHint),
          ],
        ),
      ),
    );
  }
}
