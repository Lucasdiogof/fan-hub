import 'package:equatable/equatable.dart';

class HomeShellState extends Equatable {
  // Ordem das abas: Jogos, Sócio, Home, Loja, Mídia — Home ocupa a posição
  // central (índice 2) da bottom nav, não a primeira.
  const HomeShellState({this.index = 2});

  final int index;

  HomeShellState copyWith({int? index}) {
    return HomeShellState(index: index ?? this.index);
  }

  @override
  List<Object?> get props => [index];
}
