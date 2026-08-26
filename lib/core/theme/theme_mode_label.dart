import 'package:flutter/material.dart';
import 'package:goias_app/l10n/app_localizations.dart';

String themeModeLabel(AppLocalizations l10n, ThemeMode mode) => switch (mode) {
  ThemeMode.system => l10n.themeModeAuto,
  ThemeMode.light => l10n.themeModeLight,
  ThemeMode.dark => l10n.themeModeDark,
};

String themeModeDescription(AppLocalizations l10n, ThemeMode mode) =>
    switch (mode) {
      ThemeMode.system => l10n.themeModeAutoDesc,
      ThemeMode.light => l10n.themeModeLightDesc,
      ThemeMode.dark => l10n.themeModeDarkDesc,
    };

IconData themeModeIcon(ThemeMode mode) => switch (mode) {
  ThemeMode.system => Icons.brightness_auto_outlined,
  ThemeMode.light => Icons.light_mode_outlined,
  ThemeMode.dark => Icons.dark_mode_outlined,
};
