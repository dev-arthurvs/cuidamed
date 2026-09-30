import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:cuidamed_mobile/paginas/painel_paciente.dart';

import 'apoio.dart';

void main() {
  const rota = '/cuidador/paciente/1/painel';

  testWidgets('Mostra permissão atual e aviso só quando o paciente não tem login', (tester) async {
    await montarPagina(tester, estadoCuidador(), rota, (_) => const PainelPaciente(pacienteId: 1));
    expect(find.text('Maria da Silva'), findsOneWidget);
    expect(tester.widget<Switch>(find.byType(Switch)).value, isTrue);
    expect(find.textContaining('Maria pode adicionar'), findsOneWidget);
    expect(find.textContaining('Atenção', findRichText: true), findsNothing);
  });

  testWidgets('Desvincular pede confirmação e cancelar não faz nada', (tester) async {
    final estado = estadoCuidador();
    await montarPagina(tester, estado, rota, (_) => const PainelPaciente(pacienteId: 1));
    await rolarAte(tester, find.text('Desvincular paciente').last);
    await tester.tap(find.widgetWithText(OutlinedButton, 'Desvincular paciente'));
    await tester.pumpAndSettle();
    expect(find.text('Desvincular paciente?'), findsOneWidget);
    await tester.tap(find.text('Cancelar'));
    await tester.pumpAndSettle();
    expect(estado.pacientes, hasLength(1));
  });

  testWidgets('Paciente inexistente mostra mensagem', (tester) async {
    await montarPagina(tester, estadoCuidador(), '/cuidador/paciente/99/painel', (_) => const PainelPaciente(pacienteId: 99));
    expect(find.text('Paciente não encontrado'), findsOneWidget);
  });

  testWidgets('Fonte grande em 360px não estoura', (tester) async {
    await montarPagina(tester, estadoCuidador()..tamanhoFonte = 'grande', rota, (_) => const PainelPaciente(pacienteId: 1));
    await rolarAte(tester, find.widgetWithText(OutlinedButton, 'Desvincular paciente'));
    expect(tester.takeException(), isNull);
  });
}
