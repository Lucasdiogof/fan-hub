import 'package:goias_app/features/arena/games/tactical_identity/domain/tactical_identity_models.dart';

/// A ESTRUTURA das 10 perguntas da "Identidade Futebolística": ids, deltas
/// dos dois eixos e contribuições pras 4 dimensões ocultas. Nunca reordenar
/// nem alterar `deltaX`/`deltaY` sem decisão explícita — ver
/// `tactical_coach_references.dart` sobre a mesma regra pro dataset de
/// técnicos.
///
/// O TEXTO não mora aqui (2026-09-08). Antes ficava, em português cravado, e
/// quatro enunciados citavam "Goiás" literalmente — o que mostraria o nome do
/// clube errado pra qualquer outro clube. Agora os textos vivem nos ARBs
/// (`tacticalQ01`...) em PT/EN/ES, e são resolvidos por id no presentation
/// (`tactical_identity_copy.dart`), onde existe `AppLocalizations` e o
/// `ClubConfig` ativo. É a mesma separação que o resto do app já segue: as
/// camadas de domínio e dados nunca conhecem `BuildContext`.
///
/// Consequência prática: o estado e o repositório continuam usando esta
/// lista const como sempre (contagem, índice, resolução de `answerId` →
/// opção) sem precisar de idioma nenhum, porque nada ali depende de texto.
///
/// Desde a recalibração v2 (2026-09-01), cada alternativa também carrega
/// pequenas contribuições pras 4 dimensões táticas OCULTAS (pressing,
/// blockHeight, risk, structuralFluidity — nunca mostradas ao usuário,
/// nunca no mapa 2D) — derivadas do SIGNIFICADO real de cada texto, nunca
/// alteradas só pra "encaixar matemática" (quando uma alternativa
/// genuinamente não tem relação com uma dimensão oculta, o valor fica 0).
const tacticalIdentityQuestions = <TacticalQuestion>[
  TacticalQuestion(
    id: 'q01',
    options: [
      TacticalOption(
        id: 'q01_a',
        deltaX: -2,
        deltaY: -2,
        risk: -1,
        structuralFluidity: -1,
      ),
      TacticalOption(
        id: 'q01_b',
        deltaX: -1,
        deltaY: 2,
        risk: 1,
        structuralFluidity: 2,
      ),
      TacticalOption(
        id: 'q01_c',
        deltaX: 2,
        deltaY: -1,
        pressing: 1,
        risk: 1,
        structuralFluidity: -1,
      ),
      TacticalOption(
        id: 'q01_d',
        deltaX: 1,
        deltaY: 2,
        structuralFluidity: 2,
      ),
    ],
  ),
  TacticalQuestion(
    id: 'q02',
    options: [
      TacticalOption(
        id: 'q02_a',
        deltaX: -2,
        deltaY: -1,
        pressing: -1,
        risk: -1,
        structuralFluidity: -1,
      ),
      TacticalOption(
        id: 'q02_b',
        deltaX: -1,
        deltaY: 2,
        structuralFluidity: 2,
      ),
      TacticalOption(
        id: 'q02_c',
        deltaX: 2,
        deltaY: -1,
        pressing: 1,
        blockHeight: 1,
        risk: 2,
        structuralFluidity: -1,
      ),
      TacticalOption(
        id: 'q02_d',
        deltaX: 1,
        deltaY: 2,
        structuralFluidity: 2,
      ),
    ],
  ),
  TacticalQuestion(
    id: 'q03',
    options: [
      TacticalOption(
        id: 'q03_a',
        deltaX: 0,
        deltaY: -2,
        structuralFluidity: -2,
      ),
      TacticalOption(
        id: 'q03_b',
        deltaX: -2,
        deltaY: 1,
        pressing: -1,
        risk: -1,
        structuralFluidity: 1,
      ),
      TacticalOption(
        id: 'q03_c',
        deltaX: 2,
        deltaY: 2,
        pressing: -1,
        blockHeight: -2,
        risk: -1,
        structuralFluidity: 1,
      ),
      TacticalOption(
        id: 'q03_d',
        deltaX: 1,
        deltaY: -1,
        pressing: 2,
        blockHeight: 1,
        risk: 1,
        structuralFluidity: -1,
      ),
    ],
  ),
  TacticalQuestion(
    id: 'q04',
    options: [
      TacticalOption(
        id: 'q04_a',
        deltaX: -2,
        deltaY: -2,
        blockHeight: 1,
        risk: -1,
        structuralFluidity: -1,
      ),
      TacticalOption(
        id: 'q04_b',
        deltaX: -1,
        deltaY: 2,
        blockHeight: 1,
        structuralFluidity: 2,
      ),
      TacticalOption(
        id: 'q04_c',
        deltaX: 2,
        deltaY: -1,
        blockHeight: 1,
        risk: 2,
        structuralFluidity: -1,
      ),
      TacticalOption(
        id: 'q04_d',
        deltaX: 1,
        deltaY: 2,
        risk: 1,
        structuralFluidity: 2,
      ),
    ],
  ),
  TacticalQuestion(
    id: 'q05',
    options: [
      TacticalOption(
        id: 'q05_a',
        deltaX: -2,
        deltaY: -2,
        risk: 1,
        structuralFluidity: -2,
      ),
      TacticalOption(
        id: 'q05_b',
        deltaX: -1,
        deltaY: 2,
        structuralFluidity: 2,
      ),
      TacticalOption(
        id: 'q05_c',
        deltaX: 2,
        deltaY: 2,
        pressing: -1,
        blockHeight: -2,
        risk: -1,
        structuralFluidity: 1,
      ),
      TacticalOption(
        id: 'q05_d',
        deltaX: 2,
        deltaY: -1,
        pressing: 2,
        blockHeight: 2,
        risk: 2,
        structuralFluidity: -1,
      ),
    ],
  ),
  TacticalQuestion(
    id: 'q06',
    options: [
      TacticalOption(
        id: 'q06_a',
        deltaX: 0,
        deltaY: -2,
        pressing: 1,
        risk: -1,
        structuralFluidity: -2,
      ),
      TacticalOption(
        id: 'q06_b',
        deltaX: -1,
        deltaY: 2,
        structuralFluidity: 2,
      ),
      TacticalOption(
        id: 'q06_c',
        deltaX: 1,
        deltaY: 1,
        structuralFluidity: 1,
      ),
      TacticalOption(
        id: 'q06_d',
        deltaX: 1,
        deltaY: -1,
        pressing: -1,
        risk: 1,
        structuralFluidity: 1,
      ),
    ],
  ),
  TacticalQuestion(
    id: 'q07',
    options: [
      TacticalOption(
        id: 'q07_a',
        deltaX: -1,
        deltaY: -2,
        structuralFluidity: -2,
      ),
      TacticalOption(
        id: 'q07_b',
        deltaX: -1,
        deltaY: 1,
        structuralFluidity: 1,
      ),
      TacticalOption(
        id: 'q07_c',
        deltaX: 2,
        deltaY: 1,
        blockHeight: 1,
        risk: 1,
      ),
      TacticalOption(
        id: 'q07_d',
        deltaX: -2,
        deltaY: 1,
        structuralFluidity: 1,
      ),
    ],
  ),
  TacticalQuestion(
    id: 'q08',
    options: [
      TacticalOption(
        id: 'q08_a',
        deltaX: -1,
        deltaY: -2,
        pressing: 2,
        blockHeight: 2,
        risk: 1,
        structuralFluidity: -1,
      ),
      TacticalOption(
        id: 'q08_b',
        deltaX: 0,
        deltaY: 2,
        pressing: 1,
        structuralFluidity: 2,
      ),
      TacticalOption(
        id: 'q08_c',
        deltaX: 1,
        deltaY: 1,
        pressing: -1,
        blockHeight: -1,
        risk: -1,
      ),
      TacticalOption(
        id: 'q08_d',
        deltaX: 2,
        deltaY: -1,
        pressing: 1,
      ),
    ],
  ),
  TacticalQuestion(
    id: 'q09',
    options: [
      TacticalOption(
        id: 'q09_a',
        deltaX: -2,
        deltaY: -2,
        risk: -1,
        structuralFluidity: -2,
      ),
      TacticalOption(
        id: 'q09_b',
        deltaX: -1,
        deltaY: 2,
        risk: 1,
        structuralFluidity: 1,
      ),
      TacticalOption(
        id: 'q09_c',
        deltaX: 2,
        deltaY: -1,
        pressing: 1,
        blockHeight: 2,
        risk: 2,
        structuralFluidity: -1,
      ),
      TacticalOption(
        id: 'q09_d',
        deltaX: 1,
        deltaY: 2,
        risk: 1,
        structuralFluidity: 2,
      ),
    ],
  ),
  TacticalQuestion(
    id: 'q10',
    options: [
      TacticalOption(
        id: 'q10_a',
        deltaX: -1,
        deltaY: -2,
        structuralFluidity: -2,
      ),
      TacticalOption(
        id: 'q10_b',
        deltaX: -1,
        deltaY: 2,
        structuralFluidity: 2,
      ),
      TacticalOption(
        id: 'q10_c',
        deltaX: 2,
        deltaY: -1,
        blockHeight: 1,
        risk: 1,
        structuralFluidity: -1,
      ),
      TacticalOption(
        id: 'q10_d',
        deltaX: 1,
        deltaY: 2,
        risk: 1,
        structuralFluidity: 2,
      ),
    ],
  ),
];
