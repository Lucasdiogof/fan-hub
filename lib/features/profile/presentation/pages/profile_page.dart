import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:goias_app/core/di/injection_container.dart';
import 'package:goias_app/core/l10n/l10n_extensions.dart';
import 'package:goias_app/core/l10n/locale_cubit.dart';
import 'package:goias_app/core/l10n/supported_locales.dart';
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
import 'package:goias_app/features/store/domain/entities/store_order.dart';
import 'package:goias_app/features/store/domain/repositories/store_repository.dart';
import 'package:goias_app/shared/widgets/app_bottom_sheet.dart';
import 'package:goias_app/shared/widgets/back_button_circle.dart';
import 'package:goias_app/shared/widgets/global_loading.dart';
import 'package:goias_app/shared/widgets/page_title.dart';
import 'package:goias_app/shared/widgets/content_container.dart';

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
            constraints: BoxConstraints(maxWidth: ContentWidth.detail.maxWidth),
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
                      PageTitle(context.l10n.profileTitle),
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
                        title: context.l10n.profileMyAccount,
                        rows: [
                          _MenuRow(
                            icon: Icons.person_outline_rounded,
                            label: context.l10n.profilePersonalData,
                            onTap: () => context.push('/profile/personal'),
                          ),
                          _MenuRow(
                            icon: Icons.location_on_outlined,
                            label: context.l10n.profileMyAddress,
                            onTap: () => _openAddress(context),
                          ),
                          _MenuRow(
                            icon: Icons.lock_outline_rounded,
                            label: context.l10n.profileSecurity,
                            onTap: () => context.push('/profile/security'),
                          ),
                          BlocBuilder<ThemeCubit, ThemeMode>(
                            bloc: sl<ThemeCubit>(),
                            builder: (context, mode) => _MenuRow(
                              icon: Icons.palette_outlined,
                              label: context.l10n.profileTheme,
                              value: themeModeLabel(context.l10n, mode),
                              onTap: () => context.push('/profile/theme'),
                            ),
                          ),
                          BlocBuilder<LocaleCubit, Locale?>(
                            bloc: sl<LocaleCubit>(),
                            builder: (context, locale) => _MenuRow(
                              icon: Icons.language_rounded,
                              label: context.l10n.settingsLanguageMenu,
                              value: locale == null
                                  ? context.l10n.languageSystemLabel
                                  : languageEndonym(locale.languageCode),
                              onTap: () => context.push('/profile/language'),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.xl),
                      const _StoreMenuSection(),
                      const SizedBox(height: AppSpacing.xl),
                      const SocialLinksSection(),
                      const SizedBox(height: AppSpacing.xl),
                      _MenuSection(
                        title: context.l10n.profileLegal,
                        rows: [
                          _MenuRow(
                            icon: Icons.description_outlined,
                            label: context.l10n.authTermsLink,
                            onTap: () => context.push('/profile/terms'),
                          ),
                          _MenuRow(
                            icon: Icons.privacy_tip_outlined,
                            label: context.l10n.authPrivacyLink,
                            onTap: () => context.push('/profile/privacy'),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.xl),
                      _MenuSection(
                        title: context.l10n.profileAccount,
                        rows: [
                          _MenuRow(
                            icon: Icons.person_remove_outlined,
                            label: context.l10n.profileDeleteAccount,
                            danger: true,
                            onTap: () => _confirmDeleteAccount(context),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.xxl),
                      const _SignOutButton(),
                      if (kDebugMode) ...[
                        const SizedBox(height: AppSpacing.xxl),
                        const MockMembershipToggle(),
                      ],
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

/// Mesma lógica de carregar antes de navegar que o Elenco usa em O Clube
/// (ver `ClubPage._openSquad`), agora pro endereço salvo.
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
    title: context.l10n.profileDeleteConfirmTitle,
    description: context.l10n.profileDeleteConfirmMessage,
    confirmLabel: context.l10n.commonContinue,
    cancelLabel: context.l10n.commonCancel,
    destructive: true,
  );
  if (confirmed == true && context.mounted) {
    unawaited(context.push('/profile/delete-account'));
  }
}

/// "Meus pedidos"/"Endereços" só aparecem depois do primeiro pedido — antes
/// disso a Store ainda não gerou nada pra gerenciar aqui, então mostrar as
/// duas seria um beco sem saída. A entrada "Goiás Store" em si é sempre
/// visível. Widget próprio (não [FutureBuilder] direto em [_ProfileView])
/// pra guardar a `Future` uma única vez, sem refazer a leitura local a cada
/// rebuild do resto da tela de Perfil.
class _StoreMenuSection extends StatefulWidget {
  const _StoreMenuSection();

  @override
  State<_StoreMenuSection> createState() => _StoreMenuSectionState();
}

class _StoreMenuSectionState extends State<_StoreMenuSection> {
  late final Future<List<StoreOrder>> _ordersFuture = sl<StoreRepository>()
      .getOrders();

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<StoreOrder>>(
      future: _ordersFuture,
      builder: (context, snapshot) {
        final hasOrders = snapshot.data?.isNotEmpty ?? false;
        return _MenuSection(
          title: context.l10n.storeProfileSectionTitle,
          rows: [
            _MenuRow(
              icon: Icons.storefront_outlined,
              label: context.l10n.storeProfileEntry,
              onTap: () => context.push('/store'),
            ),
            if (hasOrders)
              _MenuRow(
                icon: Icons.receipt_long_outlined,
                label: context.l10n.storeProfileMyOrders,
                onTap: () => context.push('/store/orders'),
              ),
            if (hasOrders)
              _MenuRow(
                icon: Icons.location_on_outlined,
                label: context.l10n.storeProfileAddresses,
                onTap: () => context.push('/store/addresses'),
              ),
          ],
        );
      },
    );
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
      title: context.l10n.profileSignOutTitle,
      description: context.l10n.profileSignOutMessage,
      confirmLabel: context.l10n.profileSignOutConfirm,
      cancelLabel: context.l10n.commonCancel,
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
            border: Border.all(color: colors.primary.withValues(alpha: 0.35)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.logout_rounded, size: 18, color: colors.primary),
              const SizedBox(width: AppSpacing.sm),
              Text(
                context.l10n.profileSignOut,
                style: TextStyle(
                  fontSize: 14.5,
                  fontWeight: FontWeight.w700,
                  color: colors.primary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
