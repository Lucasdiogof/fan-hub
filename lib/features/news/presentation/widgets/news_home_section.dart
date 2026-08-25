import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:goias_app/core/di/injection_container.dart';
import 'package:goias_app/core/theme/app_spacing.dart';
import 'package:goias_app/features/news/presentation/cubit/news_cubit.dart';
import 'package:goias_app/features/news/presentation/cubit/news_state.dart';
import 'package:goias_app/features/news/presentation/news_navigation.dart';
import 'package:goias_app/features/news/presentation/widgets/news_item_row.dart';
import 'package:goias_app/features/news/presentation/widgets/news_skeleton_row.dart';
import 'package:goias_app/shared/state/load_status.dart';
import 'package:goias_app/shared/widgets/section_header.dart';

/// Preview das 3 notícias mais recentes — conteúdo secundário, então nunca
/// usa o `GlobalLoading` bloqueante; se falhar ou vier vazio, a seção some
/// em vez de mostrar um erro chamativo no meio da Home.
class NewsHomeSection extends StatelessWidget {
  const NewsHomeSection({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: sl<NewsCubit>(),
      child: BlocBuilder<NewsCubit, NewsState>(
        builder: (context, state) {
          if (state.status == LoadStatus.error ||
              state.status == LoadStatus.empty) {
            return const SizedBox.shrink();
          }
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SectionHeader(
                title: 'NOTÍCIAS',
                actionLabel: 'Ver mais',
                onAction: () => context.push('/news'),
              ),
              const SizedBox(height: AppSpacing.sm),
              if (state.status == LoadStatus.initial ||
                  state.status == LoadStatus.loading)
                const Column(
                  children: [
                    NewsSkeletonRow(),
                    NewsSkeletonRow(),
                    NewsSkeletonRow(),
                  ],
                )
              else
                Column(
                  children: [
                    for (final item in state.items.take(3))
                      NewsItemRow(
                        item: item,
                        onTap: () => openNewsArticle(context, item),
                      ),
                  ],
                ),
            ],
          );
        },
      ),
    );
  }
}
