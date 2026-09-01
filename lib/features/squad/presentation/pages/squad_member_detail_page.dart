import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:goias_app/core/l10n/l10n_extensions.dart';
import 'package:goias_app/core/theme/app_colors.dart';
import 'package:goias_app/core/theme/app_spacing.dart';
import 'package:goias_app/features/profile/data/social_links_data.dart';
import 'package:goias_app/features/squad/domain/club_history_entry.dart';
import 'package:goias_app/features/squad/domain/squad_member.dart';
import 'package:goias_app/features/squad/presentation/widgets/squad_avatar.dart';
import 'package:goias_app/shared/utils/external_link_launcher.dart';
import 'package:goias_app/shared/widgets/back_button_circle.dart';
import 'package:goias_app/shared/widgets/content_container.dart';

/// Perfil do jogador — puramente visual (sem seguir/favoritar/persistência
/// nenhuma). Instagram é só um link externo já resolvido no `SquadMember`
/// (ver `instagram_url` no Supabase); esta tela nunca inventa URL, só
/// mostra o botão quando o dado já existe.
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
                      AppSpacing.lg,
                      AppSpacing.lg,
                      AppSpacing.xxxl,
                    ),
                    children: [
                      _PlayerProfileHeader(member: member),
                      const SizedBox(height: AppSpacing.xxl),
                      _SectionLabel(context.l10n.squadAboutSection),
                      const SizedBox(height: AppSpacing.sm),
                      _PlayerInfoGrid(member: member),
                      if (member.clubHistory.isNotEmpty) ...[
                        const SizedBox(height: AppSpacing.xxl),
                        _SectionLabel(context.l10n.squadClubHistory),
                        const SizedBox(height: AppSpacing.md),
                        _PlayerCareerSection(history: member.clubHistory),
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

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text.toUpperCase(),
      style: TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w800,
        letterSpacing: 1,
        color: context.colors.textHint,
      ),
    );
  }
}

class _PlayerProfileHeader extends StatelessWidget {
  const _PlayerProfileHeader({required this.member});

  final SquadMember member;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final showFullName =
        member.fullName != null && member.fullName != member.name;
    final positionLine = member.shirtNumber != null
        ? '${member.position} · #${member.shirtNumber}'
        : member.position;

    return Center(
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(5),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: colors.secondary,
            ),
            child: SquadAvatar(
              memberId: member.id,
              photoUrl: member.photoUrl,
              shirtNumber: member.shirtNumber,
              size: 124,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(
            member.name,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 27,
              fontWeight: FontWeight.w800,
              color: colors.textPrimary,
              height: 1.15,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            positionLine,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: colors.primary,
            ),
          ),
          if (showFullName) ...[
            const SizedBox(height: 8),
            Text(
              member.fullName!,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 13.5, color: colors.textSecondary),
            ),
          ],
          if (member.instagramUrl != null) ...[
            const SizedBox(height: AppSpacing.lg),
            _InstagramButton(member: member),
          ],
        ],
      ),
    );
  }
}

/// Glifo oficial reaproveitado de `SocialLinksData` (mesmo usado no
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
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
          decoration: BoxDecoration(
            color: colors.secondary,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: colors.border),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 15,
                height: 15,
                child: SvgPicture.string(
                  '<svg viewBox="0 0 24 24" xmlns="http://www.w3.org/2000/svg">'
                  '<path d="$_instagramSvgPath"/></svg>',
                  colorFilter: ColorFilter.mode(
                    colors.primary,
                    BlendMode.srcIn,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                context.l10n.squadInstagramLabel,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: colors.primary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Grid 2 colunas, valor primeiro e label depois — mesmos dados de sempre
/// (número, idade, nacionalidade, altura, pé), só a apresentação muda.
class _PlayerInfoGrid extends StatelessWidget {
  const _PlayerInfoGrid({required this.member});

  final SquadMember member;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final l10n = context.l10n;
    final items = <(IconData, String, String)>[
      if (member.shirtNumber != null)
        (Icons.tag_rounded, '#${member.shirtNumber}', l10n.squadNumber),
      if (member.age != null)
        (Icons.cake_outlined, l10n.squadAgeValue(member.age!), l10n.squadAge),
      if (member.nationality != null)
        (Icons.flag_outlined, member.nationality!, l10n.squadNationality),
      if (member.heightCm != null)
        (Icons.height_rounded, '${member.heightCm} cm', l10n.squadHeight),
      if (member.foot != null)
        (Icons.sports_soccer_rounded, member.foot!, l10n.squadFoot),
    ];

    if (items.isEmpty) return const SizedBox.shrink();

    final rows = <List<(IconData, String, String)>>[
      for (var i = 0; i < items.length; i += 2)
        items.sublist(i, i + 2 > items.length ? items.length : i + 2),
    ];

    return Container(
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(color: colors.border),
      ),
      child: Column(
        children: [
          for (var r = 0; r < rows.length; r++) ...[
            if (r > 0) Divider(height: 1, color: colors.border),
            IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (var c = 0; c < rows[r].length; c++) ...[
                    if (c > 0) VerticalDivider(width: 1, color: colors.border),
                    Expanded(child: _StatTile(item: rows[r][c])),
                  ],
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({required this.item});

  final (IconData, String, String) item;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final (icon, value, label) = item;
    return Padding(
      padding: const EdgeInsets.symmetric(
        vertical: AppSpacing.md,
        horizontal: AppSpacing.lg,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: colors.primary),
          const SizedBox(height: 6),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 19,
              fontWeight: FontWeight.w800,
              color: colors.textPrimary,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(fontSize: 12.5, color: colors.textSecondary),
          ),
        ],
      ),
    );
  }
}

/// Timeline vertical — mesma lógica/dados de `ClubHistoryEntry` de sempre
/// (período, clube, jogos, gols, empréstimo, incerteza da fonte), só a
/// tabela horizontal virou uma lista, melhor pra nomes de clube longos e
/// pra mobile em geral.
class _PlayerCareerSection extends StatelessWidget {
  const _PlayerCareerSection({required this.history});

  final List<ClubHistoryEntry> history;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (var i = 0; i < history.length; i++)
          _PlayerCareerItem(entry: history[i], isLast: i == history.length - 1),
      ],
    );
  }
}

class _PlayerCareerItem extends StatelessWidget {
  const _PlayerCareerItem({required this.entry, required this.isLast});

  final ClubHistoryEntry entry;
  final bool isLast;

  /// "abr/2012–jan/2013" -> "2012–2013"; "jan/2020–atual" -> "2020–atual".
  static final _monthPrefix = RegExp('[a-zçã]{3}/', caseSensitive: false);
  String _yearsOnly(String period) => period.replaceAll(_monthPrefix, '');

  String _n(int? value) => value?.toString() ?? '0';

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final l10n = context.l10n;
    final highlight = entry.isGoias;
    final uncertain = entry.dataQuality != 'verified';
    final teamName = entry.loan
        ? '${entry.team} ${l10n.squadLoanTag}'
        : entry.team;

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: 18,
            child: Column(
              children: [
                Container(
                  width: 10,
                  height: 10,
                  margin: const EdgeInsets.only(top: 4),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: highlight ? colors.primary : colors.textHint,
                  ),
                ),
                if (!isLast)
                  Expanded(child: Container(width: 1.5, color: colors.border)),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(
                bottom: isLast ? AppSpacing.xs : AppSpacing.lg,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _yearsOnly(entry.period),
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                      color: colors.textHint,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Flexible(
                        child: Text(
                          teamName,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: highlight
                                ? FontWeight.w800
                                : FontWeight.w700,
                            color: highlight
                                ? colors.primary
                                : colors.textPrimary,
                            height: 1.2,
                          ),
                        ),
                      ),
                      if (uncertain) ...[
                        const SizedBox(width: 5),
                        Tooltip(
                          message: entry.notes ?? l10n.squadDataUnconfirmed,
                          child: Icon(
                            entry.dataQuality == 'review'
                                ? Icons.error_outline_rounded
                                : Icons.help_outline_rounded,
                            size: 14,
                            color: colors.textHint,
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    l10n.squadCareerStatsLine(
                      _n(entry.appearances),
                      _n(entry.goals),
                    ),
                    style: TextStyle(
                      fontSize: 12.5,
                      color: colors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
