import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:goias_app/core/l10n/l10n_extensions.dart';
import 'package:goias_app/core/theme/app_colors.dart';
import 'package:goias_app/core/theme/app_spacing.dart';
import 'package:goias_app/features/membership/data/membership_plans_catalog.dart';
import 'package:goias_app/shared/widgets/back_button_circle.dart';
import 'package:goias_app/shared/widgets/page_title.dart';
import 'package:goias_app/shared/widgets/content_container.dart';

/// "Conhecer outros planos" a partir da experiência de quem já é sócio —
/// lista completa, sem competir com o plano atual.
class MembershipPlansCatalogPage extends StatefulWidget {
  const MembershipPlansCatalogPage({super.key});

  @override
  State<MembershipPlansCatalogPage> createState() =>
      _MembershipPlansCatalogPageState();
}

class _MembershipPlansCatalogPageState
    extends State<MembershipPlansCatalogPage> {
  // Enquanto um plano está sendo aberto, esta tela não pode ser fechada
  // (nem pelo botão de voltar, nem pelo gesto do sistema) — senão o
  // `context.pop(result)` abaixo tenta completar de novo um Future que o
  // pop antecipado já completou, e o app quebra com "Future already
  // completed".
  bool _opening = false;

  Future<void> _openPlan(String planId) async {
    if (_opening) return;
    setState(() => _opening = true);
    final result = await context.push<String>('/membership/plans/$planId');
    if (!mounted) return;
    setState(() => _opening = false);
    if (result != null) context.pop(result);
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return PopScope(
      canPop: !_opening,
      child: Scaffold(
        backgroundColor: colors.background,
        body: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: ContentWidth.wide.maxWidth),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.lg,
                  AppSpacing.md,
                  AppSpacing.lg,
                  0,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    BackButtonCircle(
                      onTap: _opening ? () {} : () => context.pop(),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    PageTitle(context.l10n.membershipPlansTitle),
                    const SizedBox(height: AppSpacing.xl),
                    Expanded(
                      child: ListView.separated(
                        itemCount: MembershipPlansCatalog.plans.length,
                        separatorBuilder: (_, _) =>
                            const SizedBox(height: AppSpacing.md),
                        itemBuilder: (context, index) {
                          final plan = MembershipPlansCatalog.plans[index];
                          return _PlanRow(
                            name: plan.name,
                            sector: plan.stadiumSector,
                            onTap: _opening ? null : () => _openPlan(plan.id),
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
      ),
    );
  }
}

class _PlanRow extends StatelessWidget {
  const _PlanRow({required this.name, required this.sector, this.onTap});

  final String name;
  final String? sector;
  final VoidCallback? onTap;

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
                  Text(
                    name,
                    style: TextStyle(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w800,
                      color: colors.textPrimary,
                    ),
                  ),
                  if (sector != null)
                    Text(
                      context.l10n.membershipSector(sector!),
                      style: TextStyle(
                        fontSize: 12,
                        color: colors.textSecondary,
                      ),
                    ),
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
