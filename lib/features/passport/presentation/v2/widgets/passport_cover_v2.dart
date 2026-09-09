import 'package:flutter/material.dart';
import 'package:goias_app/core/club/club_config.dart';
import 'package:goias_app/core/di/injection_container.dart';
import 'package:goias_app/core/l10n/l10n_extensions.dart';
import 'package:goias_app/core/theme/app_spacing.dart';
import 'package:goias_app/features/passport/domain/entities/passport_summary.dart';
import 'package:goias_app/features/passport/domain/passport_level.dart';
import 'package:goias_app/features/passport/presentation/passport_copy_extension.dart';
import 'package:goias_app/features/passport/presentation/v2/widgets/passport_level_style.dart';

/// Capa do passaporte — inspirada num cartão de identidade do torcedor, não
/// num dashboard. `deepGreen` é fixo (não muda entre light/dark, ver
/// `AppColors`), então o INTERIOR do card fica idêntico nos dois temas de
/// propósito — é a mesma identidade visual sóbria já usada em hero/banner
/// no resto do app. Só a sombra externa reage ao tema (mais forte no dark,
/// bem discreta no light), pra o card manter contraste com o fundo da
/// página nos dois casos sem deixar de ser "verde nos dois temas". De
/// propósito bem enxuta (só eyebrow + selo de nível + headline) — "Desde
/// {ano}" e o progresso da temporada saíram daqui por pedido explícito,
/// pra não repetir o que a tela já mostra logo abaixo.
///
/// A moldura (borda simples/dupla), a linha de acento, a textura, a marca
/// d'água e o selo vêm todos de [passportLevelStyleFor] — única fonte da
/// progressão visual por nível, pra este widget nunca precisar de `if`s de
/// nível no meio do layout. O TAMANHO/LAYOUT do card é sempre o mesmo em
/// todo nível — só a decoração muda, de propósito (evita o card
/// crescer/pular ao subir de nível).
class PassportCoverV2 extends StatelessWidget {
  const PassportCoverV2({
    required this.summary,
    this.holderName,
    this.onTap,
    super.key,
  });

  final PassportSummary summary;

  /// Nome completo do torcedor — substitui o rótulo genérico "MEU
  /// PASSAPORTE" (mesmo espírito de um documento de identidade real, com o
  /// nome do titular estampado). `null`/vazio (perfil ainda não carregou
  /// ou sem nome cadastrado) cai de volta pro rótulo genérico, nunca mostra
  /// e-mail nem fica em branco.
  final String? holderName;

  /// Abre a trajetória (vitórias/empates/derrotas, casa/fora, gols) — `null`
  /// deixa o card só decorativo, pro caso de ser reaproveitado em algum
  /// lugar sem essa navegação.
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final trimmedName = holderName?.trim();
    final eyebrowText = (trimmedName != null && trimmedName.isNotEmpty)
        ? trimmedName.toUpperCase()
        : l10n.passportCoverEyebrow;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final level = passportLevelForMatches(summary.totalMatches);
    final levelStyle = passportLevelStyleFor(level);

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppRadius.hero),
        border: Border.all(
          color: levelStyle.borderColor,
          width: passportCoverBorderWidth,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.38 : 0.1),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppRadius.hero),
        child: Material(
          color: sl<ClubConfig>().branding.light.brandDeep,
          child: InkWell(
            onTap: onTap,
            child: Stack(
              children: [
                if (levelStyle.textureOpacity > 0)
                  Positioned.fill(
                    child: CustomPaint(
                      painter: _BleacherTexturePainter(
                        opacity: levelStyle.textureOpacity,
                      ),
                    ),
                  ),
                // Textura de fundo — pequena, quase toda cortada pelo canto,
                // opacidade muito baixa: sugere identidade/segurança de
                // documento oficial sem virar "o círculo grande no fundo".
                // Refina (sobe um pouco de opacidade) por nível, nunca muda
                // de posição/tamanho.
                Positioned(
                  right: -46,
                  bottom: -46,
                  child: Opacity(
                    opacity: levelStyle.watermarkOpacity,
                    child: ColorFiltered(
                      colorFilter: const ColorFilter.mode(
                        Colors.white,
                        BlendMode.srcIn,
                      ),
                      child: Image.asset(
                        sl<ClubConfig>().assets.crestBadge,
                        width: 150,
                        height: 150,
                      ),
                    ),
                  ),
                ),
                // Moldura dupla — a partir do nível 3, uma segunda linha bem
                // sutil por dentro da borda externa. Puramente decorativo,
                // não afeta o padding do conteúdo.
                if (levelStyle.innerBorderColor != null)
                  Positioned.fill(
                    child: Padding(
                      padding: const EdgeInsets.all(4),
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(
                            AppRadius.hero - 4,
                          ),
                          border: Border.all(
                            color: levelStyle.innerBorderColor!,
                            width: 1,
                          ),
                        ),
                      ),
                    ),
                  ),
                // Acento dourado — só a partir do nível 4, uma linha fina no
                // topo (nunca a moldura inteira, pra continuar sendo acento
                // e não virar cor de fundo).
                if (levelStyle.accentLineColor != null)
                  Positioned(
                    top: 0,
                    left: AppSpacing.xl,
                    right: AppSpacing.xl,
                    child: Container(
                      height: 2,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            levelStyle.accentLineColor!.withValues(alpha: 0),
                            levelStyle.accentLineColor!,
                            levelStyle.accentLineColor!.withValues(alpha: 0),
                          ],
                        ),
                      ),
                    ),
                  ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.lg,
                    AppSpacing.lg,
                    AppSpacing.lg,
                    AppSpacing.lg,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.confirmation_number_outlined,
                            size: 14,
                            color: Colors.white.withValues(alpha: 0.72),
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              eyebrowText,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 1.1,
                                color: Colors.white.withValues(alpha: 0.72),
                              ),
                            ),
                          ),
                          _LevelBadge(
                            label: passportLevelLabel(context.passportCopy, level),
                            style: levelStyle,
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.md),
                      Text(
                        context.passportCopy.matchesLived(summary.totalMatches),
                        style: const TextStyle(
                          fontSize: 23,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                          height: 1.18,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _LevelBadge extends StatelessWidget {
  const _LevelBadge({required this.label, required this.style});

  final String label;
  final PassportLevelStyle style;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: style.badgeBackground,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: style.badgeBorderColor),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (style.badgeIcon != null) ...[
            Icon(style.badgeIcon, size: 11, color: style.badgeForeground),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 9.5,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.2,
              color: style.badgeForeground,
            ),
          ),
        ],
      ),
    );
  }
}

/// Listras diagonais bem finas e espaçadas — textura discreta inspirada em
/// arquibancada/campo, nunca um padrão chamativo. Só entra em cena a
/// partir do nível 3 (`textureOpacity > 0`); desenhada por cima do
/// `ColoredBox` de fundo, por baixo do conteúdo.
class _BleacherTexturePainter extends CustomPainter {
  const _BleacherTexturePainter({required this.opacity});

  final double opacity;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: opacity)
      ..strokeWidth = 1;
    const gap = 15.0;
    for (var x = -size.height; x < size.width; x += gap) {
      canvas.drawLine(
        Offset(x, size.height),
        Offset(x + size.height, 0),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _BleacherTexturePainter oldDelegate) =>
      oldDelegate.opacity != opacity;
}
