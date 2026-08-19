import 'package:equatable/equatable.dart';

class RegulationSection extends Equatable {
  const RegulationSection({required this.index, required this.title, required this.body});

  final int index;
  final String title;
  final String body;

  @override
  List<Object?> get props => [index, title, body];
}
