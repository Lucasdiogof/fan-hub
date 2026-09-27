import 'dart:io';

Future<void> main() async {
  final outDir = Directory('assets/partners');
  await outDir.create(recursive: true);

  final items = <(String, Uri)>[
    (
      'puma',
      Uri.parse(
        'https://img.redbullbragantino.com/images/2026/2/4/dfcsflqaf3nupklqk7za/puma',
      ),
    ),
    (
      'asaas',
      Uri.parse(
        'https://img.redbullbragantino.com/images/2026/4/9/sttqoyvrxewigmndoxxy/asaas',
      ),
    ),
    (
      'nd',
      Uri.parse(
        'https://img.redbullbragantino.com/images/2026/2/4/flm5lta2ql7lniqjsxd5/nd',
      ),
    ),
    (
      'curaprox',
      Uri.parse(
        'https://img.redbullbragantino.com/images/2026/2/4/cvawo7k4nqnd6wrajurj/curaprox',
      ),
    ),
    (
      'knn-idiomas',
      Uri.parse(
        'https://img.redbullbragantino.com/images/2026/8/25/qcxkkbhx3bz2dkfyygaf/knn-idiomas',
      ),
    ),
    (
      'peluso-sperandio',
      Uri.parse(
        'https://img.redbullbragantino.com/images/2026/2/4/b3blwskeo5ad98lxhiab/peluso-sperandio',
      ),
    ),
    (
      'convem',
      Uri.parse(
        'https://img.redbullbragantino.com/images/2026/7/22/bnmf27esnngescqkmlvd/convem-supermercados',
      ),
    ),
    (
      'unimed',
      Uri.parse(
        'https://img.redbullbragantino.com/images/2026/3/30/lgzporikoavbq9pbe4vg/unimed',
      ),
    ),
    (
      'unimagem',
      Uri.parse(
        'https://img.redbullbragantino.com/images/2026/3/30/ygvizkcuntvlsk59p6t9/unimagem',
      ),
    ),
    (
      'humanitarian',
      Uri.parse(
        'https://img.redbullbragantino.com/images/2026/3/30/spfw4zi4aqppc7cdqdy0/humanitarian',
      ),
    ),
    (
      'lo-sardo',
      Uri.parse(
        'https://img.redbullbragantino.com/images/2026/3/30/lrbcketb3okuz4rn2pli/lo-sardo',
      ),
    ),
    (
      'colegio-populus',
      Uri.parse(
        'https://img.redbullbragantino.com/images/2026/2/4/adcn0uoz3xz3dd3kl3pn/colegio-populus',
      ),
    ),
    (
      'ecobier',
      Uri.parse(
        'https://img.redbullbragantino.com/images/2026/3/19/ibpr9rgycnvofmrzgdta/ecobier-logo',
      ),
    ),
    (
      'cpjoia',
      Uri.parse(
        'https://img.redbullbragantino.com/images/2026/2/4/rssbn35q1kpdfm97t3gb/cpjoia',
      ),
    ),
    (
      'campus-live',
      Uri.parse(
        'https://img.redbullbragantino.com/images/2026/2/4/amwid1dfbyxbqwsj1qix/campus-live',
      ),
    ),
    (
      'meu-ingles-sob-medida',
      Uri.parse(
        'https://img.redbullbragantino.com/images/2026/2/4/uhguugeltbzukv5vkc8z/meu-ingles-sob-medida',
      ),
    ),
    (
      'trendx',
      Uri.parse(
        'https://img.redbullbragantino.com/images/2026/7/22/rhtmhvkd2hjtuzdvhzat/logo-trendx',
      ),
    ),
  ];

  final client = HttpClient();
  client.userAgent = 'Mozilla/5.0';

  var ok = 0;
  try {
    for (final item in items) {
      final (slug, uri) = item;
      stdout.write('Baixando $slug... ');

      try {
        final request = await client.getUrl(uri);
        request.headers.set(
          HttpHeaders.acceptHeader,
          'image/png,image/*;q=0.9,*/*;q=0.8',
        );
        final response = await request.close();

        if (response.statusCode < 200 || response.statusCode >= 300) {
          stderr.writeln('HTTP ${response.statusCode}');
          await response.drain();
          continue;
        }

        final bytes = await response.fold<List<int>>(
          <int>[],
          (buffer, chunk) => buffer..addAll(chunk),
        );

        final file = File('${outDir.path}/$slug.png');
        await file.writeAsBytes(bytes, flush: true);

        final contentType =
            response.headers.contentType?.mimeType ?? 'desconhecido';
        stdout.writeln('OK (${bytes.length} bytes, $contentType)');
        ok++;
      } catch (e) {
        stderr.writeln('ERRO: $e');
      }
    }
  } finally {
    client.close(force: true);
  }

  stdout.writeln('\nConcluído: $ok/${items.length} logos em ${outDir.path}');
  if (ok != items.length) exitCode = 1;
}
