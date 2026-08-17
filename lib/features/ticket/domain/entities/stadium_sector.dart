import 'package:equatable/equatable.dart';

class StadiumSector extends Equatable {
  const StadiumSector({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.availability,
  });

  final String id;
  final String name;
  final String description;
  final double price;

  /// 0.0 (esgotado) a 1.0 (totalmente disponível).
  final double availability;

  bool get isSoldOut => availability <= 0;

  @override
  List<Object?> get props => [id, name, description, price, availability];
}
