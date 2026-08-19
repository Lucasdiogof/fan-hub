import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:goias_app/core/di/injection_container.dart';
import 'package:goias_app/core/theme/app_colors.dart';
import 'package:goias_app/core/theme/app_spacing.dart';
import 'package:goias_app/features/home/presentation/cubit/home_cubit.dart';
import 'package:goias_app/features/home/presentation/cubit/home_shell_cubit.dart';
import 'package:goias_app/features/home/presentation/cubit/home_state.dart';
import 'package:goias_app/features/home/presentation/widgets/home_brand_header.dart';
import 'package:goias_app/features/home/presentation/widgets/membership_banner.dart';
import 'package:goias_app/features/home/presentation/widgets/next_match_section.dart';
import 'package:goias_app/features/partners/presentation/widgets/partners_home_section.dart';

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
                    AppSpacing.sm,
                    AppSpacing.lg,
                    AppSpacing.xxxl,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const HomeBrandHeader(),
                      if (state.nextMatch != null) ...[
                        const SizedBox(height: AppSpacing.xl),
                        NextMatchSection(
                          match: state.nextMatch!,
                          onTickets: () => context.read<HomeShellCubit>().navigateToTab(2),
                        ),
                      ],
                      const SizedBox(height: AppSpacing.xl),
                      MembershipBanner(
                        onViewPlans: () => context.read<HomeShellCubit>().navigateToTab(3),
                      ),
                      const SizedBox(height: AppSpacing.xl),
                      const PartnersHomeSection(),
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
