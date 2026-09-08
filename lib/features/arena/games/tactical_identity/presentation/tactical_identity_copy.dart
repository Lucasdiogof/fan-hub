import 'package:flutter/widgets.dart';
import 'package:goias_app/core/club/club_config.dart';
import 'package:goias_app/core/di/injection_container.dart';
import 'package:goias_app/core/l10n/l10n_extensions.dart';
import 'package:goias_app/features/arena/games/tactical_identity/domain/tactical_identity_models.dart';
import 'package:goias_app/l10n/app_localizations.dart';

/// Texto das perguntas da "Identidade Futebolística", resolvido por id.
///
/// Vive no presentation porque depende de duas coisas que domínio e dados não
/// conhecem — e não devem conhecer: o idioma (`AppLocalizations`) e o clube
/// ativo (`ClubConfig`). A estrutura das perguntas (deltas, dimensões
/// ocultas) continua const em `tactical_identity_questions.dart`.
///
/// Quatro enunciados citam o clube. Antes o nome estava cravado como "Goiás"
/// no meio da frase, o que faria o torcedor do Bragantino ler o nome do
/// rival dentro do próprio jogo. Agora o nome entra por
/// `ClubConfig.identity.shortName`, e a frase foi escrita em cada idioma pra
/// aceitar qualquer clube: em português e espanhol com artigo masculino ("o
/// Goiás", "o Bragantino" / "el Goiás", "el Bragantino"), em inglês sem
/// artigo. Nada de concatenar nome solto no fim da frase.
extension TacticalIdentityCopy on BuildContext {
  String tacticalQuestionText(TacticalQuestion question) {
    final l10n = this.l10n;
    final club = sl<ClubConfig>().identity.shortName;
    return switch (question.id) {
      'q01' => l10n.tacticalQ01(club),
      'q02' => l10n.tacticalQ02,
      'q03' => l10n.tacticalQ03(club),
      'q04' => l10n.tacticalQ04,
      'q05' => l10n.tacticalQ05,
      'q06' => l10n.tacticalQ06,
      'q07' => l10n.tacticalQ07(club),
      'q08' => l10n.tacticalQ08,
      'q09' => l10n.tacticalQ09(club),
      'q10' => l10n.tacticalQ10,
      // Um id fora do banco só existe se alguém editar
      // `tacticalIdentityQuestions` sem criar a chave l10n correspondente —
      // erro de programação, não estado de runtime.
      _ => throw StateError('Pergunta tática sem texto: ${question.id}'),
    };
  }

  String tacticalOptionText(TacticalOption option) =>
      _optionText(l10n, option.id);

  /// Descrição da intro — também citava o clube ("...técnicos que passaram
  /// pelo Goiás..."), mesmo bug/correção das 4 perguntas acima, achado numa
  /// QA posterior (2026-09-08).
  String get tacticalIntroDescription =>
      l10n.tacticalIntroDescription(sl<ClubConfig>().identity.shortName);

  /// Título "principal referência" — tinha "ESMERALDINA"/"GOIÁS" cravado.
  /// Mesmo achado da QA de 2026-09-08.
  String get tacticalResultMainReference => l10n
      .tacticalResultMainReference(sl<ClubConfig>().identity.shortName)
      .toUpperCase();
}

String _optionText(AppLocalizations l10n, String id) => switch (id) {
  'q01_a' => l10n.tacticalQ01A,
  'q01_b' => l10n.tacticalQ01B,
  'q01_c' => l10n.tacticalQ01C,
  'q01_d' => l10n.tacticalQ01D,
  'q02_a' => l10n.tacticalQ02A,
  'q02_b' => l10n.tacticalQ02B,
  'q02_c' => l10n.tacticalQ02C,
  'q02_d' => l10n.tacticalQ02D,
  'q03_a' => l10n.tacticalQ03A,
  'q03_b' => l10n.tacticalQ03B,
  'q03_c' => l10n.tacticalQ03C,
  'q03_d' => l10n.tacticalQ03D,
  'q04_a' => l10n.tacticalQ04A,
  'q04_b' => l10n.tacticalQ04B,
  'q04_c' => l10n.tacticalQ04C,
  'q04_d' => l10n.tacticalQ04D,
  'q05_a' => l10n.tacticalQ05A,
  'q05_b' => l10n.tacticalQ05B,
  'q05_c' => l10n.tacticalQ05C,
  'q05_d' => l10n.tacticalQ05D,
  'q06_a' => l10n.tacticalQ06A,
  'q06_b' => l10n.tacticalQ06B,
  'q06_c' => l10n.tacticalQ06C,
  'q06_d' => l10n.tacticalQ06D,
  'q07_a' => l10n.tacticalQ07A,
  'q07_b' => l10n.tacticalQ07B,
  'q07_c' => l10n.tacticalQ07C,
  'q07_d' => l10n.tacticalQ07D,
  'q08_a' => l10n.tacticalQ08A,
  'q08_b' => l10n.tacticalQ08B,
  'q08_c' => l10n.tacticalQ08C,
  'q08_d' => l10n.tacticalQ08D,
  'q09_a' => l10n.tacticalQ09A,
  'q09_b' => l10n.tacticalQ09B,
  'q09_c' => l10n.tacticalQ09C,
  'q09_d' => l10n.tacticalQ09D,
  'q10_a' => l10n.tacticalQ10A,
  'q10_b' => l10n.tacticalQ10B,
  'q10_c' => l10n.tacticalQ10C,
  'q10_d' => l10n.tacticalQ10D,
  _ => throw StateError('Alternativa tática sem texto: $id'),
};
