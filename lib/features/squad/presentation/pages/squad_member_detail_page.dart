import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:goias_app/core/l10n/l10n_extensions.dart';
import 'package:goias_app/core/theme/app_colors.dart';
import 'package:goias_app/core/theme/app_spacing.dart';
import 'package:goias_app/features/profile/data/social_links_data.dart';
import 'package:goias_app/features/squad/domain/squad_member.dart';
import 'package:goias_app/features/squad/presentation/widgets/club_history_table.dart';
import 'package:goias_app/features/squad/presentation/widgets/squad_avatar.dart';
import 'package:goias_app/shared/utils/external_link_launcher.dart';
import 'package:goias_app/shared/widgets/back_button_circle.dart';
import 'package:goias_app/shared/widgets/content_container.dart';

class SquadMemberDetailPage extends StatelessWidget {
  const SquadMemberDetailPage({required this.member, super.key});

  final SquadMember member;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Scaffold(
      backgroundColor: colors.background,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: ContentWidth.detail.maxWidth),
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
                  child: BackButtonCircle(
                    onTap: () =>
                        context.canPop() ? context.pop() : context.go('/'),
                  ),
                ),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.lg,
                      AppSpacing.xl,
                      AppSpacing.lg,
                      AppSpacing.xxxl,
                    ),
                    children: [
                      Center(
                        child: SquadAvatar(
                          memberId: member.id,
                          photoUrl: member.photoUrl,
                          shirtNumber: member.shirtNumber,
                          size: 96,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      Center(
                        child: Text(
                          member.name,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                            color: colors.textPrimary,
                          ),
                        ),
                      ),
                      if (member.fullName != null &&
                          member.fullName != member.name) ...[
                        const SizedBox(height: 2),
                        Center(
                          child: Text(
                            member.fullName!,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 13,
                              color: colors.textHint,
                            ),
                          ),
                        ),
                      ],
                      const SizedBox(height: 4),
                      Center(
                        child: Text(
                          member.position,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: colors.primary,
                          ),
                        ),
                      ),
                      if (member.instagramUrl != null) ...[
                        const SizedBox(height: AppSpacing.sm),
                        Center(child: _InstagramButton(member: member)),
                      ],
                      const SizedBox(height: AppSpacing.xl),
                      _InfoGrid(member: member),
                      if (member.clubHistory.isNotEmpty) ...[
                        const SizedBox(height: AppSpacing.xl),
                        Text(
                          context.l10n.squadClubHistory,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1,
                            color: colors.textHint,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        ClubHistoryTable(history: member.clubHistory),
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

/// Ícone reaproveitado de `SocialLinksData` (glifo oficial já usado no
/// Perfil) — evita duplicar o SVG do Instagram numa segunda constante.
final _instagramSvgPath = SocialLinksData.all
    .firstWhere((link) => link.name == 'Instagram')
    .svgPathData!;

class _InstagramButton extends StatelessWidget {
  const _InstagramButton({required this.member});

  final SquadMember member;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Semantics(
      button: true,
      label: context.l10n.socialOpenLink('Instagram'),
      child: InkWell(
        onTap: () => openExternalUrl(context, member.instagramUrl!),
        borderRadius: BorderRadius.circular(999),
        child: Container(
          width: 38,
          height: 38,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: colors.secondary,
            shape: BoxShape.circle,
          ),
          child: SizedBox(
            width: 18,
            height: 18,
            child: SvgPicture.string(
              '<svg viewBox="0 0 24 24" xmlns="http://www.w3.org/2000/svg">'
              '<path d="$_instagramSvgPath"/></svg>',
              colorFilter: ColorFilter.mode(colors.primary, BlendMode.srcIn),
            ),
          ),
        ),
      ),
    );
  }
}

class _InfoGrid extends StatelessWidget {
  const _InfoGrid({required this.member});

  final SquadMember member;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final l10n = context.l10n;
    final items = <(IconData, String, String)>[
      if (member.shirtNumber != null)
        (Icons.tag_rounded, l10n.squadNumber, '${member.shirtNumber}'),
      if (member.age != null)
        (Icons.cake_outlined, l10n.squadAge, l10n.squadAgeValue(member.age!)),
      if (member.nationality != null)
        (Icons.flag_outlined, l10n.squadNationality, member.nationality!),
      if (member.heightCm != null)
        (Icons.height_rounded, l10n.squadHeight, '${member.heightCm} cm'),
      if (member.foot != null)
        (Icons.sports_soccer_rounded, l10n.squadFoot, member.foot!),
    ];

    if (items.isEmpty) return const SizedBox.shrink();

    return Container(
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(color: colors.border),
      ),
      child: Column(
        children: [
          for (var i = 0; i < items.length; i++) ...[
            if (i > 0)
              Divider(
                height: 1,
                indent: AppSpacing.lg,
                endIndent: AppSpacing.lg,
                color: colors.border,
              ),
            _InfoRow(icon: items[i].$1, label: items[i].$2, value: items[i].$3),
          ],
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.md,
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: colors.primary),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Text(
              label,
              style: TextStyle(fontSize: 14, color: colors.textSecondary),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: colors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}
