import 'package:equatable/equatable.dart';
import 'package:goias_app/features/membership/domain/entities/faq_block.dart';

class FaqItem extends Equatable {
  const FaqItem({required this.id, required this.question, required this.answer});

  final String id;
  final String question;
  final List<FaqBlock> answer;

  @override
  List<Object?> get props => [id, question, answer];
}
