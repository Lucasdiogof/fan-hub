import 'package:flutter/material.dart';

String themeModeLabel(ThemeMode mode) => switch (mode) {
  ThemeMode.system => 'Automático',
  ThemeMode.light => 'Claro',
  ThemeMode.dark => 'Escuro',
};

String themeModeDescription(ThemeMode mode) => switch (mode) {
  ThemeMode.system => 'Segue o tema do seu celular',
  ThemeMode.light => 'Sempre com fundo claro',
  ThemeMode.dark => 'Sempre com fundo escuro',
};

IconData themeModeIcon(ThemeMode mode) => switch (mode) {
  ThemeMode.system => Icons.brightness_auto_outlined,
  ThemeMode.light => Icons.light_mode_outlined,
  ThemeMode.dark => Icons.dark_mode_outlined,
};
