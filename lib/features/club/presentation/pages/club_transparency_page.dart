import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:goias_app/core/di/injection_container.dart';
import 'package:goias_app/core/l10n/l10n_extensions.dart';
import 'package:goias_app/core/theme/app_colors.dart';
import 'package:goias_app/core/theme/app_spacing.dart';
import 'package:goias_app/features/club/domain/entities/club_transparency_topic.dart';
import 'package:goias_app/features/club/presentation/cubit/club_transparency_cubit.dart';
import 'package:goias_app/features/club/presentation/cubit/club_transparency_state.dart';
import 'package:goias_app/shared/state/load_status.dart';
import 'package:goias_app/shared/utils/date_labels.dart';
import 'package:goias_app/shared/widgets/back_button_circle.dart';
import 'package:goias_app/shared/widgets/goias_loading_indicator.dart';
import 'package:goias_app/shared/widgets/page_title.dart';
import 'package:goias_app/shared/widgets/state_message.dart';
import 'package:goias_app/shared/widgets/content_container.dart';

/// Transparência do clube — tópicos expansíveis (exercícios contábeis,
/// editais, estatuto, relatórios), cada um com seus documentos em PDF.
/// Supabase é a fonte da verdade (ver `club_transparency.sql`); abrir um
/// documento delega pro navegador/visualizador nativo — que já oferece
/// "salvar", sem precisar de um leitor de PDF próprio no app.
class ClubTransparencyPage extends StatelessWidget {
  const ClubTransparencyPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<ClubTransparencyCubit>()..load(),
      child: const _ClubTransparencyView(),
    );
  }
}

class _ClubTransparencyView extends StatelessWidget {
  const _ClubTransparencyView();

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Scaffold(
      backgroundColor: colors.background,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: ContentWidth.wide.maxWidth),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.lg,
                    AppSpacing.md,
                    AppSpacing.lg,
                    0,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      BackButtonCircle(onTap: () => context.pop()),
                      const SizedBox(height: AppSpacing.lg),
                      PageTitle(
                        context.l10n.clubSectionTransparency.toUpperCase(),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child:
                      BlocBuilder<ClubTransparencyCubit, ClubTransparencyState>(
                        builder: (context, state) {
                          return RefreshIndicator(
                            onRefresh: () =>
                                context.read<ClubTransparencyCubit>().refresh(),
                            color: colors.primary,
                            child: switch (state.status) {
                              LoadStatus.initial || LoadStatus.loading =>
                                _centered(const GoiasLoadingIndicator()),
                              LoadStatus.error => _centered(
                                StateMessage(
                                  icon: Icons.wifi_off_rounded,
                                  title: context
                                      .l10n
                                      .clubTransparencyLoadErrorTitle,
                                  message: state.errorMessage,
                                ),
                              ),
                              LoadStatus.empty => _centered(
                                StateMessage(
                                  icon: Icons.description_outlined,
                                  title:
                                      context.l10n.clubTransparencyEmptyTitle,
                                  message:
                                      context.l10n.clubTransparencyEmptyMessage,
                                ),
                              ),
                              LoadStatus.success => _TopicList(
                                topics: state.topics,
                              ),
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
    );
  }
}

Widget _centered(Widget child) {
  return ListView(
    physics: const AlwaysScrollableScrollPhysics(),
    children: [
      Padding(
        padding: const EdgeInsets.only(top: 80),
        child: Center(child: child),
      ),
    ],
  );
}

class _TopicList extends StatelessWidget {
  const _TopicList({required this.topics});

  final List<ClubTransparencyTopic> topics;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.lg,
        AppSpacing.lg,
        AppSpacing.xxxl,
      ),
      itemCount: topics.length,
      separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.sm),
      itemBuilder: (context, index) => _TopicTile(topic: topics[index]),
    );
  }
}

class _TopicTile extends StatelessWidget {
  const _TopicTile({required this.topic});

  final ClubTransparencyTopic topic;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final l10n = context.l10n;
    return Material(
      // `ExpansionTile` é baseado em `ListTile` e pinta o próprio fundo/
      // splash no `Material` ancestor mais próximo — precisa ser este
      // widget, não o `Container` colorido abaixo (senão o toque fica
      // sem feedback visual, ver assertion "ListTile background color
      // or ink splashes may be invisible").
      color: colors.surface,
      borderRadius: BorderRadius.circular(AppRadius.card),
      clipBehavior: Clip.antiAlias,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppRadius.card),
          border: Border.all(color: colors.border),
        ),
        child: Theme(
          data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
          child: ExpansionTile(
            tilePadding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: 4,
            ),
            childrenPadding: EdgeInsets.zero,
            iconColor: colors.primary,
            collapsedIconColor: colors.textHint,
            title: Text(
              topic.title,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w800,
                color: colors.textPrimary,
              ),
            ),
            subtitle: Text(
              l10n.clubTransparencyDocumentCount(topic.documents.length),
              style: TextStyle(fontSize: 11.5, color: colors.textHint),
            ),
            children: [
              for (var i = 0; i < topic.documents.length; i++) ...[
                Divider(height: 1, color: colors.border),
                _DocumentRow(document: topic.documents[i]),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _DocumentRow extends StatelessWidget {
  const _DocumentRow({required this.document});

  final ClubTransparencyDocument document;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return InkWell(
      onTap: () =>
          context.push('/clube/transparencia/documento', extra: document),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        child: Row(
          children: [
            Icon(
              Icons.picture_as_pdf_outlined,
              size: 20,
              color: colors.textHint,
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    document.title,
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                      color: colors.textPrimary,
                      height: 1.3,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    fullDateLabel(document.date),
                    style: TextStyle(fontSize: 11, color: colors.textHint),
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Icon(Icons.open_in_new_rounded, size: 15, color: colors.textHint),
          ],
        ),
      ),
    );
  }
}
