import 'package:flutter_test/flutter_test.dart';
import 'package:goias_app/features/home/presentation/cubit/home_shell_cubit.dart';

void main() {
  test('estado inicial começa na aba Home (índice 2, posição central)', () {
    final cubit = HomeShellCubit();
    addTearDown(cubit.close);
    expect(cubit.state.index, 2);
  });

  test('navigateToTab troca o índice da aba ativa', () {
    final cubit = HomeShellCubit();
    addTearDown(cubit.close);

    cubit.navigateToTab(0);
    expect(cubit.state.index, 0);

    cubit.navigateToTab(4);
    expect(cubit.state.index, 4);
  });
}
