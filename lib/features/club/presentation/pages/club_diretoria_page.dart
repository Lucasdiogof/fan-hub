import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:goias_app/core/di/injection_container.dart';
import 'package:goias_app/core/l10n/l10n_extensions.dart';
import 'package:goias_app/core/theme/app_colors.dart';
import 'package:goias_app/core/theme/app_spacing.dart';
import 'package:goias_app/features/club/domain/entities/club_board_section.dart';
import 'package:goias_app/features/club/presentation/cubit/club_board_cubit.dart';
import 'package:goias_app/features/club/presentation/cubit/club_board_state.dart';
import 'package:goias_app/shared/state/load_status.dart';
import 'package:goias_app/shared/widgets/back_button_circle.dart';
import 'package:goias_app/shared/widgets/goias_loading_indicator.dart';
import 'package:goias_app/shared/widgets/page_title.dart';
import 'package:goias_app/shared/widgets/state_message.dart';
import 'package:goias_app/shared/widgets/content_container.dart';
import 'package:goias_app/shared/widgets/viewport_centered.dart';

/// Diretoria do clube — Supabase é a fonte da verdade (ver `club_board.sql`
/// e `SupabaseClubBoardRepository`), então nome/cargo/seção atualizados lá
/// aparecem aqui sem precisar de um novo build do app.
class ClubDiretoriaPage extends StatelessWidget {
  const ClubDiretoriaPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<ClubBoardCubit>()..load(),
      child: const _ClubDiretoriaView(),
    );
  }
}

class _ClubDiretoriaView extends StatelessWidget {
  const _ClubDiretoriaView();

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
                      PageTitle(context.l10n.clubSectionBoard.toUpperCase()),
                    ],
                  ),
                ),
                Expanded(
                  child: BlocBuilder<ClubBoardCubit, ClubBoardState>(
                    builder: (context, state) {
                      return RefreshIndicator(
                        onRefresh: () =>
                            context.read<ClubBoardCubit>().refresh(),
                        color: colors.primary,
                        child: switch (state.status) {
                          LoadStatus.initial || LoadStatus.loading => _centered(
                            const GoiasLoadingIndicator(),
                          ),
                          LoadStatus.error => _centered(
                            StateMessage(
                              icon: Icons.wifi_off_rounded,
                              title: context.l10n.clubBoardLoadErrorTitle,
                              message: state.errorMessage,
                            ),
                          ),
                          LoadStatus.empty => _centered(
                            StateMessage(
                              icon: Icons.groups_outlined,
                              title: context.l10n.clubBoardEmptyTitle,
                              message: context.l10n.clubBoardEmptyMessage,
                            ),
                          ),
                          LoadStatus.success => _BoardList(
                            sections: state.sections,
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

Widget _centered(Widget child) => viewportCentered(child);

class _BoardList extends StatelessWidget {
  const _BoardList({required this.sections});

  final List<ClubBoardSection> sections;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.lg,
        AppSpacing.lg,
        AppSpacing.xxxl,
      ),
      children: [
        for (final section in sections) ...[
          Text(
            section.title.toUpperCase(),
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.8,
              color: colors.textSecondary,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Container(
            decoration: BoxDecoration(
              color: colors.surface,
              borderRadius: BorderRadius.circular(AppRadius.card),
              border: Border.all(color: colors.border),
            ),
            child: Column(
              children: [
                for (var i = 0; i < section.members.length; i++) ...[
                  if (i > 0) Divider(height: 1, color: colors.border),
                  _MemberRow(member: section.members[i]),
                ],
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
        ],
      ],
    );
  }
}

class _MemberRow extends StatelessWidget {
  const _MemberRow({required this.member});

  final ClubBoardMember member;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _InitialsAvatar(name: member.name, photoUrl: member.photoUrl),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  member.name,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: colors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  member.role,
                  style: TextStyle(
                    fontSize: 12,
                    color: colors.textSecondary,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _InitialsAvatar extends StatelessWidget {
  const _InitialsAvatar({required this.name, this.photoUrl});

  final String name;
  final String? photoUrl;

  String get _initials {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty) return '';
    final first = parts.first.characters.first;
    final last = parts.length > 1 ? parts.last.characters.first : '';
    return (first + last).toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final url = photoUrl;
    return ClipOval(
      child: Container(
        width: 44,
        height: 44,
        alignment: Alignment.center,
        color: colors.secondary,
        child: url != null && url.isNotEmpty
            ? Image.network(
                url,
                width: 44,
                height: 44,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Text(
                  _initials,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: colors.primary,
                  ),
                ),
              )
            : Text(
                _initials,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: colors.primary,
                ),
              ),
      ),
    );
  }
}
