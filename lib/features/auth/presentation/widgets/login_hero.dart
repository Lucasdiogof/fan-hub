import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:goias_app/core/theme/app_assets.dart';
import 'package:goias_app/core/theme/app_spacing.dart';
import 'package:goias_app/shared/widgets/stadium_backdrop.dart';

class LoginHero extends StatelessWidget {
  const LoginHero({this.compact = false, super.key});

  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        const StadiumBackdrop(imageAsset: AppAssets.stadium),
        SafeArea(
          bottom: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(AppSpacing.xxl, AppSpacing.xxl, AppSpacing.xxl, AppSpacing.xl),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SvgPicture.asset(AppAssets.goiasCrest, height: compact ? 52 : 66),
                SizedBox(height: compact ? AppSpacing.md : AppSpacing.lg),
                const Text(
                  'O Verdão mais perto de você.',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 26,
                    height: 1.15,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.2,
                    shadows: [Shadow(color: Colors.black45, blurRadius: 12, offset: Offset(0, 2))],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
