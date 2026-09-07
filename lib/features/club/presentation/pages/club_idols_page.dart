import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:goias_app/core/club/club_config.dart';
import 'package:goias_app/core/di/injection_container.dart';
import 'package:goias_app/core/l10n/l10n_extensions.dart';
import 'package:goias_app/core/theme/app_colors.dart';
import 'package:goias_app/core/theme/app_spacing.dart';
import 'package:goias_app/features/club/domain/entities/club_idol.dart';
import 'package:goias_app/shared/widgets/back_button_circle.dart';
import 'package:goias_app/shared/widgets/content_container.dart';
import 'package:goias_app/shared/widgets/page_title.dart';
import 'package:goias_app/shared/widgets/state_message.dart';

/// Ídolos do clube ATIVO — lê `institutionalContent.publishedIdols`, nunca
/// uma lista estática de um clube específico. Um clube sem ídolos
/// publicáveis nem chega aqui pela navegação (o card em `/clube` só
/// aparece quando há conteúdo), mas se alguém abrir a rota direto a tela
/// mostra estado vazio — jamais o conteúdo de outro clube.
class ClubIdolsPage extends StatelessWidget {
  const ClubIdolsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final l10n = context.l10n;
    final idols = sl<ClubConfig>().institutionalContent.publishedIdols;
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
                      PageTitle(l10n.clubSectionIdols.toUpperCase()),
                    ],
                  ),
                ),
                Expanded(
                  child: idols.isEmpty
                      ? Center(
                          child: StateMessage(
                            icon: Icons.stars_outlined,
                            title: l10n.clubSectionIdols,
                            message: l10n.clubIdolsSubtitle,
                          ),
                        )
                      : ListView(
                          padding: const EdgeInsets.fromLTRB(
                            AppSpacing.lg,
                            AppSpacing.xl,
                            AppSpacing.lg,
                            AppSpacing.xxxl,
                          ),
                          children: [
                            Text(
                              l10n.clubIdolsCount(idols.length).toUpperCase(),
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 1.2,
                                color: colors.textSecondary,
                              ),
                            ),
                            const SizedBox(height: AppSpacing.md),
                            for (var i = 0; i < idols.length; i++) ...[
                              if (i > 0) const SizedBox(height: AppSpacing.md),
                              _IdolCard(idol: idols[i]),
                            ],
                          ],
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

class _IdolCard extends StatelessWidget {
  const _IdolCard({required this.idol});

  final ClubIdol idol;

  /// "Zagueiro · 1988-1991", só um dos dois, ou nada — nunca um traço solto
  /// nem um rótulo inventado quando a pesquisa não trouxe o dado.
  String? get _subtitle {
    final parts = [
      idol.position,
      idol.period,
    ].where((part) => part != null && part.trim().isNotEmpty).toList();
    return parts.isEmpty ? null : parts.join(' · ');
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final subtitle = _subtitle;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(color: colors.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _IdolAvatar(name: idol.name, photoAsset: idol.photoAsset),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  idol.name,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: colors.textPrimary,
                  ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.4,
                      color: colors.primary,
                    ),
                  ),
                ],
                if (idol.description.trim().isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    idol.description,
                    style: TextStyle(
                      fontSize: 13.5,
                      height: 1.45,
                      color: colors.textSecondary,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Foto real quando existe asset; caso contrário, iniciais sobre a cor
/// secundária do clube — mesma linguagem do avatar da Diretoria. NUNCA uma
/// imagem genérica fingindo ser o jogador.
class _IdolAvatar extends StatelessWidget {
  const _IdolAvatar({required this.name, this.photoAsset});

  final String name;
  final String? photoAsset;

  String get _initials {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts.first.isEmpty) return '';
    final first = parts.first.characters.first;
    final last = parts.length > 1 && parts.last.isNotEmpty
        ? parts.last.characters.first
        : '';
    return (first + last).toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final asset = photoAsset;
    const size = 52.0;
    return ClipOval(
      child: Container(
        width: size,
        height: size,
        alignment: Alignment.center,
        color: colors.secondary,
        child: asset != null && asset.isNotEmpty
            ? Image.asset(
                asset,
                width: size,
                height: size,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) =>
                    _InitialsText(initials: _initials),
              )
            : _InitialsText(initials: _initials),
      ),
    );
  }
}

class _InitialsText extends StatelessWidget {
  const _InitialsText({required this.initials});

  final String initials;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Text(
      initials,
      style: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w900,
        color: colors.primary,
      ),
    );
  }
}
