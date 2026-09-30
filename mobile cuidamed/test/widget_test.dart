import 'package:flutter_test/flutter_test.dart';

import 'package:cuidamed_mobile/app.dart';

void main() {
  testWidgets('App inicia na tela de login', (WidgetTester tester) async {
    await tester.pumpWidget(const CuidaMedApp());
    await tester.pump();

    expect(find.text('Entrar'), findsWidgets);
  });
}
