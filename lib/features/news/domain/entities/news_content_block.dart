sealed class NewsContentBlock {
  const NewsContentBlock();
}

class NewsParagraphBlock extends NewsContentBlock {
  const NewsParagraphBlock(this.text);

  final String text;
}

class NewsLinkBlock extends NewsContentBlock {
  const NewsLinkBlock({required this.text, required this.url});

  final String text;
  final String url;
}
