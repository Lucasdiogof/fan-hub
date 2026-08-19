import 'package:goias_app/features/membership/domain/entities/regulation_section.dart';

final _headerPattern = RegExp(r'^##\s+(\d+)\.\s+(.*)$');

/// Parser mínimo — o conteúdo já vem estruturado como `## N. Título` por
/// seção, então não há necessidade de um pacote de Markdown completo.
List<RegulationSection> parseRegulationSections(String markdown) {
  final sections = <RegulationSection>[];
  var currentTitle = '';
  var currentIndex = 0;
  final buffer = StringBuffer();

  void flush() {
    if (currentTitle.isEmpty) return;
    sections.add(RegulationSection(index: currentIndex, title: currentTitle, body: buffer.toString().trim()));
    buffer.clear();
  }

  for (final line in markdown.split('\n')) {
    final match = _headerPattern.firstMatch(line);
    if (match != null) {
      flush();
      currentIndex = int.parse(match.group(1)!);
      currentTitle = match.group(2)!.trim();
    } else {
      buffer.writeln(line);
    }
  }
  flush();
  return sections;
}
