class LegalSection {
  const LegalSection({required this.title, required this.body});

  final String title;
  final String body;
}

class LegalDocument {
  const LegalDocument({
    required this.title,
    required this.lastUpdated,
    required this.intro,
    required this.sections,
  });

  final String title;
  final String lastUpdated;
  final String intro;
  final List<LegalSection> sections;
}
