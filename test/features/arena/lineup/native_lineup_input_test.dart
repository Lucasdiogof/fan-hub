import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:goias_app/features/arena/games/lineup/widgets/native_lineup_input.dart';

/// Testa `NativeLineupInput` isolado, sem `LineupCubit`/`BlocProvider` — o
/// widget nunca guarda o palpite, só reporta letras/exclusões via callback,
/// então um harness simples com contadores já é suficiente.
class _Harness extends StatefulWidget {
  const _Harness({this.maxLength = 5});

  final int maxLength;

  @override
  State<_Harness> createState() => _HarnessState();
}

class _HarnessState extends State<_Harness> {
  final letters = <String>[];
  int deleteCalls = 0;
  int enterCalls = 0;

  int get currentLength => letters.length;
  bool get canSubmit => letters.length == widget.maxLength;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: NativeLineupInput(
          maxLength: widget.maxLength,
          currentLength: currentLength,
          canSubmit: canSubmit,
          onLetter: (letter) => setState(() => letters.add(letter)),
          onDelete: () => setState(() {
            deleteCalls++;
            if (letters.isNotEmpty) letters.removeLast();
          }),
          onEnter: () => enterCalls++,
        ),
      ),
    );
  }
}

void main() {
  Finder textField() => find.byType(TextField);

  testWidgets('typing a letter forwards it uppercased via onLetter', (
    tester,
  ) async {
    await tester.pumpWidget(const _Harness());
    await tester.enterText(textField(), 'f');
    await tester.pump();

    final state = tester.state<_HarnessState>(find.byType(_Harness));
    expect(state.letters, ['F']);
  });

  testWidgets('deleting a character calls onDelete', (tester) async {
    await tester.pumpWidget(const _Harness());
    await tester.enterText(textField(), 'FE');
    await tester.pump();
    await tester.enterText(textField(), 'F');
    await tester.pump();

    final state = tester.state<_HarnessState>(find.byType(_Harness));
    expect(state.deleteCalls, 1);
    expect(state.letters, ['F']);
  });

  testWidgets('never reports more letters than maxLength', (tester) async {
    await tester.pumpWidget(const _Harness(maxLength: 3));
    await tester.enterText(textField(), 'ABCDEF');
    await tester.pump();

    final state = tester.state<_HarnessState>(find.byType(_Harness));
    expect(state.letters, ['A', 'B', 'C']);
  });

  testWidgets('normalizes lowercase and strips anything that is not A-Z', (
    tester,
  ) async {
    await tester.pumpWidget(const _Harness());
    await tester.enterText(textField(), 'a1 é!b');
    await tester.pump();

    final state = tester.state<_HarnessState>(find.byType(_Harness));
    expect(state.letters, ['A', 'B']);
  });

  testWidgets(
    'reconciles its internal buffer when currentLength changes externally '
    '(e.g. after a submitted guess resets it)',
    (tester) async {
      await tester.pumpWidget(const _Harness(maxLength: 3));
      await tester.enterText(textField(), 'ABC');
      await tester.pump();

      // Simula o cubit resetando o palpite depois de um envio — o teste
      // reconstrói o harness com `currentLength: 0` sem passar por
      // onLetter/onDelete, exatamente como acontece de verdade.
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: NativeLineupInput(
              maxLength: 3,
              currentLength: 0,
              canSubmit: false,
              onLetter: (_) {},
              onDelete: () {},
              onEnter: () {},
            ),
          ),
        ),
      );
      await tester.pump();

      final field = tester.widget<TextField>(textField());
      expect(field.controller!.text, isEmpty);

      // Digitar de novo depois do reset funciona normalmente.
      await tester.enterText(textField(), 'X');
      await tester.pump();
      expect(field.controller!.text.length, 1);
    },
  );

  testWidgets('onSubmitted only calls onEnter when canSubmit is true', (
    tester,
  ) async {
    await tester.pumpWidget(const _Harness(maxLength: 3));
    await tester.enterText(textField(), 'AB');
    await tester.pump();
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pump();
    expect(tester.state<_HarnessState>(find.byType(_Harness)).enterCalls, 0);

    await tester.enterText(textField(), 'ABC');
    await tester.pump();
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pump();
    expect(tester.state<_HarnessState>(find.byType(_Harness)).enterCalls, 1);
  });

  testWidgets('requestFocus() opens the keyboard on the hidden field', (
    tester,
  ) async {
    final key = GlobalKey<NativeLineupInputState>();
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: NativeLineupInput(
            key: key,
            maxLength: 5,
            currentLength: 0,
            canSubmit: false,
            onLetter: (_) {},
            onDelete: () {},
            onEnter: () {},
          ),
        ),
      ),
    );

    key.currentState!.requestFocus();
    await tester.pump();

    final field = tester.widget<TextField>(textField());
    expect(field.focusNode!.hasFocus, isTrue);
  });
}
