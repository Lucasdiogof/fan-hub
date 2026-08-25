import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:goias_app/core/di/injection_container.dart';
import 'package:goias_app/core/theme/app_colors.dart';
import 'package:goias_app/core/theme/app_spacing.dart';
import 'package:goias_app/core/theme/theme_cubit.dart';
import 'package:goias_app/core/theme/theme_mode_label.dart';
import 'package:goias_app/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:goias_app/features/profile/presentation/cubit/address_cubit.dart';
import 'package:goias_app/features/profile/presentation/cubit/profile_cubit.dart';
import 'package:goias_app/features/profile/presentation/widgets/mock_membership_toggle.dart';
import 'package:goias_app/features/profile/presentation/widgets/profile_avatar_header.dart';
import 'package:goias_app/features/profile/presentation/widgets/social_links_section.dart';
import 'package:goias_app/features/squad/presentation/cubit/squad_cubit.dart';
import 'package:goias_app/shared/widgets/app_bottom_sheet.dart';
import 'package:goias_app/shared/widgets/back_button_circle.dart';
import 'package:goias_app/shared/widgets/global_loading.dart';
import 'package:goias_app/shared/widgets/page_title.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    // ProfileCubit é singleton (sl) — o mesmo estado é reaproveitado entre
    // Perfil e Dados pessoais, então editar nome/foto já reflete aqui sem
    // precisar recarregar do zero a cada navegação.
    return BlocProvider.value(
      value: sl<ProfileCubit>(),
      child: const _ProfileView(),
    );
  }
}

class _ProfileView extends StatelessWidget {
  const _ProfileView();

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Scaffold(
      backgroundColor: colors.background,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.lg,
                    AppSpacing.md,
                    AppSpacing.lg,
                    0,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      BackButtonCircle(
                        onTap: () =>
                            context.canPop() ? context.pop() : context.go('/'),
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      const PageTitle('PERFIL'),
                    ],
                  ),
                ),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.lg,
                      AppSpacing.xxl,
                      AppSpacing.lg,
                      AppSpacing.xxxl,
                    ),
                    children: [
                      const ProfileAvatarHeader(),
                      const SizedBox(height: AppSpacing.xxl),
                      _MenuSection(
                        title: 'MINHA CONTA',
                        rows: [
                          _MenuRow(
                            icon: Icons.person_outline_rounded,
                            label: 'Dados pessoais',
                            onTap: () => context.push('/profile/personal'),
                          ),
                          _MenuRow(
                            icon: Icons.location_on_outlined,
                            label: 'Meu endereço',
                            onTap: () => _openAddress(context),
                          ),
                          _MenuRow(
                            icon: Icons.lock_outline_rounded,
                            label: 'Segurança',
                            onTap: () => context.push('/profile/security'),
                          ),
                          BlocBuilder<ThemeCubit, ThemeMode>(
                            bloc: sl<ThemeCubit>(),
                            builder: (context, mode) => _MenuRow(
                              icon: Icons.palette_outlined,
                              label: 'Tema',
                              value: themeModeLabel(mode),
                              onTap: () => context.push('/profile/theme'),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.xl),
                      _MenuSection(
                        title: 'GOIÁS',
                        rows: [
                          _MenuRow(
                            icon: Icons.shield_outlined,
                            label: 'Elenco',
                            onTap: () => _openSquad(context),
                          ),
                          _MenuRow(
                            icon: Icons.handshake_outlined,
                            label: 'Parceiros do Goiás',
                            onTap: () => context.push('/partners'),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.xl),
                      const SocialLinksSection(),
                      const SizedBox(height: AppSpacing.xl),
                      _MenuSection(
                        title: 'LEGAL',
                        rows: [
                          _MenuRow(
                            icon: Icons.description_outlined,
                            label: 'Termos de Uso',
                            onTap: () => context.push(
                              '/coming-soon',
                              extra: (title: 'TERMOS DE USO', message: null),
                            ),
                          ),
                          _MenuRow(
                            icon: Icons.privacy_tip_outlined,
                            label: 'Política de Privacidade',
                            onTap: () => context.push(
                              '/coming-soon',
                              extra: (
                                title: 'POLÍTICA DE PRIVACIDADE',
                                message: null,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.xl),
                      _MenuSection(
                        title: 'CONTA',
                        rows: [
                          _MenuRow(
                            icon: Icons.person_remove_outlined,
                            label: 'Excluir conta',
                            danger: true,
                            onTap: () => _confirmDeleteAccount(context),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.xxl),
                      const _SignOutButton(),
                      const SizedBox(height: AppSpacing.xxl),
                      const MockMembershipToggle(),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Carrega o Elenco ANTES de navegar (ver `GlobalLoading.run`) — a tela
/// já abre com os 31 jogadores prontos, nunca vazia esperando a busca.
Future<void> _openSquad(BuildContext context) async {
  final cubit = sl<SquadCubit>();
  await GlobalLoading.run(context, cubit.load);
  if (!context.mounted) return;
  unawaited(context.push('/squad', extra: cubit));
}

/// Mesma lógica pro endereço salvo.
Future<void> _openAddress(BuildContext context) async {
  final cubit = sl<AddressCubit>();
  await GlobalLoading.run(context, cubit.load);
  if (!context.mounted) return;
  unawaited(context.push('/profile/address', extra: cubit));
}

/// Primeira confirmação, calma e sem tom ameaçador — a segunda confirmação
/// (senha + digitar EXCLUIR) fica na própria [DeleteAccountPage].
Future<void> _confirmDeleteAccount(BuildContext context) async {
  final confirmed = await AppBottomSheet.show(
    context,
    icon: Icons.person_remove_outlined,
    title: 'Excluir conta?',
    description:
        'Ao excluir sua conta, seus dados e seu progresso serão removidos '
        'permanentemente. Essa ação não pode ser desfeita.',
    confirmLabel: 'CONTINUAR',
    cancelLabel: 'Cancelar',
    destructive: true,
  );
  if (confirmed == true && context.mounted) {
    unawaited(context.push('/profile/delete-account'));
  }
}

class _MenuSection extends StatelessWidget {
  const _MenuSection({required this.title, required this.rows});

  final String title;
  final List<Widget> rows;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 2, bottom: AppSpacing.sm),
          child: Text(
            title,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              letterSpacing: 1,
              color: colors.textHint,
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: colors.surface,
            borderRadius: BorderRadius.circular(AppRadius.card),
            border: Border.all(color: colors.border),
          ),
          child: Column(
            children: [
              for (var i = 0; i < rows.length; i++) ...[
                if (i > 0)
                  Divider(
                    height: 1,
                    indent: AppSpacing.lg,
                    endIndent: AppSpacing.lg,
                    color: colors.border,
                  ),
                rows[i],
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _MenuRow extends StatelessWidget {
  const _MenuRow({
    required this.icon,
    required this.label,
    required this.onTap,
    this.value,
    this.danger = false,
  });

  final IconData icon;
  final String label;
  final String? value;
  final VoidCallback onTap;
  final bool danger;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final accent = danger ? colors.error : colors.primary;
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.md + 2,
        ),
        child: Row(
          children: [
            Icon(icon, size: 20, color: accent),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 14.5,
                  fontWeight: FontWeight.w600,
                  color: danger ? accent : colors.textPrimary,
                ),
              ),
            ),
            if (value != null) ...[
              Text(
                value!,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: colors.textHint,
                ),
              ),
              const SizedBox(width: 6),
            ],
            Icon(Icons.chevron_right_rounded, size: 20, color: colors.textHint),
          ],
        ),
      ),
    );
  }
}

class _SignOutButton extends StatelessWidget {
  const _SignOutButton();

  Future<void> _confirmSignOut(BuildContext context) async {
    final authCubit = context.read<AuthCubit>();
    final confirmed = await AppBottomSheet.show(
      context,
      icon: Icons.logout_rounded,
      title: 'Sair da conta?',
      description: 'Você precisará entrar novamente para acessar sua conta.',
      confirmLabel: 'SAIR',
      cancelLabel: 'Cancelar',
      destructive: true,
    );
    if (confirmed == true) {
      await authCubit.signOut();
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Material(
      color: colors.surface,
      borderRadius: BorderRadius.circular(AppRadius.button),
      child: InkWell(
        onTap: () => _confirmSignOut(context),
        borderRadius: BorderRadius.circular(AppRadius.button),
        child: Container(
          height: 52,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadius.button),
            border: Border.all(color: colors.error.withValues(alpha: 0.4)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.logout_rounded, size: 18, color: colors.error),
              const SizedBox(width: AppSpacing.sm),
              Text(
                'Sair',
                style: TextStyle(
                  fontSize: 14.5,
                  fontWeight: FontWeight.w700,
                  color: colors.error,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
