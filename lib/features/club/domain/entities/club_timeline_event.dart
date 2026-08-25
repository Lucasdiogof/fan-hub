/// [sourceName]/[sourceUrl] ficam prontos pra quando cada marco puder
/// ser auditado contra a fonte original (site do clube) — hoje nem todo
/// evento tem uma URL específica, só a fonte geral já citada em [ClubHistorySection].
class ClubTimelineEvent {
  const ClubTimelineEvent({
    required this.year,
    required this.title,
    this.description,
    this.sourceName,
    this.sourceUrl,
  });

  final int year;
  final String title;
  final String? description;
  final String? sourceName;
  final String? sourceUrl;
}
