import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:goias_app/core/l10n/l10n_extensions.dart';
import 'package:goias_app/core/mock/mock_data.dart';
import 'package:goias_app/core/theme/app_colors.dart';
import 'package:goias_app/core/theme/app_spacing.dart';
import 'package:goias_app/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:goias_app/features/auth/presentation/cubit/auth_state.dart';
import 'package:goias_app/shared/widgets/club_badge.dart';

/// Header leve e pessoal — sem card verde grande por baixo. Só marca
/// presença (escudo + saudação); quem domina a primeira dobra é o próximo
/// jogo, não este componente.
class HomeBrandHeader extends StatelessWidget {
  const HomeBrandHeader({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final authState = context.watch<AuthCubit>().state;
    final firstName = _firstName(
      authState is AuthAuthenticated ? authState.user.fullName : null,
    );

    final title = firstName != null
        ? '${_greeting(context)}, $firstName'
        : 'GOIÁS ESPORTE CLUBE';

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      child: Row(
        children: [
          // O brasão oficial já é auto-contido (aro branco próprio,
          // contraste em qualquer fundo) — não precisa mais do chip
          // circular por trás que a versão tingida antiga precisava.
          ClubBadge(team: MockData.goias, size: 44),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: colors.textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          _HeaderIconButton(
            icon: Icons.person_outline,
            onTap: () => context.push('/profile'),
          ),
        ],
      ),
    );
  }
}

String? _firstName(String? fullName) {
  if (fullName == null || fullName.trim().isEmpty) return null;
  return fullName.trim().split(RegExp(r'\s+')).first;
}

String _greeting(BuildContext context) {
  final l10n = context.l10n;
  final hour = DateTime.now().hour;
  if (hour < 12) return l10n.homeGreetingMorning;
  if (hour < 18) return l10n.homeGreetingAfternoon;
  return l10n.homeGreetingEvening;
}

class _HeaderIconButton extends StatelessWidget {
  const _HeaderIconButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Material(
      color: colors.secondary,
      shape: CircleBorder(side: BorderSide(color: colors.primary, width: 1.6)),
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: SizedBox(
          width: 44,
          height: 44,
          child: Icon(icon, size: 20, color: colors.primary),
        ),
      ),
    );
  }
}
