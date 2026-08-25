import 'package:goias_app/features/news/domain/entities/news_content_block.dart';

NewsContentBlock parseNewsContentBlock(Map<String, dynamic> json) {
  final type = json['type'] as String;
  return switch (type) {
    'link' => NewsLinkBlock(
      text: json['text'] as String,
      url: json['url'] as String,
    ),
    _ => NewsParagraphBlock(json['text'] as String),
  };
}
