import 'package:equatable/equatable.dart';

class Competition extends Equatable {
  const Competition({required this.id, required this.name, required this.season});

  final int id;
  final String name;
  final int season;

  @override
  List<Object?> get props => [id, name, season];
}
