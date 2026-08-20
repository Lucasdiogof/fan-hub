import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
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
    final firstName = _firstName(authState is AuthAuthenticated ? authState.user.fullName : null);

    final title = firstName != null ? '${_greeting()}, $firstName' : 'GOIÁS ESPORTE CLUBE';

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            alignment: Alignment.center,
            decoration: BoxDecoration(color: colors.secondary, shape: BoxShape.circle),
            child: const ClubBadge(team: MockData.goias, size: 30),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(color: colors.textPrimary, fontSize: 16, fontWeight: FontWeight.w800),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          _HeaderIconButton(icon: Icons.person_outline, onTap: () => context.push('/profile')),
        ],
      ),
    );
  }
}

String? _firstName(String? fullName) {
  if (fullName == null || fullName.trim().isEmpty) return null;
  return fullName.trim().split(RegExp(r'\s+')).first;
}

String _greeting() {
  final hour = DateTime.now().hour;
  if (hour < 12) return 'Bom dia';
  if (hour < 18) return 'Boa tarde';
  return 'Boa noite';
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
      shape: const CircleBorder(),
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: SizedBox(
          width: 44,
          height: 44,
          child: Icon(icon, size: 20, color: colors.textPrimary),
        ),
      ),
    );
  }
}
