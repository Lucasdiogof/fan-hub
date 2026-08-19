import 'package:flutter/material.dart';
import 'package:goias_app/core/di/injection_container.dart';
import 'package:goias_app/core/error/result.dart';
import 'package:goias_app/core/theme/app_colors.dart';
import 'package:goias_app/core/theme/app_spacing.dart';
import 'package:goias_app/features/membership/domain/entities/membership.dart';
import 'package:goias_app/features/membership/domain/repositories/membership_repository.dart';
import 'package:goias_app/features/membership/presentation/widgets/membership_card_mock.dart';
import 'package:goias_app/shared/widgets/page_title.dart';
import 'package:goias_app/shared/widgets/state_message.dart';

class MembershipHomePage extends StatefulWidget {
  const MembershipHomePage({super.key});

  @override
  State<MembershipHomePage> createState() => _MembershipHomePageState();
}

class _MembershipHomePageState extends State<MembershipHomePage> {
  late final Future<Result<Membership?>> _future = sl<MembershipRepository>().getMyMembership();

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Scaffold(
      backgroundColor: colors.background,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 900),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.md, AppSpacing.lg, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const PageTitle('SÓCIO ESMERALDA'),
                  const SizedBox(height: AppSpacing.xxxl),
                  Expanded(
                    child: FutureBuilder<Result<Membership?>>(
                      future: _future,
                      builder: (context, snapshot) {
                        if (snapshot.connectionState != ConnectionState.done) {
                          return Center(child: CircularProgressIndicator(color: colors.primary));
                        }
                        final result = snapshot.data;
                        final membership = switch (result) {
                          Success(:final data) => data,
                          _ => null,
                        };
                        if (membership == null) {
                          return const Center(
                            child: StateMessage(
                              icon: Icons.badge_outlined,
                              title: 'Você ainda não é sócio esmeraldino.',
                              message: 'Associe-se pra ter carteirinha, prioridade no estádio e descontos.',
                            ),
                          );
                        }
                        return Center(
                          child: MembershipCardMock(
                            holderName: membership.holderName,
                            planName: membership.plan.name,
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
