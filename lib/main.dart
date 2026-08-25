import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:goias_app/core/config/supabase_config.dart';
import 'package:goias_app/core/di/injection_container.dart';
import 'package:goias_app/core/router/app_router.dart';
import 'package:goias_app/core/router/splash_gate.dart';
import 'package:goias_app/core/theme/app_theme.dart';
import 'package:goias_app/core/theme/theme_cubit.dart';
import 'package:goias_app/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:goias_app/shared/utils/brazil_time.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  initializeBrazilTimeZone();
  await Supabase.initialize(
    url: SupabaseConfig.url,
    publishableKey: SupabaseConfig.publishableKey,
  );
  setupDependencies();
  runApp(const GoiasApp());
}

class GoiasApp extends StatefulWidget {
  const GoiasApp({super.key});

  @override
  State<GoiasApp> createState() => _GoiasAppState();
}

class _GoiasAppState extends State<GoiasApp> {
  final AuthCubit _authCubit = sl<AuthCubit>();
  final ThemeCubit _themeCubit = sl<ThemeCubit>();
  late final GoRouter _router = createAppRouter(_authCubit, sl<SplashGate>());

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider.value(value: _authCubit),
        BlocProvider.value(value: _themeCubit),
      ],
      child: BlocBuilder<ThemeCubit, ThemeMode>(
        bloc: _themeCubit,
        builder: (context, themeMode) {
          return MaterialApp.router(
            title: 'Goiás EC',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.light,
            darkTheme: AppTheme.dark,
            themeMode: themeMode,
            routerConfig: _router,
          );
        },
      ),
    );
  }
}
