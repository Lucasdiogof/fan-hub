import 'package:flutter_test/flutter_test.dart';
import 'package:goias_app/main.dart';

void main() {
  testWidgets('App renders without crashing', (tester) async {
    await tester.pumpWidget(const GoiasApp());
    await tester.pumpAndSettle();
    expect(find.text('Início'), findsWidgets);
  });
}
