import 'package:equatable/equatable.dart';

class ClubBoardMember extends Equatable {
  const ClubBoardMember({
    required this.id,
    required this.name,
    required this.role,
    this.displayName,
    this.photoUrl,
  });

  final String id;

  /// Nome completo/legal — sempre a fonte de verdade, mesmo quando
  /// [displayName] existe pra exibição.
  final String name;
  final String role;

  /// Nome curto/popular pra exibição (ex.: "Marquinho Chedid") — `null`
  /// quando o nome completo já é o que deve aparecer. Nunca substitui
  /// [name] na fonte de dados, só na tela (ver [displayLabel]).
  final String? displayName;
  final String? photoUrl;

  String get displayLabel => displayName ?? name;

  factory ClubBoardMember.fromJson(Map<String, dynamic> json) =>
      ClubBoardMember(
        id: json['id'] as String,
        name: json['name'] as String,
        role: json['role'] as String,
        displayName: json['display_name'] as String?,
        photoUrl: json['photo_url'] as String?,
      );

  @override
  List<Object?> get props => [id, name, role, displayName, photoUrl];
}

class ClubBoardSection extends Equatable {
  const ClubBoardSection({
    required this.id,
    required this.title,
    required this.members,
  });

  final String id;
  final String title;
  final List<ClubBoardMember> members;

  @override
  List<Object?> get props => [id, title, members];
}
