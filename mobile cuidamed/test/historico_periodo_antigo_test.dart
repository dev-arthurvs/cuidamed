import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:cuidamed_mobile/modelos/historico.dart';
import 'package:cuidamed_mobile/paginas/historico.dart';
import 'package:cuidamed_mobile/utilitarios/horarios.dart';

import 'apoio.dart';

String _dd(int n) => n.toString().padLeft(2, '0');

Future<void> _escolherDe(WidgetTester tester, DateTime data) async {
  await tester.tap(find.text('De'));
  await tester.pumpAndSettle();
  await tester.tap(find.byIcon(Icons.edit_outlined));
  await tester.pumpAndSettle();
  await tester.enterText(find.byType(TextField).last, '${_dd(data.day)}/${_dd(data.month)}/${data.year}');
  await tester.tap(find.text('OK'));
  await tester.pumpAndSettle();
}

void main() {
  final hoje = DateTime.now();
  final antiga = DateTime(hoje.year, hoje.month, hoje.day - 60);

  testWidgets('Período antigo: busca no servidor e não calcula nada até chegar', (tester) async {
    final estado = estadoPaciente();
    final dados = estado.pacientes.first;
    dados.medicamentos.clear();
    dados.historico.clear();
    final resposta = Completer<List<Historico>>();
    final chamadas = <(int, DateTime, DateTime)>[];

    await montarPagina(tester, estado, '/historico', (_) => HistoricoPagina(
          carregarAntigos: (id, de, ate) {
            chamadas.add((id, de, ate));
            return resposta.future;
          },
        ));
    expect(chamadas, isEmpty); // período padrão (hoje) não busca nada

    await _escolherDe(tester, antiga);
    expect(chamadas.length, 1);
    expect(chamadas.single.$2, antiga);
    expect(chamadas.single.$3, inicioJanelaHistorico().subtract(const Duration(days: 1)));
    expect(find.text('Carregando...'), findsOneWidget);

    resposta.complete([
      Historico(
        id: 900, pacienteId: 1, medicamentoId: 11, data: antiga, hora: '06:00',
        nomeMedicamento: 'Remédio antigo', dosagem: '10mg', status: 'TOMADO',
      ),
    ]);
    await tester.pumpAndSettle();
    expect(find.text('Carregando...'), findsNothing);
    expect(find.text('06:00'), findsOneWidget);
    expect(chamadas.length, 1); // redesenhar a tela não busca de novo
  });

  testWidgets('Falha ao buscar o período antigo: avisa e não inventa doses perdidas', (tester) async {
    final estado = estadoPaciente();
    await montarPagina(tester, estado, '/historico', (_) => HistoricoPagina(
          carregarAntigos: (_, _, _) async => throw Exception('sem internet'),
        ));

    await _escolherDe(tester, antiga);
    expect(find.text('Não foi possível carregar esse período.'), findsOneWidget);
    expect(find.text('08:00'), findsNothing);
  });

  testWidgets('Período dentro dos últimos dias não vai ao servidor', (tester) async {
    final estado = estadoPaciente();
    var chamadas = 0;
    await montarPagina(tester, estado, '/historico', (_) => HistoricoPagina(
          carregarAntigos: (_, _, _) async {
            chamadas++;
            return const [];
          },
        ));

    await _escolherDe(tester, DateTime(hoje.year, hoje.month, hoje.day - 10));
    expect(chamadas, 0);
  });
}
