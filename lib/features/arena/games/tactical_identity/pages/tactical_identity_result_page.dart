import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:goias_app/core/club/club_config.dart';
import 'package:goias_app/core/di/injection_container.dart';
import 'package:goias_app/core/l10n/l10n_extensions.dart';
import 'package:goias_app/core/theme/app_spacing.dart';
import 'package:goias_app/features/arena/games/tactical_identity/cubit/tactical_identity_cubit.dart';
import 'package:goias_app/features/arena/games/tactical_identity/data/tactical_identity_repository.dart';
import 'package:goias_app/features/arena/games/tactical_identity/domain/tactical_archetype_descriptions.dart';
import 'package:goias_app/features/arena/games/tactical_identity/domain/tactical_coach_reference_sets.dart';
import 'package:goias_app/features/arena/games/tactical_identity/domain/tactical_identity_models.dart';
import 'package:goias_app/features/arena/games/tactical_identity/presentation/tactical_identity_copy.dart';
import 'package:goias_app/features/arena/games/tactical_identity/widgets/tactical_bipolar_bar.dart';
import 'package:goias_app/features/arena/games/tactical_identity/widgets/tactical_coach_detail_sheet.dart';
import 'package:goias_app/features/arena/games/tactical_identity/widgets/tactical_map.dart';
import 'package:goias_app/features/arena/games/tactical_identity/widgets/tactical_share_card.dart';
import 'package:goias_app/features/arena/ranking/domain/arena_ranking_repository.dart';
import 'package:goias_app/features/arena/ranking/domain/ranking_entities.dart';
import 'package:goias_app/features/arena/shared/arena_colors.dart';
import 'package:goias_app/shared/utils/share_field_image.dart';
import 'package:goias_app/shared/widgets/content_container.dart';

/// Veredito — a tela mais importante do jogo (ver spec). Persistência
/// dispara em segundo plano e NUNCA bloqueia nem esconde o resultado: ele
/// já foi calculado localmente (`TacticalIdentityEngine`, síncrono) antes
/// desta tela existir, então uma falha de rede aqui é só um `catchError`
/// silencioso, nunca uma tela de erro.
class TacticalIdentityResultPage extends StatefulWidget {
  const TacticalIdentityResultPage({required this.result, super.key});

  final TacticalIdentityResult result;

  @override
  State<TacticalIdentityResultPage> createState() =>
      _TacticalIdentityResultPageState();
}

class _TacticalIdentityResultPageState
    extends State<TacticalIdentityResultPage> {
  late final _engine = tacticalIdentityEngineForClub(sl<ClubConfig>());
  final _shareKey = GlobalKey();

  late final _rankedCoaches = _engine.rankCoaches(
    widget.result.x,
    widget.result.y,
    widget.result.answers,
  );

  @override
  void initState() {
    super.initState();
    unawaited(
      sl<TacticalIdentityRepository>()
          .saveResult(widget.result)
          .catchError((_) {}),
    );
    // 50 pontos só na PRIMEIRA vez que o perfil é descoberto — a regra
    // mora no servidor (`arena_record_score`), aqui só reporta "o
    // resultado existe" (chamado toda vez que esta tela abre, inclusive
    // ao só REVER um resultado salvo — o anti-replay da RPC, ancorado no
    // `item_id` fixo 'profile', já garante 0 pontos em qualquer chamada
    // depois da primeira, nunca duplica).
    unawaited(
      sl<ArenaRankingRepository>().recordScore(
        gameId: ArenaGameIds.tacticalIdentity,
        itemId: ArenaGameIds.profileItemId,
        eventType: 'completed',
      ),
    );
  }

  Future<void> _share(BuildContext context) {
    final result = widget.result;
    final l10n = context.l10n;
    final top = result.closestCoaches.isEmpty
        ? null
        : result.closestCoaches.first;
    final buffer = StringBuffer()
      ..writeln(l10n.tacticalIdentityGameTitle.toUpperCase())
      ..writeln(result.archetype.displayName.toUpperCase())
      ..writeln(
        '${result.possession}% ${l10n.tacticalAxisPossession} · '
        '${result.vertical}% ${l10n.tacticalAxisVertical}',
      )
      ..writeln(
        '${result.dogmatic}% ${l10n.tacticalAxisDogmatic} · '
        '${result.pragmatic}% ${l10n.tacticalAxisPragmatic}',
      );
    if (top != null) {
      final clubName = sl<ClubConfig>().identity.shortName;
      buffer.writeln(
        '${top.coach.coach} • $clubName ${top.coach.period} · '
        '${l10n.tacticalIdentityAffinityLabel(top.affinity.toStringAsFixed(1))}',
      );
    }
    return shareFieldImage(
      _shareKey,
      text: buffer.toString().trim(),
      fileName: 'identidade_futebolistica.png',
    );
  }

  void _redo(BuildContext context) {
    context.pushReplacement(
      '/arena/tactical-identity/play',
      extra: TacticalIdentityCubit(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final result = widget.result;

    return Scaffold(
      backgroundColor: ArenaColors.arenaBottom,
      body: Stack(
        children: [
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [ArenaColors.arenaTop, ArenaColors.arenaBottom],
              ),
            ),
            child: SafeArea(
              child: Center(
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    maxWidth: ContentWidth.wide.maxWidth,
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          children: [
                            InkWell(
                              // Nunca `pop()` aqui: a tela de processamento
                              // usa `push` (não `replace`) pra chegar até o
                              // resultado, então a pergunta anterior fica
                              // "presa" na pilha por baixo — `pop()`
                              // voltaria pra última pergunta, não pra
                              // Arena. Vai direto, sempre.
                              onTap: () => context.go('/arena'),
                              borderRadius: BorderRadius.circular(999),
                              child: Container(
                                width: 38,
                                height: 38,
                                alignment: Alignment.center,
                                decoration: const BoxDecoration(
                                  color: Colors.white24,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.close_rounded,
                                  color: Colors.white,
                                  size: 18,
                                ),
                              ),
                            ),
                            const Spacer(),
                            Text(
                              l10n.tacticalIdentityGameTitle.toUpperCase(),
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 1.2,
                              ),
                            ),
                            const Spacer(),
                            const SizedBox(width: 38),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.lg),
                        Expanded(
                          child: SingleChildScrollView(
                            child: LayoutBuilder(
                              builder: (context, constraints) {
                                final wide = constraints.maxWidth >= 760;
                                final profile = _ProfileSection(result: result);
                                final map = _MapSection(
                                  result: result,
                                  ranked: _rankedCoaches,
                                );
                                final references = _ReferencesSection(
                                  result: result,
                                );
                                final actions = _ActionsSection(
                                  onShare: () => _share(context),
                                  onRedo: () => _redo(context),
                                );
                                if (!wide) {
                                  return Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.stretch,
                                    children: [
                                      profile,
                                      const SizedBox(height: AppSpacing.xl),
                                      references,
                                      const SizedBox(height: AppSpacing.xl),
                                      map,
                                      const SizedBox(height: AppSpacing.xl),
                                      actions,
                                    ],
                                  );
                                }
                                return Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: [
                                    IntrinsicHeight(
                                      child: Row(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Expanded(
                                            flex: 5,
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.stretch,
                                              children: [
                                                profile,
                                                const SizedBox(
                                                  height: AppSpacing.xl,
                                                ),
                                                references,
                                              ],
                                            ),
                                          ),
                                          const SizedBox(width: AppSpacing.xl),
                                          Expanded(flex: 4, child: map),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(height: AppSpacing.xl),
                                    actions,
                                  ],
                                );
                              },
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          // Card compartilhável — fora da área visível (nunca
          // `Opacity(opacity: 0)`: o Flutter pula o pintado de um filho com
          // opacidade zero como otimização, então o `RepaintBoundary` nunca
          // chegava a ser pintado de verdade e `toImage()` quebrava com
          // "!debugNeedsPaint"). Posicionado longe da tela em vez de
          // invisível — assim é pintado normalmente, só nunca aparece pro
          // usuário.
          Positioned(
            left: -4000,
            top: 0,
            child: IgnorePointer(
              child: RepaintBoundary(
                key: _shareKey,
                child: TacticalShareCard(
                  result: result,
                  ranked: _rankedCoaches,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileSection extends StatelessWidget {
  const _ProfileSection({required this.result});

  final TacticalIdentityResult result;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            l10n.tacticalResultYourProfile,
            style: TextStyle(
              color: sl<ClubConfig>().branding.light.primary,
              fontSize: 11.5,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            result.archetype.displayName.toUpperCase(),
            style: const TextStyle(
              color: Colors.black,
              fontSize: 26,
              fontWeight: FontWeight.w900,
              height: 1.1,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            result.archetype.description,
            style: const TextStyle(
              color: Color(0xFF3A3F3D),
              fontSize: 14,
              height: 1.45,
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          TacticalBipolarBar(
            leftLabel: l10n.tacticalAxisPossession,
            leftPercent: result.possession,
            rightLabel: l10n.tacticalAxisVertical,
            rightPercent: result.vertical,
          ),
          const SizedBox(height: AppSpacing.lg),
          TacticalBipolarBar(
            leftLabel: l10n.tacticalAxisDogmatic,
            leftPercent: result.dogmatic,
            rightLabel: l10n.tacticalAxisPragmatic,
            rightPercent: result.pragmatic,
          ),
        ],
      ),
    );
  }
}

class _MapSection extends StatelessWidget {
  const _MapSection({required this.result, required this.ranked});

  final TacticalIdentityResult result;
  final List<CoachAffinity> ranked;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            l10n.tacticalResultTacticalMap,
            style: TextStyle(
              color: sl<ClubConfig>().branding.light.primary,
              fontSize: 11.5,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          TacticalMap(
            userX: result.x,
            userY: result.y,
            coaches: ranked,
            onCoachTap: (affinity) => showTacticalCoachSheet(context, affinity),
          ),
        ],
      ),
    );
  }
}

class _ReferencesSection extends StatelessWidget {
  const _ReferencesSection({required this.result});

  final TacticalIdentityResult result;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final coaches = result.closestCoaches;
    if (coaches.isEmpty) return const SizedBox.shrink();
    final top = coaches.first;
    final others = coaches.skip(1).toList();
    return Container(
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            context.tacticalResultMainReference,
            style: TextStyle(
              color: sl<ClubConfig>().branding.light.primary,
              fontSize: 11.5,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            top.coach.coach,
            style: const TextStyle(
              color: Colors.black,
              fontSize: 20,
              fontWeight: FontWeight.w900,
            ),
          ),
          Text(
            '${sl<ClubConfig>().identity.shortName} • ${top.coach.period}',
            style: const TextStyle(
              color: Color(0xFF6B6F6D),
              fontSize: 12.5,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          _AffinityPill(affinity: top.affinity),
          if (others.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.lg),
            Container(height: 1, color: const Color(0xFFE7E9E7)),
            const SizedBox(height: AppSpacing.md),
            Text(
              l10n.tacticalResultOtherReferences,
              style: TextStyle(
                color: sl<ClubConfig>().branding.light.primary,
                fontSize: 11,
                fontWeight: FontWeight.w800,
                letterSpacing: 1,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            for (final affinity in others) ...[
              _OtherReferenceRow(affinity: affinity),
              const SizedBox(height: AppSpacing.sm),
            ],
          ],
        ],
      ),
    );
  }
}

class _OtherReferenceRow extends StatelessWidget {
  const _OtherReferenceRow({required this.affinity});

  final CoachAffinity affinity;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                affinity.coach.coach,
                style: const TextStyle(
                  color: Colors.black,
                  fontSize: 13.5,
                  fontWeight: FontWeight.w800,
                ),
              ),
              Text(
                '${sl<ClubConfig>().identity.shortName} • '
                '${affinity.coach.period}',
                style: const TextStyle(
                  color: Color(0xFF6B6F6D),
                  fontSize: 11.5,
                ),
              ),
            ],
          ),
        ),
        Text(
          '${affinity.affinity.toStringAsFixed(1)}%',
          style: TextStyle(
            color: sl<ClubConfig>().branding.light.primary,
            fontSize: 15,
            fontWeight: FontWeight.w900,
          ),
        ),
      ],
    );
  }
}

class _AffinityPill extends StatelessWidget {
  const _AffinityPill({required this.affinity});

  final double affinity;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: 6,
      ),
      decoration: BoxDecoration(
        color: sl<ClubConfig>().branding.light.primary.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        l10n.tacticalIdentityAffinityLabel(affinity.toStringAsFixed(1)),
        style: TextStyle(
          color: sl<ClubConfig>().branding.light.primary,
          fontSize: 12.5,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _ActionsSection extends StatelessWidget {
  const _ActionsSection({required this.onShare, required this.onRedo});

  final VoidCallback onShare;
  final VoidCallback onRedo;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Botão branco com texto verde-escuro — mesmo padrão já usado pros
        // CTAs sobre fundo escuro da Arena (ver `CrowdLineupHeroCard`),
        // nunca `AppPrimaryButton` aqui: o texto dele é sempre branco
        // (`colors.onPrimary`), o que ficaria ilegível num fundo branco.
        Material(
          color: Colors.white,
          borderRadius: BorderRadius.circular(AppRadius.button),
          child: InkWell(
            onTap: onShare,
            borderRadius: BorderRadius.circular(AppRadius.button),
            child: SizedBox(
              height: 54,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.ios_share_rounded,
                    size: 19,
                    color: sl<ClubConfig>().branding.light.primary,
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Text(
                    l10n.tacticalResultShare,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: sl<ClubConfig>().branding.light.primary,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        SizedBox(
          height: 50,
          child: OutlinedButton(
            onPressed: onRedo,
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.white,
              side: const BorderSide(color: Colors.white38),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppRadius.button),
              ),
              textStyle: const TextStyle(fontWeight: FontWeight.w800),
            ),
            child: Text(l10n.tacticalIdentityCardCtaRedo),
          ),
        ),
      ],
    );
  }
}
