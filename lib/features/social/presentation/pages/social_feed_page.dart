import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:goias_app/core/di/injection_container.dart';
import 'package:goias_app/core/l10n/l10n_extensions.dart';
import 'package:goias_app/core/theme/app_colors.dart';
import 'package:goias_app/core/theme/app_spacing.dart';
import 'package:goias_app/features/news/presentation/cubit/news_cubit.dart';
import 'package:goias_app/features/news/presentation/widgets/news_list_body.dart';
import 'package:goias_app/features/social/domain/entities/social_post.dart';
import 'package:goias_app/features/social/presentation/cubit/social_feed_cubit.dart';
import 'package:goias_app/features/social/presentation/cubit/social_feed_state.dart';
import 'package:goias_app/features/social/presentation/widgets/social_empty_state.dart';
import 'package:goias_app/features/social/presentation/widgets/social_platform_filter.dart';
import 'package:goias_app/features/social/presentation/widgets/social_post_card.dart';
import 'package:goias_app/features/social/presentation/widgets/social_skeleton_card.dart';
import 'package:goias_app/shared/state/load_status.dart';
import 'package:goias_app/shared/utils/external_link_launcher.dart';
import 'package:goias_app/shared/widgets/page_title.dart';
import 'package:goias_app/shared/widgets/state_message.dart';
import 'package:goias_app/shared/widgets/content_container.dart';

enum _MediaSection { social, news }

/// "Mídia" — feed de redes sociais e, na mesma tela, todas as notícias
/// (a Home não tem mais sua própria seção de notícias; ver mais / tudo
/// mora aqui agora). `NewsCubit` é singleton, então entrar nesta aba nunca
/// busca a lista de novo se a Home já tinha carregado antes.
class SocialFeedPage extends StatelessWidget {
  const SocialFeedPage({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => sl<SocialFeedCubit>()),
        BlocProvider.value(value: sl<NewsCubit>()),
      ],
      child: const _SocialFeedView(),
    );
  }
}

class _SocialFeedView extends StatefulWidget {
  const _SocialFeedView();

  @override
  State<_SocialFeedView> createState() => _SocialFeedViewState();
}

class _SocialFeedViewState extends State<_SocialFeedView> {
  var _section = _MediaSection.social;

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
              crossAxisAlignment: CrossAxisAlignment.stretch,
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
                      PageTitle(context.l10n.socialMediaTitle),
                      const SizedBox(height: AppSpacing.lg),
                      _SectionSelector(
                        selected: _section,
                        onSelected: (section) =>
                            setState(() => _section = section),
                      ),
                      if (_section == _MediaSection.social) ...[
                        const SizedBox(height: AppSpacing.sm),
                        BlocBuilder<SocialFeedCubit, SocialFeedState>(
                          buildWhen: (p, c) =>
                              p.selectedPlatform != c.selectedPlatform,
                          builder: (context, state) {
                            return SocialPlatformFilter(
                              selected: state.selectedPlatform,
                              onChanged: context
                                  .read<SocialFeedCubit>()
                                  .selectPlatform,
                            );
                          },
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                Expanded(
                  child: _section == _MediaSection.social
                      ? const _FeedBody()
                      : const NewsListBody(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SectionSelector extends StatelessWidget {
  const _SectionSelector({required this.selected, required this.onSelected});

  final _MediaSection selected;
  final ValueChanged<_MediaSection> onSelected;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final l10n = context.l10n;
    return Container(
      height: 38,
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: colors.secondary,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        children: [
          Expanded(
            child: _SegmentButton(
              label: l10n.socialTabSocial,
              selected: selected == _MediaSection.social,
              onTap: () => onSelected(_MediaSection.social),
            ),
          ),
          Expanded(
            child: _SegmentButton(
              label: l10n.newsTitle,
              selected: selected == _MediaSection.news,
              onTap: () => onSelected(_MediaSection.news),
            ),
          ),
        ],
      ),
    );
  }
}

class _SegmentButton extends StatelessWidget {
  const _SegmentButton({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? colors.surface : Colors.transparent,
          borderRadius: BorderRadius.circular(999),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: colors.textPrimary.withValues(alpha: 0.08),
                    blurRadius: 4,
                  ),
                ]
              : null,
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12.5,
            fontWeight: FontWeight.w800,
            color: selected ? colors.textPrimary : colors.textSecondary,
          ),
        ),
      ),
    );
  }
}

class _FeedBody extends StatelessWidget {
  const _FeedBody();

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return BlocBuilder<SocialFeedCubit, SocialFeedState>(
      builder: (context, state) {
        return RefreshIndicator(
          onRefresh: () => context.read<SocialFeedCubit>().refresh(),
          color: colors.primary,
          child: switch (state.status) {
            LoadStatus.initial || LoadStatus.loading => _SkeletonList(),
            LoadStatus.error => _centered(
              StateMessage(
                icon: Icons.wifi_off_rounded,
                title: context.l10n.socialFeedLoadError,
                message: state.errorMessage,
              ),
            ),
            LoadStatus.empty => _centered(const SocialEmptyState()),
            LoadStatus.success =>
              state.posts.isEmpty
                  ? _centered(const SocialEmptyState())
                  : _PostsList(posts: state.posts),
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
        SocialSkeletonCard(),
        SizedBox(height: AppSpacing.md),
        SocialSkeletonCard(withImage: false),
        SizedBox(height: AppSpacing.md),
        SocialSkeletonCard(),
      ],
    );
  }
}

class _PostsList extends StatelessWidget {
  const _PostsList({required this.posts});

  final List<SocialPost> posts;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        0,
        AppSpacing.lg,
        AppSpacing.xxxl,
      ),
      itemCount: posts.length,
      separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.md),
      itemBuilder: (context, index) {
        final post = posts[index];
        return SocialPostCard(
          post: post,
          onTap: () => openExternalUrl(context, post.permalink),
        );
      },
    );
  }
}
