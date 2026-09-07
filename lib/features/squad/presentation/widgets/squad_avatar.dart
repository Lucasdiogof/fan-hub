import 'package:flutter/material.dart';
import 'package:goias_app/core/club/club_config.dart';
import 'package:goias_app/core/di/injection_container.dart';
import 'package:goias_app/core/theme/app_colors.dart';

/// Foto do atleta com fallback pro número da camisa — nunca quebra a lista
/// se a imagem falhar ou não existir. Prioriza a foto embutida no app
/// (offline, por [memberId]) DO CLUBE ATIVO; se não houver, tenta
/// [photoUrl] do banco. O mapa de fotos é por clube justamente pra um
/// atleta homônimo de outro clube nunca herdar o rosto errado.
class SquadAvatar extends StatelessWidget {
  const SquadAvatar({
    required this.memberId,
    required this.photoUrl,
    required this.shirtNumber,
    required this.size,
    super.key,
  });

  final String? memberId;
  final String? photoUrl;
  final int? shirtNumber;
  final double size;

  @override
  Widget build(BuildContext context) {
    final fallback = _NumberCircle(number: shirtNumber, size: size);
    final asset = sl<ClubConfig>().assets.squadPhotos[memberId];

    if (asset != null) {
      return ClipOval(
        child: Image.asset(
          asset,
          width: size,
          height: size,
          fit: BoxFit.cover,
          alignment: Alignment.topCenter,
          errorBuilder: (context, _, _) => fallback,
        ),
      );
    }

    final url = photoUrl;
    if (url == null || url.isEmpty) return fallback;

    return ClipOval(
      child: Image.network(
        url,
        width: size,
        height: size,
        fit: BoxFit.cover,
        alignment: Alignment.topCenter,
        errorBuilder: (context, _, _) => fallback,
        loadingBuilder: (context, child, progress) =>
            progress == null ? child : fallback,
      ),
    );
  }
}

class _NumberCircle extends StatelessWidget {
  const _NumberCircle({required this.number, required this.size});

  final int? number;
  final double size;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: colors.primary,
        border: Border.all(
          color: colors.onPrimary.withValues(alpha: 0.85),
          width: 1.5,
        ),
      ),
      child: Text(
        number?.toString() ?? '–',
        style: TextStyle(
          color: colors.onPrimary,
          fontSize: size * 0.4,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}
