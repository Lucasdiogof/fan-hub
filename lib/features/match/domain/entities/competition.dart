import 'package:equatable/equatable.dart';

class Competition extends Equatable {
  const Competition({required this.name, required this.season});

  final String name;
  final int season;

  @override
  List<Object?> get props => [name, season];
}
