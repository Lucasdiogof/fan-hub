import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:goias_app/core/club/club_config.dart';
import 'package:goias_app/core/di/injection_container.dart';
import 'package:goias_app/core/l10n/l10n_extensions.dart';
import 'package:goias_app/core/theme/app_colors.dart';
import 'package:goias_app/core/theme/app_spacing.dart';
import 'package:goias_app/features/news/domain/entities/news_item.dart';
import 'package:goias_app/features/news/presentation/cubit/news_cubit.dart';
import 'package:goias_app/features/news/presentation/cubit/news_state.dart';
import 'package:goias_app/features/news/presentation/news_navigation.dart';
import 'package:goias_app/features/news/presentation/widgets/news_item_row.dart';
import 'package:goias_app/features/news/presentation/widgets/news_skeleton_row.dart';
import 'package:goias_app/shared/state/load_status.dart';
import 'package:goias_app/shared/widgets/state_message.dart';
import 'package:goias_app/shared/widgets/viewport_centered.dart';

/// Corpo da lista de notícias — todos os estados (loading/erro/vazio/lista),
/// sem cabeçalho nem `Scaffold` próprio. Usado tanto pela tela cheia de
/// Notícias quanto pela aba "Notícias" dentro do menu Mídia, que compartilham
/// o mesmo `NewsCubit` singleton (a lista já carregada nunca é buscada duas
/// vezes).
class NewsListBody extends StatelessWidget {
  const NewsListBody({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return BlocBuilder<NewsCubit, NewsState>(
      builder: (context, state) {
        return RefreshIndicator(
          onRefresh: () => context.read<NewsCubit>().refresh(),
          color: colors.primary,
          child: switch (state.status) {
            LoadStatus.initial || LoadStatus.loading => const _SkeletonList(),
            LoadStatus.error => _centered(
              StateMessage(
                icon: Icons.wifi_off_rounded,
                title: context.l10n.newsLoadError,
                message: state.errorMessage,
              ),
            ),
            LoadStatus.empty => _centered(
              StateMessage(
                icon: Icons.article_outlined,
                title: context.l10n.newsEmptyTitle,
                message: context.l10n.newsEmptyMessage(
                  sl<ClubConfig>().identity.shortName,
                ),
              ),
            ),
            LoadStatus.success => _NewsList(items: state.items),
          },
        );
      },
    );
  }
}

Widget _centered(Widget child) => viewportCentered(child);

class _SkeletonList extends StatelessWidget {
  const _SkeletonList();

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        0,
        AppSpacing.lg,
        AppSpacing.xxxl,
      ),
      children: const [
        NewsSkeletonRow(),
        NewsSkeletonRow(),
        NewsSkeletonRow(),
        NewsSkeletonRow(),
        NewsSkeletonRow(),
      ],
    );
  }
}

class _NewsList extends StatelessWidget {
  const _NewsList({required this.items});

  final List<NewsItem> items;

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        0,
        AppSpacing.lg,
        AppSpacing.xxxl,
      ),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        return NewsItemRow(
          item: item,
          onTap: () => openNewsArticle(context, item),
        );
      },
    );
  }
}
