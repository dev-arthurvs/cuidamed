import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:cuidamed_mobile/componentes/botao.dart';
import 'package:cuidamed_mobile/componentes/cartao_observacoes.dart';
import 'package:cuidamed_mobile/estado/app_estado.dart';
import 'package:cuidamed_mobile/modelos/paciente.dart';
import 'package:cuidamed_mobile/paginas/detalhe_paciente.dart';

import 'apoio.dart';

Paciente _paciente(String? obs) => Paciente(id: 1, nome: 'Maria da Silva', email: 'maria@email.com', observacoesClinicas: obs);

Botao _botaoSalvar(WidgetTester tester) => tester.widget<Botao>(find.widgetWithText(Botao, 'Salvar observações'));

void main() {
  testWidgets('Aparece nos detalhes do paciente, com o texto salvo no campo', (tester) async {
    final estado = estadoCuidador();
    final dados = estado.pacientes.first;
    estado.pacientes = [
      PacienteComDados(paciente: _paciente('Alergia a dipirona.'), medicamentos: dados.medicamentos, historico: dados.historico),
    ];
    await montarPagina(tester, estado, '/cuidador/paciente/1', (_) => const DetalhePaciente(pacienteId: 1));
    await rolarAte(tester, find.text('Observações clínicas'));
    expect(find.widgetWithText(TextField, 'Alergia a dipirona.'), findsOneWidget);
  });

  testWidgets('Salvar só ativa com alteração; Descartar volta ao texto salvo', (tester) async {
    await montarPagina(tester, estadoCuidador(), '/x',
        (_) => Scaffold(body: SingleChildScrollView(child: CartaoObservacoes(paciente: _paciente('Toma em jejum.')))));
    expect(_botaoSalvar(tester).onPressed, isNull);
    expect(find.text('Descartar'), findsNothing);

    await tester.enterText(find.byType(TextField), 'Toma em jejum. Alergia a dipirona.');
    await tester.pump();
    expect(_botaoSalvar(tester).onPressed, isNotNull);

    await tester.tap(find.text('Descartar'));
    await tester.pump();
    expect(find.widgetWithText(TextField, 'Toma em jejum.'), findsOneWidget);
    expect(_botaoSalvar(tester).onPressed, isNull);
  });

  testWidgets('Sincronização: atualiza o campo se não está editando; preserva o rascunho se está', (tester) async {
    late StateSetter redesenhar;
    var obs = 'Versão 1';
    await montarPagina(tester, estadoCuidador(), '/x', (_) => Scaffold(
          body: StatefulBuilder(builder: (context, setState) {
            redesenhar = setState;
            return SingleChildScrollView(child: CartaoObservacoes(paciente: _paciente(obs)));
          }),
        ));

    // Sem edição em andamento: o valor novo do servidor aparece.
    redesenhar(() => obs = 'Versão 2 (alterada no web)');
    await tester.pump();
    expect(find.widgetWithText(TextField, 'Versão 2 (alterada no web)'), findsOneWidget);

    // Com rascunho: a sincronização não apaga o que está sendo digitado.
    await tester.enterText(find.byType(TextField), 'Meu rascunho');
    await tester.pump();
    redesenhar(() => obs = 'Versão 3');
    await tester.pump();
    expect(find.widgetWithText(TextField, 'Meu rascunho'), findsOneWidget);
  });

  testWidgets('Sem observações: campo vazio com exemplo', (tester) async {
    await montarPagina(tester, estadoCuidador(), '/x',
        (_) => Scaffold(body: SingleChildScrollView(child: CartaoObservacoes(paciente: _paciente(null)))));
    expect(tester.widget<TextField>(find.byType(TextField)).controller!.text, isEmpty);
    expect(find.textContaining('alergia a dipirona'), findsOneWidget); // exemplo (hint)
  });

  test('AppEstado expõe o salvamento das observações', () {
    expect(AppEstado().atualizarObservacoesClinicas, isA<Function>());
  });
}
