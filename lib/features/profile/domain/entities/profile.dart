import 'package:equatable/equatable.dart';

class Profile extends Equatable {
  const Profile({
    required this.id,
    required this.email,
    this.fullName,
    this.cpf,
    this.birthDate,
    this.phone,
    this.avatarUrl,
  });

  final String id;
  final String email;
  final String? fullName;
  final String? cpf;
  final DateTime? birthDate;
  final String? phone;
  final String? avatarUrl;

  String get displayName {
    final name = fullName?.trim() ?? '';
    return name.isNotEmpty ? name : email;
  }

  @override
  List<Object?> get props => [id, email, fullName, cpf, birthDate, phone, avatarUrl];
}
