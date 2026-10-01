import 'package:flutter/material.dart';
import 'package:goias_app/core/theme/app_colors.dart';

/// Foto real quando existe asset; caso contrário, iniciais sobre a cor
/// secundária do clube — mesma linguagem do avatar da Diretoria. NUNCA uma
/// imagem genérica fingindo ser o jogador. Usado na lista de Ídolos e no
/// detalhe, só muda o [size].
class ClubIdolAvatar extends StatelessWidget {
  const ClubIdolAvatar({
    required this.name,
    this.photoAsset,
    this.size = 52,
    super.key,
  });

  final String name;
  final String? photoAsset;
  final double size;

  String get _initials {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts.first.isEmpty) return '';
    final first = parts.first.characters.first;
    final last = parts.length > 1 && parts.last.isNotEmpty
        ? parts.last.characters.first
        : '';
    return (first + last).toUpperCase();
  }

  static bool _isNetworkUrl(String value) =>
      value.startsWith('http://') || value.startsWith('https://');

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final asset = photoAsset;
    final initials = _InitialsText(initials: _initials, size: size);
    Widget image;
    if (asset == null || asset.isEmpty) {
      image = initials;
    } else if (_isNetworkUrl(asset)) {
      // Foto do elenco atual (CDN oficial do clube) — mesmo padrão de
      // `SquadAvatar`/`GuessBlurredPhoto`: [photoAsset] pode ser um asset
      // local (histórico) ou uma URL remota (jogador ainda no elenco).
      image = Image.network(
        asset,
        width: size,
        height: size,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => initials,
      );
    } else {
      image = Image.asset(
        asset,
        width: size,
        height: size,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => initials,
      );
    }
    return ClipOval(
      child: Container(
        width: size,
        height: size,
        alignment: Alignment.center,
        color: colors.secondary,
        child: image,
      ),
    );
  }
}

class _InitialsText extends StatelessWidget {
  const _InitialsText({required this.initials, required this.size});

  final String initials;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Text(
      initials,
      style: TextStyle(
        // 16 no avatar de 52 da lista — proporcional no detalhe.
        fontSize: size * 16 / 52,
        fontWeight: FontWeight.w900,
        color: context.colors.primary,
      ),
    );
  }
}
