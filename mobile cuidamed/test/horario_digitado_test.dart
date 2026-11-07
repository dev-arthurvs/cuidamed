import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:cuidamed_mobile/paginas/formulario_medicamento.dart';

import 'apoio.dart';

void main() {
  // No navegador (e no desktop) os botões são compactos e, com a fonte "Pequena",
  // o relógio do Flutter ficava menor que o mínimo dele ao trocar para digitar a hora.
  for (final tamanho in ['pequena', 'media', 'grande']) {
    testWidgets('Digitar o horário na mão (17:10) funciona com a fonte $tamanho', (tester) async {
      await montarPagina(tester, estadoPaciente()..tamanhoFonte = tamanho, '/agenda/novo', (_) => const FormularioMedicamento());

      await tester.ensureVisible(find.text('+ Adicionar horário'));
      await tester.tap(find.text('+ Adicionar horário'));
      await tester.pumpAndSettle();
      await tester.tap(find.byIcon(Icons.keyboard_outlined));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);

      // Horário da tarde digitado no formato de 24 horas, como no Brasil.
      final campos = find.descendant(of: find.byType(Dialog), matching: find.byType(TextField));
      await tester.enterText(campos.at(0), '17');
      await tester.enterText(campos.at(1), '10');
      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle();
      expect(find.text('Insira um horário válido'), findsNothing);
      expect(find.text('17:10'), findsOneWidget);
    }, variant: TargetPlatformVariant.only(TargetPlatform.windows));
  }
}
