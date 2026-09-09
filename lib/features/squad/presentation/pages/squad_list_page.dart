import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:goias_app/core/club/club_config.dart';
import 'package:goias_app/core/di/injection_container.dart';
import 'package:goias_app/core/l10n/l10n_extensions.dart';
import 'package:goias_app/core/theme/app_colors.dart';
import 'package:goias_app/core/theme/app_spacing.dart';
import 'package:goias_app/features/squad/domain/position_groups.dart';
import 'package:goias_app/features/squad/domain/squad_member.dart';
import 'package:goias_app/features/squad/presentation/cubit/squad_cubit.dart';
import 'package:goias_app/features/squad/presentation/cubit/squad_state.dart';
import 'package:goias_app/shared/state/load_status.dart';
import 'package:goias_app/shared/widgets/back_button_circle.dart';
import 'package:goias_app/shared/widgets/goias_loading_indicator.dart';
import 'package:goias_app/shared/widgets/page_title.dart';
import 'package:goias_app/shared/widgets/state_message.dart';
import 'package:goias_app/shared/widgets/content_container.dart';
import 'package:goias_app/shared/widgets/viewport_centered.dart';

/// [cubit], quando fornecido, já veio construído e carregado por quem
/// navegou pra cá (ver `GlobalLoading.run` em `profile_page.dart`) — a tela
/// só reaproveita via `BlocProvider.value`. Fica `null` (e a tela cria/
/// carrega o próprio Cubit) só em navegação direta por URL.
class SquadListPage extends StatelessWidget {
  const SquadListPage({this.cubit, super.key});

  final SquadCubit? cubit;

  @override
  Widget build(BuildContext context) {
    final preloaded = cubit;
    if (preloaded != null) {
      return BlocProvider.value(
        value: preloaded,
        child: const _SquadListView(),
      );
    }
    return BlocProvider(
      create: (_) => sl<SquadCubit>()..load(),
      child: const _SquadListView(),
    );
  }
}

class _SquadListView extends StatelessWidget {
  const _SquadListView();

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Scaffold(
      backgroundColor: colors.background,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: ContentWidth.wide.maxWidth),
            child: Padding(
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
                  PageTitle(context.l10n.squadTitle),
                  const SizedBox(height: AppSpacing.xxxl),
                  Expanded(
                    child: BlocBuilder<SquadCubit, SquadState>(
                      builder: (context, state) {
                        return RefreshIndicator(
                          onRefresh: () => context.read<SquadCubit>().refresh(),
                          color: colors.primary,
                          child: switch (state.status) {
                            LoadStatus.initial || LoadStatus.loading =>
                              _centered(const GoiasLoadingIndicator()),
                            LoadStatus.error => _centered(
                              StateMessage(
                                icon: Icons.wifi_off_rounded,
                                title: context.l10n.squadLoadError,
                                message: state.errorMessage,
                              ),
                            ),
                            LoadStatus.empty => _centered(
                              StateMessage(
                                icon: Icons.groups_outlined,
                                title: context.l10n.squadEmpty,
                              ),
                            ),
                            LoadStatus.success => ListView(
                              physics: const AlwaysScrollableScrollPhysics(),
                              padding: const EdgeInsets.only(
                                bottom: AppSpacing.xxxl,
                              ),
                              children: [
                                for (final group in positionGroupOrder)
                                  _PositionGroupSection(
                                    title: positionGroupLabel(
                                      group,
                                      context.l10n,
                                    ),
                                    members: state.members
                                        .where(
                                          (member) =>
                                              member.positionGroup == group &&
                                              _hasResolvablePhoto(member),
                                        )
                                        .toList(growable: false),
                                  ),
                              ],
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
      ),
    );
  }
}

Widget _centered(Widget child) => viewportCentered(child);

/// Atleta sem foto (nem local do clube ativo, nem `photoUrl` do banco)
/// some da lista — decisão do usuário: "como se o cara não fosse
/// jogador" enquanto não há foto, nunca um círculo genérico/número.
/// Nada é apagado: `member` continua existindo no `state.members`
/// (usado em outras telas, ex. busca/detalhe por id) — é só este filtro
/// visual da listagem por posição. Basta a foto chegar (asset novo no
/// mapa do clube, ou `photoUrl` populado no banco) pra reaparecer sem
/// mexer em código nenhum.
bool _hasResolvablePhoto(SquadMember member) {
  final asset = sl<ClubConfig>().assets.squadPhotos[member.id];
  if (asset != null) return true;
  final url = member.photoUrl;
  return url != null && url.isNotEmpty;
}

class _PositionGroupSection extends StatelessWidget {
  const _PositionGroupSection({required this.title, required this.members});

  final String title;
  final List<SquadMember> members;

  @override
  Widget build(BuildContext context) {
    if (members.isEmpty) return const SizedBox.shrink();
    final colors = context.colors;
    final sorted = [...members]
      ..sort((a, b) {
        final numberA = a.shirtNumber;
        final numberB = b.shirtNumber;
        if (numberA == null && numberB == null) return 0;
        if (numberA == null) return 1;
        if (numberB == null) return -1;
        return numberA.compareTo(numberB);
      });
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title.toUpperCase(),
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              letterSpacing: 1,
              color: colors.textHint,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          LayoutBuilder(
            builder: (context, constraints) {
              final crossAxisCount = switch (constraints.maxWidth) {
                < 500 => 2,
                < 750 => 3,
                _ => 4,
              };
              return GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: crossAxisCount,
                  mainAxisSpacing: AppSpacing.md,
                  crossAxisSpacing: AppSpacing.md,
                  childAspectRatio: 0.74,
                ),
                itemCount: sorted.length,
                itemBuilder: (context, index) =>
                    _SquadCard(member: sorted[index]),
              );
            },
          ),
        ],
      ),
    );
  }
}

/// Card com a foto ocupando quase todo o espaço (retangular, não o avatar
/// circular do `SquadAvatar` — aquele é pra contextos compactos, tipo o
/// cabeçalho do perfil do jogador). Número da camisa como badge por cima
/// da foto em vez de reservar uma linha própria pra ele.
class _SquadCard extends StatelessWidget {
  const _SquadCard({required this.member});

  final SquadMember member;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Material(
      color: colors.surface,
      borderRadius: BorderRadius.circular(AppRadius.card),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => context.push('/squad/${member.id}', extra: member),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadius.card),
            border: Border.all(color: colors.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    _SquadCardPhoto(member: member),
                    if (member.shirtNumber != null)
                      Positioned(
                        top: 8,
                        right: 8,
                        child: _NumberBadge(number: member.shirtNumber!),
                      ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.sm,
                  vertical: AppSpacing.sm,
                ),
                child: Text(
                  member.name,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: colors.textPrimary,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SquadCardPhoto extends StatelessWidget {
  const _SquadCardPhoto({required this.member});

  final SquadMember member;

  @override
  Widget build(BuildContext context) {
    final asset = sl<ClubConfig>().assets.squadPhotos[member.id];
    if (asset != null) {
      return Image.asset(
        asset,
        fit: BoxFit.cover,
        alignment: Alignment.topCenter,
        errorBuilder: (context, _, _) =>
            _SquadCardPhotoFallback(number: member.shirtNumber),
      );
    }
    final url = member.photoUrl;
    if (url == null || url.isEmpty) {
      return _SquadCardPhotoFallback(number: member.shirtNumber);
    }
    return Image.network(
      url,
      fit: BoxFit.cover,
      alignment: Alignment.topCenter,
      errorBuilder: (context, _, _) =>
          _SquadCardPhotoFallback(number: member.shirtNumber),
      loadingBuilder: (context, child, progress) => progress == null
          ? child
          : _SquadCardPhotoFallback(number: member.shirtNumber),
    );
  }
}

class _SquadCardPhotoFallback extends StatelessWidget {
  const _SquadCardPhotoFallback({required this.number});

  final int? number;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return ColoredBox(
      color: colors.secondary,
      child: Center(
        child: Text(
          number?.toString() ?? '–',
          style: TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.w900,
            color: colors.primary,
          ),
        ),
      ),
    );
  }
}

class _NumberBadge extends StatelessWidget {
  const _NumberBadge({required this.number});

  final int number;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        '$number',
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w900,
          color: Colors.white,
        ),
      ),
    );
  }
}
