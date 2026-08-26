import 'package:flutter/material.dart';
import 'package:goias_app/core/l10n/l10n_extensions.dart';
import 'package:goias_app/core/theme/app_colors.dart';
import 'package:goias_app/core/theme/app_spacing.dart';
import 'package:goias_app/features/social/domain/entities/social_post.dart';
import 'package:goias_app/shared/widgets/relative_time_label.dart';

class SocialPostCard extends StatelessWidget {
  const SocialPostCard({required this.post, required this.onTap, super.key});

  final SocialPost post;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return switch (post.platform) {
      SocialPlatform.youtube => _YouTubeCard(post: post, onTap: onTap),
      SocialPlatform.instagram => _InstagramCard(post: post, onTap: onTap),
      SocialPlatform.x => _XCard(post: post, onTap: onTap),
    };
  }
}

class _YouTubeCard extends StatelessWidget {
  const _YouTubeCard({required this.post, required this.onTap});

  final SocialPost post;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return _CardShell(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _PlatformHeader(
            icon: Icons.play_circle_filled,
            iconColor: const Color(0xFFFF0000),
            label: 'YOUTUBE',
            attribution: post.authorName,
            publishedAt: post.publishedAt,
          ),
          const SizedBox(height: AppSpacing.md),
          if (post.thumbnailUrl != null)
            ClipRRect(
              borderRadius: BorderRadius.circular(AppRadius.cardSmall),
              child: AspectRatio(
                aspectRatio: 16 / 9,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Image.network(post.thumbnailUrl!, fit: BoxFit.cover),
                    Center(
                      child: Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.6),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.play_arrow_rounded,
                          color: Colors.white,
                          size: 30,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          if (post.title != null) ...[
            const SizedBox(height: AppSpacing.md),
            Text(
              post.title!,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: colors.textPrimary,
                height: 1.3,
              ),
            ),
          ],
          if (post.metrics?.views != null) ...[
            const SizedBox(height: AppSpacing.sm),
            Text(
              _formatViews(context, post.metrics!.views!),
              style: TextStyle(fontSize: 12, color: colors.textSecondary),
            ),
          ],
        ],
      ),
    );
  }

  static String _formatViews(BuildContext context, int views) {
    final l10n = context.l10n;
    if (views >= 1000000) {
      return l10n.socialViewsM((views / 1000000).toStringAsFixed(1));
    }
    if (views >= 1000) {
      return l10n.socialViewsK((views / 1000).toStringAsFixed(0));
    }
    return l10n.socialViewsCount(views);
  }
}

class _InstagramCard extends StatelessWidget {
  const _InstagramCard({required this.post, required this.onTap});

  final SocialPost post;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return _CardShell(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _PlatformHeader(
            icon: Icons.camera_alt_rounded,
            iconColor: const Color(0xFFE1306C),
            label: 'INSTAGRAM',
            attribution: '@${post.authorHandle}',
            publishedAt: post.publishedAt,
          ),
          if (post.imageUrl != null) ...[
            const SizedBox(height: AppSpacing.md),
            ClipRRect(
              borderRadius: BorderRadius.circular(AppRadius.cardSmall),
              child: Stack(
                children: [
                  Image.network(
                    post.imageUrl!,
                    fit: BoxFit.cover,
                    width: double.infinity,
                  ),
                  if (post.mediaType == SocialMediaType.video)
                    const Positioned(
                      top: AppSpacing.sm,
                      right: AppSpacing.sm,
                      child: _MediaBadge(icon: Icons.videocam_rounded),
                    ),
                  if (post.mediaType == SocialMediaType.carousel)
                    const Positioned(
                      top: AppSpacing.sm,
                      right: AppSpacing.sm,
                      child: _MediaBadge(icon: Icons.collections_rounded),
                    ),
                ],
              ),
            ),
          ],
          if (post.text != null) ...[
            const SizedBox(height: AppSpacing.md),
            Text(
              post.text!,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 13,
                color: colors.textPrimary,
                height: 1.4,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _XCard extends StatelessWidget {
  const _XCard({required this.post, required this.onTap});

  final SocialPost post;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return _CardShell(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _PlatformHeader(
            icon: Icons.tag,
            iconColor: colors.textSecondary,
            label: 'X',
            attribution: '@${post.authorHandle}',
            publishedAt: post.publishedAt,
          ),
          if (post.text != null) ...[
            const SizedBox(height: AppSpacing.md),
            Text(
              post.text!,
              style: TextStyle(
                fontSize: 14,
                color: colors.textPrimary,
                height: 1.45,
              ),
            ),
          ],
          if (post.imageUrl != null) ...[
            const SizedBox(height: AppSpacing.md),
            ClipRRect(
              borderRadius: BorderRadius.circular(AppRadius.cardSmall),
              child: Image.network(
                post.imageUrl!,
                fit: BoxFit.cover,
                width: double.infinity,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _CardShell extends StatelessWidget {
  const _CardShell({required this.child, required this.onTap});

  final Widget child;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.card),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: BorderRadius.circular(AppRadius.card),
          border: Border.all(color: colors.border),
        ),
        child: child,
      ),
    );
  }
}

class _PlatformHeader extends StatelessWidget {
  const _PlatformHeader({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.attribution,
    required this.publishedAt,
  });

  final IconData icon;
  final Color iconColor;
  final String label;
  final String attribution;
  final DateTime publishedAt;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Row(
      children: [
        Icon(icon, size: 14, color: iconColor),
        const SizedBox(width: 6),
        Text(
          label,
          style: TextStyle(
            fontSize: 10.5,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.5,
            color: colors.textSecondary,
          ),
        ),
        const SizedBox(width: 6),
        Text('•', style: TextStyle(fontSize: 10, color: colors.textHint)),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            attribution,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(fontSize: 11, color: colors.textSecondary),
          ),
        ),
        RelativeTimeLabel(dateTime: publishedAt),
      ],
    );
  }
}

class _MediaBadge extends StatelessWidget {
  const _MediaBadge({required this.icon});

  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Icon(icon, size: 14, color: Colors.white),
    );
  }
}
