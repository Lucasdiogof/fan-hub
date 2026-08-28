import 'package:equatable/equatable.dart';

class ClubBoardMember extends Equatable {
  const ClubBoardMember({
    required this.id,
    required this.name,
    required this.role,
    this.photoUrl,
  });

  final String id;
  final String name;
  final String role;
  final String? photoUrl;

  factory ClubBoardMember.fromJson(Map<String, dynamic> json) =>
      ClubBoardMember(
        id: json['id'] as String,
        name: json['name'] as String,
        role: json['role'] as String,
        photoUrl: json['photo_url'] as String?,
      );

  @override
  List<Object?> get props => [id, name, role, photoUrl];
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
