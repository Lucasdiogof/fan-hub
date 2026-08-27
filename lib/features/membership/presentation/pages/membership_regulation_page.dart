import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:go_router/go_router.dart';
import 'package:goias_app/core/di/injection_container.dart';
import 'package:goias_app/core/l10n/l10n_extensions.dart';
import 'package:goias_app/core/theme/app_colors.dart';
import 'package:goias_app/core/theme/app_spacing.dart';
import 'package:goias_app/features/membership/data/membership_regulation_repository.dart';
import 'package:goias_app/features/membership/data/regulation_catalog.dart';
import 'package:goias_app/features/membership/domain/entities/regulation_section.dart';
import 'package:goias_app/shared/utils/regulation_markdown_parser.dart';
import 'package:goias_app/shared/widgets/back_button_circle.dart';
import 'package:goias_app/shared/widgets/goias_loading_indicator.dart';

/// Leitura só-consulta do Regulamento do Sócio Esmeralda — não depende do
/// `MembershipRegistrationCubit`. Quem precisa saber se o usuário aceitou é
/// a `MembershipReviewPage`, que tem seu próprio checkbox; esta tela só
/// mostra o texto.
class MembershipRegulationPage extends StatefulWidget {
  const MembershipRegulationPage({super.key});

  @override
  State<MembershipRegulationPage> createState() =>
      _MembershipRegulationPageState();
}

class _MembershipRegulationPageState extends State<MembershipRegulationPage> {
  late final Future<List<RegulationSection>> _future = _load();
  final _sectionKeys = <int, GlobalKey>{};

  Future<List<RegulationSection>> _load() async {
    final raw = await sl<MembershipRegulationRepository>()
        .loadCurrentMarkdown();
    return parseRegulationSections(raw);
  }

  void _goToSection(int index) {
    final ctx = _sectionKeys[index]?.currentContext;
    if (ctx == null) return;
    Scrollable.ensureVisible(
      ctx,
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeInOut,
      alignment: 0.08,
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Scaffold(
      backgroundColor: colors.background,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
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
                    onTap: () =>
                        context.canPop() ? context.pop() : context.go('/'),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  Text(
                    context.l10n.membershipRegulationPageTitle,
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      color: colors.textPrimary,
                      letterSpacing: 0.2,
                    ),
                  ),
                  Text(
                    context.l10n.membershipProgramName,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: colors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Row(
                    children: [
                      Icon(
                        Icons.event_available_rounded,
                        size: 14,
                        color: colors.textHint,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        context.l10n.membershipRegulationEffectiveSince(
                          _formatDate(RegulationCatalog.current.effectiveAt),
                        ),
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: colors.textHint,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  Expanded(
                    child: FutureBuilder<List<RegulationSection>>(
                      future: _future,
                      builder: (context, snapshot) {
                        if (snapshot.connectionState != ConnectionState.done) {
                          return const Center(child: GoiasLoadingIndicator());
                        }
                        final sections = snapshot.data ?? const [];
                        for (final section in sections) {
                          _sectionKeys.putIfAbsent(
                            section.index,
                            () => GlobalKey(),
                          );
                        }
                        return ListView(
                          // `Scrollable.ensureVisible` só funciona pra seções já montadas —
                          // sem isso, `GlobalKey.currentContext` vem nulo pra qualquer item
                          // fora da viewport inicial e o índice não navega além da primeira
                          // seção. O conteúdo é só texto, então cachear tudo de uma vez é
                          // barato.
                          scrollCacheExtent: const ScrollCacheExtent.pixels(
                            100000,
                          ),
                          children: [
                            _RegulationIndex(
                              sections: sections,
                              onTapSection: _goToSection,
                            ),
                            const SizedBox(height: AppSpacing.xxxl),
                            for (final section in sections) ...[
                              _RegulationSectionView(
                                key: _sectionKeys[section.index],
                                section: section,
                              ),
                              const SizedBox(height: AppSpacing.xl),
                              if (section.index != sections.last.index) ...[
                                Divider(color: colors.border),
                                const SizedBox(height: AppSpacing.xl),
                              ],
                            ],
                            const SizedBox(height: AppSpacing.huge),
                          ],
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

String _formatDate(DateTime date) {
  String two(int n) => n.toString().padLeft(2, '0');
  return '${two(date.day)}/${two(date.month)}/${date.year}';
}

class _RegulationIndex extends StatelessWidget {
  const _RegulationIndex({required this.sections, required this.onTapSection});

  final List<RegulationSection> sections;
  final ValueChanged<int> onTapSection;

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
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.lg,
              AppSpacing.lg,
              AppSpacing.sm,
            ),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                context.l10n.membershipRegulationTableOfContents,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: colors.textSecondary,
                  letterSpacing: 0.6,
                ),
              ),
            ),
          ),
          for (var i = 0; i < sections.length; i++) ...[
            if (i > 0) Divider(height: 1, color: colors.border),
            InkWell(
              onTap: () => onTapSection(sections[i].index),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.lg,
                  vertical: 12,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        '${sections[i].index}. ${sections[i].title}',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: colors.textPrimary,
                        ),
                      ),
                    ),
                    Icon(
                      Icons.chevron_right_rounded,
                      size: 18,
                      color: colors.textHint,
                    ),
                  ],
                ),
              ),
            ),
          ],
          const SizedBox(height: AppSpacing.sm),
        ],
      ),
    );
  }
}

class _RegulationSectionView extends StatelessWidget {
  const _RegulationSectionView({required this.section, super.key});

  final RegulationSection section;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '${section.index}. ${section.title.toUpperCase()}',
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w900,
            color: colors.textPrimary,
            letterSpacing: 0.2,
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        Text(
          section.body.isEmpty
              ? 'Conteúdo oficial pendente de envio.'
              : section.body,
          style: TextStyle(
            fontSize: 13.5,
            height: 1.55,
            color: colors.textSecondary,
          ),
        ),
      ],
    );
  }
}
