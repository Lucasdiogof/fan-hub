import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:goias_app/core/di/injection_container.dart';
import 'package:goias_app/core/theme/app_colors.dart';
import 'package:goias_app/core/theme/app_spacing.dart';
import 'package:goias_app/features/home/presentation/cubit/home_cubit.dart';
import 'package:goias_app/features/home/presentation/cubit/home_state.dart';
import 'package:goias_app/features/home/presentation/widgets/featured_news_card.dart';
import 'package:goias_app/features/home/presentation/widgets/home_header.dart';
import 'package:goias_app/features/home/presentation/widgets/last_match_card.dart';
import 'package:goias_app/features/home/presentation/widgets/membership_banner.dart';
import 'package:goias_app/features/home/presentation/widgets/next_match_hero.dart';
import 'package:goias_app/features/home/presentation/widgets/upcoming_matches_section.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<HomeCubit>(),
      child: const _HomeView(),
    );
  }
}

class _HomeView extends StatelessWidget {
  const _HomeView();

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Scaffold(
      backgroundColor: colors.background,
      body: SafeArea(
        child: BlocBuilder<HomeCubit, HomeState>(
          builder: (context, state) {
            if (state.loading && state.nextMatch == null) {
              return Center(child: CircularProgressIndicator(color: colors.primary));
            }
            return Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1200),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.lg,
                    AppSpacing.md,
                    AppSpacing.lg,
                    AppSpacing.xxxl,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const HomeHeader(),
                      const SizedBox(height: AppSpacing.xxl),
                      if (state.nextMatch != null)
                        NextMatchHero(
                          match: state.nextMatch!,
                          onBuyTicket: () {},
                          onViewDetails: () {},
                        ),
                      const SizedBox(height: AppSpacing.lg),
                      LayoutBuilder(
                        builder: (context, constraints) {
                          final wide = constraints.maxWidth > 640;
                          final lastMatch = state.lastResult;
                          final news = state.featuredNews;
                          if (lastMatch == null && news == null) return const SizedBox.shrink();
                          if (!wide) {
                            return Column(
                              children: [
                                if (news != null) FeaturedNewsCard(article: news),
                                if (news != null && lastMatch != null) const SizedBox(height: AppSpacing.md),
                                if (lastMatch != null) LastMatchCard(match: lastMatch),
                              ],
                            );
                          }
                          return IntrinsicHeight(
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                if (lastMatch != null) Expanded(flex: 2, child: LastMatchCard(match: lastMatch)),
                                if (lastMatch != null && news != null) const SizedBox(width: AppSpacing.md),
                                if (news != null) Expanded(flex: 3, child: FeaturedNewsCard(article: news)),
                              ],
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      MembershipBanner(onViewPlans: () {}),
                      const SizedBox(height: AppSpacing.xxxl),
                      UpcomingMatchesSection(
                        matches: state.upcomingMatches,
                        ticketsOpenMatchIds: state.ticketsOpenMatchIds,
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
