import 'package:equatable/equatable.dart';

class HomeShellState extends Equatable {
  const HomeShellState({this.index = 0});

  final int index;

  HomeShellState copyWith({int? index}) {
    return HomeShellState(index: index ?? this.index);
  }

  @override
  List<Object?> get props => [index];
}
