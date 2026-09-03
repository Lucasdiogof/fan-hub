import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:goias_app/core/l10n/l10n_extensions.dart';
import 'package:goias_app/core/theme/app_colors.dart';
import 'package:goias_app/core/theme/app_spacing.dart';
import 'package:goias_app/features/profile/data/social_links_data.dart';
import 'package:goias_app/features/profile/domain/entities/social_link.dart';
import 'package:goias_app/shared/utils/external_link_launcher.dart';

class SocialLinksSection extends StatelessWidget {
  const SocialLinksSection({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final links = SocialLinksData.all;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 2, bottom: 2),
          child: Text(
            context.l10n.socialFollowTitle,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              letterSpacing: 1,
              color: colors.textHint,
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(left: 2, bottom: AppSpacing.md),
          child: Text(
            context.l10n.socialFollowSubtitle,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: colors.textSecondary,
            ),
          ),
        ),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 3,
          mainAxisSpacing: AppSpacing.sm,
          crossAxisSpacing: AppSpacing.sm,
          childAspectRatio: 1.6,
          children: [for (final link in links) _SocialLinkTile(link: link)],
        ),
      ],
    );
  }
}

class _SocialLinkTile extends StatelessWidget {
  const _SocialLinkTile({required this.link});

  final SocialLink link;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Semantics(
      button: true,
      label: context.l10n.socialOpenLink(link.name),
      child: Material(
        color: colors.secondary,
        borderRadius: BorderRadius.circular(AppRadius.cardSmall),
        child: InkWell(
          onTap: () => openExternalUrl(context, link.url),
          borderRadius: BorderRadius.circular(AppRadius.cardSmall),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppRadius.cardSmall),
              border: Border.all(color: colors.border),
            ),
            alignment: Alignment.center,
            child: _SocialIcon(link: link, color: colors.primary),
          ),
        ),
      ),
    );
  }
}

class _SocialIcon extends StatelessWidget {
  const _SocialIcon({required this.link, required this.color});

  final SocialLink link;
  final Color color;

  @override
  Widget build(BuildContext context) {
    if (link.icon != null) {
      return Icon(link.icon, size: 20, color: color);
    }
    return SizedBox(
      width: 18,
      height: 18,
      child: SvgPicture.string(
        '<svg viewBox="0 0 24 24" xmlns="http://www.w3.org/2000/svg">'
        '<path d="${link.svgPathData}"/></svg>',
        colorFilter: ColorFilter.mode(color, BlendMode.srcIn),
      ),
    );
  }
}
