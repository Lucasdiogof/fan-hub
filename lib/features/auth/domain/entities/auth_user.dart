import 'package:equatable/equatable.dart';

class AuthUser extends Equatable {
  const AuthUser({
    required this.id,
    required this.email,
    this.fullName,
    this.avatarUrl,
  });

  final String id;
  final String email;
  final String? fullName;
  final String? avatarUrl;

  @override
  List<Object?> get props => [id, email, fullName, avatarUrl];
}
