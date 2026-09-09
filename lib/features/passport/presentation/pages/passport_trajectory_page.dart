import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:goias_app/core/club/club_config.dart';
import 'package:goias_app/core/di/injection_container.dart';
import 'package:goias_app/core/l10n/l10n_extensions.dart';
import 'package:goias_app/core/theme/app_colors.dart';
import 'package:goias_app/core/theme/app_spacing.dart';
import 'package:goias_app/features/passport/domain/entities/passport_match.dart';
import 'package:goias_app/features/passport/domain/entities/passport_summary.dart';
import 'package:goias_app/features/passport/domain/passport_level.dart';
import 'package:goias_app/features/passport/presentation/cubit/passport_trajectory_cubit.dart';
import 'package:goias_app/features/passport/presentation/cubit/passport_trajectory_state.dart';
import 'package:goias_app/features/passport/presentation/pages/passport_count_list_page.dart';
import 'package:goias_app/features/passport/presentation/pages/passport_match_list_page.dart';
import 'package:goias_app/features/passport/presentation/passport_copy_extension.dart';
import 'package:goias_app/features/passport/presentation/v2/widgets/passport_level_style.dart';
import 'package:goias_app/features/passport/presentation/widgets/passport_memorable_match_picker.dart';
import 'package:goias_app/features/profile/presentation/cubit/profile_cubit.dart';
import 'package:goias_app/features/profile/presentation/cubit/profile_state.dart';
import 'package:goias_app/shared/state/load_status.dart';
import 'package:goias_app/shared/utils/share_field_image.dart';
import 'package:goias_app/shared/widgets/back_button_circle.dart';
import 'package:goias_app/shared/widgets/content_container.dart';
import 'package:goias_app/shared/widgets/goias_loading_indicator.dart';
import 'package:goias_app/shared/widgets/page_title.dart';
import 'package:goias_app/shared/widgets/state_message.dart';

/// Dono de uma trajetória vista a partir do ranking — `null` em todo lugar
/// que espera [PassportTrajectoryArgs]? significa "o usuário logado", nunca
/// um caso à parte. Só leitura: escrita (marcar jogo memorável) continua
/// travada ao próprio usuário no servidor, então a tela também bloqueia essa
/// interação aqui quando [PassportTrajectoryArgs] não é nulo.
class PassportTrajectoryArgs {
  const PassportTrajectoryArgs({
    required this.userId,
    required this.name,
    this.avatarUrl,
  });

  final String userId;
  final String name;
  final String? avatarUrl;
}

/// "Minha trajetória" — resumo pessoal e estatístico das partidas marcadas
/// como "Eu fui" no Passaporte Esmeraldino. Todo o conteúdo (usuário +
/// estatísticas + jogo memorável + estádio mais visitado) vive dentro de UM
/// cartão só — pensado pra ser compartilhado como se fosse uma imagem única
/// da trajetória do torcedor, não uma lista de blocos soltos (ver
/// [_TrajectoryCard] e o botão de compartilhar no cabeçalho). Também serve
/// pra ver a trajetória de OUTRO torcedor a partir do ranking — ver
/// [viewedUser].
class PassportTrajectoryPage extends StatelessWidget {
  const PassportTrajectoryPage({this.viewedUser, super.key});

  /// `null` = usuário logado (edita jogo memorável, nome/foto vêm do
  /// `ProfileCubit`). Não-nulo = visão só-leitura de outro torcedor (nome/
  /// foto vêm do próprio ranking, sem precisar de uma busca extra).
  final PassportTrajectoryArgs? viewedUser;

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (_) =>
              sl<PassportTrajectoryCubit>()..load(userId: viewedUser?.userId),
        ),
        if (viewedUser == null) BlocProvider.value(value: sl<ProfileCubit>()),
      ],
      child: _PassportTrajectoryView(viewedUser: viewedUser),
    );
  }
}

class _PassportTrajectoryView extends StatefulWidget {
  const _PassportTrajectoryView({required this.viewedUser});

  final PassportTrajectoryArgs? viewedUser;

  @override
  State<_PassportTrajectoryView> createState() =>
      _PassportTrajectoryViewState();
}

class _PassportTrajectoryViewState extends State<_PassportTrajectoryView> {
  final _cardKey = GlobalKey();

  Future<void> _share(BuildContext context) => shareFieldImage(
    _cardKey,
    text: context.passportCopy.shareText,
    fileName: 'minha_trajetoria.png',
  );

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
                      Row(
                        children: [
                          BackButtonCircle(onTap: () => context.pop()),
                          const Spacer(),
                          BlocBuilder<
                            PassportTrajectoryCubit,
                            PassportTrajectoryState
                          >(
                            builder: (context, state) => state.totalMatches == 0
                                ? const SizedBox(width: 38)
                                : _ShareButton(onTap: () => _share(context)),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      PageTitle(
                        (widget.viewedUser == null
                                ? context.l10n.passportStatsTitle
                                : context.l10n.passportTrajectoryOfUser(
                                    widget.viewedUser!.name,
                                  ))
                            .toUpperCase(),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child:
                      BlocBuilder<
                        PassportTrajectoryCubit,
                        PassportTrajectoryState
                      >(
                        builder: (context, state) {
                          return switch (state.status) {
                            LoadStatus.initial || LoadStatus.loading =>
                              const Center(child: GoiasLoadingIndicator()),
                            LoadStatus.error => Center(
                              child: StateMessage(
                                icon: Icons.wifi_off_rounded,
                                title: context.l10n.passportLoadErrorTitle,
                                actionLabel: context.l10n.commonRetry,
                                onAction: () => context
                                    .read<PassportTrajectoryCubit>()
                                    .load(),
                              ),
                            ),
                            LoadStatus.empty => const SizedBox.shrink(),
                            LoadStatus.success =>
                              state.totalMatches == 0
                                  ? Center(
                                      child: StateMessage(
                                        icon:
                                            Icons.confirmation_number_outlined,
                                        title: context
                                            .l10n
                                            .passportStatsEmptyTitle,
                                        message: context
                                            .l10n
                                            .passportStatsEmptyMessage,
                                      ),
                                    )
                                  : _TrajectoryBody(
                                      state: state,
                                      cardKey: _cardKey,
                                      viewedUser: widget.viewedUser,
                                    ),
                          };
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

class _ShareButton extends StatelessWidget {
  const _ShareButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Semantics(
      button: true,
      label: context.l10n.passportTrajectoryShareAction,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: Container(
          width: 38,
          height: 38,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: colors.secondary,
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.ios_share_rounded,
            size: 17,
            color: colors.textPrimary,
          ),
        ),
      ),
    );
  }
}

class _TrajectoryBody extends StatelessWidget {
  const _TrajectoryBody({
    required this.state,
    required this.cardKey,
    required this.viewedUser,
  });

  final PassportTrajectoryState state;
  final GlobalKey cardKey;
  final PassportTrajectoryArgs? viewedUser;

  Future<void> _pickMemorableMatch(BuildContext context) async {
    final cubit = context.read<PassportTrajectoryCubit>();
    final chosen = await showMemorableMatchPicker(
      context,
      matches: state.attendedMatches,
      selectedMatchId: state.memorableMatch?.id,
    );
    if (chosen != null) {
      await cubit.selectMemorableMatch(chosen);
    }
  }

  void _openMatches(
    BuildContext context,
    String title,
    List<PassportMatch> matches,
  ) {
    context.push(
      '/arena/passport/trajectory/matches',
      extra: PassportMatchListArgs(title: title, matches: matches),
    );
  }

  void _openCounts(
    BuildContext context,
    String title,
    IconData icon,
    List<PassportCountEntry> entries,
  ) {
    context.push(
      '/arena/passport/trajectory/counts',
      extra: PassportCountListArgs(title: title, icon: icon, entries: entries),
    );
  }

  List<PassportCountEntry> _stadiumEntries() {
    final counts = <String, int>{};
    for (final m in state.attendedMatches) {
      final venue = m.venueName;
      if (venue == null || venue.isEmpty) continue;
      counts[venue] = (counts[venue] ?? 0) + 1;
    }
    final entries =
        counts.entries
            .map((e) => PassportCountEntry(label: e.key, count: e.value))
            .toList()
          ..sort((a, b) => b.count.compareTo(a.count));
    return entries;
  }

  List<PassportCountEntry> _seasonEntries() {
    final counts = <int, int>{};
    for (final m in state.attendedMatches) {
      counts[m.season] = (counts[m.season] ?? 0) + 1;
    }
    final seasons = counts.keys.toList()..sort((a, b) => b.compareTo(a));
    return [
      for (final s in seasons)
        PassportCountEntry(label: '$s', count: counts[s]!),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final breakdown = state.breakdown;
    final winMatches = state.attendedMatches
        .where((m) => m.outcome == PassportOutcome.win)
        .toList();
    final drawMatches = state.attendedMatches
        .where((m) => m.outcome == PassportOutcome.draw)
        .toList();
    final lossMatches = state.attendedMatches
        .where((m) => m.outcome == PassportOutcome.loss)
        .toList();
    final homeMatches = state.attendedMatches
        .where((m) => m.clubIsHome == true)
        .toList();
    final awayMatches = state.attendedMatches
        .where((m) => m.clubIsHome == false)
        .toList();

    return ListView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.sm,
        AppSpacing.lg,
        AppSpacing.xxxl,
      ),
      children: [
        RepaintBoundary(
          key: cardKey,
          child: _TrajectoryCard(
            children: [
              _UserHeader(viewedUser: viewedUser),
              const SizedBox(height: AppSpacing.xxxl),
              Row(
                children: [
                  Expanded(
                    child: _GlassStatCard(
                      label: l10n.passportTrajectoryGames,
                      value: state.totalMatches,
                      onTap: () => _openMatches(
                        context,
                        l10n.passportTrajectoryGames,
                        state.attendedMatches,
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: _GlassStatCard(
                      label: l10n.passportTrajectoryStadiums,
                      value: state.stadiumSummary.uniqueStadiums,
                      onTap: () => _openCounts(
                        context,
                        l10n.passportTrajectoryStadiums,
                        Icons.stadium_outlined,
                        _stadiumEntries(),
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: _GlassStatCard(
                      label: l10n.passportTrajectorySeasons,
                      value: state.seasonsCount,
                      onTap: () => _openCounts(
                        context,
                        l10n.passportTrajectorySeasons,
                        Icons.calendar_today_outlined,
                        _seasonEntries(),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              Row(
                children: [
                  Expanded(
                    child: _GlassStatCard(
                      label: l10n.passportStatsWins,
                      value: breakdown.wins,
                      onTap: () => _openMatches(
                        context,
                        l10n.passportStatsWins,
                        winMatches,
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: _GlassStatCard(
                      label: l10n.passportStatsDraws,
                      value: breakdown.draws,
                      onTap: () => _openMatches(
                        context,
                        l10n.passportStatsDraws,
                        drawMatches,
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: _GlassStatCard(
                      label: l10n.passportStatsLosses,
                      value: breakdown.losses,
                      onTap: () => _openMatches(
                        context,
                        l10n.passportStatsLosses,
                        lossMatches,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.xl),
              _HomeAwayCard(
                homeGames: breakdown.homeGames,
                awayGames: breakdown.awayGames,
                onHomeTap: () => _openMatches(
                  context,
                  l10n.passportStatsHomeGames,
                  homeMatches,
                ),
                onAwayTap: () => _openMatches(
                  context,
                  l10n.passportStatsAwayGames,
                  awayMatches,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              _GoalsCard(
                goalsFor: breakdown.goalsFor,
                goalsAgainst: breakdown.goalsAgainst,
                goalDifference: state.goalDifference,
              ),
              const SizedBox(height: AppSpacing.xl),
              LayoutBuilder(
                builder: (context, constraints) {
                  final vertical = constraints.maxWidth < 360;
                  final memorableCard = _MemorableMatchCard(
                    match: state.memorableMatch,
                    saving: state.savingMemorableMatch,
                    editable: viewedUser == null,
                    onTap: () => _pickMemorableMatch(context),
                  );
                  final stadiumCard = _StadiumCard(
                    summary: state.stadiumSummary,
                  );
                  if (vertical) {
                    return Column(
                      children: [
                        memorableCard,
                        const SizedBox(height: AppSpacing.sm),
                        stadiumCard,
                      ],
                    );
                  }
                  return IntrinsicHeight(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Expanded(child: memorableCard),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(child: stadiumCard),
                      ],
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// O banner inteiro — fundo gradiente verde do clube, cantos bem
/// arredondados (mesmo raio dos banners promocionais do app). Tudo dentro
/// dele usa texto branco/translúcido, nunca os tokens de tema normais
/// (`colors.surface`/`colors.textPrimary`): é uma superfície de marca fixa,
/// igual funciona nos dois temas, pensada pra ser compartilhada como imagem.
class _TrajectoryCard extends StatelessWidget {
  const _TrajectoryCard({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color.lerp(colors.brandDeep, Colors.black, 0.25)!,
            Color.lerp(colors.brandDark, Colors.black, 0.25)!,
          ],
        ),
        borderRadius: BorderRadius.circular(AppRadius.banner),
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          // Escudo oficial (cores reais, mesmo usado em toda identificação
          // de time no app) — só textura de marca no espaço vazio acima das
          // estatísticas, nunca compete com o conteúdo em cima (por isso
          // fica atrás de tudo e não recebe toque).
          Positioned(
            top: 4,
            right: AppSpacing.lg,
            child: IgnorePointer(
              child: Opacity(
                opacity: 0.22,
                child: Image.asset(
                  sl<ClubConfig>().assets.crestBadge,
                  width: 84,
                  height: 84,
                  fit: BoxFit.contain,
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: children,
            ),
          ),
        ],
      ),
    );
  }
}

class _UserHeader extends StatelessWidget {
  const _UserHeader({required this.viewedUser});

  final PassportTrajectoryArgs? viewedUser;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<PassportTrajectoryCubit, PassportTrajectoryState>(
      builder: (context, trajectoryState) {
        final level = passportLevelForMatches(trajectoryState.totalMatches);
        final viewed = viewedUser;
        if (viewed != null) {
          return _UserHeaderContent(
            name: viewed.name,
            avatarUrl: viewed.avatarUrl,
            level: level,
          );
        }
        return BlocBuilder<ProfileCubit, ProfileState>(
          builder: (context, profileState) {
            final profile = profileState.profile;
            return _UserHeaderContent(
              name: profile?.displayName ?? '—',
              avatarUrl: profile?.avatarUrl,
              level: level,
            );
          },
        );
      },
    );
  }
}

class _UserHeaderContent extends StatelessWidget {
  const _UserHeaderContent({
    required this.name,
    required this.avatarUrl,
    required this.level,
  });

  final String name;
  final String? avatarUrl;
  final PassportLevel level;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _Avatar(name: name, avatarUrl: avatarUrl),
        const SizedBox(width: AppSpacing.lg),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.24),
                  ),
                ),
                child: Text(
                  passportLevelLabel(context.passportCopy, level),
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _Avatar extends StatelessWidget {
  const _Avatar({required this.name, required this.avatarUrl});

  final String name;
  final String? avatarUrl;

  String _initials(String name) {
    final words = name
        .trim()
        .split(RegExp(r'\s+'))
        .where((word) => word.isNotEmpty)
        .toList();
    if (words.isEmpty) return '';
    if (words.length == 1) return words.first.substring(0, 1).toUpperCase();
    return (words.first[0] + words.last[0]).toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final url = avatarUrl;
    final hasAvatar = url != null && url.isNotEmpty;
    return Container(
      width: 56,
      height: 56,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.14),
        shape: BoxShape.circle,
        image: hasAvatar
            ? DecorationImage(image: NetworkImage(url), fit: BoxFit.cover)
            : null,
      ),
      child: hasAvatar
          ? null
          : Text(
              _initials(name),
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: Colors.white,
              ),
            ),
    );
  }
}

/// Card de estatística "vidro" sobre o fundo verde — [onTap] nulo (Gols
/// marcados/sofridos/saldo) não vira `InkWell`, nunca um alvo de toque morto.
class _GlassStatCard extends StatelessWidget {
  const _GlassStatCard({required this.label, required this.value, this.onTap});

  final String label;
  final int value;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final content = Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.lg,
      ),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(color: Colors.white.withValues(alpha: 0.16)),
      ),
      child: Column(
        children: [
          Text(
            '$value',
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w900,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w600,
              color: Colors.white.withValues(alpha: 0.75),
            ),
          ),
        ],
      ),
    );
    if (onTap == null) return content;
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(AppRadius.card),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.card),
        child: content,
      ),
    );
  }
}

class _HomeAwayCard extends StatelessWidget {
  const _HomeAwayCard({
    required this.homeGames,
    required this.awayGames,
    required this.onHomeTap,
    required this.onAwayTap,
  });

  final int homeGames;
  final int awayGames;
  final VoidCallback onHomeTap;
  final VoidCallback onAwayTap;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(color: Colors.white.withValues(alpha: 0.16)),
      ),
      child: Row(
        children: [
          Expanded(
            child: _IconStat(
              icon: Icons.home_rounded,
              value: homeGames,
              label: l10n.passportStatsHomeGames,
              onTap: onHomeTap,
            ),
          ),
          Container(
            width: 1,
            height: 40,
            color: Colors.white.withValues(alpha: 0.16),
          ),
          Expanded(
            child: _IconStat(
              icon: Icons.flight_takeoff_rounded,
              value: awayGames,
              label: l10n.passportStatsAwayGames,
              onTap: onAwayTap,
            ),
          ),
        ],
      ),
    );
  }
}

class _IconStat extends StatelessWidget {
  const _IconStat({
    required this.icon,
    required this.value,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final int value;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.card),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
          child: Column(
            children: [
              Icon(icon, size: 17, color: Colors.white),
              const SizedBox(height: 4),
              Text(
                '$value',
                style: const TextStyle(
                  fontSize: 19,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11.5,
                  color: Colors.white.withValues(alpha: 0.75),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _GoalsCard extends StatelessWidget {
  const _GoalsCard({
    required this.goalsFor,
    required this.goalsAgainst,
    required this.goalDifference,
  });

  final int goalsFor;
  final int goalsAgainst;
  final int goalDifference;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final diffText = goalDifference > 0
        ? '+$goalDifference'
        : '$goalDifference';
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(color: Colors.white.withValues(alpha: 0.16)),
      ),
      child: Row(
        children: [
          Expanded(
            child: _GoalStat(
              value: '$goalsFor',
              label: l10n.passportStatsGoalsFor,
            ),
          ),
          Container(
            width: 1,
            height: 36,
            color: Colors.white.withValues(alpha: 0.16),
          ),
          Expanded(
            child: _GoalStat(
              value: '$goalsAgainst',
              label: l10n.passportStatsGoalsAgainst,
            ),
          ),
          Container(
            width: 1,
            height: 36,
            color: Colors.white.withValues(alpha: 0.16),
          ),
          Expanded(
            child: _GoalStat(
              value: diffText,
              label: l10n.passportStatsGoalDifference,
            ),
          ),
        ],
      ),
    );
  }
}

class _GoalStat extends StatelessWidget {
  const _GoalStat({required this.value, required this.label});

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w900,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 10.5,
            color: Colors.white.withValues(alpha: 0.75),
          ),
        ),
      ],
    );
  }
}

class _MemorableMatchCard extends StatelessWidget {
  const _MemorableMatchCard({
    required this.match,
    required this.saving,
    required this.editable,
    required this.onTap,
  });

  final PassportMatch? match;
  final bool saving;

  /// `false` quando vendo a trajetória de outro torcedor a partir do
  /// ranking — nunca dá pra escolher o jogo memorável de outra pessoa (o
  /// servidor rejeitaria mesmo se deixasse tocar).
  final bool editable;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Material(
      color: Colors.white.withValues(alpha: 0.1),
      borderRadius: BorderRadius.circular(AppRadius.card),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: editable && !saving ? onTap : null,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(AppSpacing.lg),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.white.withValues(alpha: 0.16)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                l10n.passportTrajectoryMemorableMatch.toUpperCase(),
                style: TextStyle(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.6,
                  color: Colors.white.withValues(alpha: 0.65),
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              if (match == null)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
                  child: Row(
                    children: [
                      if (editable) ...[
                        const Icon(
                          Icons.add_circle_outline_rounded,
                          size: 18,
                          color: Colors.white,
                        ),
                        const SizedBox(width: 6),
                      ],
                      Expanded(
                        child: Text(
                          editable
                              ? l10n.passportTrajectoryMemorableEmpty
                              : l10n.passportTrajectoryMemorableEmptyReadOnly,
                          style: const TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                )
              else
                _MemorableMatchDetail(match: match!),
            ],
          ),
        ),
      ),
    );
  }
}

class _MemorableMatchDetail extends StatelessWidget {
  const _MemorableMatchDetail({required this.match});

  final PassportMatch match;

  @override
  Widget build(BuildContext context) {
    final date = match.matchDate;
    final dateLabel =
        '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')}/${date.year}';
    final hasScore = match.clubScore != null && match.opponentScore != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '${sl<ClubConfig>().identity.shortName} x ${match.opponent}',
          style: const TextStyle(
            fontSize: 14.5,
            fontWeight: FontWeight.w800,
            color: Colors.white,
          ),
        ),
        if (hasScore) ...[
          const SizedBox(height: 4),
          Text(
            '${match.clubScore} x ${match.opponentScore}',
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w900,
              color: Colors.white,
            ),
          ),
        ],
        const SizedBox(height: 6),
        Text(
          dateLabel,
          style: TextStyle(
            fontSize: 12,
            color: Colors.white.withValues(alpha: 0.75),
          ),
        ),
        Text(
          match.competition,
          style: TextStyle(
            fontSize: 12,
            color: Colors.white.withValues(alpha: 0.75),
          ),
        ),
      ],
    );
  }
}

class _StadiumCard extends StatelessWidget {
  const _StadiumCard({required this.summary});

  final PassportStadiumSummary summary;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final hasData = summary.mostVisitedName != null;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(color: Colors.white.withValues(alpha: 0.16)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            l10n.passportTrajectoryMostVisitedStadium.toUpperCase(),
            style: TextStyle(
              fontSize: 10.5,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.6,
              color: Colors.white.withValues(alpha: 0.65),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          const Icon(Icons.stadium_outlined, size: 22, color: Colors.white),
          const SizedBox(height: AppSpacing.sm),
          if (hasData) ...[
            Text(
              summary.mostVisitedName!,
              style: const TextStyle(
                fontSize: 14.5,
                fontWeight: FontWeight.w800,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              l10n.passportTrajectoryGamesCount(summary.mostVisitedCount ?? 0),
              style: TextStyle(
                fontSize: 12,
                color: Colors.white.withValues(alpha: 0.75),
              ),
            ),
          ] else
            Text(
              l10n.passportTrajectoryStadiumUnavailable,
              style: const TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
        ],
      ),
    );
  }
}
