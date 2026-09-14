import 'package:flutter_test/flutter_test.dart';
import 'package:goias_app/core/error/failures.dart';
import 'package:goias_app/core/error/result.dart';
import 'package:goias_app/features/ticket/presentation/cubit/my_orders_cubit.dart';
import 'package:goias_app/shared/state/load_status.dart';

import '../../fakes/fake_ticket_repository.dart';

void main() {
  late FakeTicketRepository repository;

  setUp(() {
    repository = FakeTicketRepository();
  });

  test('ao criar, já carrega sozinho e emite success com os pedidos', () async {
    final order = buildOrder(id: 'order-1');
    repository.myOrdersResult = Success([order]);

    final cubit = MyOrdersCubit(repository);
    addTearDown(cubit.close);
    await Future<void>.delayed(Duration.zero);

    expect(cubit.state.status, LoadStatus.success);
    expect(cubit.state.orders, [order]);
  });

  test('sem pedidos nenhum, emite LoadStatus.empty', () async {
    repository.myOrdersResult = const Success([]);

    final cubit = MyOrdersCubit(repository);
    addTearDown(cubit.close);
    await Future<void>.delayed(Duration.zero);

    expect(cubit.state.status, LoadStatus.empty);
    expect(cubit.state.orders, isEmpty);
  });

  test('falha do repositório expõe a mensagem de erro', () async {
    repository.myOrdersResult = const Error(ServerFailure('indisponível'));

    final cubit = MyOrdersCubit(repository);
    addTearDown(cubit.close);
    await Future<void>.delayed(Duration.zero);

    expect(cubit.state.status, LoadStatus.error);
    expect(cubit.state.errorMessage, 'indisponível');
  });

  test('load() manual recarrega de novo', () async {
    repository.myOrdersResult = const Success([]);
    final cubit = MyOrdersCubit(repository);
    addTearDown(cubit.close);
    await Future<void>.delayed(Duration.zero);

    final order = buildOrder(id: 'order-2');
    repository.myOrdersResult = Success([order]);
    await cubit.load();

    expect(cubit.state.status, LoadStatus.success);
    expect(cubit.state.orders, [order]);
  });
}
