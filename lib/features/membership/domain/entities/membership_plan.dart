import 'package:equatable/equatable.dart';

class MembershipPlan extends Equatable {
  const MembershipPlan({
    required this.id,
    required this.name,
    required this.monthlyPrice,
    required this.benefits,
    this.highlight = false,
  });

  final String id;
  final String name;
  final double monthlyPrice;
  final List<String> benefits;
  final bool highlight;

  @override
  List<Object?> get props => [id, name, monthlyPrice, benefits, highlight];
}
