import 'package:equatable/equatable.dart';
import 'package:goias_app/features/membership/domain/entities/membership.dart';

class AppUser extends Equatable {
  const AppUser({
    required this.name,
    required this.email,
    required this.cpf,
    required this.phone,
    this.membership,
  });

  final String name;
  final String email;
  final String cpf;
  final String phone;
  final Membership? membership;

  bool get isMember => membership != null && membership!.status == MembershipStatus.active;

  @override
  List<Object?> get props => [name, email, cpf, phone, membership];
}
