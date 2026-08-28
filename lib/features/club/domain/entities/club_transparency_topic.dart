import 'package:equatable/equatable.dart';

class ClubTransparencyDocument extends Equatable {
  const ClubTransparencyDocument({
    required this.id,
    required this.title,
    required this.date,
    required this.pdfUrl,
  });

  final String id;
  final String title;
  final DateTime date;
  final String pdfUrl;

  factory ClubTransparencyDocument.fromJson(Map<String, dynamic> json) =>
      ClubTransparencyDocument(
        id: json['id'] as String,
        title: json['title'] as String,
        date: DateTime.parse(json['document_date'] as String),
        pdfUrl: json['pdf_url'] as String,
      );

  @override
  List<Object?> get props => [id, title, date, pdfUrl];
}

class ClubTransparencyTopic extends Equatable {
  const ClubTransparencyTopic({
    required this.id,
    required this.title,
    required this.documents,
  });

  final String id;
  final String title;
  final List<ClubTransparencyDocument> documents;

  @override
  List<Object?> get props => [id, title, documents];
}
