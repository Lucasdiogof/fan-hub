import 'package:flutter_test/flutter_test.dart';
import 'package:goias_app/features/profile/data/social_links_data.dart';

void main() {
  group('SocialLinksData', () {
    test('has exactly the 6 official channels', () {
      expect(SocialLinksData.all, hasLength(6));
      expect(SocialLinksData.all.map((l) => l.name), [
        'Instagram',
        'YouTube',
        'TikTok',
        'Facebook',
        'X',
        'Site oficial',
      ]);
    });

    test('every url is a real https link to the expected domain', () {
      const expectedHosts = {
        'Instagram': 'instagram.com',
        'YouTube': 'youtube.com',
        'TikTok': 'tiktok.com',
        'Facebook': 'facebook.com',
        'X': 'x.com',
        'Site oficial': 'goiasec.com.br',
      };
      for (final link in SocialLinksData.all) {
        expect(link.url, startsWith('https://'));
        expect(Uri.parse(link.url).host, contains(expectedHosts[link.name]));
      }
    });

    test(
      'each link carries exactly one of svgPathData or icon, never both or neither',
      () {
        for (final link in SocialLinksData.all) {
          final hasSvg = link.svgPathData != null;
          final hasIcon = link.icon != null;
          expect(
            hasSvg != hasIcon,
            isTrue,
            reason: '${link.name} must set exactly one',
          );
        }
      },
    );

    test(
      'only "Site oficial" uses a Material icon — the rest are brand glyphs',
      () {
        final withIcon = SocialLinksData.all.where((l) => l.icon != null);
        expect(withIcon.map((l) => l.name), ['Site oficial']);
      },
    );
  });
}
