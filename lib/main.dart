import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:goias_app/core/config/supabase_config.dart';
import 'package:goias_app/core/di/injection_container.dart';
import 'package:goias_app/core/router/app_router.dart';
import 'package:goias_app/core/theme/app_theme.dart';
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
  late final GoRouter _router = createAppRouter(_authCubit);

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _authCubit,
      child: MaterialApp.router(
        title: 'Goiás EC',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        darkTheme: AppTheme.dark,
        themeMode: ThemeMode.system,
        routerConfig: _router,
      ),
    );
  }
}
