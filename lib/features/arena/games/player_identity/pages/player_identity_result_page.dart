import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:goias_app/core/di/injection_container.dart';
import 'package:goias_app/core/l10n/l10n_extensions.dart';
import 'package:goias_app/core/theme/app_spacing.dart';
import 'package:goias_app/features/arena/games/player_identity/cubit/player_identity_cubit.dart';
import 'package:goias_app/features/arena/games/player_identity/data/player_identity_repository.dart';
import 'package:goias_app/features/arena/games/player_identity/domain/player_identity_archetype_descriptions.dart';
import 'package:goias_app/features/arena/games/player_identity/domain/player_identity_dimension_labels.dart';
import 'package:goias_app/features/arena/games/player_identity/domain/player_identity_models.dart';
import 'package:goias_app/features/arena/games/player_identity/widgets/player_identity_attribute_bar.dart';
import 'package:goias_app/features/arena/games/player_identity/widgets/player_identity_reference_sheet.dart';
import 'package:goias_app/features/arena/games/player_identity/widgets/player_identity_share_card.dart';
import 'package:goias_app/features/arena/shared/arena_colors.dart';
import 'package:goias_app/shared/utils/share_field_image.dart';
import 'package:goias_app/shared/widgets/content_container.dart';

/// Veredito — a tela mais importante do jogo. Persistência dispara em
/// segundo plano e NUNCA bloqueia nem esconde o resultado: ele já foi
/// calculado localmente (`PlayerIdentityEngine`, síncrono) antes desta tela
/// existir, então uma falha de rede aqui é só um `catchError` silencioso,
/// nunca uma tela de erro. Mesma arquitetura de `TacticalIdentityResultPage`.
class PlayerIdentityResultPage extends StatefulWidget {
  const PlayerIdentityResultPage({required this.result, super.key});

  final PlayerIdentityResult result;

  @override
  State<PlayerIdentityResultPage> createState() =>
      _PlayerIdentityResultPageState();
}

class _PlayerIdentityResultPageState extends State<PlayerIdentityResultPage> {
  final _shareKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    unawaited(
      sl<PlayerIdentityRepository>()
          .saveResult(widget.result)
          .catchError((_) {}),
    );
  }

  Future<void> _share(BuildContext context) {
    final result = widget.result;
    final l10n = context.l10n;
    final top = result.closestReferences.isEmpty
        ? null
        : result.closestReferences.first;
    final buffer = StringBuffer()
      ..writeln(l10n.playerIdentityGameTitle.toUpperCase())
      ..writeln(result.archetype.displayName.toUpperCase())
      ..writeln(
        result.topTraits
            .map((d) => '${d.label} ${result.attributes[d]}')
            .join(' · '),
      );
    if (top != null) {
      buffer.writeln(
        '${top.reference.name} • Goiás ${top.reference.period} · '
        '${l10n.playerIdentityAffinityLabel(top.affinity.toStringAsFixed(1))}',
      );
    }
    return shareFieldImage(
      _shareKey,
      text: buffer.toString().trim(),
      fileName: 'que_craque_esmeraldino.png',
    );
  }

  void _redo(BuildContext context) {
    context.pushReplacement(
      '/arena/player-identity/play',
      extra: PlayerIdentityCubit(),
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
            decoration: const BoxDecoration(
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
                              l10n.playerIdentityGameTitle.toUpperCase(),
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
                                final profile = _ProfileSection(
                                  result: result,
                                );
                                final attributes = _AttributesSection(
                                  result: result,
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
                                      attributes,
                                      const SizedBox(height: AppSpacing.xl),
                                      references,
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
                                          const SizedBox(
                                            width: AppSpacing.xl,
                                          ),
                                          Expanded(flex: 4, child: attributes),
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
                child: PlayerIdentityShareCard(result: result),
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

  final PlayerIdentityResult result;

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
            l10n.playerResultYourProfile,
            style: const TextStyle(
              color: ArenaColors.goiasOutfield,
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
          const SizedBox(height: AppSpacing.lg),
          Text(
            l10n.playerResultTraitsTitle,
            style: const TextStyle(
              color: ArenaColors.goiasOutfield,
              fontSize: 11,
              fontWeight: FontWeight.w800,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              for (final trait in result.topTraits)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: ArenaColors.goiasOutfield.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    trait.label,
                    style: const TextStyle(
                      color: ArenaColors.goiasOutfield,
                      fontSize: 12.5,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _AttributesSection extends StatelessWidget {
  const _AttributesSection({required this.result});

  final PlayerIdentityResult result;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final d in PlayerIdentityDimension.values)
            PlayerIdentityAttributeBar(
              label: d.label,
              value: result.attributes[d],
              highlighted: result.topTraits.contains(d),
            ),
        ],
      ),
    );
  }
}

class _ReferencesSection extends StatelessWidget {
  const _ReferencesSection({required this.result});

  final PlayerIdentityResult result;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final references = result.closestReferences;
    if (references.isEmpty) return const SizedBox.shrink();
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
            l10n.playerResultReferencesTitle,
            style: const TextStyle(
              color: ArenaColors.goiasOutfield,
              fontSize: 11.5,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          for (var i = 0; i < references.length; i++) ...[
            _ReferenceRow(index: i + 1, affinity: references[i]),
            if (i != references.length - 1) ...[
              const SizedBox(height: AppSpacing.sm),
              Container(height: 1, color: const Color(0xFFE7E9E7)),
              const SizedBox(height: AppSpacing.sm),
            ],
          ],
        ],
      ),
    );
  }
}

class _ReferenceRow extends StatelessWidget {
  const _ReferenceRow({required this.index, required this.affinity});

  final int index;
  final PlayerIdentityAffinity affinity;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return InkWell(
      onTap: () => showPlayerIdentityReferenceSheet(context, affinity),
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            Container(
              width: 26,
              height: 26,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: ArenaColors.goiasOutfield.withValues(alpha: 0.10),
                shape: BoxShape.circle,
              ),
              child: Text(
                '$index',
                style: const TextStyle(
                  color: ArenaColors.goiasOutfield,
                  fontSize: 12.5,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    affinity.reference.name,
                    style: const TextStyle(
                      color: Colors.black,
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  Text(
                    'Goiás • ${affinity.reference.period}',
                    style: const TextStyle(
                      color: Color(0xFF6B6F6D),
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            Text(
              l10n.playerIdentityAffinityLabel(
                affinity.affinity.toStringAsFixed(1),
              ),
              style: const TextStyle(
                color: ArenaColors.goiasOutfield,
                fontSize: 12.5,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(width: 4),
            const Icon(
              Icons.chevron_right_rounded,
              size: 18,
              color: Color(0xFFB7BCB9),
            ),
          ],
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
        // Botão branco com texto verde-escuro — mesmo padrão de
        // `TacticalIdentityResultPage`.
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
                  const Icon(
                    Icons.ios_share_rounded,
                    size: 19,
                    color: ArenaColors.goiasOutfield,
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Text(
                    l10n.playerResultShare,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: ArenaColors.goiasOutfield,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
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
            child: Text(l10n.playerIdentityCardCtaRedo),
          ),
        ),
      ],
    );
  }
}
