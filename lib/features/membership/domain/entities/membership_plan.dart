import 'package:equatable/equatable.dart';

class MembershipPlanPrice extends Equatable {
  const MembershipPlanPrice({
    required this.label,
    required this.monthlyPrice,
    required this.annualPrice,
  });

  final String label;
  final double monthlyPrice;
  final double annualPrice;

  @override
  List<Object?> get props => [label, monthlyPrice, annualPrice];
}

class MembershipPlan extends Equatable {
  const MembershipPlan({
    required this.id,
    required this.name,
    required this.tagline,
    required this.includesStadiumAccess,
    required this.benefits,
    required this.prices,
    this.stadiumSector,
    this.highlight = false,
  });

  final String id;
  final String name;
  final String tagline;
  final bool includesStadiumAccess;
  final String? stadiumSector;
  final List<String> benefits;
  final List<MembershipPlanPrice> prices;
  final bool highlight;

  MembershipPlanPrice get defaultPrice => prices.first;

  @override
  List<Object?> get props => [
    id,
    name,
    tagline,
    includesStadiumAccess,
    stadiumSector,
    benefits,
    prices,
    highlight,
  ];
}
