import 'package:goias_app/core/theme/app_colors.dart';

/// Paleta do clube — hoje só EMBRULHA `AppColors.light`/`AppColors.dark`
/// (os mesmos `static const` de sempre, valor por valor idêntico), nunca
/// os substitui. `AppTheme`/`MaterialApp` continuam consumindo
/// `AppColors.light`/`.dark` diretamente — nenhum consumidor real lê
/// `ClubConfig.branding` ainda, isso é fundação pra quando um 2º clube
/// justificar a indireção (ver `docs/multiclub/10_club_config.md#2`).
///
/// Os 3 tokens de matiz literal (`darkGreen`/`deepGreen`/`ctaGreen`) NÃO
/// foram renomeados nesta rodada — a M1 audita e prepara a raiz, não
/// migra nomenclatura de cor (isso é trabalho de uma etapa própria,
/// documentado como candidato em `multiclub_hardcode_audit.json`).
class ClubBranding {
  const ClubBranding({required this.light, required this.dark});

  final AppColors light;
  final AppColors dark;
}
