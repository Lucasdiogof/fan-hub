// Gera lib/features/membership/data/regulation_content.dart a partir de
// lib/assets/legal/membership_regulation.md — mesmo texto oficial, mas como
// const Dart em vez de markdown lido em runtime (via asset ou Supabase).
//
// Motivo: a tela do Regulamento dependia de uma linha em
// membership_regulation_versions no Supabase (com fallback pro asset local
// só em caso de erro/vazio) e ficou com a tela vazia porque essa linha
// tinha conteúdo incompleto — o `on conflict do nothing` do insert original
// impedia até uma correção de fazer efeito. O usuário pediu que a tela
// funcionasse igual Termos de Uso/Política de Privacidade, que são só
// `const` Dart sem rede nem parsing em runtime — então o Regulamento passa
// a ser isso também: nenhuma dependência de banco pra um texto que quase
// nunca muda.
//
// Rodar de novo só se o .md mudar:
//   dart run tooling/regulation/generate_regulation_dart.dart
//   dart format lib/features/membership/data/regulation_content.dart
import 'dart:io';

final _headerPattern = RegExp(r'^##\s+(\d+)\.\s+(.*)$');

String _escape(String input) {
  final buffer = StringBuffer();
  for (final rune in input.runes) {
    final ch = String.fromCharCode(rune);
    switch (ch) {
      case '\\':
        buffer.write(r'\\');
      case r'$':
        buffer.write(r'\$');
      case "'":
        buffer.write(r"\'");
      case '\n':
        buffer.write(r'\n');
      default:
        buffer.write(ch);
    }
  }
  return buffer.toString();
}

void main() {
  final source = File(
    'lib/assets/legal/membership_regulation.md',
  ).readAsStringSync();
  final lines = source.split('\n');

  final introBuffer = StringBuffer();
  final sections = <(int, String, StringBuffer)>[];
  int? currentIndex;
  var currentTitle = '';
  var body = StringBuffer();

  void flush() {
    if (currentIndex == null) return;
    sections.add((currentIndex, currentTitle, body));
    body = StringBuffer();
  }

  for (final line in lines) {
    final match = _headerPattern.firstMatch(line);
    if (match != null) {
      flush();
      currentIndex = int.parse(match.group(1)!);
      currentTitle = match.group(2)!.trim();
    } else if (currentIndex == null) {
      introBuffer.writeln(line);
    } else {
      body.writeln(line);
    }
  }
  flush();

  if (sections.length != 17) {
    stderr.writeln(
      'Esperava 17 seções (## N. Título), achei ${sections.length}. Abortando — '
      'confira lib/assets/legal/membership_regulation.md antes de regenerar.',
    );
    exit(1);
  }

  for (final (index, title, sectionBody) in sections) {
    if (sectionBody.toString().trim().isEmpty) {
      stderr.writeln('Seção $index ("$title") ficou vazia — abortando.');
      exit(1);
    }
  }

  final out = StringBuffer()
    ..writeln(
      '// GERADO por tooling/regulation/generate_regulation_dart.dart a partir de',
    )
    ..writeln(
      '// lib/assets/legal/membership_regulation.md — não editar à mão.',
    )
    ..writeln()
    ..writeln(
      "import 'package:goias_app/features/membership/domain/entities/regulation_section.dart';",
    )
    ..writeln()
    ..writeln('const membershipRegulationIntro =')
    ..writeln("    '${_escape(introBuffer.toString().trim())}';")
    ..writeln()
    ..writeln('const membershipRegulationSections = <RegulationSection>[');
  for (final (index, title, sectionBody) in sections) {
    out
      ..writeln('  RegulationSection(')
      ..writeln('    index: $index,')
      ..writeln("    title: '${_escape(title)}',")
      ..writeln("    body: '${_escape(sectionBody.toString().trim())}',")
      ..writeln('  ),');
  }
  out.writeln('];');

  File(
    'lib/features/membership/data/regulation_content.dart',
  ).writeAsStringSync(out.toString());
  stdout.writeln('OK — ${sections.length} seções geradas.');
}
