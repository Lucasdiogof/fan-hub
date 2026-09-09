import 'package:flutter/material.dart';

/// Experimental (ver `lineup_input_mode.dart`): captura o palpite pelo
/// teclado NATIVO do aparelho em vez do `LineupKeyboard` próprio do app —
/// mas nunca mostra um `TextField` tradicional. A grade continua sendo a
/// única interface visível; isto aqui é só a superfície de captura,
/// invisível (`Opacity(opacity: 0)`), que abre o teclado do sistema ao
/// ganhar foco.
///
/// Não guarda o palpite — só a LARGURA dele (`currentLength`), suficiente
/// pra saber quantas letras já foram digitadas (pra reconciliar depois de
/// cada `onLetter`/`onDelete`/reset) sem duplicar o estado de verdade, que
/// mora só no `LineupCubit`. Cada caractere digitado vira exatamente uma
/// chamada de [onLetter]; cada exclusão vira uma chamada de [onDelete] —
/// as duas a mesma interface que `LineupKeyboard` já usa, então o
/// `LineupCubit` nunca precisa saber qual dos dois está ativo.
class NativeLineupInput extends StatefulWidget {
  const NativeLineupInput({
    required this.maxLength,
    required this.currentLength,
    required this.onLetter,
    required this.onDelete,
    required this.onEnter,
    required this.canSubmit,
    super.key,
  });

  final int maxLength;
  final int currentLength;
  final ValueChanged<String> onLetter;
  final VoidCallback onDelete;
  final VoidCallback onEnter;
  final bool canSubmit;

  @override
  State<NativeLineupInput> createState() => NativeLineupInputState();
}

class NativeLineupInputState extends State<NativeLineupInput> {
  final _focusNode = FocusNode();

  /// Espelha só o COMPRIMENTO do palpite atual — nunca as letras (essas só
  /// existem no `LineupCubit`). Preenchido com um caractere neutro só pra
  /// o `TextField` ter algo do tamanho certo; o conteúdo em si nunca é lido
  /// de volta, só o `length` a cada mudança.
  late final _controller = TextEditingController(
    text: _shadowFor(widget.currentLength),
  );

  static String _shadowFor(int length) => '#' * length;

  /// Abre o teclado nativo — chamado de fora (ver `LineupGuessPage`, que
  /// encapsula a grade num `GestureDetector` pra "tocar na tentativa atual
  /// abre o teclado" funcionar mesmo se o usuário já tiver fechado o
  /// teclado antes).
  void requestFocus() => _focusNode.requestFocus();

  @override
  void didUpdateWidget(covariant NativeLineupInput oldWidget) {
    super.didUpdateWidget(oldWidget);
    // O jogo mudou o comprimento por conta própria (reset após envio,
    // seleção de outro jogador) — reconcilia o buffer interno sem disparar
    // onLetter/onDelete de novo (já foi refletido no cubit por quem causou
    // a mudança).
    if (widget.currentLength != _controller.text.length) {
      final shadow = _shadowFor(widget.currentLength);
      _controller.value = TextEditingValue(
        text: shadow,
        selection: TextSelection.collapsed(offset: shadow.length),
      );
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _onChanged(String value) {
    // Só letras A-Z contam — o mesmo filtro que `_handlePhysicalKey` já usa
    // pro teclado físico de desktop, então acento/espaço/número digitados
    // sem querer (ou colados) nunca chegam no `LineupCubit`.
    final onlyLetters = value.toUpperCase().replaceAll(RegExp(r'[^A-Z]'), '');
    // `_controller.text` já foi atualizado pelo próprio `TextField` pro
    // valor NOVO antes de `onChanged` disparar — não serve pra saber o
    // comprimento anterior. `widget.currentLength` é o comprimento real do
    // palpite antes desta digitação (vem do `LineupCubit`), então é essa a
    // base certa pro diff.
    final previousLength = widget.currentLength;

    if (onlyLetters.length > previousLength) {
      final added = onlyLetters.substring(previousLength);
      final allowed = widget.maxLength - previousLength;
      final toAdd = added.length > allowed
          ? added.substring(0, allowed)
          : added;
      for (final letter in toAdd.split('')) {
        widget.onLetter(letter);
      }
    } else if (onlyLetters.length < previousLength) {
      for (var i = 0; i < previousLength - onlyLetters.length; i++) {
        widget.onDelete();
      }
    }
    // O widget pai reconstrói com o novo `currentLength` e `didUpdateWidget`
    // acima realinha `_controller` com a extensão real do palpite — nunca
    // guarda a letra em si aqui.
  }

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: 0,
      child: SizedBox(
        height: 44,
        child: TextField(
          controller: _controller,
          focusNode: _focusNode,
          autofocus: true,
          // Sem `maxLength` aqui de propósito: o formatter automático do
          // Flutter cortaria o texto BRUTO nesse tamanho (antes do filtro
          // de letras em `_onChanged`), então um acento/espaço/dígito
          // digitado junto já cortaria a última letra válida. O limite de
          // verdade é imposto abaixo, contando só letras A-Z.
          textCapitalization: TextCapitalization.characters,
          // `visiblePassword` é o jeito mais confiável de suprimir preditivo/
          // autocomplete no Android sem esconder o texto (ver limitações no
          // relatório final sobre o QuickType do iOS).
          keyboardType: TextInputType.visiblePassword,
          autocorrect: false,
          enableSuggestions: false,
          smartDashesType: SmartDashesType.disabled,
          smartQuotesType: SmartQuotesType.disabled,
          decoration: const InputDecoration(
            counterText: '',
            border: InputBorder.none,
          ),
          onChanged: _onChanged,
          onSubmitted: (_) {
            if (widget.canSubmit) widget.onEnter();
          },
        ),
      ),
    );
  }
}
