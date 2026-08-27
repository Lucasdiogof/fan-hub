import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:goias_app/core/di/injection_container.dart';
import 'package:goias_app/core/l10n/l10n_extensions.dart';
import 'package:goias_app/core/theme/app_colors.dart';
import 'package:goias_app/core/theme/app_spacing.dart';
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

class SocialFeedPage extends StatelessWidget {
  const SocialFeedPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<SocialFeedCubit>(),
      child: const _SocialFeedView(),
    );
  }
}

class _SocialFeedView extends StatelessWidget {
  const _SocialFeedView();

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Scaffold(
      backgroundColor: colors.background,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 900),
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
                      _Header(),
                      const SizedBox(height: AppSpacing.lg),
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
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                const Expanded(child: _FeedBody()),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        PageTitle(context.l10n.socialMediaTitle),
        const SizedBox(height: 4),
        Text(
          context.l10n.socialMediaSubtitle,
          style: TextStyle(fontSize: 14, color: colors.textSecondary),
        ),
      ],
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
            LoadStatus.success => state.posts.isEmpty
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
