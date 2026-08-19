import 'package:equatable/equatable.dart';
import 'package:goias_app/features/membership/domain/entities/faq_item.dart';

class FaqCategory extends Equatable {
  const FaqCategory({required this.id, required this.title, required this.items});

  final String id;
  final String title;
  final List<FaqItem> items;

  @override
  List<Object?> get props => [id, title, items];
}
