import 'package:flutter/material.dart';
import 'package:goias_app/core/club/club_config.dart';
import 'package:goias_app/features/match/domain/entities/team.dart';
import 'package:goias_app/shared/widgets/team_visuals/team_visual_identity.dart';

/// Escudo estilizado/simplificado: formato de escudo, preenchida na cor do
/// time, sigla central — sem depender de nenhum escudo oficial (rede ou
/// asset). Substitui visualmente `_ShieldBadge` (que continua existindo em
/// `club_badge.dart`, intocado, como fallback de último caso quando a nova
/// aparência estiver desligada — ver `useStyledTeamBadges`).
class StyledTeamBadge extends StatelessWidget {
  const StyledTeamBadge({
    required this.acronym,
    required this.primaryColor,
    this.secondaryColor,
    this.size = 44,
    this.onDark = false,
    this.round = false,
    super.key,
  });

  /// Resolve a identidade visual (clube ativo ou tabela curada de times
  /// conhecidos, com fallback determinístico) e monta o badge — ponto único
  /// que `ClubBadge` chama quando a nova aparência está ligada.
  factory StyledTeamBadge.forTeam({
    required Team team,
    required ClubConfig clubConfig,
    double size = 44,
    bool onDark = false,
    bool round = false,
    Key? key,
  }) {
    final identity = resolveTeamVisualIdentity(team: team, clubConfig: clubConfig);
    return StyledTeamBadge(
      key: key,
      acronym: identity.acronym,
      primaryColor: identity.primaryColor,
      secondaryColor: identity.secondaryColor,
      size: size,
      onDark: onDark,
      round: round,
    );
  }

  /// Escudo estilizado do clube ATIVO, sem nenhum [Team] envolvido —
  /// espelha `ClubBadge.activeClub()`.
  factory StyledTeamBadge.forActiveClub({
    required ClubConfig clubConfig,
    double size = 44,
    bool onDark = false,
    bool round = false,
    Key? key,
  }) {
    final identity = resolveActiveClubVisualIdentity(clubConfig);
    return StyledTeamBadge(
      key: key,
      acronym: identity.acronym,
      primaryColor: identity.primaryColor,
      secondaryColor: identity.secondaryColor,
      size: size,
      onDark: onDark,
      round: round,
    );
  }

  final String acronym;
  final Color primaryColor;
  final Color? secondaryColor;
  final double size;

  /// Mesmo parâmetro que `ClubBadge` já expõe — aqui só ajusta o contraste
  /// do contorno (branco sobre fundo escuro, escuro sobre fundo claro), já
  /// que o preenchimento em si é sempre opaco e funciona nos dois casos.
  final bool onDark;

  /// `true` só pro slot circular da bottom nav — encaixa igual o PNG
  /// oficial encaixava naquele "puck" redondo (ver `goias_bottom_
  /// navigation_bar.dart`). Shield anguloso dentro de um container
  /// circular sobrava borda estranha nos cantos; círculo cheio resolve.
  /// Em todo resto do app o formato continua sendo o shield (`false`,
  /// default) — não é uma mudança geral de formato.
  final bool round;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _StyledShieldPainter(
          primaryColor: primaryColor,
          secondaryColor: secondaryColor,
          borderColor: onDark
              ? Colors.white.withValues(alpha: 0.35)
              : Colors.black.withValues(alpha: 0.12),
          round: round,
        ),
        child: Padding(
          padding: EdgeInsets.only(top: size * 0.06),
          child: Center(
            child: Text(
              acronym,
              maxLines: 1,
              overflow: TextOverflow.clip,
              style: TextStyle(
                color: _legibleTextColor(primaryColor),
                fontWeight: FontWeight.w800,
                fontSize: size * 0.30,
                letterSpacing: -0.2,
                height: 1,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Cores de time claras (amarelo, branco) precisam de sigla escura pra
/// continuar legível em tamanho pequeno — luminância decide, não uma lista
/// fixa de exceções.
Color _legibleTextColor(Color background) {
  return background.computeLuminance() > 0.55
      ? const Color(0xFF14181B)
      : Colors.white;
}

class _StyledShieldPainter extends CustomPainter {
  _StyledShieldPainter({
    required this.primaryColor,
    required this.secondaryColor,
    required this.borderColor,
    required this.round,
  });

  final Color primaryColor;
  final Color? secondaryColor;
  final Color borderColor;
  final bool round;

  @override
  void paint(Canvas canvas, Size size) {
    final path = round
        ? (Path()..addOval(Offset.zero & size))
        : _teamBadgeShieldPath(size);

    canvas.save();
    canvas.clipPath(path);
    canvas.drawRect(Offset.zero & size, Paint()..color = primaryColor);
    final secondary = secondaryColor;
    if (secondary != null) {
      // Faixa inferior com a segunda cor — dá um toque de identidade de
      // duas cores (Palmeiras, Flamengo, Botafogo...) sem sair do visual
      // flat/chapado pedido.
      canvas.drawRect(
        Rect.fromLTWH(0, size.height * 0.72, size.width, size.height * 0.28),
        Paint()..color = secondary,
      );
    }
    canvas.restore();

    canvas.drawPath(
      path,
      Paint()
        ..color = borderColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = size.width * 0.045,
    );
  }

  @override
  bool shouldRepaint(covariant _StyledShieldPainter oldDelegate) =>
      oldDelegate.primaryColor != primaryColor ||
      oldDelegate.secondaryColor != secondaryColor ||
      oldDelegate.borderColor != borderColor ||
      oldDelegate.round != round;
}

Path _teamBadgeShieldPath(Size size) {
  final w = size.width;
  final h = size.height;
  return Path()
    ..moveTo(w * 0.5, 0)
    ..cubicTo(w * 0.5, 0, w * 0.98, h * 0.08, w * 0.98, h * 0.08)
    ..lineTo(w * 0.98, h * 0.52)
    ..cubicTo(w * 0.98, h * 0.78, w * 0.72, h * 0.94, w * 0.5, h)
    ..cubicTo(w * 0.28, h * 0.94, w * 0.02, h * 0.78, w * 0.02, h * 0.52)
    ..lineTo(w * 0.02, h * 0.08)
    ..cubicTo(w * 0.02, h * 0.08, w * 0.5, 0, w * 0.5, 0)
    ..close();
}
