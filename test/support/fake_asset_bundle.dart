import 'package:flutter/services.dart';

/// 1x1 PNG transparente, em bytes — conteúdo real e decodificável, só sem
/// nenhum pixel visível.
const _transparentPixelPng = <int>[
  0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A, //
  0x00, 0x00, 0x00, 0x0D, 0x49, 0x48, 0x44, 0x52, //
  0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x01, //
  0x08, 0x04, 0x00, 0x00, 0x00, 0xB5, 0x1C, 0x0C, //
  0x02, 0x00, 0x00, 0x00, 0x0B, 0x49, 0x44, 0x41, //
  0x54, 0x78, 0x9C, 0x63, 0x64, 0xFC, 0xFF, 0x9F, //
  0x81, 0x1E, 0x00, 0x07, 0x14, 0x01, 0x27, 0x63, //
  0x1E, 0x66, 0x00, 0x00, 0x00, 0x00, 0x49, 0x45, //
  0x4E, 0x44, 0xAE, 0x42, 0x60, 0x82, //
];

/// Devolve o mesmo PNG transparente pra QUALQUER chave — usado só pra
/// widget test decodificar `Image.asset`/`AssetImage` sem precisar que o
/// path exista de verdade (`flutter test` só resolve assets declarados em
/// `pubspec.yaml`, e paths fixture como `test/assets/club_b/...` nunca
/// deveriam entrar lá — poluiria o bundle real do app com arte de teste).
/// Nunca usar em teste que precise validar o CONTEÚDO da imagem, só a
/// referência (path pedido).
class FakeAssetBundle extends CachingAssetBundle {
  @override
  Future<ByteData> load(String key) async {
    // `Image.asset`/`AssetImage` modernos consultam isto ANTES de resolver
    // a imagem em si, pra escolher a variante certa (resolução/idioma) —
    // sem responder com um manifest vazio válido, a decodificação do
    // manifesto falha antes mesmo de chegar no path pedido.
    if (key == 'AssetManifest.bin') {
      return const StandardMessageCodec().encodeMessage(
        <String, dynamic>{},
      )!;
    }
    return ByteData.sublistView(Uint8List.fromList(_transparentPixelPng));
  }
}
