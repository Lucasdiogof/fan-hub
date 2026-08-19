import 'package:equatable/equatable.dart';

class FaqSpan extends Equatable {
  const FaqSpan({required this.text, this.bold = false, this.link});

  final String text;
  final bool bold;
  final String? link;

  @override
  List<Object?> get props => [text, bold, link];
}

sealed class FaqBlock extends Equatable {
  const FaqBlock();
}

class FaqParagraphBlock extends FaqBlock {
  const FaqParagraphBlock(this.spans);

  final List<FaqSpan> spans;

  @override
  List<Object?> get props => [spans];
}

class FaqListBlock extends FaqBlock {
  const FaqListBlock(this.items);

  final List<List<FaqSpan>> items;

  @override
  List<Object?> get props => [items];
}
