import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:goias_app/core/di/injection_container.dart';
import 'package:goias_app/core/theme/app_colors.dart';
import 'package:goias_app/core/theme/app_spacing.dart';
import 'package:goias_app/features/ticket/domain/entities/ticket_order.dart';
import 'package:goias_app/features/ticket/presentation/cubit/my_orders_cubit.dart';
import 'package:goias_app/features/ticket/presentation/cubit/my_orders_state.dart';
import 'package:goias_app/shared/state/load_status.dart';
import 'package:goias_app/shared/widgets/back_button_circle.dart';
import 'package:goias_app/shared/widgets/page_title.dart';
import 'package:goias_app/shared/widgets/state_message.dart';

class MyOrdersPage extends StatelessWidget {
  const MyOrdersPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(create: (_) => sl<MyOrdersCubit>(), child: const _MyOrdersView());
  }
}

class _MyOrdersView extends StatelessWidget {
  const _MyOrdersView();

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
                  BackButtonCircle(onTap: () => context.canPop() ? context.pop() : context.go('/')),
                  const SizedBox(height: AppSpacing.lg),
                  const PageTitle('MEUS PEDIDOS'),
                  const SizedBox(height: AppSpacing.xxxl),
                  Expanded(
                    child: BlocBuilder<MyOrdersCubit, MyOrdersState>(
                      builder: (context, state) {
                        return RefreshIndicator(
                          onRefresh: () => context.read<MyOrdersCubit>().load(),
                          color: colors.primary,
                          child: switch (state.status) {
                            LoadStatus.initial || LoadStatus.loading => _centered(
                              CircularProgressIndicator(color: colors.primary),
                            ),
                            LoadStatus.error => _centered(
                              StateMessage(
                                icon: Icons.wifi_off_rounded,
                                title: 'Não foi possível carregar seus pedidos',
                                message: state.errorMessage,
                              ),
                            ),
                            LoadStatus.empty => _centered(
                              const StateMessage(
                                icon: Icons.receipt_long_outlined,
                                title: 'Nenhum pedido encontrado',
                                message: 'Suas compras de ingressos aparecerão aqui.',
                              ),
                            ),
                            LoadStatus.success => ListView.separated(
                              physics: const AlwaysScrollableScrollPhysics(),
                              padding: const EdgeInsets.only(bottom: AppSpacing.xxxl),
                              itemCount: state.orders.length,
                              separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.md),
                              itemBuilder: (context, index) => _OrderCard(order: state.orders[index]),
                            ),
                          },
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

Widget _centered(Widget child) {
  return ListView(
    physics: const AlwaysScrollableScrollPhysics(),
    children: [Padding(padding: const EdgeInsets.only(top: 100), child: Center(child: child))],
  );
}

class _OrderCard extends StatelessWidget {
  const _OrderCard({required this.order});

  final TicketOrder order;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final date = order.date;
    final dateLabel = '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(color: colors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Pedido ${order.number}',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: colors.textSecondary),
                ),
              ),
              Text(
                'R\$ ${order.amount.toStringAsFixed(2).replaceAll('.', ',')}',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: colors.textPrimary),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(order.eventName, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: colors.textPrimary)),
          const SizedBox(height: 4),
          Text('$dateLabel · ${order.status.label}', style: TextStyle(fontSize: 13, color: colors.textSecondary)),
        ],
      ),
    );
  }
}
