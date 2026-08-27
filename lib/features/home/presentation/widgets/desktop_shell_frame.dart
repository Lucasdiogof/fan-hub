import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:goias_app/core/di/injection_container.dart';
import 'package:goias_app/core/theme/app_breakpoints.dart';
import 'package:goias_app/features/home/presentation/cubit/home_shell_cubit.dart';
import 'package:goias_app/features/home/presentation/widgets/main_navigation_rail.dart';

/// Envolve toda rota "interna" (fora do shell de `/`) com o mesmo rail
/// lateral da Home no desktop, pra nunca dar a impressão de que a rota
/// interna é só o app mobile flutuando no meio do navegador. No celular
/// (abaixo do corte `isAtLeastExpanded`) é um no-op: devolve [child] direto,
/// sem nenhuma mudança de comportamento em relação ao que já existia.
class DesktopShellFrame extends StatelessWidget {
  const DesktopShellFrame({required this.child, this.tabIndex, super.key});

  final Widget child;
  final int? tabIndex;

  @override
  Widget build(BuildContext context) {
    if (!context.isAtLeastExpanded) return child;

    return Scaffold(
      body: Row(
        children: [
          MainNavigationRail(
            selectedIndex: tabIndex ?? -1,
            onSelected: (index) {
              sl<HomeShellCubit>().navigateToTab(index);
              context.go('/');
            },
          ),
          Expanded(child: child),
        ],
      ),
    );
  }
}

/// Mapeia o prefixo da rota pra aba do shell "dona" daquele fluxo — só pras
/// que claramente pertencem a uma aba. O resto abre sem nenhum item
/// destacado no rail (ainda navegável, só sem realce).
int? tabIndexForLocation(String location) {
  const mapping = <String, int>{
    '/match': 1,
    '/crowd-lineup': 1,
    '/tickets': 1,
    '/membership': 2,
    '/arena': 4,
  };
  for (final entry in mapping.entries) {
    if (location == entry.key || location.startsWith('${entry.key}/')) {
      return entry.value;
    }
  }
  return null;
}
