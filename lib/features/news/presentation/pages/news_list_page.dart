import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:goias_app/core/di/injection_container.dart';
import 'package:goias_app/core/theme/app_colors.dart';
import 'package:goias_app/core/theme/app_spacing.dart';
import 'package:goias_app/features/news/domain/entities/news_item.dart';
import 'package:goias_app/features/news/presentation/cubit/news_cubit.dart';
import 'package:goias_app/features/news/presentation/cubit/news_state.dart';
import 'package:goias_app/features/news/presentation/news_navigation.dart';
import 'package:goias_app/features/news/presentation/widgets/news_item_row.dart';
import 'package:goias_app/features/news/presentation/widgets/news_skeleton_row.dart';
import 'package:goias_app/shared/state/load_status.dart';
import 'package:goias_app/shared/widgets/back_button_circle.dart';
import 'package:goias_app/shared/widgets/page_title.dart';
import 'package:goias_app/shared/widgets/state_message.dart';

class NewsListPage extends StatelessWidget {
  const NewsListPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: sl<NewsCubit>(),
      child: const _NewsListView(),
    );
  }
}

class _NewsListView extends StatelessWidget {
  const _NewsListView();

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Scaffold(
      backgroundColor: colors.background,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
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
                      BackButtonCircle(
                        onTap: () =>
                            context.canPop() ? context.pop() : context.go('/'),
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      const PageTitle('NOTÍCIAS'),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                const Expanded(child: _NewsListBody()),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _NewsListBody extends StatelessWidget {
  const _NewsListBody();

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
                title: 'Não foi possível carregar as notícias',
                message: state.errorMessage,
              ),
            ),
            LoadStatus.empty => _centered(
              const StateMessage(
                icon: Icons.article_outlined,
                title: 'Nenhuma notícia por aqui ainda',
                message:
                    'Volte mais tarde para conferir as novidades do Goiás.',
              ),
            ),
            LoadStatus.success => _NewsList(items: state.items),
          },
        );
      },
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
