import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:cuidamed_mobile/estado/app_estado.dart';
import 'package:cuidamed_mobile/modelos/historico.dart';
import 'package:cuidamed_mobile/modelos/medicamento.dart';
import 'package:cuidamed_mobile/paginas/agenda_medicamentos.dart';
import 'package:cuidamed_mobile/utilitarios/horarios.dart';
import 'package:cuidamed_mobile/utilitarios/whatsapp.dart';

import 'apoio.dart';

Historico _h(String data, String status) => Historico(
      id: 1,
      pacienteId: 1,
      medicamentoId: 1,
      data: DateTime.parse(data),
      hora: '08:00',
      nomeMedicamento: 'X',
      dosagem: '1mg',
      status: status,
    );

void main() {
  group('Adesão: só os últimos 30 dias (o que o rótulo promete)', () {
    const hoje = '2026-09-24';
    test('ignora registros mais antigos que 30 dias', () {
      final historico = [
        _h('2026-08-01', 'PERDIDO'), _h('2026-08-02', 'PERDIDO'), // fora da janela
        _h('2026-08-26', 'TOMADO'), // 29 dias atrás: dentro
        _h('2026-09-24', 'PERDIDO'),
      ];
      expect(calcularAdesao(historico, hojeIso: hoje), 50); // antes: 25%
    });
    test('30 dias atrás já fica fora', () {
      expect(calcularAdesao([_h('2026-08-25', 'PERDIDO')], hojeIso: hoje), 100);
    });
  });

  group('Lembrete do WhatsApp: contagem de dias do ciclo', () {
    String mensagem(DateTime? fim) => montarMensagemLembrete(
          nomePaciente: 'Maria',
          medicamento: 'X',
          horario: '08:00',
          forma: 'COMPRIMIDO',
          quantidadePorDose: 1,
          dosagem: '10mg',
          dataFim: fim,
        );
    final hoje = DateTime.now();
    final diaHoje = DateTime(hoje.year, hoje.month, hoje.day);
    test('último dia', () => expect(mensagem(diaHoje), contains('Hoje é o último dia do ciclo')));
    test('véspera', () => expect(mensagem(diaHoje.add(const Duration(days: 1))), contains('Falta 1 dia para acabar')));
    test('vários dias', () => expect(mensagem(diaHoje.add(const Duration(days: 5))), contains('Faltam 5 dias para acabar')));
    test('uso contínuo: sem frase de ciclo', () => expect(mensagem(null), isNot(contains('ciclo'))));
  });

  testWidgets('Estoque com menos de um dia: "não dá para o dia todo" (antes "dura ~0 dias")', (tester) async {
    final estado = estadoPaciente();
    final dados = estado.pacientes.first;
    estado.pacientes = [
      PacienteComDados(paciente: dados.paciente, historico: const [], medicamentos: [
        Medicamento(
          id: 9,
          pacienteId: 1,
          nome: 'Remédio',
          dosagem: '10mg',
          forma: 'COMPRIMIDO',
          frequencia: 'TRES_VEZES_AO_DIA',
          dataInicio: DateTime(2026, 1, 1),
          horarios: const ['08:00', '14:00', '20:00'],
          quantidadeEstoque: 2,
          quantidadePorDose: 1,
        ),
      ]),
    ];
    await montarPagina(tester, estado, '/agenda', (_) => const AgendaMedicamentos());
    expect(find.textContaining('não dá para o dia todo'), findsOneWidget);
    expect(find.textContaining('dura ~0'), findsNothing);
  });

  testWidgets('Status das doses se atualizam sozinhos a cada 30 s (como no web) e param ao sair', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final estado = AppEstado();
    var redesenhos = 0;
    estado.addListener(() => redesenhos++);
    await tester.pump(const Duration(seconds: 31));
    expect(redesenhos, 0); // sem login: nenhum relógio

    estado.iniciarRelogio(); // o login liga o relógio
    await tester.pump(const Duration(seconds: 30));
    expect(redesenhos, 1);
    await tester.pump(const Duration(seconds: 30));
    expect(redesenhos, 2);

    await estado.sair();
    final depoisDeSair = redesenhos;
    await tester.pump(const Duration(seconds: 90));
    expect(redesenhos, depoisDeSair); // saiu: relógio parado
    estado.dispose();
  });

  test('Relógio de atualização tem o mesmo intervalo do web (30 s)', () {
    expect(AppEstado.intervaloAtualizacao, const Duration(seconds: 30));
  });
}
