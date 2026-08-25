class NewsItem {
  const NewsItem({
    required this.id,
    required this.title,
    required this.category,
    required this.publishedAt,
    required this.imageUrl,
    required this.url,
  });

  final String id;
  final String title;
  final String category;

  /// Null quando o site não expôs uma data reconhecível — a UI mostra a
  /// categoria no lugar em vez de inventar uma data.
  final DateTime? publishedAt;
  final String imageUrl;
  final String url;
}
