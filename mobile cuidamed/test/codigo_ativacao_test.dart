import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:cuidamed_mobile/estado/app_estado.dart';
import 'package:cuidamed_mobile/modelos/paciente.dart';
import 'package:cuidamed_mobile/paginas/definir_senha.dart';
import 'package:cuidamed_mobile/paginas/detalhe_paciente.dart';

import 'apoio.dart';

AppEstado _cuidadorCom(String? codigo) {
  final estado = estadoCuidador();
  final dados = estado.pacientes.first;
  estado.pacientes = [
    PacienteComDados(
      paciente: Paciente(id: 1, nome: 'Maria da Silva', email: 'maria@email.com', cuidadorId: 5, codigoAtivacao: codigo),
      medicamentos: dados.medicamentos,
      historico: dados.historico,
    ),
  ];
  return estado;
}

void main() {
  testWidgets('Detalhes mostram o código enquanto o paciente não ativou o acesso', (tester) async {
    await montarPagina(tester, _cuidadorCom('K7M2QA'), '/cuidador/paciente/1', (_) => const DetalhePaciente(pacienteId: 1));
    await rolarAte(tester, find.text('K7M2QA'));
    expect(find.text('Acesso do paciente'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Depois de ativado (sem código), o card some', (tester) async {
    await montarPagina(tester, _cuidadorCom(null), '/cuidador/paciente/1', (_) => const DetalhePaciente(pacienteId: 1));
    await rolarAte(tester, find.text('Observações clínicas'));
    expect(find.text('Acesso do paciente'), findsNothing);
  });

  testWidgets('"Ativar meu acesso" pede o código', (tester) async {
    await montarPagina(tester, estadoPaciente()..usuario = null, '/definir-senha', (_) => const DefinirSenha());
    expect(find.text('Código de ativação'), findsOneWidget);

    await tester.enterText(find.widgetWithText(TextField, 'seu@email.com'), 'maria@email.com');
    await rolarAte(tester, find.text('Ativar acesso'));
    await tester.tap(find.text('Ativar acesso'));
    await tester.pump();
    expect(find.text('Informe o código de ativação que seu cuidador passou.'), findsOneWidget);
  });
}
