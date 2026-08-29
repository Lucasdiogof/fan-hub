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
import 'package:goias_app/features/social/presentation/widgets/social_post_card.dart';
import 'package:goias_app/features/social/presentation/widgets/social_skeleton_card.dart';
import 'package:goias_app/shared/state/load_status.dart';
import 'package:goias_app/shared/utils/external_link_launcher.dart';
import 'package:goias_app/shared/widgets/page_title.dart';
import 'package:goias_app/shared/widgets/state_message.dart';
import 'package:goias_app/shared/widgets/content_container.dart';

/// Instagram, Notícias, YouTube e X num filtro só, lado a lado — Notícias
/// entra aqui porque também é conteúdo do site oficial, não uma aba à
/// parte. `NewsCubit` é singleton, então trocar pra "Notícias" nunca busca
/// a lista de novo se a Home já tinha carregado antes.
enum _MediaFilter { instagram, news, youtube, x }

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
  var _filter = _MediaFilter.instagram;

  void _select(_MediaFilter filter) {
    setState(() => _filter = filter);
    final platform = switch (filter) {
      _MediaFilter.instagram => SocialPlatform.instagram,
      _MediaFilter.youtube => SocialPlatform.youtube,
      _MediaFilter.x => SocialPlatform.x,
      _MediaFilter.news => null,
    };
    if (platform != null) {
      context.read<SocialFeedCubit>().selectPlatform(platform);
    }
  }

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
                      _MediaFilterBar(selected: _filter, onSelected: _select),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                Expanded(
                  child: _filter == _MediaFilter.news
                      ? const NewsListBody()
                      : const _FeedBody(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _MediaFilterBar extends StatelessWidget {
  const _MediaFilterBar({required this.selected, required this.onSelected});

  final _MediaFilter selected;
  final ValueChanged<_MediaFilter> onSelected;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final options = [
      (_MediaFilter.instagram, l10n.socialPlatformInstagram),
      (_MediaFilter.news, l10n.newsTitle),
      (_MediaFilter.youtube, l10n.socialPlatformYoutube),
      (_MediaFilter.x, l10n.socialPlatformX),
    ];
    final colors = context.colors;
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(AppRadius.button),
        border: Border.all(color: colors.border),
      ),
      child: Row(
        children: [
          for (final (filter, label) in options)
            Expanded(
              child: _FilterChip(
                label: label,
                selected: selected == filter,
                onTap: () => onSelected(filter),
              ),
            ),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
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
      borderRadius: BorderRadius.circular(AppRadius.button - 4),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(vertical: 10),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? colors.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(AppRadius.button - 4),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: colors.primary.withValues(alpha: 0.35),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ]
              : null,
        ),
        child: Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 10.5,
            fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
            letterSpacing: 0.3,
            color: selected ? colors.onPrimary : colors.textSecondary,
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
