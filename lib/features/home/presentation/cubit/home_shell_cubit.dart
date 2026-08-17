import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:goias_app/features/home/presentation/cubit/home_shell_state.dart';

class HomeShellCubit extends Cubit<HomeShellState> {
  HomeShellCubit() : super(const HomeShellState());

  void navigateToTab(int index) => emit(state.copyWith(index: index));
}
