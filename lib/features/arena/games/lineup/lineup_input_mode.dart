/// Qual método de entrada a tela de adivinhação usa pra digitar o palpite —
/// só isso. O jogo em si (`LineupCubit`) nunca soube e continua sem saber
/// qual dos dois está ativo; ele só recebe `addLetter`/`removeLetter`, de
/// onde quer que venham.
enum LineupGuessInputMode {
  /// Teclado próprio do app (`LineupKeyboard`) — o comportamento de sempre,
  /// nunca alterado por este experimento.
  customKeyboard,

  /// Experimental: abre o teclado nativo do aparelho, mantendo a grade
  /// visual atual — ver `NativeLineupInput`.
  nativeKeyboard,
}

/// PONTO ÚNICO de troca. Pra voltar pro teclado custom, troque só esta
/// linha pra `LineupGuessInputMode.customKeyboard` — nenhum outro arquivo
/// precisa mudar.
const lineupGuessInputMode = LineupGuessInputMode.customKeyboard;
