import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:cuidamed_mobile/componentes/escolha_paciente.dart';
import 'package:cuidamed_mobile/estado/app_estado.dart';
import 'package:cuidamed_mobile/modelos/paciente.dart';
import 'package:cuidamed_mobile/paginas/agenda_medicamentos.dart';
import 'package:cuidamed_mobile/paginas/ciclos_encerrados.dart';
import 'package:cuidamed_mobile/paginas/historico.dart';

import 'apoio.dart';

/// Cuidador com dois pacientes; o "em foco" (último acessado) é a Maria.
AppEstado _cuidadorComDois() {
  final estado = estadoCuidador();
  final maria = estado.pacientes.first;
  estado.pacientes = [
    maria,
    PacienteComDados(
      paciente: Paciente(id: 2, nome: 'João Pereira', email: 'joao@email.com'),
      medicamentos: const [],
      historico: const [],
    ),
  ];
  return estado;
}

void main() {
  test('Menu: só as telas por paciente do cuidador abrem com a lista', () {
    expect(rotaDoMenu('/agenda', 'cuidador'), '/agenda?escolher=1');
    expect(rotaDoMenu('/ciclos-encerrados', 'cuidador'), '/ciclos-encerrados?escolher=1');
    expect(rotaDoMenu('/historico', 'cuidador'), '/historico?escolher=1');
    expect(rotaDoMenu('/farmacias', 'cuidador'), '/farmacias');
    expect(rotaDoMenu('/agenda', 'paciente'), '/agenda');
  });

  testWidgets('Pelo menu, as três telas mostram a lista de pacientes', (tester) async {
    for (final (rota, pagina) in [
      ('/agenda', const AgendaMedicamentos() as Widget),
      ('/ciclos-encerrados', const CiclosEncerrados()),
      ('/historico', const HistoricoPagina()),
    ]) {
      await montarPagina(tester, _cuidadorComDois(), '$rota?escolher=1', (_) => pagina);
      expect(find.text('Escolha o paciente'), findsOneWidget, reason: rota);
      expect(find.text('Maria da Silva'), findsOneWidget, reason: rota);
      expect(find.text('João Pereira'), findsOneWidget, reason: rota);
    }
  });

  testWidgets('Escolher um paciente abre a tela dele (não o último acessado)', (tester) async {
    final estado = _cuidadorComDois();
    await montarPagina(tester, estado, '/ciclos-encerrados?escolher=1', (_) => const CiclosEncerrados());
    await tester.tap(find.text('João Pereira'));
    await tester.pumpAndSettle();
    expect(estado.pacienteFocoId, 2);
    expect(find.text('Escolha o paciente'), findsNothing);
    expect(find.text('Ciclos encerrados de João Pereira'), findsOneWidget);
  });

  testWidgets('Sem o parâmetro (vindo dos detalhes) abre direto; paciente nunca vê a lista', (tester) async {
    await montarPagina(tester, _cuidadorComDois(), '/agenda', (_) => const AgendaMedicamentos());
    expect(find.text('Escolha o paciente'), findsNothing);

    await montarPagina(tester, estadoPaciente(), '/agenda?escolher=1', (_) => const AgendaMedicamentos());
    expect(find.text('Escolha o paciente'), findsNothing);
  });

  testWidgets('Sem pacientes vinculados: aviso e atalho para o início', (tester) async {
    final estado = estadoCuidador()..pacientes = [];
    await montarPagina(tester, estado, '/agenda?escolher=1', (_) => const AgendaMedicamentos());
    expect(find.text('Nenhum paciente vinculado ainda.'), findsOneWidget);
    expect(find.text('Ir para o início'), findsOneWidget);
  });
}
