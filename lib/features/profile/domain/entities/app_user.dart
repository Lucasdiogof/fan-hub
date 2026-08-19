import 'package:equatable/equatable.dart';

class AppUser extends Equatable {
  const AppUser({required this.name, required this.email, required this.cpf, required this.phone});

  final String name;
  final String email;
  final String cpf;
  final String phone;

  @override
  List<Object?> get props => [name, email, cpf, phone];
}
