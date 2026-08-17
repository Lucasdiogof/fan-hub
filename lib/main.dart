import 'package:flutter/material.dart';
import 'package:goias_app/core/di/injection_container.dart';
import 'package:goias_app/core/router/app_router.dart';
import 'package:goias_app/core/theme/app_theme.dart';

void main() {
  setupDependencies();
  runApp(const GoiasApp());
}

class GoiasApp extends StatelessWidget {
  const GoiasApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Goiás EC',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: ThemeMode.system,
      routerConfig: appRouter,
    );
  }
}
